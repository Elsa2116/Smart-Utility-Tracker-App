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
  final _authService = AuthService();
  final _dbHelper = DBHelper();
  late Future<List<Alert>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  void _loadAlerts() {
    final userId = _authService.currentUserId;
    if (userId != null) {
      _alertsFuture = _dbHelper.getAlertsByUserId(userId);
    }
  }

  Future<void> _deleteAlert(int id) async {
    await _dbHelper.deleteAlert(id);
    setState(() => _loadAlerts());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Alert>>(
        future: _alertsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final alerts = snapshot.data ?? [];

          if (alerts.isEmpty) {
            return const Center(
              child: Text('No alerts yet'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: alerts.length,
            itemBuilder: (context, index) {
              final alert = alerts[index];
              final icon = alert.type == 'electricity'
                  ? Icons.flash_on
                  : alert.type == 'water'
                      ? Icons.water_drop
                      : Icons.local_gas_station;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(icon, color: Colors.orange),
                  title: Text(alert.type.toUpperCase()),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(alert.message),
                      Text(
                        alert.date.toString().split('.')[0],
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
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
