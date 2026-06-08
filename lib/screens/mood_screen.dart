import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/bp_entry.dart';
import 'package:intl/intl.dart';

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  List<MoodEntry> _entries = [];
  bool _isLoading = true;
  bool _showAddForm = false;

  String _selectedMood = 'good';
  int _dayRating = 3;
  int _sleepQuality = 3;
  int _energyLevel = 3;
  final _notesController = TextEditingController();

  final List<Map<String, dynamic>> _moods = [
    {'value': 'good', 'label': '😊 Good', 'icon': '😊', 'color': Colors.green},
    {'value': 'stressed', 'label': '😰 Stressed', 'icon': '😰', 'color': Colors.orange},
    {'value': 'calm', 'label': '😌 Calm', 'icon': '😌', 'color': Colors.blue},
    {'value': 'anxious', 'label': '😟 Anxious', 'icon': '😟', 'color': Colors.purple},
    {'value': 'sad', 'label': '😢 Sad', 'icon': '😢', 'color': Colors.grey},
    {'value': 'energized', 'label': '⚡ Energized', 'icon': '⚡', 'color': Colors.yellow},
  ];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final entries = await api.getMoodEntries();
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addEntry() async {
    try {
      final api = ApiService();
      await api.addMoodEntry(
        mood: _selectedMood,
        dayRating: _dayRating,
        sleepQuality: _sleepQuality,
        energyLevel: _energyLevel,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      
      _notesController.clear();
      setState(() => _showAddForm = false);
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
      await api.deleteMoodEntry(id);
      _loadEntries();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  String _getMoodEmoji(String mood) {
    return _moods.firstWhere((m) => m['value'] == mood, orElse: () => _moods[0])['icon'];
  }

  Color _getMoodColor(String mood) {
    return _moods.firstWhere((m) => m['value'] == mood, orElse: () => _moods[0])['color'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mood Tracking'),
        actions: [
          IconButton(
            icon: Icon(_showAddForm ? Icons.close : Icons.add),
            onPressed: () => setState(() => _showAddForm = !_showAddForm),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_showAddForm) _buildAddForm(),
                Expanded(
                  child: _entries.isEmpty
                      ? const Center(child: Text('No entries yet'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _entries.length,
                          itemBuilder: (context, i) {
                            final entry = _entries[i];
                            return _buildEntryCard(entry);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildAddForm() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'How are you feeling?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _moods.map((mood) {
                final isSelected = _selectedMood == mood['value'];
                return ChoiceChip(
                  label: Text('${mood['icon']} ${mood['label']}'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedMood = mood['value']);
                  },
                  selectedColor: (mood['color'] as Color).withOpacity(0.3),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _buildRatingRow('Day Rating', _dayRating, (v) => setState(() => _dayRating = v)),
            const SizedBox(height: 12),
            _buildRatingRow('Sleep Quality', _sleepQuality, (v) => setState(() => _sleepQuality = v)),
            const SizedBox(height: 12),
            _buildRatingRow('Energy Level', _energyLevel, (v) => setState(() => _energyLevel = v)),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _addEntry,
              child: const Text('Save Mood'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingRow(String label, int value, Function(int) onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(label, style: const TextStyle(fontSize: 14)),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final rating = i + 1;
              return GestureDetector(
                onTap: () => onChanged(rating),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: rating <= value
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$rating',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: rating <= value
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildEntryCard(MoodEntry entry) {
    final dateFormat = DateFormat('MMM d, y • h:mm a');
    final color = _getMoodColor(entry.mood);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onLongPress: () => _deleteEntry(entry.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _getMoodEmoji(entry.mood),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.mood.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateFormat.format(entry.recordedAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMiniStat('Day', entry.dayRating),
                        const SizedBox(width: 8),
                        _buildMiniStat('Sleep', entry.sleepQuality),
                        const SizedBox(width: 8),
                        _buildMiniStat('Energy', entry.energyLevel),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, int? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: ${value ?? '-'}',
        style: const TextStyle(fontSize: 10),
      ),
    );
  }
}