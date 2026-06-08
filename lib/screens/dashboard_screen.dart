import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/bp_entry.dart';
import '../models/pregnancy.dart';
import 'blood_pressure_screen.dart';
import 'mood_screen.dart';
import 'water_screen.dart';
import 'steps_screen.dart';
import 'weight_screen.dart';
import 'pregnancy_screen.dart';
import 'settings_screen.dart';
import '../widgets/quick_add_dialog.dart';

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
  PregnancyProfile? _pregnancyProfile;

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

  void _showQuickAdd(String trackerType) {
    showDialog(
      context: context,
      builder: (ctx) => QuickAddDialog(trackerType: trackerType),
    ).then((saved) {
      if (saved == true) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Entry added!'), duration: Duration(seconds: 1)),
        );
      }
    });
  }

  int get _enabledTrackerCount {
    int count = 1; // Home tab
    if (_preferences?['enable_blood_pressure'] == true) count++;
    if (_preferences?['enable_mood'] == true) count++;
    if (_preferences?['enable_water'] == true) count++;
    if (_preferences?['enable_steps'] == true) count++;
    if (_preferences?['enable_weight'] == true) count++;
    if (_isPregnancyEnabled) count++;
    return count;
  }

  List<NavigationDestination> get _destinations {
    List<NavigationDestination> dests = [
      const NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
    ];
    if (_preferences?['enable_blood_pressure'] == true) {
      dests.add(const NavigationDestination(icon: Icon(Icons.favorite), label: 'BP'));
    }
    if (_preferences?['enable_mood'] == true) {
      dests.add(const NavigationDestination(icon: Icon(Icons.emoji_emotions), label: 'Mood'));
    }
    if (_preferences?['enable_water'] == true) {
      dests.add(const NavigationDestination(icon: Icon(Icons.water_drop), label: 'Water'));
    }
    if (_preferences?['enable_steps'] == true) {
      dests.add(const NavigationDestination(icon: Icon(Icons.directions_walk), label: 'Steps'));
    }
    if (_preferences?['enable_weight'] == true) {
      dests.add(const NavigationDestination(icon: Icon(Icons.monitor_weight), label: 'Weight'));
    }
    if (_isPregnancyEnabled) {
      dests.add(const NavigationDestination(icon: Icon(Icons.pregnant_woman), label: 'Baby'));
    }
    return dests;
  }

  List<Widget> get _screens {
    List<Widget> scrs = [_buildHomeScreen()];
    if (_preferences?['enable_blood_pressure'] == true) scrs.add(const BloodPressureScreen());
    if (_preferences?['enable_mood'] == true) scrs.add(const MoodScreen());
    if (_preferences?['enable_water'] == true) scrs.add(const WaterScreen());
    if (_preferences?['enable_steps'] == true) scrs.add(const StepsScreen());
    if (_preferences?['enable_weight'] == true) scrs.add(const WeightScreen());
    if (_isPregnancyEnabled) scrs.add(const PregnancyScreen());
    scrs.add(SettingsScreen(onLogout: widget.onLogout));
    return scrs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
      bottomNavigationBar: NavigationBar(
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
              _buildTodayStats(),
              const SizedBox(height: 16),
              _buildQuickAddGrid(),
              const SizedBox(height: 16),
              _buildWeeklyOverview(),
              const SizedBox(height: 16),
              _buildInsightsCard(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickAddMenu(),
        child: const Icon(Icons.add),
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

  Widget _buildTodayStats() {
    final bpTotal = int.tryParse(_stats?['bp']?['total']?.toString() ?? '0') ?? 0;
    final avgSystolic = int.tryParse(_stats?['bp']?['avg_systolic']?.toString() ?? '0') ?? 0;
    final avgDiastolic = int.tryParse(_stats?['bp']?['avg_diastolic']?.toString() ?? '0') ?? 0;
    final waterTotal = int.tryParse(_stats?['water']?['total']?.toString() ?? '0') ?? 0;
    final stepsTotal = int.tryParse(_stats?['steps']?['total']?.toString() ?? '0') ?? 0;
    final waterGoal = (_preferences?['water_goal'] ?? 2500) as int;
    final stepsGoal = (_preferences?['steps_goal'] ?? 10000) as int;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '📊 Today\'s Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '❤️ BP',
                bpTotal > 0 ? '$avgSystolic/$avgDiastolic' : '--/--',
                'mmHg',
                _getBpTrend(bpTotal),
                bpTotal > 0 ? _getBpColor(avgSystolic, avgDiastolic) : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                '💧 Water',
                '$waterTotal',
                'ml / ${waterGoal}ml',
                _buildProgressBar(waterTotal / waterGoal),
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                '👟 Steps',
                '$stepsTotal',
                '/ ${stepsGoal}',
                _buildProgressBar(stepsTotal / stepsGoal),
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMoodCard(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, Widget? trend, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
              const Spacer(),
              if (trend != null) trend,
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCard() {
    final moodTotal = int.tryParse(_stats?['mood']?['total']?.toString() ?? '0') ?? 0;
    final moodBreakdown = _stats?['mood']?['breakdown'] as Map<String, dynamic>? ?? {};
    
    String dominantMood = '😊';
    if (moodBreakdown.isNotEmpty) {
      final sorted = moodBreakdown.entries.toList()
        ..sort((a, b) => (b.value as int).compareTo(a.value as int));
      if (sorted.isNotEmpty) {
        switch (sorted.first.key) {
          case 'happy': dominantMood = '😄';
          case 'sad': dominantMood = '😢';
          case 'anxious': dominantMood = '😰';
          case 'tired': dominantMood = '😴';
          case 'angry': dominantMood = '😤';
          case 'neutral': dominantMood = '😐';
          case 'excited': dominantMood = '🤗';
          case 'calm': dominantMood = '😌';
        }
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('😊 Mood', style: TextStyle(color: Colors.amber.shade700, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('$moodTotal entries', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            dominantMood,
            style: const TextStyle(fontSize: 32),
          ),
          Text(
            moodTotal > 0 ? 'This week' : 'No entries',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _getBpTrend(int total) {
    if (total == 0) return const SizedBox();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.trending_up, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 2),
        Text('$total', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  Color _getBpColor(int systolic, int diastolic) {
    if (systolic < 120 && diastolic < 80) return Colors.green;
    if (systolic < 130 && diastolic < 85) return Colors.lightGreen;
    if (systolic < 140 || diastolic < 90) return Colors.orange;
    return Colors.red;
  }

  Widget _buildProgressBar(double progress) {
    return SizedBox(
      height: 6,
      width: 60,
      child: LinearProgressIndicator(
        value: progress.clamp(0, 1),
        backgroundColor: Colors.grey.shade300,
        valueColor: AlwaysStoppedAnimation(
          progress >= 1 ? Colors.green : Theme.of(context).colorScheme.primary,
        ),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildQuickAddGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '⚡ Quick Add',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            if (_preferences?['enable_blood_pressure'] == true)
              Expanded(child: _buildQuickAddButton('💉', 'BP', () => _showQuickAdd('bp'))),
            if (_preferences?['enable_mood'] == true)
              Expanded(child: _buildQuickAddButton('😊', 'Mood', () => _showQuickAdd('mood'))),
            if (_preferences?['enable_water'] == true)
              Expanded(child: _buildQuickAddButton('💧', 'Water', () => _showQuickAdd('water'))),
            if (_preferences?['enable_steps'] == true)
              Expanded(child: _buildQuickAddButton('👟', 'Steps', () => _showQuickAdd('steps'))),
            if (_preferences?['enable_weight'] == true)
              Expanded(child: _buildQuickAddButton('⚖️', 'Weight', () => _showQuickAdd('weight'))),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAddButton(String emoji, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickAddMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Add Entry',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (_preferences?['enable_blood_pressure'] == true)
                  _buildBottomSheetChip('💉 Blood Pressure', () {
                    Navigator.pop(ctx);
                    _showQuickAdd('bp');
                  }),
                if (_preferences?['enable_mood'] == true)
                  _buildBottomSheetChip('😊 Mood', () {
                    Navigator.pop(ctx);
                    _showQuickAdd('mood');
                  }),
                if (_preferences?['enable_water'] == true)
                  _buildBottomSheetChip('💧 Water', () {
                    Navigator.pop(ctx);
                    _showQuickAdd('water');
                  }),
                if (_preferences?['enable_steps'] == true)
                  _buildBottomSheetChip('👟 Steps', () {
                    Navigator.pop(ctx);
                    _showQuickAdd('steps');
                  }),
                if (_preferences?['enable_weight'] == true)
                  _buildBottomSheetChip('⚖️ Weight', () {
                    Navigator.pop(ctx);
                    _showQuickAdd('weight');
                  }),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheetChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      avatar: Text(label.split(' ')[0]),
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    final bpTotal = int.tryParse(_stats?['bp']?['total']?.toString() ?? '0') ?? 0;
    final avgSystolic = int.tryParse(_stats?['bp']?['avg_systolic']?.toString() ?? '0') ?? 0;
    final avgDiastolic = int.tryParse(_stats?['bp']?['avg_diastolic']?.toString() ?? '0') ?? 0;

    String insight = 'Start tracking to get insights!';
    if (bpTotal > 0) {
      if (avgSystolic >= 140 || avgDiastolic >= 90) {
        insight = '⚠️ Your average BP is elevated. Consider reducing salt intake and exercising more.';
      } else if (avgSystolic >= 130 || avgDiastolic >= 85) {
        insight = '💡 Your BP is slightly high. Regular monitoring recommended.';
      } else {
        insight = '✅ Great job! Your BP is in a healthy range. Keep it up!';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb, color: Colors.amber),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              insight,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}