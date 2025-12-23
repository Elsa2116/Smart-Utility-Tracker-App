import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Import your authentication service

// The main RegisterScreen widget
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers to retrieve user input from TextFields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService(); // Instance of your authentication service
  bool _isLoading = false; // Loading state for async operations

  // Function to validate user inputs before registration
  bool _validateInputs() {
    if (_nameController.text.isEmpty) {
      _showError('Please enter your name');
      return false;
    }
    if (_emailController.text.isEmpty) {
      _showError('Please enter your email');
      return false;
    }
    if (!_emailController.text.contains('@')) {
      _showError('Please enter a valid email');
      return false;
    }
    if (_passwordController.text.isEmpty) {
      _showError('Please enter a password');
      return false;
    }
    if (_passwordController.text.length < 6) {
      _showError('Password must be at least 6 characters');
      return false;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return false;
    }
    return true; // All validations passed
  }

  // Show an error dialog
  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show a success dialog and navigate to HomeScreen
  void _showSuccess(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushReplacementNamed('/home');
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Register the user
  Future<void> _register() async {
    if (!_validateInputs()) {
      return; // Stop if validation fails
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    // Call the register function from AuthService
    final success = await _authService.register(
      _nameController.text,
      _emailController.text,
      _passwordController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });

      if (success) {
        _showSuccess('Account created successfully!');
      } else {
        _showError('Email already exists. Please use a different email.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.app_registration, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Create Account',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            // Name input
            TextField(
              controller: _nameController,
              enabled: !_isLoading, // Disable input while loading
              decoration: InputDecoration(
                labelText: 'Full Name',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            // Email input
            TextField(
              controller: _emailController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Email',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            // Password input
            TextField(
              controller: _passwordController,
              enabled: !_isLoading,
              obscureText: true, // Hide text
              decoration: InputDecoration(
                labelText: 'Password',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            // Confirm password input
            TextField(
              controller: _confirmPasswordController,
              enabled: !_isLoading,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),
            // Register button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Register', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            // Navigate to login screen
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? '),
                GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () =>
                          Navigator.of(context).pushReplacementNamed('/login'),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers to free memory
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
