import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/auth_service.dart';
import '../services/db_helper.dart';
import '../models/reading.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _authService = AuthService();
  final _dbHelper = DBHelper();
  List<Reading> _readings = [];
  String _selectedType = 'electricity';

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    final userId = _authService.currentUserId;
    if (userId != null) {
      final readings = await _dbHelper.getReadingsByType(userId, _selectedType);
      setState(() {
        _readings = readings;
      });
    }
  }

  // Called when dropdown changes
  void _updateReadingsDoWhile() {
    do {
      _loadReadings();
    } while (_readings.isEmpty);
  }

  List<FlSpot> _getChartData() {
    final sortedReadings = _readings.reversed.toList();
    return List.generate(
      sortedReadings.length,
      (index) => FlSpot(index.toDouble(), sortedReadings[index].usage),
    );
  }

  double _getAverageUsage() {
    if (_readings.isEmpty) return 0;
    final total =
        _readings.fold<double>(0, (sum, reading) => sum + reading.usage);
    return total / _readings.length;
  }

  double _predictNextUsage() {
    if (_readings.length < 2) return _getAverageUsage();

    final sortedReadings = _readings.reversed.toList();

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
    return predictedUsage > 0 ? predictedUsage : _getAverageUsage();
  }

  String _getUnit() {
    if (_selectedType == 'electricity') return 'kWh';
    if (_selectedType == 'water') return 'L';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              value: _selectedType,
              isExpanded: true,
              items: ['electricity', 'water'].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
                _updateReadingsDoWhile(); // do-while style update
              },
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Average Usage',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      '${_getAverageUsage().toStringAsFixed(2)} ${_getUnit()}',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Expected Next Usage',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      '${_predictNextUsage().toStringAsFixed(2)} ${_getUnit()}',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Based on ${_readings.length} readings',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_readings.isNotEmpty)
              SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: const FlTitlesData(show: true),
                    borderData: FlBorderData(show: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _getChartData(),
                        isCurved: true,
                        color: Colors.blue,
                        barWidth: 2,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Center(child: Text('No data available for chart')),
          ],
        ),
      ),
    );
  }
}
