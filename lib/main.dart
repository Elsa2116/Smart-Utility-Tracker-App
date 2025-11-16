import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/data_provider.dart';
import 'screens/splash_screen.dart'; // ✅ Add this import
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/add_reading_screen.dart';
import 'screens/history_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/payments_screen.dart';
import 'screens/reminders_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/alerts_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => DataProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Utility Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      // ✅ Start with splash screen instead of login
      initialRoute: '/splash',
      debugShowCheckedModeBanner: false,
      routes: {
        '/splash': (context) => const SplashScreen(), // ✅ Added route
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => const HomeScreen(),
        '/add-reading': (context) => const AddReadingScreen(),
        '/history': (context) => const HistoryScreen(),
        '/analytics': (context) => const AnalyticsScreen(),
        '/payments': (context) => const PaymentsScreen(),
        '/reminders': (context) => const RemindersScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/alerts': (context) => const AlertsScreen(),
      },
    );
  }
}
