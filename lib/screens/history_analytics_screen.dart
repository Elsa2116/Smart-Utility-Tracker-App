import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart'; // For drawing charts
import '../services/auth_service.dart'; // Custom auth service to get current user
import '../services/db_helper.dart'; // Custom database helper for readings
import '../models/reading.dart'; // Reading model

// Stateful widget to display user's reading history and analytics
class HistoryAnalyticsScreen extends StatefulWidget {
  const HistoryAnalyticsScreen({super.key});

  @override
  State<HistoryAnalyticsScreen> createState() => _HistoryAnalyticsScreenState();
}

// State class with SingleTickerProviderStateMixin for TabController
class _HistoryAnalyticsScreenState extends State<HistoryAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  // Services
  final _authService = AuthService();
  final _dbHelper = DBHelper();

  late TabController _tabController; // Controller for History/Analytics tabs
  List<Reading> _allReadings = []; // All readings fetched
  List<Reading> _filteredReadings = []; // Filtered readings based on type
  String _selectedType = 'all'; // Filter type ('all', 'electricity', 'water')
  bool _isLoading = true; // Loading state
  Map<String, dynamic> _analyticsData = {}; // Analytics data for charts/cards

  String _chartType = 'electricity'; // Type of chart displayed in Analytics tab

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Two tabs
    _loadData(); // Load readings on init
  }

  @override
  void dispose() {
    _tabController.dispose(); // Dispose controller to free resources
    super.dispose();
  }

  //  Load reading data from REAL database (no demo data)
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final userId = _authService.currentUserId;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      //  Get latest readings from DB (already ordered DESC in DBHelper)
      final readings = await _dbHelper.getReadingsByUserId(userId);

      setState(() {
        _allReadings = readings;
        _isLoading = false;
      });

      //  Apply current filter after loading
      _filterReadings();
    } catch (e) {
      // If something fails, stop loading safely
      setState(() => _isLoading = false);
      debugPrint('Error loading readings: $e');
    }
  }

  // Filter readings based on selected type
  void _filterReadings() {
    if (_selectedType == 'all') {
      setState(() => _filteredReadings = List<Reading>.from(_allReadings));
    } else {
      setState(() {
        _filteredReadings = _allReadings
            .where((reading) => reading.type == _selectedType)
            .toList();
      });
    }
    _calculateAnalytics(); // Recalculate analytics after filtering
  }

  //  Delete all readings (or by type) from DB + refresh UI
  Future<void> _clearReadingsFromDb() async {
    final userId = _authService.currentUserId;
    if (userId == null) return;

    final db = await _dbHelper.database;

    // If 'all', delete all readings for user
    if (_selectedType == 'all') {
      await db.delete('readings', where: 'userId = ?', whereArgs: [userId]);
    } else {
      // Otherwise delete only the selected type
      await db.delete('readings',
          where: 'userId = ? AND type = ?', whereArgs: [userId, _selectedType]);
    }

    // Reload from DB so UI + analytics update correctly
    await _loadData();
  }

  // Delete single reading from DB + refresh UI
  Future<void> _deleteSingleReading(Reading reading) async {
    if (reading.id == null) return;

    await _dbHelper.deleteReading(reading.id!);

    // Remove locally for instant UI, then recompute analytics
    setState(() {
      _allReadings.removeWhere((r) => r.id == reading.id);
    });
    _filterReadings();
  }

  // Calculate analytics data: total, average, max, min, trends, predictions
  void _calculateAnalytics() {
    if (_allReadings.isEmpty) {
      setState(() => _analyticsData = {});
      return;
    }

    // Separate electricity and water readings
    final electricityReadings =
        _allReadings.where((r) => r.type == 'electricity').toList();
    final waterReadings = _allReadings.where((r) => r.type == 'water').toList();

    // Electricity analytics
    final electricityAvg = electricityReadings.isNotEmpty
        ? electricityReadings.fold<double>(0, (sum, r) => sum + r.usage) /
            electricityReadings.length
        : 0;
    final electricityTotal = electricityReadings.isNotEmpty
        ? electricityReadings.fold<double>(0, (sum, r) => sum + r.usage)
        : 0;
    final electricityMax = electricityReadings.isNotEmpty
        ? electricityReadings
            .map((r) => r.usage)
            .reduce((a, b) => a > b ? a : b)
        : 0;
    final electricityMin = electricityReadings.isNotEmpty
        ? electricityReadings
            .map((r) => r.usage)
            .reduce((a, b) => a < b ? a : b)
        : 0;

    // Water analytics
    final waterAvg = waterReadings.isNotEmpty
        ? waterReadings.fold<double>(0, (sum, r) => sum + r.usage) /
            waterReadings.length
        : 0;
    final waterTotal = waterReadings.isNotEmpty
        ? waterReadings.fold<double>(0, (sum, r) => sum + r.usage)
        : 0;
    final waterMax = waterReadings.isNotEmpty
        ? waterReadings.map((r) => r.usage).reduce((a, b) => a > b ? a : b)
        : 0;
    final waterMin = waterReadings.isNotEmpty
        ? waterReadings.map((r) => r.usage).reduce((a, b) => a < b ? a : b)
        : 0;

    // Predict next month usage
    final electricityPrediction = _predictNextUsage(electricityReadings);
    final waterPrediction = _predictNextUsage(waterReadings);

    // Trend calculation (percentage change)
    final electricityTrend = electricityReadings.length >= 2
        ? _calculateTrend(electricityReadings)
        : 0;
    final waterTrend =
        waterReadings.length >= 2 ? _calculateTrend(waterReadings) : 0;

    setState(() {
      _analyticsData = {
        'electricity': {
          'readings': electricityReadings,
          'average': electricityAvg,
          'total': electricityTotal,
          'max': electricityMax,
          'min': electricityMin,
          'prediction': electricityPrediction,
          'trend': electricityTrend,
          'count': electricityReadings.length,
        },
        'water': {
          'readings': waterReadings,
          'average': waterAvg,
          'total': waterTotal,
          'max': waterMax,
          'min': waterMin,
          'prediction': waterPrediction,
          'trend': waterTrend,
          'count': waterReadings.length,
        },
        'overall': {
          'totalReadings': _allReadings.length,
          'totalElectricity': electricityTotal,
          'totalWater': waterTotal,
        },
      };
    });
  }

  // Predict next usage using simple linear regression
  double _predictNextUsage(List<Reading> readings) {
    if (readings.length < 2) return 0;

    // Sort by date ascending (oldest -> newest)
    final sortedReadings = List<Reading>.from(readings)
      ..sort((a, b) => a.date.compareTo(b.date));

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    final n = sortedReadings.length;

    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += sortedReadings[i].usage;
      sumXY += i * sortedReadings[i].usage;
      sumX2 += i * i;
    }

    final denom = (n * sumX2 - sumX * sumX);
    if (denom == 0) return 0;

    final slope = (n * sumXY - sumX * sumY) / denom;
    final intercept = (sumY - slope * sumX) / n;
    final predictedUsage = intercept + slope * n;

    return predictedUsage > 0 ? predictedUsage : 0;
  }

  // Calculate percentage trend between first half and second half of readings
  double _calculateTrend(List<Reading> readings) {
    if (readings.length < 2) return 0;

    readings.sort((a, b) => a.date.compareTo(b.date));
    final firstHalf = readings.sublist(0, readings.length ~/ 2);
    final secondHalf = readings.sublist(readings.length ~/ 2);

    final firstAvg =
        firstHalf.fold<double>(0, (sum, r) => sum + r.usage) / firstHalf.length;
    final secondAvg = secondHalf.fold<double>(0, (sum, r) => sum + r.usage) /
        secondHalf.length;

    if (firstAvg == 0) return 0;
    return ((secondAvg - firstAvg) / firstAvg) * 100; // Trend as percentage
  }

  // Get unit string for display
  String _getUnit(String type) => type == 'electricity' ? 'kWh' : 'L';

  // Get color based on trend
  Color _getTrendColor(double trend) {
    if (trend > 10) return Colors.red;
    if (trend > 5) return Colors.orange;
    if (trend < -10) return Colors.green;
    if (trend < -5) return Colors.lightGreen;
    return Colors.grey;
  }

  // Get descriptive text for trend
  String _getTrendText(double trend) {
    if (trend > 10) return '↑ High Increase';
    if (trend > 5) return '↑ Slight Increase';
    if (trend < -10) return '↓ High Decrease';
    if (trend < -5) return '↓ Slight Decrease';
    return '→ Stable';
  }

  // Convert readings to FlSpot for charts
  List<FlSpot> _getChartData(String type) {
    final readings = _analyticsData[type]?['readings'] as List<Reading>? ?? [];
    if (readings.isEmpty) return [];

    readings.sort((a, b) => a.date.compareTo(b.date));
    return List.generate(
      readings.length,
      (index) => FlSpot(index.toDouble(), readings[index].usage),
    );
  }

  // ✅ REPLACED: Better interval helper for Y-axis labels (prevents 100/300 jumps)
  double _getYAxisInterval(List<FlSpot> spots) {
    if (spots.isEmpty) return 1;

    final ys = spots.map((e) => e.y).toList()..sort();
    final minY = ys.first;
    final maxY = ys.last;

    final range = (maxY - minY).abs();
    if (range == 0) return 1;

    // We want about 6–8 labels
    final raw = range / 7;

    // Choose "nice" intervals
    if (raw <= 1) return 1;
    if (raw <= 2) return 2;
    if (raw <= 5) return 5;
    if (raw <= 10) return 10;
    if (raw <= 20) return 20;
    if (raw <= 50) return 50;
    if (raw <= 100) return 100;

    return 200;
  }

  // Build the History tab
  Widget _buildHistoryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    return Column(
      children: [
        // Filter dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFF374151),
          child: Row(
            children: [
              const Icon(Icons.filter_list, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              const Text('Filter by:', style: TextStyle(color: Colors.white70)),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4B5563),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedType,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF4B5563),
                    style: const TextStyle(color: Colors.white),
                    icon: const Icon(Icons.arrow_drop_down,
                        color: Colors.white70),
                    underline: Container(),
                    items: ['all', 'electricity', 'water'].map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                            type == 'all' ? 'All Types' : type.toUpperCase(),
                            style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedType = value!);
                      _filterReadings(); // Update filtered list
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Total readings count and clear button
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Readings: ${_filteredReadings.length}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              ElevatedButton.icon(
                onPressed: () {
                  // Show delete confirmation dialog
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF374151),
                      title: const Text('Clear History',
                          style: TextStyle(color: Colors.white)),
                      content: Text('Clear all $_selectedType readings?',
                          style: const TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel',
                                style: TextStyle(color: Colors.blue))),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context);

                            //  Clear from DB (not just UI)
                            await _clearReadingsFromDb();

                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('$_selectedType readings cleared'),
                                  backgroundColor: Colors.green),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                },
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Clear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.2),
                  foregroundColor: Colors.red,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
        ),

        // List of readings
        Expanded(
          child: _filteredReadings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history,
                          size: 64, color: Colors.blue.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      const Text('No readings found',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 18)),
                      const SizedBox(height: 8),
                      const Text('Add readings to see history',
                          style: TextStyle(color: Colors.grey, fontSize: 14)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: _filteredReadings.length,
                  itemBuilder: (context, index) {
                    final reading = _filteredReadings[index];
                    return Dismissible(
                      key: Key(reading.id?.toString() ?? index.toString()),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete,
                            color: Colors.white, size: 30),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) async {
                        //  Delete from DB
                        await _deleteSingleReading(reading);

                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Deleted ${reading.type} reading'),
                              backgroundColor: Colors.red),
                        );
                      },
                      child: _buildReadingCard(reading),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Individual reading card
  Widget _buildReadingCard(Reading r) {
    IconData icon = r.type == 'water' ? Icons.water_drop : Icons.bolt;
    Color color = r.type == 'water' ? Colors.blue : Colors.amber;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4B5563)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.type.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text('${r.date.day}/${r.date.month}/${r.date.year}',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${r.usage}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              Text(r.type == 'electricity' ? 'kWh' : 'L',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  // Analytics tab
  Widget _buildAnalyticsTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    if (_allReadings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics,
                size: 64, color: Colors.blue.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('No analytics data',
                style: TextStyle(color: Colors.white70, fontSize: 18)),
            const SizedBox(height: 8),
            const Text('Add readings to see analytics',
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/add-reading')
                    .then((_) => _loadData());
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Add First Reading'),
            ),
          ],
        ),
      );
    }

    final data = _analyticsData[_chartType] as Map<String, dynamic>? ?? {};
    final avg = (data['average'] ?? 0).toDouble();
    final total = (data['total'] ?? 0).toDouble();
    final max = (data['max'] ?? 0).toDouble();
    final min = (data['min'] ?? 0).toDouble();
    final prediction = (data['prediction'] ?? 0).toDouble();
    final trend = (data['trend'] ?? 0).toDouble();
    final unit = _getUnit(_chartType);

    final spots = _getChartData(_chartType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart type selector (electricity/water)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF374151),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4B5563)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tune, color: Colors.white70, size: 20),
                const SizedBox(width: 10),
                const Text('Chart:', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4B5563),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButton<String>(
                      value: _chartType,
                      isExpanded: true,
                      dropdownColor: const Color(0xFF4B5563),
                      style: const TextStyle(color: Colors.white),
                      underline: Container(),
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.white70),
                      items: const [
                        DropdownMenuItem(
                          value: 'electricity',
                          child: Text('ELECTRICITY'),
                        ),
                        DropdownMenuItem(
                          value: 'water',
                          child: Text('WATER'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _chartType = value);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Summary cards row
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  title: 'Average',
                  value: avg.toStringAsFixed(1),
                  unit: unit,
                  icon: Icons.bar_chart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  title: 'Total',
                  value: total.toStringAsFixed(1),
                  unit: unit,
                  icon: Icons.summarize,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  title: 'Max',
                  value: max.toStringAsFixed(1),
                  unit: unit,
                  icon: Icons.trending_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalyticsCard(
                  title: 'Min',
                  value: min.toStringAsFixed(1),
                  unit: unit,
                  icon: Icons.trending_down,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Trend + prediction
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF374151),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4B5563)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Insights',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.show_chart, color: _getTrendColor(trend)),
                    const SizedBox(width: 8),
                    Text(
                      '${_getTrendText(trend)} (${trend.toStringAsFixed(1)}%)',
                      style: TextStyle(color: _getTrendColor(trend)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.auto_graph, color: Colors.white70),
                    const SizedBox(width: 8),
                    Text(
                      'Next prediction: ${prediction.toStringAsFixed(1)} $unit',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Line chart with Y-axis numbers
          Container(
            height: 260,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF374151),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4B5563)),
            ),
            child: spots.isEmpty
                ? const Center(
                    child: Text('No chart data',
                        style: TextStyle(color: Colors.white70)),
                  )
                : LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),

                      //  SHOW LEFT (Y) + BOTTOM (X) numbers
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            interval: _getYAxisInterval(spots),
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toStringAsFixed(0),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                (value.toInt() + 1).toString(),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 10),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),

                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                        ),
                      ],
                    ),
                  ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Small analytics card widget
  Widget _buildAnalyticsCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4B5563)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Text('$value $unit',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History & Analytics'),
        centerTitle: true,
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F2937), Color(0xFF111827)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildHistoryTab(),
            _buildAnalyticsTab(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // After add-reading returns, reload DB
          Navigator.pushNamed(context, '/add-reading').then((_) => _loadData());
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
