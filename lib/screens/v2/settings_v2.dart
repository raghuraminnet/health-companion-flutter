import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import 'v2_theme.dart';

/// Settings screen on the v2 design system.
///
/// Loads preferences + settings from the API in parallel; lets the user
/// toggle trackers, adjust goals, pick units, change theme, and sign out.
/// Changes are flushed via a single Save action.
class SettingsV2 extends StatefulWidget {
  final VoidCallback onLogout;

  const SettingsV2({super.key, required this.onLogout});

  @override
  State<SettingsV2> createState() => _SettingsV2State();
}

class _SettingsV2State extends State<SettingsV2> {
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

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final results = await Future.wait([
        api.getPreferences(),
        api.getSettings(),
      ]);
      final prefs = results[0];
      final sett = results[1];

      if (!mounted) return;
      setState(() {
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
        _isDirty = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _save() async {
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
      if (!mounted) return;
      setState(() => _isDirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Colors.bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _TopBar(
                    dirty: _isDirty,
                    saving: _isSaving,
                    onSave: _save,
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel('Health trackers'),
                  const SizedBox(height: 12),
                  _TrackersCard(
                    enableBP: _enableBP,
                    enableMood: _enableMood,
                    enableWater: _enableWater,
                    enableSteps: _enableSteps,
                    enableWeight: _enableWeight,
                    enablePregnancy: _enablePregnancy,
                    onChange: (key, v) {
                      setState(() {
                        switch (key) {
                          case 'bp':
                            _enableBP = v;
                            break;
                          case 'mood':
                            _enableMood = v;
                            break;
                          case 'water':
                            _enableWater = v;
                            break;
                          case 'steps':
                            _enableSteps = v;
                            break;
                          case 'weight':
                            _enableWeight = v;
                            break;
                          case 'pregnancy':
                            _enablePregnancy = v;
                            break;
                        }
                      });
                      _markDirty();
                    },
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel('Goals'),
                  const SizedBox(height: 12),
                  _GoalsCard(
                    waterGoal: _waterGoal,
                    stepsGoal: _stepsGoal,
                    onWater: (v) {
                      setState(() => _waterGoal = v);
                      _markDirty();
                    },
                    onSteps: (v) {
                      setState(() => _stepsGoal = v);
                      _markDirty();
                    },
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel('Units'),
                  const SizedBox(height: 12),
                  _UnitsCard(
                    weightUnit: _weightUnit,
                    bpUnit: _bpUnit,
                    onWeight: (v) {
                      setState(() => _weightUnit = v);
                      _markDirty();
                    },
                    onBp: (v) {
                      setState(() => _bpUnit = v);
                      _markDirty();
                    },
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel('Theme'),
                  const SizedBox(height: 12),
                  _ThemeCard(
                    current: _theme,
                    onPick: (v) {
                      setState(() => _theme = v);
                      _markDirty();
                    },
                  ),
                  const SizedBox(height: 20),
                  const _SectionLabel('Account'),
                  const SizedBox(height: 12),
                  _AccountCard(onLogout: widget.onLogout),
                ],
              ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool dirty;
  final bool saving;
  final VoidCallback onSave;
  const _TopBar({
    required this.dirty,
    required this.saving,
    required this.onSave,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Settings', style: Theme.of(context).textTheme.headlineMedium),
        const Spacer(),
        if (saving)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: dirty ? 1 : 0.4,
            child: InkWell(
              onTap: dirty ? onSave : null,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: dirty ? V2Colors.text : V2Colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: dirty ? Colors.white : V2Colors.textMuted,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall),
      );
}

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: V2Colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: V2Colors.border),
        ),
        child: child,
      );
}

class _TrackersCard extends StatelessWidget {
  final bool enableBP, enableMood, enableWater, enableSteps,
      enableWeight, enablePregnancy;
  final void Function(String key, bool value) onChange;
  const _TrackersCard({
    required this.enableBP,
    required this.enableMood,
    required this.enableWater,
    required this.enableSteps,
    required this.enableWeight,
    required this.enablePregnancy,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final entries = [
      ('Blood pressure', 'Track BP readings', Icons.favorite_rounded,
          V2Colors.bp, V2Colors.bpSoft, enableBP, 'bp'),
      ('Mood', 'Log daily mood', Icons.emoji_emotions_rounded,
          V2Colors.mood, V2Colors.moodSoft, enableMood, 'mood'),
      ('Water intake', 'Track hydration', Icons.water_drop_rounded,
          V2Colors.water, V2Colors.waterSoft, enableWater, 'water'),
      ('Steps', 'Count daily steps', Icons.directions_walk_rounded,
          V2Colors.steps, V2Colors.stepsSoft, enableSteps, 'steps'),
      ('Weight', 'Monitor weight', Icons.monitor_weight_rounded,
          V2Colors.weight, V2Colors.weightSoft, enableWeight, 'weight'),
      ('Pregnancy', 'Track pregnancy progress', Icons.pregnant_woman_rounded,
          V2Colors.steps, V2Colors.stepsSoft, enablePregnancy, 'pregnancy'),
    ];

    return _CardShell(
      child: Column(
        children: List.generate(entries.length, (i) {
          final e = entries[i];
          return Column(
            children: [
              _SwitchRow(
                icon: e.$3,
                color: e.$4,
                soft: e.$5,
                title: e.$1,
                subtitle: e.$2,
                value: e.$6,
                onChanged: (v) => onChange(e.$7, v),
              ),
              if (i < entries.length - 1)
                const Divider(
                    height: 1,
                    thickness: 1,
                    color: V2Colors.border,
                    indent: 64),
            ],
          );
        }),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color soft;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchRow({
    required this.icon,
    required this.color,
    required this.soft,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }
}

class _GoalsCard extends StatelessWidget {
  final int waterGoal;
  final int stepsGoal;
  final ValueChanged<int> onWater;
  final ValueChanged<int> onSteps;
  const _GoalsCard({
    required this.waterGoal,
    required this.stepsGoal,
    required this.onWater,
    required this.onSteps,
  });
  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        children: [
          _SliderRow(
            icon: Icons.water_drop_rounded,
            color: V2Colors.water,
            soft: V2Colors.waterSoft,
            title: 'Water goal',
            unit: 'ml',
            value: waterGoal,
            min: 500,
            max: 5000,
            divisions: 45,
            step: 100,
            onChanged: onWater,
          ),
          const Divider(
              height: 1, thickness: 1, color: V2Colors.border, indent: 20),
          _SliderRow(
            icon: Icons.directions_walk_rounded,
            color: V2Colors.steps,
            soft: V2Colors.stepsSoft,
            title: 'Steps goal',
            unit: 'steps',
            value: stepsGoal,
            min: 1000,
            max: 30000,
            divisions: 29,
            step: 1000,
            onChanged: onSteps,
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color soft;
  final String title;
  final String unit;
  final int value;
  final double min;
  final double max;
  final int divisions;
  final int step;
  final ValueChanged<int> onChanged;
  const _SliderRow({
    required this.icon,
    required this.color,
    required this.soft,
    required this.title,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.step,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final display = (value ~/ step) * step;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Text(
                '$display $unit',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: color,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              overlayColor: color.withValues(alpha: 0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: value.toDouble().clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitsCard extends StatelessWidget {
  final String weightUnit;
  final String bpUnit;
  final ValueChanged<String> onWeight;
  final ValueChanged<String> onBp;
  const _UnitsCard({
    required this.weightUnit,
    required this.bpUnit,
    required this.onWeight,
    required this.onBp,
  });
  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        children: [
          _ChoiceRow(
            icon: Icons.monitor_weight_rounded,
            color: V2Colors.weight,
            soft: V2Colors.weightSoft,
            title: 'Weight unit',
            value: weightUnit,
            options: const ['kg', 'lbs'],
            onChanged: onWeight,
          ),
          const Divider(
              height: 1, thickness: 1, color: V2Colors.border, indent: 64),
          _ChoiceRow(
            icon: Icons.favorite_rounded,
            color: V2Colors.bp,
            soft: V2Colors.bpSoft,
            title: 'BP unit',
            value: bpUnit,
            options: const ['mmHg', 'kPa'],
            onChanged: onBp,
          ),
        ],
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color soft;
  final String title;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;
  const _ChoiceRow({
    required this.icon,
    required this.color,
    required this.soft,
    required this.title,
    required this.value,
    required this.options,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          Wrap(
            spacing: 6,
            children: options.map((o) {
              final selected = o == value;
              return InkWell(
                onTap: () => onChanged(o),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? color : V2Colors.surfaceAlt,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    o,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : V2Colors.textMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String current;
  final ValueChanged<String> onPick;
  const _ThemeCard({required this.current, required this.onPick});

  static const _themes = [
    ('dark', '🌙', 'Dark'),
    ('light', '☀️', 'Light'),
    ('pink', '🌸', 'Pink'),
    ('white', '✨', 'White'),
  ];

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _themes.map((t) {
            final selected = t.$1 == current;
            return InkWell(
              onTap: () => onPick(t.$1),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 68,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? V2Colors.brandSoft : V2Colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? V2Colors.brand : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Text(t.$2, style: const TextStyle(fontSize: 22)),
                    const SizedBox(height: 4),
                    Text(
                      t.$3,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color:
                            selected ? V2Colors.brand : V2Colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final VoidCallback onLogout;
  const _AccountCard({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: InkWell(
        onTap: onLogout,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 20,
                  color: Color(0xFFB91C1C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Logout',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: const Color(0xFFB91C1C),
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: Color(0xFFB91C1C)),
            ],
          ),
        ),
      ),
    );
  }
}