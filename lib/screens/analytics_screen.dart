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
  // Authentication service to get current user
  final _authService = AuthService();

  // Database helper to get readings (electricity / water)
  final _dbHelper = DBHelper();

  // Stores the list of readings fetched from database
  List<Reading> _readings = [];

  // Default selected type of reading
  String _selectedType = 'electricity';

  @override
  void initState() {
    super.initState();
    _loadReadings(); // Load readings when screen opens
  }

  // Loads readings from database based on selected type
  Future<void> _loadReadings() async {
    final userId = _authService.currentUserId;

    // Only load readings if user is logged in
    if (userId != null) {
      final readings = await _dbHelper.getReadingsByType(userId, _selectedType);

      // Update UI with new readings
      setState(() {
        _readings = readings;
      });
    }
  }

  // This uses do-while logic to reload readings until the list has data
  void _updateReadingsDoWhile() {
    do {
      _loadReadings();
    } while (_readings.isEmpty);
  }

  // Converts readings into chart points (FlSpot)
  List<FlSpot> _getChartData() {
    final sortedReadings = _readings.reversed.toList(); // Newest first

    return List.generate(
      sortedReadings.length,
      (index) => FlSpot(
        index.toDouble(), // X-axis: index
        sortedReadings[index].usage, // Y-axis: usage
      ),
    );
  }

  // Calculates the average usage for the selected type
  double _getAverageUsage() {
    if (_readings.isEmpty) return 0;

    final total =
        _readings.fold<double>(0, (sum, reading) => sum + reading.usage);

    return total / _readings.length;
  }

  // Predicts the next usage using simple linear regression
  double _predictNextUsage() {
    // If few readings exist, fallback to average usage
    if (_readings.length < 2) return _getAverageUsage();

    final sortedReadings = _readings.reversed.toList();

    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    final n = sortedReadings.length;

    // Calculate values for regression formula
    for (int i = 0; i < n; i++) {
      sumX += i;
      sumY += sortedReadings[i].usage;
      sumXY += i * sortedReadings[i].usage;
      sumX2 += i * i;
    }

    // Linear regression: slope (m) and intercept (b)
    final slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    // Predict next value for x = n
    final predictedUsage = intercept + slope * n;

    // Avoid negative predictions
    return predictedUsage > 0 ? predictedUsage : _getAverageUsage();
  }

  // Returns unit based on selected reading type
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

      // Allows page to scroll
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dropdown to switch between electricity or water
            DropdownButton<String>(
              value: _selectedType,
              isExpanded: true,
              items: ['electricity', 'water'].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()), // Display in uppercase
                );
              }).toList(),

              // When user selects a new type, reload data
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
                _updateReadingsDoWhile();
              },
            ),

            const SizedBox(height: 24),

            // Card showing average usage
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Average Usage',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 8),

                    // Show average value in bold blue text
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

            // Card showing predicted next usage
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Expected Next Usage',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),

                    const SizedBox(height: 8),

                    // Display predicted usage
                    Text(
                      '${_predictNextUsage().toStringAsFixed(2)} ${_getUnit()}',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),

                    const SizedBox(height: 8),

                    // Helpful info for user
                    Text(
                      'Based on ${_readings.length} readings',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // If readings exist, show chart
            if (_readings.isNotEmpty)
              SizedBox(
                height: 300,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: const FlTitlesData(show: true),
                    borderData: FlBorderData(show: true),

                    // One line on the chart
                    lineBarsData: [
                      LineChartBarData(
                        spots: _getChartData(), // Data points
                        isCurved: true, // Smooth line
                        color: Colors.blue,
                        barWidth: 2,
                        dotData: const FlDotData(show: true), // Show points
                      ),
                    ],
                  ),
                ),
              )
            else
              // If no readings in database
              const Center(child: Text('No data available for chart')),
          ],
        ),
      ),
    );
  }
}
