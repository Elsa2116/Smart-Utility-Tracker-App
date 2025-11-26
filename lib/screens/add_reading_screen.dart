import 'package:flutter/material.dart'; // Flutter UI toolkit
import '../services/auth_service.dart'; // Auth service (user login)
import '../services/db_helper.dart'; // Database helper
import '../models/reading.dart'; // Reading model

class AddReadingScreen extends StatefulWidget {
  // Screen to add new reading
  const AddReadingScreen({Key? key}) : super(key: key); // Constructor

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

    final userId = _authService.currentUserId; // Get logged-in user's ID
    if (userId == null) return; // Stop if no user

    // Create Reading object from inputs
    final reading = Reading(
      userId: userId,
      usage: double.parse(_usageController.text), // Convert to number
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
      Navigator.of(context).pop(); // Go back to previous screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Main screen layout
      appBar: AppBar(
        title: const Text('Add Reading'), // App bar title
        centerTitle: true, // Center the title
      ),
      body: SingleChildScrollView(
        // Scrollable page
        padding: const EdgeInsets.all(16.0), // Screen padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align left
          children: [
            // Section title
            const Text('Utility Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Dropdown for electricity/water
            DropdownButton<String>(
              value: _selectedType, // Current selected
              isExpanded: true, // Full width
              items: ['electricity', 'water'].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toUpperCase()), // Show in uppercase
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedType = value!; // Update selected type
                });
              },
            ),

            const SizedBox(height: 20),

            // Usage label
            const Text('Usage Amount',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Usage input field
            TextField(
              controller: _usageController, // Binds to usage
              keyboardType: TextInputType.number, // Numeric keyboard
              decoration: InputDecoration(
                labelText: 'Enter usage', // Placeholder text
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixText: _selectedType == 'electricity'
                    ? 'kWh'
                    : 'L', // Unit display
              ),
            ),

            const SizedBox(height: 20),

            // Date label
            const Text('Date',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Date selector container
            GestureDetector(
              onTap: () => _selectDate(context), // Opens calendar
              child: Container(
                padding: const EdgeInsets.all(12), // Inner spacing
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey), // Border outline
                  borderRadius: BorderRadius.circular(8), // Rounded corners
                ),
                child: Text(
                    _selectedDate.toString().split(' ')[0]), // Show date only
              ),
            ),

            const SizedBox(height: 20),

            // Notes label
            const Text('Notes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Notes input area
            TextField(
              controller: _notesController, // Notes controller
              maxLines: 3, // Multi-line
              decoration: InputDecoration(
                labelText: 'Add notes (optional)', // Label
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),

            const SizedBox(height: 24),

            // Button to add reading
            SizedBox(
              width: double.infinity, // Full width button
              child: ElevatedButton(
                onPressed: _addReading, // Calls add function
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12), // Button height
                ),
                child: const Text('Add Reading',
                    style: TextStyle(fontSize: 16)), // Button text
              ),
            ),
          ],
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
