import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'history_analytics_screen.dart';
import 'payments_screen.dart';
import 'reminders_screen.dart';
import 'settings_screen.dart';
import 'add_reading_screen.dart';

// AppShell is the MAIN container of the app
// It holds the BottomNavigationBar and switches screens
// without rebuilding them or removing the bottom bar
class AppShell extends StatefulWidget {
  final int initialIndex; //  initial tab index when AppShell opens

  const AppShell({super.key, this.initialIndex = 0}); //  default is Home (0)

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Keeps track of which tab is currently selected
  int _selectedIndex = 0;

  // Notifier so pages can know when tab changes (IndexedStack keeps them alive)
  final ValueNotifier<int> _tabNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex; // start from the passed tab
    _tabNotifier.value = _selectedIndex; //  sync notifier
  }

  // Called whenever a bottom navigation item is tapped
  // This updates the selected index and switches the visible screen
  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);

    //  notify screens that tab changed
    _tabNotifier.value = index;
  }

  @override
  void dispose() {
    _tabNotifier.dispose(); //  clean up
    super.dispose();
  }

  // List of all pages used in the BottomNavigationBar
  // IndexedStack keeps ALL pages alive in memory
  // so state (scroll position, forms, tabs) is preserved
  late final List<Widget> _pages = [
    // pass tab notifier so Home can reload readings when user returns to tab 0
    HomeScreen(onTabChange: _onItemTapped, tabIndexNotifier: _tabNotifier),

    // IMPORTANT: pass onTabChange so "Add Reading" can switch tabs after saving
    AddReadingScreen(onTabChange: _onItemTapped), // index 1 → Add Reading

    //  HistoryAnalyticsScreen does NOT accept onTabChange (your file has only {super.key})
    const HistoryAnalyticsScreen(), // index 2 → Insights

    const PaymentsScreen(), // index 3 → Payments
    const RemindersScreen(), // index 4 → Reminders

    //  IMPORTANT: SettingsScreen uses onTabChange for back button → must be passed
    SettingsScreen(onTabChange: _onItemTapped), // index 5 → Settings
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack shows ONE screen at a time
      // but keeps all other screens alive (important!)
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),

      // Bottom navigation bar shared across ALL screens
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex, // Highlight active tab
        onTap: _onItemTapped, // Handle tab switching
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1F2937),
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,

        // All navigation items (6 tabs)
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Add'),
          BottomNavigationBarItem(
              icon: Icon(Icons.insights), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
          BottomNavigationBarItem(icon: Icon(Icons.alarm), label: 'Reminders'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
