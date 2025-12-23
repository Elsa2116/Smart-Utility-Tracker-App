import 'package:flutter/material.dart'; // Import Flutter material package for UI components
import '../services/auth_service.dart'; // Import custom authentication service
import '../services/db_helper.dart'; // Import custom database helper service
import '../models/reading.dart'; // Import Reading model

class HomeScreen extends StatefulWidget {
  // Define HomeScreen as a StatefulWidget for dynamic UI
  const HomeScreen(
      {super.key}); // Constructor with key for widget identification

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState(); // Create mutable state for this widget
}

class _HomeScreenState extends State<HomeScreen> {
  // State class for HomeScreen
  final _authService =
      AuthService(); // Instantiate AuthService for user authentication
  final _dbHelper = DBHelper(); // Instantiate DBHelper for database operations
  int _selectedIndex = 0; // Track selected bottom navigation index
  List<Reading> _recentReadings = []; // Store list of recent readings
  bool _showAllReadings =
      false; // Control whether to show all readings or only the first few

  @override
  void initState() {
    super.initState(); // Call parent initState
    _loadData(); // Load recent readings when widget initializes
  }

  Future<void> _loadData() async {
    // Method to load recent readings (dummy data here)
    setState(() {
      // Update the state with new readings
      _recentReadings = [
        Reading(
          userId: 1,
          usage: 245,
          type: 'electricity',
          date: DateTime.now().subtract(const Duration(days: 1)), // Yesterday
        ),
        Reading(
          userId: 1,
          usage: 45,
          type: 'water',
          date:
              DateTime.now().subtract(const Duration(days: 2)), // Two days ago
        ),
        Reading(
          userId: 1,
          usage: 230,
          type: 'electricity',
          date:
              DateTime.now().subtract(const Duration(days: 30)), // 30 days ago
        ),
        Reading(
          userId: 1,
          usage: 42,
          type: 'water',
          date:
              DateTime.now().subtract(const Duration(days: 32)), // 32 days ago
        ),
      ];
    });
  }

  void _onItemTapped(int index) {
    // Handle bottom navigation tap events
    setState(() {
      // Update the selected index
      _selectedIndex = index;
    });

    // Navigate to different screens based on the tapped index
    switch (index) {
      case 0: // Home, do nothing
        break;
      case 1: // Add Reading screen
        Navigator.pushNamed(context, '/add-reading').then((_) => _loadData());
        break;
      case 2: // Insights screen
        Navigator.pushNamed(context, '/insights');
        break;
      case 3: // Payments screen
        Navigator.pushNamed(context, '/payments').then((_) => _loadData());
        break;
      case 4: // Reminders screen
        Navigator.pushNamed(context, '/reminders');
        break;
      case 5: // Settings screen
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayedReadings = _showAllReadings
        ? _recentReadings
        : _recentReadings
            .take(2)
            .toList(); // Determine which readings to display

    return Scaffold(
      // Main scaffold of the screen
      appBar: AppBar(
        // Top app bar
        backgroundColor: const Color(0xFF1F2937), // Dark gray background
        elevation: 0, // No shadow
        leading: Padding(
          // Padding for leading widget (logo)
          padding: const EdgeInsets.all(8.0),
          child: _buildLogo(), // Custom logo widget
        ),
        title: const Text(
          // App title
          'Smart Utility Tracker',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          // Action icons on the app bar
          IconButton(
            icon: const Icon(Icons.notifications_outlined,
                color: Colors.white), // Notifications icon
            onPressed: () => Navigator.pushNamed(
                context, '/alerts'), // Navigate to Alerts screen
            tooltip: 'Alerts',
          ),
          IconButton(
            icon: _buildProfileIcon(), // Profile icon
            onPressed: () => Navigator.pushNamed(
                context, '/profile'), // Navigate to Profile screen
            tooltip: 'Profile',
          ),
        ],
      ),
      body: Container(
        // Main body container
        decoration: const BoxDecoration(
          // Background gradient
          gradient: LinearGradient(
            colors: [Color(0xFF1F2937), Color(0xFF111827)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          // Scrollable content
          padding: const EdgeInsets.all(16),
          child: Column(
            // Vertical layout
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8), // Spacer
              Text(
                'Welcome back!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4), // Spacer
              Text(
                'Track your utilities',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 32), // Spacer
              _buildQuickStats(), // Widget showing electricity and water averages
              const SizedBox(height: 32), // Spacer
              Row(
                // Header row for recent readings
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Readings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (_recentReadings.length >
                      2) // Show "Show All/Show Less" button if more than 2 readings
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _showAllReadings =
                              !_showAllReadings; // Toggle readings display
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
              const SizedBox(height: 12), // Spacer
              if (_recentReadings.isEmpty) // Show empty state if no readings
                _emptyReadingsWidget()
              else // Otherwise, show reading cards
                Column(
                  children: displayedReadings.map(_buildReadingCard).toList(),
                ),
              const SizedBox(height: 24), // Spacer
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16), // Spacer
              _buildQuickActions(), // Quick actions widget using Wrap for responsive layout
              const SizedBox(height: 32), // Bottom spacer
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        // Bottom navigation bar
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // Handle item taps
        backgroundColor: const Color(0xFF1F2937), // Dark background
        type: BottomNavigationBarType.fixed, // Fixed navigation bar
        selectedItemColor: Colors.blue[400], // Selected item color
        unselectedItemColor: Colors.grey[600], // Unselected item color
        items: const [
          // Navigation items
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

  Widget _buildQuickStats() {
    // Widget for electricity & water average cards
    final electricityReadings = _recentReadings
        .where((r) => r.type == 'electricity')
        .toList(); // Filter electricity readings
    final waterReadings = _recentReadings
        .where((r) => r.type == 'water')
        .toList(); // Filter water readings

    final electricityAvg = electricityReadings.isNotEmpty
        ? electricityReadings.fold<double>(0, (sum, r) => sum + r.usage) /
            electricityReadings.length // Calculate average electricity usage
        : 0;
    final waterAvg = waterReadings.isNotEmpty
        ? waterReadings.fold<double>(0, (sum, r) => sum + r.usage) /
            waterReadings.length // Calculate average water usage
        : 0;

    return Row(
      // Row to show two stat cards side by side
      children: [
        Expanded(
          child: _buildStatCard(
              'Electricity',
              electricityAvg.toStringAsFixed(1),
              'kWh',
              Icons.bolt,
              Colors.amber),
        ),
        const SizedBox(width: 12), // Spacer
        Expanded(
          child: _buildStatCard('Water', waterAvg.toStringAsFixed(1), 'L',
              Icons.water_drop, Colors.blue),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, String unit, IconData icon, Color color) {
    // Individual stat card
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF374151), // Dark gray background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4B5563)), // Border color
      ),
      child: Column(
        // Vertical layout for icon, title, value
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            // Icon + Title row
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2), // Icon background
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20), // Stat icon
              ),
              const SizedBox(width: 8),
              Text(
                title, // Stat title
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
            // Value + Unit row
            children: [
              Text(
                value, // Numeric value
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit, // Unit text
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Average Usage', // Description below value
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
    // Wrap widget for multiple action cards
    return Wrap(
      spacing: 12, // Horizontal spacing
      runSpacing: 12, // Vertical spacing
      children: [
        SizedBox(
          width:
              (MediaQuery.of(context).size.width - 44) / 2, // Responsive width
          child: _buildActionCard(
            'Add Reading',
            Icons.add_circle_outline,
            Colors.blue,
            () => Navigator.pushNamed(context, '/add-reading').then(
                (_) => _loadData()), // Navigate and reload data after adding
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          child: _buildActionCard(
            'View History',
            Icons.history,
            Colors.green,
            () => Navigator.pushNamed(
                context, '/insights'), // Navigate to insights
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          child: _buildActionCard(
            'Payments',
            Icons.payment,
            Colors.purple,
            () => Navigator.pushNamed(
                context, '/payments'), // Navigate to payments
          ),
        ),
        SizedBox(
          width: (MediaQuery.of(context).size.width - 44) / 2,
          child: _buildActionCard(
            'Analytics',
            Icons.analytics,
            Colors.orange,
            () => Navigator.pushNamed(
                context, '/insights'), // Navigate to analytics/insights
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap) {
    // Individual action card
    return GestureDetector(
      onTap: onTap, // Handle tap event
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF374151), // Card background
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4B5563)), // Card border
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2), // Icon background
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24), // Icon
              ),
              const SizedBox(height: 12),
              Text(
                title, // Action title
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
    // Logo widget in app bar
    try {
      return ClipOval(
        child: Image.asset(
          'assets/logo.jpg', // Logo image
          fit: BoxFit.cover,
          width: 40,
          height: 40,
          errorBuilder: (_, __, ___) =>
              _buildFallbackLogo(), // Fallback if image not found
        ),
      );
    } catch (e) {
      // Fallback for any other errors
      return _buildFallbackLogo();
    }
  }

  Widget _buildFallbackLogo() {
    // Simple fallback logo
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(20), // Circular container
      ),
      child: const Center(
        child: Text(
          "SU", // Initials as fallback
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildProfileIcon() {
    // Profile icon in app bar
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle, // Circular background
        color: Colors.blue.shade800,
      ),
      child: const Icon(
        Icons.person, // Person icon
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _emptyReadingsWidget() {
    // Empty state widget if no readings
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: const Color(0xFF374151), // Background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4B5563)), // Border
      ),
      child: Column(
        children: [
          Icon(Icons.trending_up,
              size: 48, color: Colors.blue[400]), // Empty state icon
          const SizedBox(height: 12),
          Text('No readings yet',
              style: TextStyle(
                  color: Colors.grey[300], fontSize: 16)), // Main message
          const SizedBox(height: 4),
          Text('Add your first reading to get started',
              style:
                  TextStyle(color: Colors.grey[500], fontSize: 14)), // Subtext
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/add-reading')
                .then((_) => _loadData()), // Add first reading button
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
    // Widget for individual reading card
    IconData icon =
        r.type == 'water' ? Icons.water_drop : Icons.bolt; // Icon based on type
    Color color =
        r.type == 'water' ? Colors.blue : Colors.amber; // Color based on type

    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Space below card
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF374151), // Background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF4B5563)), // Border
      ),
      child: Row(
        // Horizontal layout
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24), // Reading icon
          ),
          const SizedBox(width: 16), // Spacer
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.type.toUpperCase(), // Type label
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  '${r.date.day}/${r.date.month}/${r.date.year}', // Date
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${r.usage}', // Usage value
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
              Text(
                r.type == 'electricity' ? 'kWh' : 'L', // Unit
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
