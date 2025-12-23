import 'package:flutter/material.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Animation controller to control the scale and fade animations
  late AnimationController _controller;

  // Animation object for scaling and fading effect
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller
    _controller = AnimationController(
      vsync: this, // required for animations
      duration: const Duration(seconds: 2), // animation duration
    );

    // Apply a curved animation for smooth transition
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut, // ease in and out for smoothness
    );

    _controller.forward(); // Start the animation immediately

    // Set a timer to navigate to the login screen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
      // pushReplacementNamed replaces the current screen with the new one
    });
  }

  @override
  void dispose() {
    _controller.dispose(); // Dispose the animation controller to free resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2937), // Dark background color
      body: Center(
        child: ScaleTransition(
          scale: _animation, // Apply scaling animation
          child: FadeTransition(
            opacity: _animation, // Apply fading animation
            child: Column(
              mainAxisSize: MainAxisSize.min, // Minimize column height
              children: [
                _buildLogo(), // Custom method to display logo
                const SizedBox(height: 20), // Spacing between logo and text
                const Text(
                  "Smart Utility Tracker", // App title
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget to display the app logo
  Widget _buildLogo() {
    return Image.asset(
      'assets/logo.jpg', // Path to the app logo image
      width: 130,
      height: 130,
      fit: BoxFit.cover, // Cover entire box
      errorBuilder: (context, error, stackTrace) {
        // Fallback logo in case the image is missing
        return Container(
          width: 130,
          height: 130,
          color: Colors.blue,
          child: const Center(
            child: Text(
              'SU', // Initials for Smart Utility
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 40,
              ),
            ),
          ),
        );
      },
    );
  }
}
