import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/bp_entry.dart';
import 'package:intl/intl.dart';

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  List<WeightEntry> _entries = [];
  bool _isLoading = true;
  double? _latestWeight;

  final _weightController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final entries = await api.getWeightEntries();
      setState(() {
        _entries = entries;
        _latestWeight = entries.isNotEmpty ? entries.first.weight : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addEntry() async {
    final weight = double.tryParse(_weightController.text);
    if (weight == null || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid weight')),
      );
      return;
    }

    try {
      final api = ApiService();
      await api.addWeightEntry(
        weight: weight,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );
      _weightController.clear();
      _notesController.clear();
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
      await api.deleteWeightEntry(id);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight'),
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
                _buildCurrentWeightCard(),
                _buildAddForm(),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'History',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (_entries.isNotEmpty)
                        Text(
                          '${_entries.length} entries',
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

  Widget _buildCurrentWeightCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.3),
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Current Weight',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _latestWeight?.toStringAsFixed(1) ?? '--',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                ' kg',
                style: TextStyle(fontSize: 20, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_entries.length >= 2)
            Text(
              _getWeightChange(),
              style: TextStyle(
                color: _getWeightChangeColor(),
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }

  String _getWeightChange() {
    if (_entries.length < 2) return '';
    final current = _entries[0].weight;
    final previous = _entries[1].weight;
    final diff = current - previous;
    final sign = diff >= 0 ? '+' : '';
    return '$sign${diff.toStringAsFixed(1)} kg since last entry';
  }

  Color _getWeightChangeColor() {
    if (_entries.length < 2) return Colors.grey;
    final diff = _entries[0].weight - _entries[1].weight;
    if (diff.abs() < 0.5) return Colors.green;
    return diff < 0 ? Colors.green : Colors.orange;
  }

  Widget _buildAddForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    hintText: 'Weight',
                    prefixIcon: Icon(Icons.monitor_weight),
                    suffixText: 'kg',
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
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'Notes (optional)',
              prefixIcon: Icon(Icons.note),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTile(WeightEntry entry) {
    final dateFormat = DateFormat('MMM d, y • h:mm a');
    
    return ListTile(
      onLongPress: () => _deleteEntry(entry.id),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.monitor_weight, color: Colors.purple),
      ),
      title: Text('${entry.weight} kg'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateFormat.format(entry.recordedAt)),
          if (entry.notes != null && entry.notes!.isNotEmpty)
            Text(entry.notes!, style: const TextStyle(fontSize: 12)),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.grey),
        onPressed: () => _deleteEntry(entry.id),
      ),
    );
  }
}