import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/db_helper.dart';
import '../models/threshold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _dbHelper = DBHelper();
  late Future<List<UsageThreshold>> _thresholdsFuture;

  @override
  void initState() {
    super.initState();
    _loadThresholds();
  }

  void _loadThresholds() {
    final userId = _authService.currentUserId;
    if (userId != null) {
      setState(() {
        _thresholdsFuture = _dbHelper.getThresholdsByUserId(userId);
      });
    } else {
      _thresholdsFuture = Future.value([]);
    }
  }

  void _showThresholdDialog(String type, UsageThreshold? existing) {
    final controller = TextEditingController(
      text: existing?.maxUsage.toString() ?? '',
    );
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Set ${type.toUpperCase()} Threshold'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Max usage',
              suffixText: type == 'electricity' ? 'kWh' : 'L',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final value = double.tryParse(controller.text);
                      if (value == null || value <= 0) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid number'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                        return;
                      }

                      final userId = _authService.currentUserId;
                      if (userId == null) return;

                      final threshold = UsageThreshold(
                        id: existing?.id,
                        userId: userId,
                        type: type,
                        maxUsage: value,
                        unit: type == 'electricity' ? 'kWh' : 'L',
                      );

                      try {
                        setDialogState(() => isSaving = true);
                        await _dbHelper.insertThreshold(threshold);

                        if (!mounted) return;
                        Navigator.pop(context); // Close dialog

                        setState(() {
                          _thresholdsFuture =
                              _dbHelper.getThresholdsByUserId(userId);
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('$type threshold saved successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Failed to save $type threshold: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setDialogState(() => isSaving = false);
                      }
                    },
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // White background
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black), // Back arrow
          onPressed: () {
            Navigator.pop(context); // Go back to previous screen
          },
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white, // White AppBar
        elevation: 1,
      ),
      body: FutureBuilder<List<UsageThreshold>>(
        future: _thresholdsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final thresholds = snapshot.data ?? [];
          final thresholdMap = {for (var t in thresholds) t.type: t};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Usage Thresholds',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                ...['electricity', 'water'].map((type) {
                  final threshold = thresholdMap[type];
                  final unit = type == 'electricity' ? 'kWh' : 'L';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Colors.white,
                    elevation: 2,
                    child: ListTile(
                      title: Text(
                        type.toUpperCase(),
                        style: const TextStyle(color: Colors.black),
                      ),
                      subtitle: threshold != null
                          ? Text(
                              'Max: ${threshold.maxUsage.toStringAsFixed(2)} $unit',
                              style: const TextStyle(color: Colors.black54),
                            )
                          : const Text(
                              'Not set',
                              style: TextStyle(color: Colors.black54),
                            ),
                      trailing: const Icon(Icons.edit, color: Colors.black54),
                      onTap: () => _showThresholdDialog(type, threshold),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}
