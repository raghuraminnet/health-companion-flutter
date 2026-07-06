// Health Companion — Water tracker (v2 design, v2+ API)
// Patched by Chitti on 2026-06-25:
//   - converted from StatelessWidget (mock data) to StatefulWidget (live API)
//   - loads entries via ApiService.getWaterEntries, goal via ApiService.getSettings
//   - quick-add buttons (250 ml / 500 ml / 1 glass) call ApiService.addWaterEntry
//   - "add" button on the log sheet calls ApiService.addWaterEntry, pops sheet, refreshes
//   - long-press on a history entry deletes it via ApiService.deleteWaterEntry
//   - _LatestHero + _SevenDayBars + _HistoryList now receive real data
//   - _BackBtn wired to Navigator.pop (was a no-op)

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/bp_entry.dart';
import '../../services/api_service.dart';
import 'v2_theme.dart';

class WaterV2 extends StatefulWidget {
  const WaterV2({super.key});

  @override
  State<WaterV2> createState() => _WaterV2State();
}

class _WaterV2State extends State<WaterV2> {
  List<WaterEntry> _entries = [];
  int _goal = 2500;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final api = ApiService();
      final results = await Future.wait([
        api.getWaterEntries(limit: 200),
        api.getSettings(),
      ]);
      if (!mounted) return;
      setState(() {
        _entries = results[0] as List<WaterEntry>;
        final s = results[1] as Map<String, dynamic>;
        _goal = (s['water_goal'] as num?)?.toInt() ?? 2500;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _add(int amount, String unit) async {
    try {
      await ApiService().addWaterEntry(amount: amount, unit: unit);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Add failed: $e')),
        );
      }
    }
  }

  Future<void> _delete(String id) async {
    try {
      await ApiService().deleteWaterEntry(id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  int get _todayTotal {
    final now = DateTime.now();
    return _entries
        .where((e) =>
            e.recordedAt.year == now.year &&
            e.recordedAt.month == now.month &&
            e.recordedAt.day == now.day)
        .fold<int>(0, (sum, e) => sum + e.amount);
  }

  List<double> get _weekData {
    // 7 days, oldest first, today last
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List<double>.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return _entries
          .where((e) =>
              e.recordedAt.year == day.year &&
              e.recordedAt.month == day.month &&
              e.recordedAt.day == day.day)
          .fold<double>(0.0, (sum, e) => sum + e.amount);
    });
  }

  void _showSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: V2Colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _AddSheet(onSave: (amount, unit) async {
        await ApiService().addWaterEntry(amount: amount, unit: unit);
        if (mounted) Navigator.pop(context);
        await _load();
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: V2Colors.bg,
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null && _entries.isEmpty) {
      return Scaffold(
        backgroundColor: V2Colors.bg,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: V2Colors.textMuted),
                  const SizedBox(height: 12),
                  Text('Could not load entries',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(_error!,
                      style: const TextStyle(color: V2Colors.textMuted, fontSize: 12),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  FilledButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final today = _todayTotal.toDouble();
    final goal = _goal.toDouble();
    final pct = goal == 0 ? 0.0 : (today / goal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: V2Colors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              _TopBar(title: 'Water', onBack: () => Navigator.pop(context)),
              const SizedBox(height: 20),
              _LatestHero(today: today, goal: goal, pct: pct),
              const SizedBox(height: 16),
              _QuickAdd(onAdd: _add),
              const SizedBox(height: 20),
              _SevenDayBars(data: _weekData),
              const SizedBox(height: 20),
              const _SectionLabel('History'),
              const SizedBox(height: 12),
              _HistoryList(entries: _entries, onDelete: _delete),
            ],
          ),
        ),
      ),
      floatingActionButton: _PillFab(
        label: 'Log water',
        color: V2Colors.water,
        onTap: _showSheet,
      ),
    );
  }
}

// ─── Top bar with back button ──────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  const _TopBar({required this.title, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
      ],
    );
  }
}

// ─── Hero card: today's progress ring + total ──────────────────────────
class _LatestHero extends StatelessWidget {
  final double today;
  final double goal;
  final double pct;
  const _LatestHero({required this.today, required this.goal, required this.pct});

  @override
  Widget build(BuildContext context) {
    final remaining = (goal - today).clamp(0, goal).toDouble();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: V2Colors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 110, height: 110,
            child: Stack(alignment: Alignment.center, children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: pct,
                  strokeWidth: 10,
                  backgroundColor: V2Colors.waterSoft,
                  valueColor: const AlwaysStoppedAnimation(V2Colors.water),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${(pct * 100).round()}%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      color: V2Colors.text, height: 1)),
                const Text('of goal',
                    style: TextStyle(
                      fontSize: 11, color: V2Colors.textMuted,
                      fontWeight: FontWeight.w600)),
              ]),
            ]),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 4),
                Text('${today.toStringAsFixed(0)} ml',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      color: V2Colors.text, height: 1, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text('${remaining.toStringAsFixed(0)} ml to go',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: V2Colors.water)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quick-add row (250 / 500 / 1 glass) ────────────────────────────────
class _QuickAdd extends StatelessWidget {
  final Future<void> Function(int amount, String unit) onAdd;
  const _QuickAdd({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _QuickBtn('250 ml', Icons.local_drink_rounded, V2Colors.water,
            () => onAdd(250, 'ml'))),
        const SizedBox(width: 10),
        Expanded(child: _QuickBtn('500 ml', Icons.local_drink_rounded, V2Colors.water,
            () => onAdd(500, 'ml'))),
        const SizedBox(width: 10),
        Expanded(child: _QuickBtn('1 glass', Icons.water_drop_rounded, V2Colors.water,
            () => onAdd(250, 'ml'))),
      ],
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn(this.label, this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: V2Colors.waterSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

// ─── 7-day bar chart ───────────────────────────────────────────────────
class _SevenDayBars extends StatelessWidget {
  final List<double> data;
  const _SevenDayBars({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxVal = data.isEmpty ? 1.0 : data.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal == 0 ? 3.0 : (maxVal * 1.2 / 1000).clamp(0.5, 10.0);
    final avg = data.isEmpty
        ? 0.0
        : data.reduce((a, b) => a + b) / data.length / 1000;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: V2Colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('7-day intake', style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            Text('avg ${avg.toStringAsFixed(1)} L',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: V2Colors.water)),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final i = value.toInt();
                        if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(labels[i],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: V2Colors.textMuted)),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(enabled: false),
                barGroups: List.generate(data.length, (i) =>
                    BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: data[i] / 1000,
                        color: V2Colors.water,
                        width: 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6), bottom: Radius.circular(2)),
                      ),
                    ])),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── History list ──────────────────────────────────────────────────────
class _HistoryList extends StatelessWidget {
  final List<WaterEntry> entries;
  final Future<void> Function(String id) onDelete;
  const _HistoryList({required this.entries, required this.onDelete});

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final hm =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (d == today) return 'Today · $hm';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday · $hm';
    return '${dt.year}-${dt.month.toString().padLeft(2, "0")}-${dt.day.toString().padLeft(2, "0")} · $hm';
  }

  Future<void> _confirmAndDelete(BuildContext context, WaterEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('${e.amount} ${e.unit} · ${_formatTime(e.recordedAt)}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await onDelete(e.id);
  }

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: V2Colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: V2Colors.border),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.water_drop_outlined, size: 32, color: V2Colors.textMuted),
              const SizedBox(height: 8),
              Text('No entries yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: V2Colors.textMuted)),
              const SizedBox(height: 2),
              Text('Use the quick-add or + Log water button to start',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, color: V2Colors.textMuted)),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: V2Colors.border),
      ),
      child: Column(
        children: List.generate(entries.length, (i) {
          final last = i == entries.length - 1;
          final e = entries[i];
          return Column(children: [
            InkWell(
              onLongPress: () => _confirmAndDelete(context, e),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: V2Colors.waterSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.water_drop_rounded,
                        size: 20, color: V2Colors.water),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text('${e.amount}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 18, fontWeight: FontWeight.w800,
                                  color: V2Colors.text)),
                            const SizedBox(width: 3),
                            Text(e.unit,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12, fontWeight: FontWeight.w600,
                                  color: V2Colors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(_formatTime(e.recordedAt),
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            if (!last) const Divider(
                height: 1, thickness: 1, color: V2Colors.border, indent: 66),
          ]);
        }),
      ),
    );
  }
}

// ─── "Log water" modal sheet ───────────────────────────────────────────
class _AddSheet extends StatefulWidget {
  final Future<void> Function(int amount, String unit) onSave;
  const _AddSheet({required this.onSave});

  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  int _amount = 250;
  String _unit = 'ml';
  bool _isSaving = false;

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(_amount, _unit);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 14,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: V2Colors.borderStrong,
              borderRadius: BorderRadius.circular(999)),
          )),
          const SizedBox(height: 18),
          Text('Log water',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 22),
          Center(child: Column(children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text('$_amount',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 64, fontWeight: FontWeight.w800,
                      color: V2Colors.water, height: 1, letterSpacing: -2)),
                const SizedBox(width: 6),
                Text(_unit,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: V2Colors.textMuted)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Tap - or + to adjust',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w600,
                  color: V2Colors.textMuted)),
          ])),
          const SizedBox(height: 18),
          Row(children: [
            _StepBtn(icon: Icons.remove, onTap: () {
              setState(() => _amount = (_amount - 50).clamp(50, 5000));
            }),
            const SizedBox(width: 12),
            _StepBtn(icon: Icons.add, onTap: () {
              setState(() => _amount = (_amount + 50).clamp(50, 5000));
            }),
            const Spacer(),
            Wrap(spacing: 8, children: [
              for (final p in const [250, 500, 750])
                _ChipBtn(label: '$p ml', onTap: () {
                  setState(() => _amount = p);
                }),
            ]),
          ]),
          const SizedBox(height: 18),
          Row(children: [
            for (final u in const ['ml', 'oz', 'cup'])
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(u),
                  selected: _unit == u,
                  onSelected: (_) => setState(() => _unit = u),
                  selectedColor: V2Colors.waterSoft,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700, fontSize: 12,
                    color: _unit == u ? V2Colors.water : V2Colors.textMuted),
                  side: BorderSide.none,
                  backgroundColor: V2Colors.surfaceAlt,
                ),
              ),
          ]),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: V2Colors.water,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Add',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────
class _StepBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: V2Colors.waterSoft, shape: BoxShape.circle,
          border: Border.all(color: V2Colors.water.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: V2Colors.water),
      ),
    );
  }
}

class _ChipBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _ChipBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: V2Colors.surfaceAlt,
      side: BorderSide.none,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700, fontSize: 12, color: V2Colors.text),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String t;
  const _SectionLabel(this.t);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(t.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
  );
}

class _PillFab extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PillFab({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 54,
      child: FloatingActionButton.extended(
        onPressed: onTap,
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        icon: const Icon(Icons.add_rounded),
        label: Text(label,
            style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 14)),
      ),
    );
  }
}
