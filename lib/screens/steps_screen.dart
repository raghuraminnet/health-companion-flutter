import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/bp_entry.dart';
import 'package:intl/intl.dart';

class StepsScreen extends StatefulWidget {
  const StepsScreen({super.key});

  @override
  State<StepsScreen> createState() => _StepsScreenState();
}

class _StepsScreenState extends State<StepsScreen> {
  List<StepsEntry> _entries = [];
  bool _isLoading = true;
  int _dailyGoal = 10000;
  int _todayTotal = 0;

  final _stepsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final entries = await api.getStepsEntries();
      final settings = await api.getSettings();
      
      final today = DateTime.now();
      final todayEntries = entries.where((e) {
        return e.recordedAt.year == today.year &&
               e.recordedAt.month == today.month &&
               e.recordedAt.day == today.day;
      }).toList();
      
      setState(() {
        _entries = entries;
        _dailyGoal = settings['steps_goal'] ?? 10000;
        _todayTotal = todayEntries.fold(0, (sum, e) => sum + e.steps);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addEntry() async {
    final steps = int.tryParse(_stepsController.text);
    if (steps == null || steps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid number')),
      );
      return;
    }

    try {
      final api = ApiService();
      await api.addStepsEntry(steps: steps);
      _stepsController.clear();
      _loadEntries();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add: $e')),
        );
      }
    }
  }

  Future<void> _deleteEntry(String id) async {
    try {
      final api = ApiService();
      await api.deleteStepsEntry(id);
      _loadEntries();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_todayTotal / _dailyGoal).clamp(0.0, 1.0);
    final distanceKm = (_todayTotal / 1300).toStringAsFixed(2);
    final calories = (_todayTotal * 0.04).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Steps'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEntries,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildProgressCard(progress, distanceKm, calories),
                _buildAddForm(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Entries",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '$_todayTotal / $_dailyGoal',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: _entries.isEmpty
                      ? const Center(child: Text('No entries yet'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _entries.length,
                          itemBuilder: (context, i) {
                            final entry = _entries[i];
                            return _buildEntryTile(entry);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildProgressCard(double progress, String distanceKm, int calories) {
    final color = progress >= 1.0 ? Colors.green : Colors.orange;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 120,
                height: 120,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$_todayTotal',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text('steps', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Distance', '$distanceKm km', Icons.directions_walk),
              _buildStatItem('Calories', '$calories kcal', Icons.local_fire_department),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  Widget _buildAddForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _stepsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter steps',
                prefixIcon: Icon(Icons.directions_walk),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _addEntry,
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTile(StepsEntry entry) {
    final dateFormat = DateFormat('h:mm a');
    
    return ListTile(
      onLongPress: () => _deleteEntry(entry.id),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.directions_walk, color: Colors.orange),
      ),
      title: Text('${entry.steps} steps'),
      subtitle: Text(dateFormat.format(entry.recordedAt)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.grey),
        onPressed: () => _deleteEntry(entry.id),
      ),
    );
  }
}