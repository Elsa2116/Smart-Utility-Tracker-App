import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    print('LoginScreen: initState called');
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    print('LoginScreen: Checking login status...');
    final isLoggedIn = await _authService.checkLoginStatus();
    print('LoginScreen: checkLoginStatus returned: $isLoggedIn');

    if (isLoggedIn && mounted) {
      print('LoginScreen: User is already logged in, redirecting to /home');
      // Add a small delay for better UX
      await Future.delayed(const Duration(milliseconds: 100));
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      print('LoginScreen: User is not logged in, showing login form');
    }
  }

  void _validateAndLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validate inputs
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
          'Invalid Password', 'Password must be at least 4 characters');
      return;
    }

    _login();
  }

  Future<void> _login() async {
    print('LoginScreen: Starting login process...');
    setState(() {
      _isLoading = true;
    });

    final success = await _authService.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (mounted) {
      if (success) {
        print('LoginScreen: Login successful');
        _showSuccessDialog('Login Successful', 'Welcome back!', () {
          print('LoginScreen: Navigating to /home after success');
          Navigator.of(context).pushReplacementNamed('/home');
        });
      } else {
        print('LoginScreen: Login failed');
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog(
            'Login Failed', 'Invalid email or password. Please try again.');
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              print('LoginScreen: Error dialog closed');
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String title, String message, VoidCallback onOk) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              print('LoginScreen: Success dialog closed, executing callback');
              Navigator.pop(context);
              onOk();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('LoginScreen: Building widget');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Utility Tracker'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.electric_meter, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Welcome Back',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
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
            TextField(
              controller: _passwordController,
              enabled: !_isLoading,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                prefixIcon: const Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 24),
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
                    : const Text('Login', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? "),
                GestureDetector(
                  onTap: _isLoading
                      ? null
                      : () {
                          print('LoginScreen: Navigating to RegisterScreen');
                          Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) => const RegisterScreen()),
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
    print('LoginScreen: dispose called');
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
