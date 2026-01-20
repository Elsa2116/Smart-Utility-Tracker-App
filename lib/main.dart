import 'package:flutter/material.dart';
import 'package:smart_utility_tracker/screens/splash_screen.dart';
import 'package:smart_utility_tracker/screens/login_screen.dart';
import 'package:smart_utility_tracker/screens/profile_screen.dart';
import 'package:smart_utility_tracker/screens/alerts_screen.dart';

import 'package:smart_utility_tracker/screens/app_shell.dart'; 

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Utility Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1F2937),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),

        //  ALL BOTTOM NAVIGATION TABS MUST POINT TO AppShell
        '/home': (context) => const AppShell(initialIndex: 0),
        '/add-reading': (context) => const AppShell(initialIndex: 1),
        '/insights': (context) => const AppShell(initialIndex: 2),
        '/payments': (context) => const AppShell(initialIndex: 3),
        '/reminders': (context) => const AppShell(initialIndex: 4),
        '/settings': (context) => const AppShell(initialIndex: 5),

        //  These are NOT tabs, so they can stay as normal pages
        '/profile': (context) => const ProfileScreen(userId: 1),
        '/alerts': (context) => const AlertsScreen(),
      },
    );
  }
}
