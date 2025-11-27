import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/db_helper.dart';
import '../models/alert.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({Key? key}) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  // Authentication service to get the current logged-in user
  final _authService = AuthService();

  // Database helper for CRUD operations on alerts
  final _dbHelper = DBHelper();

  // Future that holds the list of alerts to be loaded
  late Future<List<Alert>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _loadAlerts(); // Load alerts when the screen is initialized
  }

  // Loads alerts for the currently logged-in user
  void _loadAlerts() {
    final userId = _authService.currentUserId;
    if (userId != null) {
      // Fetch alerts from database based on userId
      _alertsFuture = _dbHelper.getAlertsByUserId(userId);
    }
  }

  // Delete an alert by ID and refresh the list
  Future<void> _deleteAlert(int id) async {
    await _dbHelper.deleteAlert(id);
    setState(() => _loadAlerts()); // Reload alerts after deletion
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        centerTitle: true, // Center the app bar title
      ),

      // FutureBuilder waits for the alerts to load
      body: FutureBuilder<List<Alert>>(
        future: _alertsFuture,
        builder: (context, snapshot) {
          // Display loading indicator while fetching data
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // If no alerts found, show empty message
          final alerts = snapshot.data ?? [];
          if (alerts.isEmpty) {
            return const Center(
              child: Text('No alerts yet'),
            );
          }

          // List of alerts displayed using ListView.builder
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];

              // Set icon based on alert type (electricity, water, gas)
              final icon = alert.type == 'electricity'
                  ? Icons.flash_on
                  : alert.type == 'water'
                      ? Icons.water_drop
                      : Icons.local_gas_station;

              // Card widget for each alert item
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(icon, color: Colors.orange), // Alert icon
                  title: Text(alert.type.toUpperCase()), // Alert type

                  // Alert message + date
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert.message),
                      Text(
                        alert.date.toString().split('.')[0], // Format date
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),

                  // Delete button for each alert
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteAlert(alert.id!),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
