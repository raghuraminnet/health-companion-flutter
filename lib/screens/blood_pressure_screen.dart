import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import '../models/bp_entry.dart';

class BloodPressureScreen extends StatefulWidget {
  const BloodPressureScreen({super.key});

  @override
  State<BloodPressureScreen> createState() => _BloodPressureScreenState();
}

class _BloodPressureScreenState extends State<BloodPressureScreen> {
  List<BpEntry> _entries = [];
  bool _isLoading = true;
  bool _isAdding = false;
  
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _pulseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final entries = await api.getBpEntries();
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load: $e')),
        );
      }
    }
  }

  Future<void> _addEntry() async {
    if (_systolicController.text.isEmpty || _diastolicController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter systolic and diastolic values')),
      );
      return;
    }

    setState(() => _isAdding = true);
    try {
      final api = ApiService();
      await api.addBpEntry(
        systolic: int.parse(_systolicController.text),
        diastolic: int.parse(_diastolicController.text),
        pulse: _pulseController.text.isNotEmpty ? int.parse(_pulseController.text) : null,
      );
      
      _systolicController.clear();
      _diastolicController.clear();
      _pulseController.clear();
      
      await _loadEntries();
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _isAdding = false);
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
      await api.deleteBpEntry(id);
      await _loadEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry deleted'), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '💉 Add Blood Pressure',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _systolicController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Systolic',
                      suffixText: 'mmHg',
                      border: OutlineInputBorder(),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('/', style: TextStyle(fontSize: 32)),
                ),
                Expanded(
                  child: TextField(
                    controller: _diastolicController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Diastolic',
                      suffixText: 'mmHg',
                      border: OutlineInputBorder(),
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pulseController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Pulse (optional)',
                suffixText: 'BPM',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.favorite),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isAdding ? null : _addEntry,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: _isAdding
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Entry'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Color _getBpColor(BpEntry entry) {
    switch (entry.status) {
      case 'normal': return Colors.green;
      case 'elevated': return Colors.lightGreen;
      case 'stage1': return Colors.orange;
      case 'stage2': return Colors.deepOrange;
      case 'crisis': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blood Pressure'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEntries,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? _buildEmptyState()
              : _buildEntryList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No BP entries yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first entry',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryList() {
    return RefreshIndicator(
      onRefresh: _loadEntries,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          final color = _getBpColor(entry);
          
          return Dismissible(
            key: Key(entry.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Entry'),
                  content: const Text('Are you sure you want to delete this entry?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (_) => _deleteEntry(entry.id),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${entry.systolic}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          Text(
                            '${entry.diastolic}',
                            style: TextStyle(
                              fontSize: 14,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.statusLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: color,
 ),
                          ),
                          const SizedBox(height: 4),
                          if (entry.pulse != null)
                            Text(
                              'Pulse: ${entry.pulse} BPM',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                          Text(
                            _formatDate(entry.recordedAt),
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (entry.medicationTaken)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('💊', style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}