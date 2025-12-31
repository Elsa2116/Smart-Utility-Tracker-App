import 'package:flutter/material.dart'; // Flutter UI toolkit
import '../services/auth_service.dart'; // Auth service (user login)
import '../services/db_helper.dart'; // Database helper
import '../models/reading.dart'; // Reading model

class AddReadingScreen extends StatefulWidget {
  // Screen to add new reading
  final void Function(int index)? onTabChange;
  const AddReadingScreen({super.key, this.onTabChange}); // Constructor

  @override
  State<AddReadingScreen> createState() =>
      _AddReadingScreenState(); // Create state
}

class _AddReadingScreenState extends State<AddReadingScreen> {
  final _usageController = TextEditingController(); // Controls usage input
  final _notesController = TextEditingController(); // Controls notes input
  final _authService = AuthService(); // Auth service instance
  final _dbHelper = DBHelper(); // Database helper instance
  String _selectedType = 'electricity'; // Default utility type
  DateTime _selectedDate = DateTime.now(); // Selected date (default today)

  // Opens date picker
  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context, // Required for showing dialog
      initialDate: _selectedDate, // Current selected date
      firstDate: DateTime(2020), // Earliest allowed date
      lastDate: DateTime.now(), // Latest allowed date
    );
    if (picked != null) {
      // If user chooses a date
      setState(() {
        _selectedDate = picked; // Update date
      });
    }
  }

  // Adds reading to database
  Future<void> _addReading() async {
    if (_usageController.text.isEmpty) {
      // Check if usage is empty
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter usage amount')), // Error message
      );
      return; // Stop function
    }

    // ✅ validate number (prevents crash if user types letters)
    final usageValue = double.tryParse(_usageController.text);
    if (usageValue == null || usageValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid number')),
      );
      return;
    }

    final userId = _authService.currentUserId; // Get logged-in user's ID
    if (userId == null) return; // Stop if no user

    // Create Reading object from inputs
    final reading = Reading(
      userId: userId,
      usage: usageValue, // Convert to number
      type: _selectedType, // Selected type
      date: _selectedDate, // Selected date
      notes: _notesController.text, // Notes
    );

    await _dbHelper.insertReading(reading); // Insert into DB

    if (mounted) {
      // If widget is still active
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Reading added successfully')), // Success message
      );

      // ✅ Clear fields after success
      _usageController.clear();
      _notesController.clear();

      // ✅ Reset selections
      setState(() {
        _selectedType = 'electricity';
        _selectedDate = DateTime.now();
      });

      widget.onTabChange?.call(0); // Go back to previous screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Reading'),
        centerTitle: true,
      ),
      resizeToAvoidBottomInset:
          true, // allows screen to resize when keyboard opens
      body: SafeArea(
        // prevents content from being hidden under status bar/notch
        child: SingleChildScrollView(
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
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
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
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
      ),
    );
  }

  @override
  void dispose() {
    _usageController.dispose(); // Cleanup usage controller
    _notesController.dispose(); // Cleanup notes controller
    super.dispose(); // Call parent dispose
  }
}
