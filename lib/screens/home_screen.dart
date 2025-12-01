import 'dart:io'; // Added import
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/db_helper.dart';
import '../models/reading.dart';
import 'add_reading_screen.dart';
import 'history_analytics_screen.dart';
import 'payments_screen.dart';
import 'alerts_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();
  final _dbHelper = DBHelper();
  int _selectedIndex = 0;
  List<Reading> _recentReadings = [];
  bool _showAllReadings = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Demo data for testing
    setState(() {
      _recentReadings = [
        Reading(
          userId: 1,
          usage: 245,
          type: 'electricity',
          date: DateTime.now().subtract(const Duration(days: 1)),
        ),
        Reading(
          userId: 1,
          usage: 45,
          type: 'water',
          date: DateTime.now().subtract(const Duration(days: 2)),
        ),
        Reading(
          userId: 1,
          usage: 230,
          type: 'electricity',
          date: DateTime.now().subtract(const Duration(days: 30)),
        ),
        Reading(
          userId: 1,
          usage: 42,
          type: 'water',
          date: DateTime.now().subtract(const Duration(days: 32)),
        ),
      ];
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Home - already on home screen
        break;
      case 1:
        Navigator.pushNamed(context, '/add-reading').then((_) => _loadData());
        break;
      case 2:
        Navigator.pushNamed(context, '/insights');
        break;
      case 3:
        Navigator.pushNamed(context, '/payments').then((_) => _loadData());
        break;
      case 4:
        Navigator.pushNamed(context, '/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedReadings =
        _showAllReadings ? _recentReadings : _recentReadings.take(2).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1F2937),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildLogo(),
        ),
        title: const Text(
          'Smart Utility Tracker',
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          // Notification button (Alerts)
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/alerts'),
            tooltip: 'Alerts',
          ),
          // Removed duplicate profile button - accessible via Settings tab
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F2937), Color(0xFF111827)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Welcome back!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track your utilities',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 32),

              // Quick Stats Cards
              _buildQuickStats(),

              const SizedBox(height: 32),

              // Recent Readings Header with See All button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Readings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (_recentReadings.length > 2)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showAllReadings = !_showAllReadings;
                        });
                      },
                      icon: Icon(
                        _showAllReadings
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: Colors.blue[400],
                        size: 18,
                      ),
                      label: Text(
                        _showAllReadings ? 'Show Less' : 'Show All',
                        style: TextStyle(
                          color: Colors.blue[400],
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (_recentReadings.isEmpty)
                _emptyReadingsWidget()
              else
                Column(
                  children: displayedReadings.map(_buildReadingCard).toList(),
                ),

              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _buildQuickActions(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: const Color(0xFF1F2937),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[400],
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Add'),
          BottomNavigationBarItem(
              icon: Icon(Icons.insights), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Payments'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final electricityReadings =
        _recentReadings.where((r) => r.type == 'electricity').toList();
    final waterReadings =
        _recentReadings.where((r) => r.type == 'water').toList();

    final electricityAvg = electricityReadings.isNotEmpty
        ? electricityReadings.fold<double>(0, (sum, r) => sum + r.usage) /
            electricityReadings.length
        : 0;
    final waterAvg = waterReadings.isNotEmpty
        ? waterReadings.fold<double>(0, (sum, r) => sum + r.usage) /
            waterReadings.length
        : 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Electricity',
            electricityAvg.toStringAsFixed(1),
            'kWh',
            Icons.bolt,
            Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Water',
            waterAvg.toStringAsFixed(1),
            'L',
            Icons.water_drop,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, String unit, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4B5563)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Average Usage',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      children: [
        _buildActionCard(
          'Add Reading',
          Icons.add_circle_outline,
          Colors.blue,
          () => Navigator.pushNamed(context, '/add-reading')
              .then((_) => _loadData()),
        ),
        _buildActionCard(
          'View History',
          Icons.history,
          Colors.green,
          () => Navigator.pushNamed(context, '/insights'),
        ),
        _buildActionCard(
          'Payments',
          Icons.payment,
          Colors.purple,
          () => Navigator.pushNamed(context, '/payments'),
        ),
        _buildActionCard(
          'Analytics',
          Icons.analytics,
          Colors.orange,
          () => Navigator.pushNamed(context, '/insights'),
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF374151),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4B5563)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    try {
      return ClipOval(
        child: Image.asset(
          'assets/logo.jpg',
          fit: BoxFit.cover,
          width: 40,
          height: 40,
          errorBuilder: (_, __, ___) => _buildFallbackLogo(),
        ),
      );
    } catch (e) {
      return _buildFallbackLogo();
    }
  }

  Widget _buildFallbackLogo() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(
        child: Text(
          "SU",
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildProfileIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.shade800,
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _emptyReadingsWidget() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4B5563)),
      ),
      child: Column(
        children: [
          Icon(Icons.trending_up, size: 48, color: Colors.blue[400]),
          const SizedBox(height: 12),
          Text('No readings yet',
              style: TextStyle(color: Colors.grey[300], fontSize: 16)),
          const SizedBox(height: 4),
          Text('Add your first reading to get started',
              style: TextStyle(color: Colors.grey[500], fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/add-reading')
                .then((_) => _loadData()),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add First Reading'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadingCard(Reading r) {
    IconData icon = r.type == 'water' ? Icons.water_drop : Icons.bolt;
    Color color = r.type == 'water' ? Colors.blue : Colors.amber;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF374151),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4B5563)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.type.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${r.date.day}/${r.date.month}/${r.date.year}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${r.usage}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              Text(
                r.type == 'electricity' ? 'kWh' : 'L',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
