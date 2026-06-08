import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/bp_entry.dart';
import 'package:intl/intl.dart';

class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key});

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen> {
  List<WaterEntry> _entries = [];
  bool _isLoading = true;
  int _dailyGoal = 2500;
  int _todayTotal = 0;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final entries = await api.getWaterEntries();
      final settings = await api.getSettings();
      
      final today = DateTime.now();
      final todayEntries = entries.where((e) {
        return e.recordedAt.year == today.year &&
               e.recordedAt.month == today.month &&
               e.recordedAt.day == today.day;
      }).toList();
      
      setState(() {
        _entries = entries;
        _dailyGoal = settings['water_goal'] ?? 2500;
        _todayTotal = todayEntries.fold(0, (sum, e) => sum + e.amount);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addEntry(int amount) async {
    try {
      final api = ApiService();
      await api.addWaterEntry(amount: amount);
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
      await api.deleteWaterEntry(id);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Intake'),
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
                _buildProgressCard(progress),
                const SizedBox(height: 16),
                _buildQuickAddButtons(),
                const SizedBox(height: 24),
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
                        '$_todayTotal / $_dailyGoal ml',
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

  Widget _buildProgressCard(double progress) {
    final color = progress >= 1.0 ? Colors.green : Colors.blue;
    
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
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$_todayTotal ml',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            progress >= 1.0 ? '🎉 Goal achieved!' : '💧 Keep drinking!',
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAddButtons() {
    final amounts = [100, 200, 250, 500];
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: amounts.map((amount) {
          return ElevatedButton(
            onPressed: () => _addEntry(amount),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.withOpacity(0.2),
              foregroundColor: Colors.blue,
            ),
            child: Text('+$amount ml'),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEntryTile(WaterEntry entry) {
    final dateFormat = DateFormat('h:mm a');
    
    return ListTile(
      onLongPress: () => _deleteEntry(entry.id),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.water_drop, color: Colors.blue),
      ),
      title: Text('${entry.amount} ml'),
      subtitle: Text(dateFormat.format(entry.recordedAt)),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.grey),
        onPressed: () => _deleteEntry(entry.id),
      ),
    );
  }
}