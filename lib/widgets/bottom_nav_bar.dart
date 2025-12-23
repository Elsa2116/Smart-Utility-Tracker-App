import 'package:flutter/material.dart';

/// A custom bottom navigation bar widget.
///
/// This widget displays a BottomNavigationBar with 5 items:
/// Home, Add, History, Analytics, and Payments.
/// The currently selected index and tap callbacks are passed in.
class BottomNavBar extends StatelessWidget {
  // Index of the currently selected bottom nav item
  final int currentIndex;

  // Callback function when a nav item is tapped
  final Function(int) onTap;

  // Constructor requires currentIndex and onTap function
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex, // Highlight the current item
      onTap: onTap, // Call this function when a nav item is tapped
      items: const [
        // Home button
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        // Add button
        BottomNavigationBarItem(
          icon: Icon(Icons.add),
          label: 'Add',
        ),
        // History button
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        // Analytics button
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
        // Payments button
        BottomNavigationBarItem(
          icon: Icon(Icons.payment),
          label: 'Payments',
        ),
      ],
    );
  }
}
