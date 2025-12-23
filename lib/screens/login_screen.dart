import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

// LoginScreen widget
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers to get user input from text fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Instance of the authentication service
  final _authService = AuthService();

  // Boolean to track loading state during login
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('LoginScreen: initState called');
    // Check if user is already logged in
    _checkLoginStatus();
  }

  // Function to check login status
  Future<void> _checkLoginStatus() async {
    print('LoginScreen: Checking login status...');
    final isLoggedIn = await _authService.checkLoginStatus();
    print('LoginScreen: checkLoginStatus returned: $isLoggedIn');

    if (isLoggedIn && mounted) {
      // Navigate to home screen if already logged in
      await Future.delayed(const Duration(milliseconds: 100));
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  // Function to validate user input and initiate login
  void _validateAndLogin() {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    // Basic validation checks
    if (email.isEmpty) {
      _showErrorDialog('Email Required', 'Please enter your email address');
      return;
    }

    if (!email.contains('@')) {
      _showErrorDialog('Invalid Email', 'Please enter a valid email address');
      return;
    }

    if (password.isEmpty) {
      _showErrorDialog('Password Required', 'Please enter your password');
      return;
    }

    if (password.length < 4) {
      _showErrorDialog(
        'Invalid Password',
        'Password must be at least 4 characters',
      );
      return;
    }

    // Call login function if validation passes
    _login(email, password);
  }

  // Function to handle login process
  Future<void> _login(String email, String password) async {
    print('LoginScreen: Starting login process...');
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    final success = await _authService.login(email, password);

    if (!mounted) return;

    if (success) {
      // Show success dialog and navigate to home screen
      _showSuccessDialog('Login Successful', 'Welcome back!', () {
        Navigator.of(context).pushReplacementNamed('/home');
      });
    } else {
      // Reset loading state and show error dialog
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog(
        'Login Failed',
        'Invalid email or password. Please try again.',
      );
    }
  }

  // Function to show an error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
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

  // Function to show a success dialog
  void _showSuccessDialog(
    String title,
    String message,
    VoidCallback onOk,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onOk(); // Execute callback on OK
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Utility Tracker'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            // App logo/icon
            const Icon(Icons.electric_meter, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            // Welcome text
            const Text(
              'Welcome Back',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            // Email input field
            TextField(
              controller: _emailController,
              enabled: !_isLoading,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Password input field
            TextField(
              controller: _passwordController,
              enabled: !_isLoading,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Login button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _validateAndLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Login',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            // Navigation to Register screen
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          );
                        },
                  child: Text(
                    'Register',
                    style: TextStyle(
                      color: _isLoading ? Colors.grey : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
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
    // Dispose controllers to free up memory
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
