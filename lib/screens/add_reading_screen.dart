import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/db_helper.dart';
import '../models/reading.dart';

class AddReadingScreen extends StatefulWidget {
  const AddReadingScreen({Key? key}) : super(key: key);

  @override
  State<AddReadingScreen> createState() => _AddReadingScreenState();
}

class _AddReadingScreenState extends State<AddReadingScreen> {
  final _usageController = TextEditingController();
  final _notesController = TextEditingController();
  final _authService = AuthService();
  final _dbHelper = DBHelper();
  String _selectedType = 'electricity';
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _addReading() async {
    if (_usageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter usage amount')),
      );
      return;
    }

    final userId = _authService.currentUserId;
    if (userId == null) return;

    final reading = Reading(
      userId: userId,
      usage: double.parse(_usageController.text),
      type: _selectedType,
      date: _selectedDate,
      notes: _notesController.text,
    );

    await _dbHelper.insertReading(reading);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reading added successfully')),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Reading'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Utility Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
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
              },
            ),
            const SizedBox(height: 20),
            const Text('Usage Amount',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _usageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Enter usage',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixText: _selectedType == 'electricity' ? 'kWh' : 'L',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Date',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_selectedDate.toString().split(' ')[0]),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Notes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Add notes (optional)',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addReading,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child:
                    const Text('Add Reading', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usageController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
