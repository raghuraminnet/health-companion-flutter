import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'pregnancy_screen.dart';
import 'settings_screen.dart';

/// Legacy home dashboard (v1 surface).
///
/// After the v2 design system rollout, the daily trackers (BP, Mood, Water,
/// Steps, Weight) ship as redesigned screens under `screens/v2/`, and the
/// default landing screen is `DashboardV2`. This screen remains only so the
/// existing `AuthScreen` post-login redirect keeps compiling — it shows a
/// basic home view with greeting card, optional pregnancy banner, and
/// weekly summary.
class DashboardScreen extends StatefulWidget {
  final VoidCallback onLogout;
  
  const DashboardScreen({super.key, required this.onLogout});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _stats;
  Map<String, dynamic>? _preferences;
  bool _isLoading = true;
  bool _isPregnancyEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) {
        api.setToken(token);
      }
      
      final results = await Future.wait([
        api.getStats(),
        api.getPreferences(),
      ]);
      
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _preferences = results[1] as Map<String, dynamic>;
        _isPregnancyEnabled = _preferences?['enable_pregnancy'] == true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  int get _enabledTrackerCount {
    int count = 1; // Home tab
    if (_isPregnancyEnabled) count++;
    return count;
  }

  List<NavigationDestination> get _destinations {
    List<NavigationDestination> dests = [
      const NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
    ];
    if (_isPregnancyEnabled) {
      dests.add(const NavigationDestination(icon: Icon(Icons.pregnant_woman), label: 'Baby'));
    }
    return dests;
  }

  List<Widget> get _screens {
    List<Widget> scrs = [_buildHomeScreen()];
    if (_isPregnancyEnabled) scrs.add(const PregnancyScreen());
    scrs.add(SettingsScreen(onLogout: widget.onLogout));
    return scrs;
  }

  @override
  Widget build(BuildContext context) {
    final onSettings = _currentIndex >= _destinations.length;
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
      bottomNavigationBar: onSettings
          ? null
          : NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              destinations: _destinations,
            ),
    );
  }

  Widget _buildHomeScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => setState(() => _currentIndex = _enabledTrackerCount),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreetingCard(),
              const SizedBox(height: 16),
              if (_isPregnancyEnabled) ...[
                _buildPregnancyBanner(),
                const SizedBox(height: 16),
              ],
              _buildWeeklyOverview(),
              const SizedBox(height: 16),
              _buildInsightsCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreetingCard() {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning! ☀️';
    } else if (hour < 17) {
      greeting = 'Good Afternoon! 🌤️';
    } else {
      greeting = 'Good Evening! 🌙';
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Track your health journey',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, size: 35, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildPregnancyBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.pink.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.pink.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.pink.shade100,
              shape: BoxShape.circle,
            ),
            child: const Text('👶', style: TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Baby Progress',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Week 8 • Baby is the size of a Raspberry',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.pink,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '20%',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📈 Weekly Summary',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildWeekDayStat('Mon', _getDayData('mon')),
              _buildWeekDayStat('Tue', _getDayData('tue')),
              _buildWeekDayStat('Wed', _getDayData('wed')),
              _buildWeekDayStat('Thu', _getDayData('thu')),
              _buildWeekDayStat('Fri', _getDayData('fri')),
              _buildWeekDayStat('Sat', _getDayData('sat')),
              _buildWeekDayStat('Sun', _getDayData('sun')),
            ],
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _getDayData(String day) {
    final weekly = _stats?['weekly'] as Map<String, dynamic>? ?? {};
    return weekly[day] as Map<String, dynamic>? ?? {'bp': 0, 'water': 0, 'steps': 0, 'mood': 0};
  }

  Widget _buildWeekDayStat(String day, Map<String, dynamic> data) {
    final hasData = (data['bp'] as int? ?? 0) > 0 || 
                    (data['water'] as int? ?? 0) > 0 || 
                    (data['steps'] as int? ?? 0) > 0;
    return Column(
      children: [
        Text(day, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: hasData ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: hasData ? Icon(
              Icons.check,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ) : const Text('.', style: TextStyle(color: Colors.grey)),
          ),
        ),
      ],
    );
  }

  Widget _buildInsightsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb, color: Colors.amber),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Open a daily tracker from the redesigned v2 preview to start logging insights.',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
