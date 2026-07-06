// Health Companion — Steps tracker (v2 design, v2+ API)
// Patched by Chitti on 2026-06-25 — converted from mock to live API.

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/bp_entry.dart';
import '../../services/api_service.dart';
import 'v2_theme.dart';

class StepsV2 extends StatefulWidget {
  const StepsV2({super.key});
  @override
  State<StepsV2> createState() => _StepsV2State();
}

class _StepsV2State extends State<StepsV2> {
  List<StepsEntry> _entries = [];
  int _goal = 10000;
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
        api.getStepsEntries(limit: 200),
        api.getSettings(),
      ]);
      if (!mounted) return;
      setState(() {
        _entries = results[0] as List<StepsEntry>;
        _goal = (results[1] as Map<String, dynamic>)['steps_goal'] as int? ?? 10000;
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

  Future<void> _add(int steps) async {
    try {
      await ApiService().addStepsEntry(steps: steps);
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
      await ApiService().deleteStepsEntry(id);
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
        .fold<int>(0, (sum, e) => sum + e.steps);
  }

  List<double> get _weekData {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return List<double>.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      return _entries.where((e) {
        final r = e.recordedAt.toLocal();
        return r.year == day.year && r.month == day.month && r.day == day.day;
      }).fold<double>(0.0, (sum, e) => sum + e.steps);
    });
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: V2Colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _AddSheet(onSave: (steps) async {
        await ApiService().addStepsEntry(steps: steps);
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
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }
    if (_error != null && _entries.isEmpty) {
      return Scaffold(
        backgroundColor: V2Colors.bg,
        body: SafeArea(child: Center(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: V2Colors.textMuted),
            const SizedBox(height: 12),
            Text('Could not load entries', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(_error!, style: const TextStyle(color: V2Colors.textMuted, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ]),
        ))),
      );
    }

    final today = _todayTotal;
    final pct = _goal == 0 ? 0.0 : (today / _goal).clamp(0.0, 1.0);
    return Scaffold(
      backgroundColor: V2Colors.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              _TopBar(onBack: () => Navigator.pop(context)),
              const SizedBox(height: 12),
              _LatestHero(today: today, goal: _goal, pct: pct),
              const SizedBox(height: 16),
              _QuickAdd(onAdd: _add),
              const SizedBox(height: 20),
              _SevenDayArea(data: _weekData),
              const SizedBox(height: 20),
              const _SectionLabel('History'),
              const SizedBox(height: 12),
              _HistoryList(entries: _entries, onDelete: _delete),
            ],
          ),
        ),
      ),
      floatingActionButton: _LogFab(onTap: _showAddSheet),
    );
  }
}

// ─── Top bar ───────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final VoidCallback onBack;
  const _TopBar({required this.onBack});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      _CircleIconBtn(icon: Icons.arrow_back_rounded, onTap: onBack),
      const Spacer(),
      _CircleIconBtn(icon: Icons.tune_rounded, onTap: () {}),
    ]);
  }
}

class _CircleIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: V2Colors.surface, shape: BoxShape.circle,
          border: Border.all(color: V2Colors.border),
        ),
        child: Icon(icon, size: 20, color: V2Colors.text),
      ),
    );
  }
}

// ─── Hero ───────────────────────────────────────────────────────────────
class _LatestHero extends StatelessWidget {
  final int today;
  final int goal;
  final double pct;
  const _LatestHero({required this.today, required this.goal, required this.pct});
  @override
  Widget build(BuildContext context) {
    final remaining = (goal - today).clamp(0, goal);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: V2Colors.border),
      ),
      child: Row(children: [
        SizedBox(
          width: 110, height: 110,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: pct,
                strokeWidth: 10,
                backgroundColor: V2Colors.stepsSoft,
                valueColor: const AlwaysStoppedAnimation(V2Colors.steps),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${(pct * 100).round()}%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 26, fontWeight: FontWeight.w800,
                    color: V2Colors.text, height: 1)),
              const Text('of goal',
                  style: TextStyle(fontSize: 11, color: V2Colors.textMuted, fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
        const SizedBox(width: 20),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Today', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text('$today',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 36, fontWeight: FontWeight.w800,
                  color: V2Colors.text, height: 1, letterSpacing: -0.8)),
            const SizedBox(height: 2),
            Text('of $goal steps',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: V2Colors.textMuted)),
            const SizedBox(height: 6),
            Text('$remaining to go',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: V2Colors.steps)),
          ],
        )),
      ]),
    );
  }
}

// ─── Quick add ─────────────────────────────────────────────────────────
class _QuickAdd extends StatelessWidget {
  final Future<void> Function(int steps) onAdd;
  const _QuickAdd({required this.onAdd});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _QuickBtn('1k', V2Colors.steps, () => onAdd(1000))),
      const SizedBox(width: 10),
      Expanded(child: _QuickBtn('2.5k', V2Colors.steps, () => onAdd(2500))),
      const SizedBox(width: 10),
      Expanded(child: _QuickBtn('5k', V2Colors.steps, () => onAdd(5000))),
    ]);
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn(this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: V2Colors.stepsSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Center(child: Text(label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16, fontWeight: FontWeight.w800, color: color))),
      ),
    );
  }
}

// ─── 7-day area chart ──────────────────────────────────────────────────
class _SevenDayArea extends StatelessWidget {
  final List<double> data;
  const _SevenDayArea({required this.data});
  @override
  Widget build(BuildContext context) {
    final maxVal = data.isEmpty ? 1.0 : data.reduce((a, b) => a > b ? a : b);
    final maxY = maxVal == 0 ? 15000.0 : (maxVal * 1.2).clamp(1000.0, 100000.0);
    final avg = data.isEmpty ? 0.0 : data.reduce((a, b) => a + b) / data.length;
    final spots = <FlSpot>[];
    for (var i = 0; i < data.length; i++) {
      if (data[i] > 0) spots.add(FlSpot(i.toDouble(), data[i]));
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: V2Colors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('7-day steps', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          Text('avg ${(avg / 1000).toStringAsFixed(1)}k',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: V2Colors.steps)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: spots.isEmpty
              ? Center(child: Text('No data yet',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: V2Colors.textMuted)))
              : LineChart(LineChartData(
                  minX: 0, maxX: 6, minY: 0, maxY: maxY,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true, reservedSize: 22,
                      getTitlesWidget: (v, _) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        final i = v.toInt();
                        if (i < 0 || i >= days.length) return const SizedBox.shrink();
                        return Padding(padding: const EdgeInsets.only(top: 6),
                          child: Text(days[i],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: V2Colors.textMuted)));
                      },
                    )),
                  ),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true, curveSmoothness: 0.3,
                      color: V2Colors.steps,
                      barWidth: 3,
                      dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(radius: 4, color: V2Colors.steps, strokeWidth: 0)),
                      belowBarData: BarAreaData(show: true,
                          color: V2Colors.steps.withValues(alpha: 0.12)),
                    ),
                  ],
                )),
        ),
      ]),
    );
  }
}

// ─── History list ──────────────────────────────────────────────────────
class _HistoryList extends StatelessWidget {
  final List<StepsEntry> entries;
  final Future<void> Function(String id) onDelete;
  const _HistoryList({required this.entries, required this.onDelete});

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final hm = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (d == today) return 'Today · $hm';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday · $hm';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} · $hm';
  }

  Future<void> _confirmDelete(BuildContext context, StepsEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('${e.steps} steps · ${_formatTimestamp(e.recordedAt)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
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
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.directions_walk_outlined, size: 32, color: V2Colors.textMuted),
          const SizedBox(height: 8),
          Text('No steps yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w600, color: V2Colors.textMuted)),
        ])),
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: V2Colors.border),
      ),
      child: Column(children: List.generate(entries.length, (i) {
        final last = i == entries.length - 1;
        final e = entries[i];
        return Column(children: [
          InkWell(
            onLongPress: () => _confirmDelete(context, e),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: V2Colors.stepsSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_walk_rounded, size: 20, color: V2Colors.steps),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('${e.steps}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18, fontWeight: FontWeight.w800, color: V2Colors.text)),
                        const SizedBox(width: 4),
                        Text('steps',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, fontWeight: FontWeight.w600, color: V2Colors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(_formatTimestamp(e.recordedAt),
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                )),
              ]),
            ),
          ),
          if (!last) const Divider(height: 1, thickness: 1, color: V2Colors.border, indent: 66),
        ]);
      })),
    );
  }
}

// ─── Add sheet ─────────────────────────────────────────────────────────
class _AddSheet extends StatefulWidget {
  final Future<void> Function(int steps) onSave;
  const _AddSheet({required this.onSave});
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  int _amount = 1000;
  bool _isSaving = false;

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(_amount);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e')));
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
      child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: V2Colors.borderStrong,
              borderRadius: BorderRadius.circular(999)),
        )),
        const SizedBox(height: 18),
        Text('Log steps', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 22),
        Center(child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic, children: [
            Text('$_amount',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 64, fontWeight: FontWeight.w800,
                  color: V2Colors.steps, height: 1, letterSpacing: -2)),
            const SizedBox(width: 6),
            Text('steps', style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.w700, color: V2Colors.textMuted)),
          ]),
          const SizedBox(height: 4),
          Text('Tap - or + to adjust by 500',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w600, color: V2Colors.textMuted)),
        ])),
        const SizedBox(height: 18),
        Row(children: [
          _StepBtn(icon: Icons.remove, onTap: () {
            setState(() => _amount = (_amount - 500).clamp(0, 100000));
          }),
          const SizedBox(width: 12),
          _StepBtn(icon: Icons.add, onTap: () {
            setState(() => _amount = (_amount + 500).clamp(0, 100000));
          }),
          const Spacer(),
          Wrap(spacing: 8, children: [
            for (final p in const [1000, 2500, 5000])
              _ChipBtn(label: '${p ~/ 1000}k', onTap: () => setState(() => _amount = p)),
          ]),
        ]),
        const SizedBox(height: 22),
        SizedBox(width: double.infinity,
          child: FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: V2Colors.steps,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isSaving
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Add', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}

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
          color: V2Colors.stepsSoft, shape: BoxShape.circle,
          border: Border.all(color: V2Colors.steps.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: V2Colors.steps),
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

class _LogFab extends StatelessWidget {
  final VoidCallback onTap;
  const _LogFab({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 54,
      child: FloatingActionButton.extended(
        onPressed: onTap,
        backgroundColor: V2Colors.steps,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        icon: const Icon(Icons.add_rounded),
        label: Text('Log steps',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
      ),
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
