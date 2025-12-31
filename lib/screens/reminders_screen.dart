import 'package:flutter/material.dart';

// Main Reminders Screen as a StatefulWidget to handle dynamic data
class RemindersScreen extends StatefulWidget {
  final void Function(int index)? onTabChange;
  const RemindersScreen({super.key, this.onTabChange});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  // Sample list of reminders
  final List<Map<String, dynamic>> _reminders = [
    {
      'title': 'Check Electricity Meter',
      'date': 'Every 1st of Month',
      'enabled': true,
      'id': 1,
    },
    {
      'title': 'Pay Water Bill',
      'date': 'Every 15th of Month',
      'enabled': true,
      'id': 2,
    },
  ]; // Removed gas reminder

  // Function to delete a reminder by ID
  void _deleteReminder(int id) {
    setState(() {
      _reminders.removeWhere((reminder) => reminder['id'] == id);
    });

    // Show a SnackBar confirmation when a reminder is deleted
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder deleted successfully'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // Function to show a confirmation dialog before deleting a reminder
  void _showDeleteDialog(int id, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel action
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReminder(id); // Delete action
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
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
        title: const Text('Reminders'),
        centerTitle: true,
        actions: [
          // Display number of reminders in the app bar
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '${_reminders.length} reminders',
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      // Body displays either a message if empty or the list of reminders
      body: _reminders.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No reminders set',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  Text(
                    'Add a new reminder to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _reminders.length,
              itemBuilder: (context, index) {
                final reminder = _reminders[index];

                // Dismissible widget allows swipe-to-delete functionality
                return Dismissible(
                  key: Key(reminder['id'].toString()),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    // Show confirmation dialog before dismissing
                    if (direction == DismissDirection.endToStart) {
                      return await showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Reminder'),
                          content: Text(
                              'Are you sure you want to delete "${reminder['title']}"?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return false;
                  },
                  onDismissed: (direction) {
                    // Delete reminder when dismissed
                    _deleteReminder(reminder['id']);
                  },
                  child: Card(
                    margin: const EdgeInsets.all(8),
                    child: ListTile(
                      title: Text(
                        reminder['title'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        reminder['date'],
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Switch to enable/disable a reminder
                          Switch(
                            value: reminder['enabled'],
                            onChanged: (value) {
                              setState(() {
                                reminder['enabled'] = value;
                              });
                            },
                          ),
                          // Delete button to manually delete a reminder
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red,
                            onPressed: () {
                              _showDeleteDialog(
                                reminder['id'],
                                reminder['title'],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      // Floating Action Button to add a new reminder
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show dialog for "coming soon" feature
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Add New Reminder'),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Feature coming soon!'),
                  SizedBox(height: 10),
                  Text(
                      'You will be able to add custom reminders in the next update.'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
