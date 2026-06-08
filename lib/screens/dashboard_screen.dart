import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/bp_entry.dart';
import 'blood_pressure_screen.dart';
import 'mood_screen.dart';
import 'water_screen.dart';
import 'steps_screen.dart';
import 'weight_screen.dart';
import 'profile_screen.dart';

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

  final List<Widget> _screens = [];

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
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildHomeScreen(),
      if (_preferences?['enable_blood_pressure'] == true) const BloodPressureScreen(),
      if (_preferences?['enable_mood'] == true) const MoodScreen(),
      if (_preferences?['enable_water'] == true) const WaterScreen(),
      if (_preferences?['enable_steps'] == true) const StepsScreen(),
      if (_preferences?['enable_weight'] == true) const WeightScreen(),
      const ProfileScreen(onLogout: null),
    ];

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          if (_preferences?['enable_blood_pressure'] == true)
            const NavigationDestination(icon: Icon(Icons.favorite), label: 'BP'),
          if (_preferences?['enable_mood'] == true)
            const NavigationDestination(icon: Icon(Icons.emoji_emotions), label: 'Mood'),
          if (_preferences?['enable_water'] == true)
            const NavigationDestination(icon: Icon(Icons.water_drop), label: 'Water'),
          if (_preferences?['enable_steps'] == true)
            const NavigationDestination(icon: Icon(Icons.directions_walk), label: 'Steps'),
          if (_preferences?['enable_weight'] == true)
            const NavigationDestination(icon: Icon(Icons.monitor_weight), label: 'Weight'),
        ],
      ),
    );
  }

  Widget _buildHomeScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Companion'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
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
              Text(
                'Your Health Today',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildStatCards(),
              const SizedBox(height: 24),
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildQuickActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCards() {
    final bpTotal = int.tryParse(_stats?['bp']?['total']?.toString() ?? '0') ?? 0;
    final avgSystolic = int.tryParse(_stats?['bp']?['avg_systolic']?.toString() ?? '0') ?? 0;
    final avgDiastolic = int.tryParse(_stats?['bp']?['avg_diastolic']?.toString() ?? '0') ?? 0;
    final waterTotal = int.tryParse(_stats?['water']?['total']?.toString() ?? '0') ?? 0;
    final stepsTotal = int.tryParse(_stats?['steps']?['total']?.toString() ?? '0') ?? 0;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _buildStatCard(
          'Blood Pressure',
          bpTotal > 0 ? '$avgSystolic/$avgDiastolic' : '--/--',
          'mmHg',
          Icons.favorite,
          Colors.red,
        ),
        _buildStatCard(
          'Mood Entries',
          _stats?['mood']?['total']?.toString() ?? '0',
          'this week',
          Icons.emoji_emotions,
          Colors.amber,
        ),
        _buildStatCard(
          'Water Intake',
          waterTotal.toString(),
          'ml',
          Icons.water_drop,
          Colors.blue,
        ),
        _buildStatCard(
          'Steps',
          stepsTotal.toString(),
          'steps',
          Icons.directions_walk,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String unit, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(unit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (_preferences?['enable_blood_pressure'] == true)
          _buildActionChip('Add BP', Icons.favorite, () => setState(() => _currentIndex = 1)),
        if (_preferences?['enable_mood'] == true)
          _buildActionChip('Log Mood', Icons.emoji_emotions, () => setState(() => _currentIndex = 2)),
        if (_preferences?['enable_water'] == true)
          _buildActionChip('Add Water', Icons.water_drop, () => setState(() => _currentIndex = 3)),
        if (_preferences?['enable_steps'] == true)
          _buildActionChip('Log Steps', Icons.directions_walk, () => setState(() => _currentIndex = 4)),
        if (_preferences?['enable_weight'] == true)
          _buildActionChip('Log Weight', Icons.monitor_weight, () => setState(() => _currentIndex = 5)),
      ],
    );
  }

  Widget _buildActionChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }
}