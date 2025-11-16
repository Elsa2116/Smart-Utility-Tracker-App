import 'package:flutter/material.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({Key? key}) : super(key: key);

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final List<Map<String, dynamic>> _reminders = [
    {'title': 'Check Electricity Meter', 'date': 'Every 1st of Month', 'enabled': true},
    {'title': 'Pay Water Bill', 'date': 'Every 15th of Month', 'enabled': true},
    {'title': 'Check Gas Usage', 'date': 'Every 20th of Month', 'enabled': false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: _reminders.length,
        itemBuilder: (context, index) {
          final reminder = _reminders[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(reminder['title']),
              subtitle: Text(reminder['date']),
              trailing: Switch(
                value: reminder['enabled'],
                onChanged: (value) {
                  setState(() {
                    reminder['enabled'] = value;
                  });
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
