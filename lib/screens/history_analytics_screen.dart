// history_analytics_screen.dart

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

  // Load reading data from database or demo data
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final userId = _authService.currentUserId;
    if (userId != null) {
      // Demo data for now; replace with actual DB call
      setState(() {
        _allReadings = [
          Reading(
              userId: 1,
              usage: 245,
              type: 'electricity',
              date: DateTime.now().subtract(const Duration(days: 1))),
          Reading(
              userId: 1,
              usage: 220,
              type: 'electricity',
              date: DateTime.now().subtract(const Duration(days: 30))),
          Reading(
              userId: 1,
              usage: 210,
              type: 'electricity',
              date: DateTime.now().subtract(const Duration(days: 60))),
          Reading(
              userId: 1,
              usage: 45,
              type: 'water',
              date: DateTime.now().subtract(const Duration(days: 2))),
          Reading(
              userId: 1,
              usage: 40,
              type: 'water',
              date: DateTime.now().subtract(const Duration(days: 32))),
          Reading(
              userId: 1,
              usage: 38,
              type: 'water',
              date: DateTime.now().subtract(const Duration(days: 62))),
        ];
        _filteredReadings = _allReadings; // Initially show all readings
        _isLoading = false;
        _calculateAnalytics(); // Compute analytics data
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  // Filter readings based on selected type
  void _filterReadings() {
    if (_selectedType == 'all') {
      setState(() => _filteredReadings = _allReadings);
    } else {
      setState(() {
        _filteredReadings = _allReadings
            .where((reading) => reading.type == _selectedType)
            .toList();
      });
    }
    _calculateAnalytics(); // Recalculate analytics after filtering
  }

  // Calculate analytics data: total, average, max, min, trends, predictions
  void _calculateAnalytics() {
    if (_allReadings.isEmpty) return;

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

    final sortedReadings = List<Reading>.from(readings.reversed);
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    final n = sortedReadings.length;

    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += sortedReadings[i].usage;
      sumXY += i * sortedReadings[i].usage;
      sumX2 += i * i;
    }

    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
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
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              if (_selectedType == 'all') {
                                _allReadings.clear();
                              } else {
                                _allReadings.removeWhere(
                                    (r) => r.type == _selectedType);
                              }
                              _filterReadings();
                            });
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
                      onDismissed: (direction) {
                        setState(() {
                          _allReadings.remove(reading);
                          _filterReadings();
                        });
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
                Navigator.pushNamed(context, '/add-reading');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Add First Reading'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart type selector (electricity/water)
          // ... [rest of the analytics widgets, summary cards, charts, detail cards, trends]
          // Already have clear comments for chart/trend calculations above
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
          Navigator.pushNamed(context, '/add-reading').then((_) => _loadData());
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
