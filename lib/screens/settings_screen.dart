import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'v2/preview_v2.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onLogout;
  
  const SettingsScreen({super.key, required this.onLogout});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic> _preferences = {};
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;
  bool _isSaving = false;

  // Tracker toggles
  bool _enableBP = true;
  bool _enableMood = true;
  bool _enableWater = true;
  bool _enableSteps = true;
  bool _enableWeight = true;
  bool _enablePregnancy = false;

  // Settings
  String _theme = 'dark';
  int _waterGoal = 2500;
  int _stepsGoal = 10000;
  String _weightUnit = 'kg';
  String _bpUnit = 'mmHg';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final results = await Future.wait([
        api.getPreferences(),
        api.getSettings(),
      ]);
      
      final prefs = results[0];
      final sett = results[1];
      
      setState(() {
        _preferences = prefs;
        _settings = sett;
        _enableBP = prefs['enable_blood_pressure'] ?? true;
        _enableMood = prefs['enable_mood'] ?? true;
        _enableWater = prefs['enable_water'] ?? true;
        _enableSteps = prefs['enable_steps'] ?? true;
        _enableWeight = prefs['enable_weight'] ?? true;
        _enablePregnancy = prefs['enable_pregnancy'] ?? false;
        _theme = sett['theme'] ?? 'dark';
        _waterGoal = sett['water_goal'] ?? 2500;
        _stepsGoal = sett['steps_goal'] ?? 10000;
        _weightUnit = sett['weight_unit'] ?? 'kg';
        _bpUnit = sett['bp_unit'] ?? 'mmHg';
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      final api = ApiService();
      
      await Future.wait([
        api.updatePreferences({
          'enable_blood_pressure': _enableBP,
          'enable_mood': _enableMood,
          'enable_water': _enableWater,
          'enable_steps': _enableSteps,
          'enable_weight': _enableWeight,
          'enable_pregnancy': _enablePregnancy,
          'theme': _theme,
        }),
        api.updateSettings({
          'water_goal': _waterGoal,
          'steps_goal': _stepsGoal,
          'weight_unit': _weightUnit,
          'bp_unit': _bpUnit,
          'theme': _theme,
        }),
      ]);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveSettings,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Health Trackers', Icons.favorite),
                  _buildSwitchTile(
                    'Blood Pressure',
                    'Track your BP readings',
                    Icons.favorite,
                    _enableBP,
                    (v) => setState(() => _enableBP = v),
                  ),
                  _buildSwitchTile(
                    'Mood',
                    'Log your daily mood',
                    Icons.emoji_emotions,
                    _enableMood,
                    (v) => setState(() => _enableMood = v),
                  ),
                  _buildSwitchTile(
                    'Water Intake',
                    'Track hydration',
                    Icons.water_drop,
                    _enableWater,
                    (v) => setState(() => _enableWater = v),
                  ),
                  _buildSwitchTile(
                    'Steps',
                    'Count your daily steps',
                    Icons.directions_walk,
                    _enableSteps,
                    (v) => setState(() => _enableSteps = v),
                  ),
                  _buildSwitchTile(
                    'Weight',
                    'Monitor your weight',
                    Icons.monitor_weight,
                    _enableWeight,
                    (v) => setState(() => _enableWeight = v),
                  ),
                  _buildSwitchTile(
                    'Pregnancy',
                    'Track pregnancy progress',
                    Icons.pregnant_woman,
                    _enablePregnancy,
                    (v) => setState(() => _enablePregnancy = v),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Goals', Icons.track_changes),
                  _buildSliderTile(
                    'Water Goal',
                    '${_waterGoal}ml',
                    Icons.water_drop,
                    _waterGoal.toDouble(),
                    500,
                    5000,
                    (v) => setState(() => _waterGoal = v.toInt()),
                  ),
                  _buildSliderTile(
                    'Steps Goal',
                    '$_stepsGoal',
                    Icons.directions_walk,
                    _stepsGoal.toDouble(),
                    1000,
                    30000,
                    (v) => setState(() => _stepsGoal = v.toInt()),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Units', Icons.straighten),
                  _buildDropdownTile(
                    'Weight Unit',
                    _weightUnit,
                    ['kg', 'lbs'],
                    (v) => setState(() => _weightUnit = v),
                  ),
                  _buildDropdownTile(
                    'BP Unit',
                    _bpUnit,
                    ['mmHg', 'kPa'],
                    (v) => setState(() => _bpUnit = v),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Account', Icons.person),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red)),
                    onTap: widget.onLogout,
                  ),
                  _buildV2PreviewTile(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Card(
      child: SwitchListTile(
        secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildSliderTile(
    String title,
    String valueLabel,
    IconData icon,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(title),
                const Spacer(),
                Text(
                  valueLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Slider(
              value: value,
              min: min,
              max: max,
              divisions: ((max - min) / 100).toInt(),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownTile(
    String title,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.straighten),
        title: Text(title),
        trailing: DropdownButton(
          value: value,
          items: options.map((o) => DropdownMenuItem(
            value: o,
            child: Text(o),
          )).toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }

  Widget _buildV2PreviewTile() {
    return Card(
      color: const Color(0xFFEDE9FE),
      child: ListTile(
        leading: const Icon(Icons.auto_awesome, color: Color(0xFF6D28D9)),
        title: const Text('Preview v2 redesign',
            style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text(
            'Direction B \u2014 Friendly Wellness (light theme)'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const V2PreviewScreen()),
        ),
      ),
    );
  }
}