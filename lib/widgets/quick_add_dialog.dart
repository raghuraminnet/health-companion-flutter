import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';

class QuickAddDialog extends StatefulWidget {
  final String trackerType;
  
  const QuickAddDialog({super.key, required this.trackerType});

  @override
  State<QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends State<QuickAddDialog> {
  bool _isSubmitting = false;
  
  // BP values
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _pulseController = TextEditingController();
  
  // Mood values
  String _selectedMood = 'Happy';
  int _dayRating = 5;
  int _sleepQuality = 3;
  int _energyLevel = 3;
  
  // Water value
  final _waterController = TextEditingController(text: '250');
  
  // Steps value
  final _stepsController = TextEditingController();
  
  // Weight value
  final _weightController = TextEditingController();

  final List<String> _moods = ['😄 Happy', '😢 Sad', '😰 Anxious', '😴 Tired', '😤 Angry', '😐 Neutral', '🤗 Excited', '😌 Calm'];
  final List<String> _moodValues = ['happy', 'sad', 'anxious', 'tired', 'angry', 'neutral', 'excited', 'calm'];

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    _waterController.dispose();
    _stepsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final api = ApiService();
      
      switch (widget.trackerType) {
        case 'bp':
          if (_systolicController.text.isEmpty || _diastolicController.text.isEmpty) {
            throw Exception('Enter systolic and diastolic');
          }
          await api.addBpEntry(
            systolic: int.parse(_systolicController.text),
            diastolic: int.parse(_diastolicController.text),
            pulse: _pulseController.text.isNotEmpty ? int.parse(_pulseController.text) : null,
          );
          break;
          
        case 'mood':
          await api.addMoodEntry(
            mood: _moodValues[_moods.indexOf(_selectedMood)],
            dayRating: _dayRating,
            sleepQuality: _sleepQuality,
            energyLevel: _energyLevel,
          );
          break;
          
        case 'water':
          if (_waterController.text.isEmpty) throw Exception('Enter amount');
          await api.addWaterEntry(amount: int.parse(_waterController.text));
          break;
          
        case 'steps':
          if (_stepsController.text.isEmpty) throw Exception('Enter steps');
          await api.addStepsEntry(steps: int.parse(_stepsController.text));
          break;
          
        case 'weight':
          if (_weightController.text.isEmpty) throw Exception('Enter weight');
          await api.addWeightEntry(weight: double.parse(_weightController.text));
          break;
      }
      
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getTitle(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildForm(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(12),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (widget.trackerType) {
      case 'bp': return '💉 Add Blood Pressure';
      case 'mood': return '😊 Log Mood';
      case 'water': return '💧 Add Water';
      case 'steps': return '👟 Add Steps';
      case 'weight': return '⚖️ Log Weight';
      default: return 'Add Entry';
    }
  }

  Widget _buildForm() {
    switch (widget.trackerType) {
      case 'bp': return _buildBPForm();
      case 'mood': return _buildMoodForm();
      case 'water': return _buildWaterForm();
      case 'steps': return _buildStepsForm();
      case 'weight': return _buildWeightForm();
      default: return const Text('Unknown tracker');
    }
  }

  Widget _buildBPForm() {
    return Column(
      children: [
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
      ],
    );
  }

  Widget _buildMoodForm() {
    return Column(
      children: [
        const Text('How are you feeling?', style: TextStyle(fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_moods.length, (i) {
            final isSelected = _selectedMood == _moods[i];
            return ChoiceChip(
              label: Text(_moods[i], style: const TextStyle(fontSize: 20)),
              selected: isSelected,
              onSelected: (s) => setState(() => _selectedMood = _moods[i]),
              selectedColor: Colors.amber.shade200,
            );
          }),
        ),
        const SizedBox(height: 20),
        _buildRatingRow('Day Rating', _dayRating, 5, (v) => setState(() => _dayRating = v)),
        const SizedBox(height: 12),
        _buildRatingRow('Sleep Quality', _sleepQuality, 5, (v) => setState(() => _sleepQuality = v)),
        const SizedBox(height: 12),
        _buildRatingRow('Energy Level', _energyLevel, 5, (v) => setState(() => _energyLevel = v)),
      ],
    );
  }

  Widget _buildRatingRow(String label, int value, int max, ValueChanged<int> onChanged) {
    return Row(
      children: [
        SizedBox(width: 100, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: max.toDouble(),
            divisions: max - 1,
            label: value.toString(),
            onChanged: (v) => onChanged(v.toInt()),
          ),
        ),
        SizedBox(width: 30, child: Text(value.toString(), textAlign: TextAlign.center)),
      ],
    );
  }

  Widget _buildWaterForm() {
    return Column(
      children: [
        TextField(
          controller: _waterController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Amount',
            suffixText: 'ml',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.water_drop),
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [100, 200, 250, 500, 750, 1000].map((amt) {
            return ActionChip(
              label: Text('${amt}ml'),
              onPressed: () => setState(() => _waterController.text = amt.toString()),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStepsForm() {
    return Column(
      children: [
        TextField(
          controller: _stepsController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Steps',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.directions_walk),
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [1000, 2500, 5000, 7500, 10000].map((amt) {
            return ActionChip(
              label: Text('$amt'),
              onPressed: () => setState(() => _stepsController.text = amt.toString()),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildWeightForm() {
    return Column(
      children: [
        TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,1}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Weight',
            suffixText: 'kg',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.monitor_weight),
          ),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}