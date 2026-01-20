import 'dart:io'; // FileImage when user picks from gallery
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/db_helper.dart';
import '../models/threshold.dart';
import '../models/user.dart';
import '../screens/profile_screen.dart';

// SettingsScreen: The main screen for user settings
class SettingsScreen extends StatefulWidget {
  final void Function(int index)? onTabChange;
  const SettingsScreen({super.key, this.onTabChange});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService(); // Handles authentication-related actions
  final _dbHelper = DBHelper(); // Handles database operations
  late Future<List<UsageThreshold>>
      _thresholdsFuture; // Future for fetching thresholds

  bool _notificationsEnabled = true; // Toggle for notifications
  final List<String> _languages = [
    "English",
    "Amharic",
    "Oromo",
    "Tigrigna"
  ]; // Supported languages
  String _selectedLanguage = "English"; // Currently selected language

  @override
  void initState() {
    super.initState();
    _loadThresholds(); // Load usage thresholds from database
    _loadPreferences(); // Load saved user preferences from SharedPreferences
  }

  // Load saved preferences like notifications & language
  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications') ?? true;
      _selectedLanguage = prefs.getString('language') ?? "English";
    });
  }

  // Save a preference key-value pair to SharedPreferences
  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      prefs.setBool(key, value);
    } else {
      prefs.setString(key, value);
    }
  }

  // Load usage thresholds for the current user from the database
  void _loadThresholds() {
    final userId = _authService.currentUserId;
    if (userId != null) {
      setState(() {
        _thresholdsFuture = _dbHelper.getThresholdsByUserId(userId);
      });
    } else {
      _thresholdsFuture = Future.value([]); // If no user, return empty list
    }
  }

  // Get the current logged-in user's info
  Future<User?> _getCurrentUser() async {
    final userId = _authService.currentUserId;
    if (userId == null) return null;
    return _dbHelper.getUserById(userId);
  }

  //  Decide whether image is network URL or local file path
  ImageProvider? _getProfileImageProvider(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.isEmpty) return null;

    // If it starts with http/https → treat as network image
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return NetworkImage(pathOrUrl);
    }

    // Otherwise treat as local file image (gallery path)
    final file = File(pathOrUrl);
    if (file.existsSync()) {
      return FileImage(file);
    }

    return null; // If file missing, fallback to icon
  }

  // Show a dialog to set or edit usage thresholds
  void _showThresholdDialog(String type, UsageThreshold? existing) {
    final controller = TextEditingController(
      text: existing?.maxUsage.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set ${type.toUpperCase()} threshold'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Max usage value',
            suffixText: type == 'electricity' ? 'kWh' : 'L',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel button
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Validate input
              final value = double.tryParse(controller.text);
              if (value == null || value <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid amount'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final userId = _authService.currentUserId;
              if (userId == null) return;

              // Create threshold object
              final threshold = UsageThreshold(
                id: existing?.id,
                userId: userId,
                type: type,
                maxUsage: value,
                unit: type == 'electricity' ? 'kWh' : 'L',
              );

              // Save to database
              await _dbHelper.insertThreshold(threshold);

              // Refresh the threshold list
              setState(() {
                _thresholdsFuture = _dbHelper.getThresholdsByUserId(userId);
              });

              Navigator.pop(context); // Close dialog
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Navigate to ProfileScreen for editing profile
  Future<void> _showEditProfile() async {
    final userId = _authService.currentUserId;
    if (userId != null) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProfileScreen(userId: userId),
        ),
      );

      //  Refresh screen after returning so updated image shows immediately
      if (mounted) setState(() {});
    }
  }

  // Show support & feedback dialog
  void _showSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support & Feedback'),
        content:
            const Text('Email: support@smartutility.com\nPhone: +1234567890'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Logout user and navigate to login screen
  Future<void> _logout() async {
    await _authService.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => widget.onTabChange?.call(0), // Back button
        ),
        title: const Text(
          'Settings',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display user info
            FutureBuilder<User?>(
              future: _getCurrentUser(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                final user = snapshot.data!;

                final profileImageProvider =
                    _getProfileImageProvider(user.profileImageUrl);

                return ListTile(
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundImage: profileImageProvider,
                    child: profileImageProvider == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: _showEditProfile,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Section: Usage Thresholds
            const Text(
              "Usage Thresholds",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            FutureBuilder<List<UsageThreshold>>(
              future: _thresholdsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data!;
                final map = {for (var t in list) t.type: t};
                return Column(
                  children: ["electricity", "water"].map((type) {
                    final threshold = map[type];
                    return Card(
                      child: ListTile(
                        title: Text(type.toUpperCase()),
                        subtitle: threshold != null
                            ? Text(
                                "Max: ${threshold.maxUsage} ${threshold.unit}")
                            : const Text("Not set"),
                        trailing: const Icon(Icons.edit),
                        onTap: () {
                          _showThresholdDialog(
                              type, threshold); // Edit threshold
                        },
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 30),

            // Section: General Settings
            const Text(
              "General Settings",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // Notification toggle
            SwitchListTile(
              title: const Text('Enable Notifications'),
              value: _notificationsEnabled,
              onChanged: (val) {
                setState(() => _notificationsEnabled = val);
                _savePreference('notifications', val); // Save preference
              },
            ),
            const SizedBox(height: 25),

            // Language selection dropdown
            const Text(
              "Language",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            DropdownButton<String>(
              value: _selectedLanguage,
              items: _languages.map((lang) {
                return DropdownMenuItem(
                  value: lang,
                  child: Text(lang),
                );
              }).toList(),
              isExpanded: true,
              onChanged: (value) {
                setState(() => _selectedLanguage = value!);
                _savePreference('language', value!); // Save language preference
              },
            ),
            const SizedBox(height: 30),

            // Section: Account & Support
            const Text(
              "Account & Support",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit Profile'),
              onTap: _showEditProfile,
            ),
            ListTile(
              leading: const Icon(Icons.lock_outlined),
              title: const Text('Change Password'),
              onTap: _showEditProfile,
            ),
            ListTile(
              leading: const Icon(Icons.add_alert_outlined),
              title: const Text('Add Notification'),
              onTap: () {
                Navigator.pushNamed(context, '/alerts');
              },
            ),
            ListTile(
              leading: const Icon(Icons.support_outlined),
              title: const Text('Feedback & Support'),
              onTap: _showSupportDialog,
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Privacy Policy'),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Privacy Policy'),
                    content: const SingleChildScrollView(
                      child: Text(
                        'We are committed to protecting your privacy. Your personal information is kept secure and will never be shared with third parties without your consent.',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 30),

            // Button: Reset App Data
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await _dbHelper.resetDatabase(); // Clear all database entries
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.clear(); // Clear stored preferences
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("All app data cleared"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text("Reset App Data"),
            ),
            const SizedBox(height: 12),

            // Button: Logout
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: _logout,
              child: const Text("Logout"),
            ),
          ],
        ),
      ),
    );
  }
}
