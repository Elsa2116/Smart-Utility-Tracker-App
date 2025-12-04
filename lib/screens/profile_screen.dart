import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/db_helper.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  final int userId;

  const ProfileScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DBHelper _dbHelper = DBHelper();
  final AuthService _authService = AuthService();
  final ImagePicker _imagePicker = ImagePicker();
  User? _user;
  bool _isLoading = true;
  bool _darkMode = false;
  bool _notificationsEnabled = true;
  File? _profileImage;
  String? _profileImageUrl;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    print('ProfileScreen: initState called with userId: ${widget.userId}');
    _loadUser();
  }

  Future<void> _loadUser() async {
    print('ProfileScreen: Loading user data...');
    try {
      final user = await _dbHelper.getUserById(widget.userId);

      if (user != null) {
        print('ProfileScreen: User loaded from database: ${user.name}');
        setState(() {
          _user = user;
          _nameController.text = user.name;
          _isLoading = false;
        });
      } else {
        print('ProfileScreen: User not found in database, using fallback');
        setState(() {
          _user = User(
            id: widget.userId,
            name: 'Elsa Alemayehu',
            email: 'elsialemayehu33@gmail.com',
            password: 'password123',
            createdAt: DateTime.now(),
            profileImageUrl: _profileImageUrl,
          );
          _nameController.text = _user!.name;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('ProfileScreen: Error loading user: $e');
      setState(() {
        _user = User(
          id: widget.userId,
          name: 'Elsa Alemayehu',
          email: 'elsialemayehu33@gmail.com',
          password: 'password123',
          createdAt: DateTime.now(),
          profileImageUrl: _profileImageUrl,
        );
        _nameController.text = _user!.name;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final option = await showModalBottomSheet<int>(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, 1),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.pop(context, 2),
              ),
              if (_profileImage != null || _profileImageUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo',
                      style: TextStyle(color: Colors.red)),
                  onTap: () => Navigator.pop(context, 3),
                ),
            ],
          ),
        ),
      );

      if (option == null) return;

      XFile? pickedFile;

      if (option == 1) {
        pickedFile = await _imagePicker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 800,
          maxHeight: 800,
        );
      } else if (option == 2) {
        pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 800,
          maxHeight: 800,
        );
      } else if (option == 3) {
        setState(() {
          _profileImage = null;
          _profileImageUrl = null;
        });

        if (_user != null) {
          await _dbHelper.updateUser(User(
            id: _user!.id,
            name: _user!.name,
            email: _user!.email,
            password: _user!.password,
            createdAt: _user!.createdAt,
            profileImageUrl: null,
          ));
        }

        return;
      }

      if (pickedFile != null) {
        setState(() {
          _profileImage = File(pickedFile!.path);
        });

        if (_user != null) {
          await _dbHelper.updateUser(User(
            id: _user!.id,
            name: _user!.name,
            email: _user!.email,
            password: _user!.password,
            createdAt: _user!.createdAt,
            profileImageUrl: pickedFile.path,
          ));
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProfile() async {
    if (_user != null && _nameController.text.isNotEmpty) {
      try {
        final updatedUser = User(
          id: _user!.id,
          name: _nameController.text,
          email: _user!.email,
          password: _passwordController.text.isEmpty
              ? _user!.password
              : _passwordController.text,
          createdAt: _user!.createdAt,
          profileImageUrl: _profileImageUrl,
        );

        await _dbHelper.updateUser(updatedUser);

        setState(() {
          _user = updatedUser;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid name"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _logout() async {
    print('ProfileScreen: Logout button pressed');

    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              print('ProfileScreen: User canceled logout');
              Navigator.pop(context, false);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              print('ProfileScreen: User confirmed logout');
              Navigator.pop(context, true);
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      print('ProfileScreen: Starting logout process...');

      // 1. Clear authentication state
      await _authService.logout();
      print('ProfileScreen: AuthService.logout() completed');

      // 2. Clear ALL navigation stack and go to login
      print('ProfileScreen: Navigating to login screen...');

      // Option 1: Try named routes first
      try {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (Route<dynamic> route) {
            print('ProfileScreen: Removing route: ${route.settings.name}');
            return false;
          },
        );
        print('ProfileScreen: Named route navigation successful');
      } catch (e) {
        print('ProfileScreen: Named route error: $e, trying direct navigation');

        // Option 2: Direct navigation as fallback
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) {
            print('ProfileScreen: Removing route: ${route.settings.name}');
            return false;
          },
        );
        print('ProfileScreen: Direct navigation successful');
      }

      print('ProfileScreen: Logout process completed');
    }
  }

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

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Edit Profile'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickImage();
                      _showEditProfileDialog();
                    },
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue.shade100,
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                          child: _profileImage != null
                              ? ClipOval(
                                  child: Image.file(
                                    _profileImage!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.blue,
                                      );
                                    },
                                  ),
                                )
                              : (_profileImageUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        _profileImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return const Icon(
                                            Icons.person,
                                            size: 50,
                                            color: Colors.blue,
                                          );
                                        },
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 50,
                                      color: Colors.blue,
                                    )),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tap image to change',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password (optional)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _updateProfile();
                  Navigator.pop(context);
                },
                child: const Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('ProfileScreen: Building widget');
    return Scaffold(
      backgroundColor: _darkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: _darkMode ? const Color(0xFF1E1E1E) : Colors.white,
        foregroundColor: _darkMode ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditProfileDialog,
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.pushNamed(context, '/alerts');
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _darkMode
                          ? const Color(0xFF1E1E1E)
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color:
                            _darkMode ? Colors.white24 : Colors.blue.shade100,
                      ),
                    ),
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.blue.shade100,
                                  border: Border.all(
                                    color: Colors.blue,
                                    width: 3,
                                  ),
                                ),
                                child: _profileImage != null
                                    ? ClipOval(
                                        child: Image.file(
                                          _profileImage!,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(
                                              Icons.person,
                                              size: 60,
                                              color: Colors.blue.shade600,
                                            );
                                          },
                                        ),
                                      )
                                    : (_profileImageUrl != null
                                        ? ClipOval(
                                            child: Image.network(
                                              _profileImageUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Icon(
                                                  Icons.person,
                                                  size: 60,
                                                  color: Colors.blue.shade600,
                                                );
                                              },
                                            ),
                                          )
                                        : Icon(
                                            Icons.person,
                                            size: 60,
                                            color: Colors.blue.shade600,
                                          )),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _user!.name,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _darkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _user!.email,
                          style: TextStyle(
                            fontSize: 14,
                            color: _darkMode
                                ? Colors.white70
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Upload Photo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'General',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _darkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    icon: Icons.dark_mode_outlined,
                    title: 'Dark Mode',
                    subtitle: 'Switch between light and dark themes',
                    trailing: Switch(
                      value: _darkMode,
                      onChanged: (value) {
                        setState(() => _darkMode = value);
                      },
                      activeColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSettingItem(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications',
                    subtitle: 'Receive alerts for bills and usage',
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() => _notificationsEnabled = value);
                      },
                      activeColor: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _darkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    icon: Icons.edit_outlined,
                    title: 'Edit Profile',
                    subtitle: 'Update your personal information',
                    onTap: _showEditProfileDialog,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingItem(
                    icon: Icons.lock_outlined,
                    title: 'Change Password',
                    subtitle: 'Update your login password',
                    onTap: () {
                      _passwordController.clear();
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Change Password'),
                          content: TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Enter new password',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                _updateProfile();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password updated'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              },
                              child: const Text('Update'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingItem(
                    icon: Icons.add_alert_outlined,
                    title: 'Add Notification',
                    subtitle: 'Create custom alerts',
                    onTap: () {
                      Navigator.pushNamed(context, '/alerts');
                    },
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Support',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _darkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    icon: Icons.support_outlined,
                    title: 'Feedback & Support',
                    subtitle: 'Get help or send feedback',
                    onTap: _showSupportDialog,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingItem(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'View our privacy policy',
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
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _darkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _darkMode ? Colors.white12 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.blue, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _darkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: _darkMode ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (onTap != null && trailing == null)
              Icon(Icons.chevron_right,
                  color: _darkMode ? Colors.white70 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    print('ProfileScreen: dispose called');
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
