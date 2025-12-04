import 'package:flutter/material.dart';
import 'package:smart_utility_tracker/screens/splash_screen.dart';
import 'package:smart_utility_tracker/screens/login_screen.dart';
import 'package:smart_utility_tracker/screens/home_screen.dart';
import 'package:smart_utility_tracker/screens/profile_screen.dart';
import 'package:smart_utility_tracker/screens/history_analytics_screen.dart';
import 'package:smart_utility_tracker/screens/payments_screen.dart';
import 'package:smart_utility_tracker/screens/alerts_screen.dart';
import 'package:smart_utility_tracker/screens/add_reading_screen.dart';
import 'package:smart_utility_tracker/screens/reminders_screen.dart';
import 'package:smart_utility_tracker/screens/settings_screen.dart';

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
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(userId: 1),
        '/insights': (context) => const HistoryAnalyticsScreen(),
        '/payments': (context) => const PaymentsScreen(),
        '/alerts': (context) => const AlertsScreen(),
        '/reminders': (context) => const RemindersScreen(), // added
        '/settings': (context) => const SettingsScreen(), // added
        '/add-reading': (context) => const AddReadingScreen(),
      },
    );
  }
}
