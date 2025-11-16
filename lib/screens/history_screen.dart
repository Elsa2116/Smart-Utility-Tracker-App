import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/db_helper.dart';
import '../models/reading.dart';
import '../widgets/reading_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _authService = AuthService();
  final _dbHelper = DBHelper();
  List<Reading> _readings = [];
  String _selectedType = 'all';

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    final userId = _authService.currentUserId;
    if (userId != null) {
      List<Reading> readings;
      if (_selectedType == 'all') {
        readings = await _dbHelper.getReadingsByUserId(userId);
      } else {
        readings = await _dbHelper.getReadingsByType(userId, _selectedType);
      }
      setState(() {
        _readings = readings;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reading History'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<String>(
              value: _selectedType,
              isExpanded: true,
              items: ['all', 'electricity', 'water'].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type == 'all' ? 'All Types' : type.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!;
                });
                _loadReadings();
              },
            ),
          ),
          Expanded(
            child: _readings.isEmpty
                ? const Center(child: Text('No readings found'))
                : ListView.builder(
                    itemCount: _readings.length,
                    itemBuilder: (context, index) {
                      return Dismissible(
                        key: Key(_readings[index].id.toString()),
                        onDismissed: (direction) async {
                          await _dbHelper.deleteReading(_readings[index].id!);
                          _loadReadings();
                        },
                        child: ReadingCard(reading: _readings[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
