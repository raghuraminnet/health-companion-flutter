// Health Companion — Weight tracker (v2 design, v2+ API)
// Patched by Chitti on 2026-06-25 — converted from mock to live API.

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/bp_entry.dart';
import '../../services/api_service.dart';
import 'v2_theme.dart';

class WeightV2 extends StatefulWidget {
  const WeightV2({super.key});
  @override
  State<WeightV2> createState() => _WeightV2State();
}

class _WeightV2State extends State<WeightV2> {
  List<WeightEntry> _entries = [];
  String _unit = 'kg';
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
        api.getWeightEntries(limit: 200),
        api.getSettings(),
      ]);
      if (!mounted) return;
      final s = results[1] as Map<String, dynamic>;
      setState(() {
        _entries = results[0] as List<WeightEntry>;
        _unit = (s['weight_unit'] as String?) ?? 'kg';
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

  Future<void> _delete(String id) async {
    try {
      await ApiService().deleteWeightEntry(id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  WeightEntry? get _latest => _entries.isEmpty ? null : _entries.first;

  double? _deltaFromPrev() {
    if (_entries.length < 2) return null;
    return _entries.first.weight - _entries[1].weight;
  }

  List<FlSpot> _spots() {
    // reverse to chronological (oldest → newest), indexed 0..n-1
    final chronological = [..._entries].reversed.toList();
    return [
      for (var i = 0; i < chronological.length; i++)
        FlSpot(i.toDouble(), chronological[i].weight),
    ];
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: V2Colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _AddSheet(
        defaultUnit: _unit,
        lastWeight: _latest?.weight ?? 70.0,
        onSave: (weight, unit) async {
          await ApiService().addWeightEntry(weight: weight, notes: null);
          if (mounted) Navigator.pop(context);
          await _load();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: V2Colors.bg,
        body: const SafeArea(child: Center(child: CircularProgressIndicator())),
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
    final latest = _latest;
    final delta = _deltaFromPrev();
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
              if (latest != null) _LatestHero(entry: latest, delta: delta, unit: _unit)
              else const _EmptyHero(),
              const SizedBox(height: 20),
              _SevenDayTrend(spots: _spots()),
              const SizedBox(height: 20),
              const _SectionLabel('History'),
              const SizedBox(height: 12),
              _HistoryList(entries: _entries, unit: _unit, onDelete: _delete),
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
  final WeightEntry entry;
  final double? delta;
  final String unit;
  const _LatestHero({required this.entry, required this.delta, required this.unit});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: V2Colors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Latest',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w700, color: V2Colors.textMuted)),
          const Spacer(),
          if (delta != null) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: delta! >= 0 ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(delta! >= 0 ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                  size: 16, color: delta! >= 0 ? const Color(0xFFB91C1C) : const Color(0xFF047857)),
              Text('${delta!.abs().toStringAsFixed(1)} $unit',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: delta! >= 0 ? const Color(0xFFB91C1C) : const Color(0xFF047857))),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(entry.weight.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 64, fontWeight: FontWeight.w800,
                    color: V2Colors.text, height: 1, letterSpacing: -2)),
              const SizedBox(width: 8),
              Text(unit,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18, fontWeight: FontWeight.w700, color: V2Colors.textMuted)),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(_formatTimestampHero(entry.recordedAt),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: FontWeight.w600, color: V2Colors.textMuted)),
      ]),
    );
  }
}

String _formatTimestampHero(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(dt.year, dt.month, dt.day);
  final hm = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  if (d == today) return 'Today · $hm';
  if (d == today.subtract(const Duration(days: 1))) return 'Yesterday · $hm';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} · $hm';
}

class _EmptyHero extends StatelessWidget {
  const _EmptyHero();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: V2Colors.border),
      ),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.monitor_weight_outlined, size: 32, color: V2Colors.textMuted),
        const SizedBox(height: 8),
        Text('No weight entries yet',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w600, color: V2Colors.textMuted)),
        const SizedBox(height: 2),
        Text('Tap + Log weight to add your first',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: V2Colors.textMuted)),
      ])),
    );
  }
}

// ─── 7-day trend ────────────────────────────────────────────────────────
class _SevenDayTrend extends StatelessWidget {
  final List<FlSpot> spots;
  const _SevenDayTrend({required this.spots});
  @override
  Widget build(BuildContext context) {
    final maxY = spots.isEmpty ? 100.0
        : ((spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 2).clamp(50.0, 300.0));
    final minY = spots.isEmpty ? 50.0
        : ((spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 2).clamp(20.0, maxY - 5));
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: V2Colors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Weight trend',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: spots.isEmpty
              ? Center(child: Text('No data yet',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: V2Colors.textMuted)))
              : LineChart(LineChartData(
                  minX: 0, maxX: (spots.length - 1).toDouble(),
                  minY: minY, maxY: maxY,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true, curveSmoothness: 0.3,
                      color: V2Colors.weight,
                      barWidth: 3,
                      dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(radius: 4, color: V2Colors.weight, strokeWidth: 0)),
                      belowBarData: BarAreaData(show: true,
                          color: V2Colors.weight.withValues(alpha: 0.12)),
                    ),
                  ],
                )),
        ),
      ]),
    );
  }
}

// ─── History ────────────────────────────────────────────────────────────
class _HistoryList extends StatelessWidget {
  final List<WeightEntry> entries;
  final String unit;
  final Future<void> Function(String id) onDelete;
  const _HistoryList({required this.entries, required this.unit, required this.onDelete});

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(dt.year, dt.month, dt.day);
    final hm = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (d == today) return 'Today · $hm';
    if (d == today.subtract(const Duration(days: 1))) return 'Yesterday · $hm';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} · $hm';
  }

  Future<void> _confirmDelete(BuildContext context, WeightEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('${e.weight} ${e.notes ?? ''} · ${_formatTimestamp(e.recordedAt)}'),
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
          const Icon(Icons.history_rounded, size: 32, color: V2Colors.textMuted),
          const SizedBox(height: 8),
          Text('No weight yet',
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
                    color: V2Colors.weightSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.monitor_weight_rounded, size: 20, color: V2Colors.weight),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(e.weight.toStringAsFixed(1),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18, fontWeight: FontWeight.w800, color: V2Colors.text)),
                        const SizedBox(width: 4),
                        Text(unit,
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
  final String defaultUnit;
  final double lastWeight;
  final Future<void> Function(double weight, String unit) onSave;
  const _AddSheet({
    required this.defaultUnit,
    required this.lastWeight,
    required this.onSave,
  });
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  late double _weight = widget.lastWeight;
  late String _unit = widget.defaultUnit;
  bool _isSaving = false;

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(_weight, _unit);
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
      child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: V2Colors.borderStrong,
              borderRadius: BorderRadius.circular(999)),
        )),
        const SizedBox(height: 18),
        Text('Log weight', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 22),
        Center(child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic, children: [
            Text(_weight.toStringAsFixed(1),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 64, fontWeight: FontWeight.w800,
                  color: V2Colors.weight, height: 1, letterSpacing: -2)),
            const SizedBox(width: 6),
            Text(_unit, style: GoogleFonts.plusJakartaSans(
                fontSize: 18, fontWeight: FontWeight.w700, color: V2Colors.textMuted)),
          ]),
          const SizedBox(height: 4),
          Text('Tap - or + to adjust by 0.1',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w600, color: V2Colors.textMuted)),
        ])),
        const SizedBox(height: 18),
        Row(children: [
          _StepBtn(icon: Icons.remove, onTap: () {
            setState(() => _weight = (_weight - 0.1).clamp(20.0, 300.0));
          }),
          const SizedBox(width: 12),
          _StepBtn(icon: Icons.add, onTap: () {
            setState(() => _weight = (_weight + 0.1).clamp(20.0, 300.0));
          }),
          const Spacer(),
          Wrap(spacing: 8, children: [
            for (final p in const [70.0, 72.0, 75.0])
              _ChipBtn(label: p.toStringAsFixed(0), onTap: () => setState(() => _weight = p)),
          ]),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          for (final u in const ['kg', 'lbs'])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(u),
                selected: _unit == u,
                onSelected: (_) => setState(() => _unit = u),
                selectedColor: V2Colors.weightSoft,
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700, fontSize: 12,
                  color: _unit == u ? V2Colors.weight : V2Colors.textMuted),
                side: BorderSide.none,
                backgroundColor: V2Colors.surfaceAlt,
              ),
            ),
        ]),
        const SizedBox(height: 18),
        SizedBox(width: double.infinity,
          child: FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: V2Colors.weight,
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
          color: V2Colors.weightSoft, shape: BoxShape.circle,
          border: Border.all(color: V2Colors.weight.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: V2Colors.weight),
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
        backgroundColor: V2Colors.weight,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        icon: const Icon(Icons.add_rounded),
        label: Text('Log weight',
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
