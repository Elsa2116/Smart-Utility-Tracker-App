import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/db_helper.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../models/user.dart';

// ProfileScreen displays the user's profile and allows updating name, password, and profile picture
class ProfileScreen extends StatefulWidget {
  final int userId; // ID of the user whose profile is being displayed

  const ProfileScreen({super.key, required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final DBHelper _dbHelper = DBHelper(); // Database helper for CRUD operations
  final AuthService _authService =
      AuthService(); // Authentication service for logout
  final ImagePicker _imagePicker =
      ImagePicker(); // Image picker to select profile photo

  User? _user; // Holds the current user object
  bool _isLoading = true; // Shows loading indicator while fetching data
  File? _profileImage; // Local image file if user picks a new image
  String? _profileImageUrl; // URL or path of the user's profile image

  // Controllers for the text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUser(); // Load user data when screen initializes
  }

  // ✅ Decide whether the saved value is a network URL or a local file path
  ImageProvider? _getProfileImageProvider(String? pathOrUrl) {
    if (pathOrUrl == null || pathOrUrl.isEmpty) return null;

    // If it's a real URL (http/https), show network image
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) {
      return NetworkImage(pathOrUrl);
    }

    // Otherwise treat it as a local file path (gallery image path)
    final file = File(pathOrUrl);
    if (file.existsSync()) {
      return FileImage(file);
    }

    return null; // File not found → fallback to default icon
  }

  // Fetch user data from the database
  Future<void> _loadUser() async {
    try {
      final user = await _dbHelper.getUserById(widget.userId);
      if (user != null) {
        setState(() {
          _user = user;
          _nameController.text = user.name;
          _profileImageUrl = user.profileImageUrl;
          _isLoading = false; // Stop loading once data is fetched
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Allow the user to pick an image from the gallery
  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Compress the image for better performance
    );

    if (pickedFile != null) {
      final newPath = pickedFile.path;

      setState(() {
        _profileImage = File(newPath);
        _profileImageUrl = newPath; // Save local file path
      });

      // Update the user object in the database with the new image
      if (_user != null) {
        final updated = User(
          id: _user!.id,
          name: _user!.name,
          email: _user!.email,
          password: _user!.password,
          createdAt: _user!.createdAt,
          profileImageUrl: newPath, // ✅ store local path
        );

        await _dbHelper.updateUser(updated);

        // ✅ Update local _user so other fields remain consistent
        setState(() {
          _user = updated;
        });

        // Optional confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated successfully")),
        );
      }
    }
  }

  // Update the user's profile (name, password, profile image)
  Future<void> _updateProfile() async {
    if (_user != null && _nameController.text.isNotEmpty) {
      final updatedUser = User(
        id: _user!.id,
        name: _nameController.text,
        email: _user!.email,
        // Keep old password if new password is empty
        password: _passwordController.text.isEmpty
            ? _user!.password
            : _passwordController.text,
        createdAt: _user!.createdAt,
        profileImageUrl: _profileImageUrl, // ✅ can be local path or URL
      );

      await _dbHelper.updateUser(updatedUser); // Save changes to the database

      setState(() {
        _user = updatedUser; // Update local user object
      });

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );

      // ✅ Send result back so SettingsScreen can refresh if needed
      Navigator.pop(context, true);
    }
  }

  // Logout the user and navigate to LoginScreen
  Future<void> _logout() async {
    await _authService.logout(); // Call logout service
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false, // Remove all previous routes
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Pick correct provider (local file OR network)
    final imageProvider = _profileImage != null
        ? FileImage(_profileImage!)
        : _getProfileImageProvider(_profileImageUrl);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            ) // Show loader while fetching data
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile picture display and pick image gesture
                  GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: imageProvider,
                      child: imageProvider == null
                          ? const Icon(Icons.person, size: 50) // Default icon
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name input field
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 16),

                  // Password input field (optional)
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'New Password (optional)'),
                  ),
                  const SizedBox(height: 24),

                  // Button to save profile changes
                  ElevatedButton(
                    onPressed: _updateProfile,
                    child: const Text('Save Changes'),
                  ),
                  const SizedBox(height: 16),

                  // Logout button
                  ElevatedButton(
                    onPressed: _logout,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers to free resources
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
