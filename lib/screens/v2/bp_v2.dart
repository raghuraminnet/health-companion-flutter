// Health Companion — Blood Pressure tracker (v2 design, v2+ API)
// Patched by Chitti on 2026-06-25:
//   - converted from StatelessWidget (mock) to StatefulWidget (live API)
//   - loads via ApiService.getBpEntries
//   - "Log reading" sheet Save → ApiService.addBpEntry
//   - long-press history row → confirm → ApiService.deleteBpEntry
//   - _LatestHero shows most recent reading + status pill (uses BpEntry.statusLabel)
//   - _SevenDayTrend renders last 7 days of sys/dia
//   - _BackBtn / _TuneBtn wired (back navigates, tune is a no-op for now)

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/bp_entry.dart';
import '../../services/api_service.dart';
import 'v2_theme.dart';

class BpV2 extends StatefulWidget {
  const BpV2({super.key});
  @override
  State<BpV2> createState() => _BpV2State();
}

class _BpV2State extends State<BpV2> {
  List<BpEntry> _entries = [];
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
      final list = await ApiService().getBpEntries(limit: 200);
      if (!mounted) return;
      setState(() {
        _entries = list;
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
      await ApiService().deleteBpEntry(id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  BpEntry? get _latest => _entries.isEmpty ? null : _entries.first;

  List<FlSpot> _spots(bool systolic) {
    // returns 7 points (oldest → newest), based on entries in last 7 days
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final points = <FlSpot>[];
    for (var i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dayEntries = _entries.where((e) {
        final r = e.recordedAt.toLocal();
        return r.year == day.year && r.month == day.month && r.day == day.day;
      }).toList()
        ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
      if (dayEntries.isNotEmpty) {
        // average for the day
        final sum = dayEntries
            .map((e) => systolic ? e.systolic : e.diastolic)
            .reduce((a, b) => a + b);
        points.add(FlSpot((6 - i).toDouble(), sum / dayEntries.length));
      }
    }
    return points;
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
        onSave: ({
          required systolic,
          required diastolic,
          pulse,
          session = 'morning',
          entryContext,
          medicationTaken = false,
        }) async {
          await ApiService().addBpEntry(
            systolic: systolic,
            diastolic: diastolic,
            pulse: pulse,
            session: session,
            context: entryContext,
            medicationTaken: medicationTaken,
          );
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
        body: const SafeArea(
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
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, size: 48, color: V2Colors.textMuted),
                const SizedBox(height: 12),
                Text('Could not load entries', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(_error!, style: const TextStyle(color: V2Colors.textMuted, fontSize: 12), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(onPressed: _load, child: const Text('Retry')),
              ]),
            ),
          ),
        ),
      );
    }

    final latest = _latest;
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
              if (latest != null) _LatestHero(entry: latest)
              else   const _EmptyHero(),
              const SizedBox(height: 20),
              _SevenDayTrend(
                sysSpots: _spots(true),
                diaSpots: _spots(false),
              ),
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
      const _CircleIconBtn(icon: Icons.tune_rounded, onTap: _noop),
    ]);
  }
}

void _noop() {}

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

// ─── Hero: latest reading + status ────────────────────────────────────
class _LatestHero extends StatelessWidget {
  final BpEntry entry;
  const _LatestHero({required this.entry});
  @override
  Widget build(BuildContext context) {
    final status = entry.status;
    final statusColor = _statusColor(status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: V2Colors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(entry.statusLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: statusColor)),
          ),
          const Spacer(),
          Text(_formatTimestamp(entry.recordedAt),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: V2Colors.textMuted)),
        ]),
        const SizedBox(height: 16),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('${entry.systolic}',
                  style: const TextStyle(
                    fontSize: 64, fontWeight: FontWeight.w800,
                    color: V2Colors.text, height: 1, letterSpacing: -2)),
              Text(' / ', style: TextStyle(
                  fontSize: 36, fontWeight: FontWeight.w700,
                  color: V2Colors.textMuted)),
              Text('${entry.diastolic}',
                  style: const TextStyle(
                    fontSize: 64, fontWeight: FontWeight.w800,
                    color: V2Colors.text, height: 1, letterSpacing: -2)),
              const SizedBox(width: 8),
              Text('mmHg', style: GoogleFonts.plusJakartaSans(
                  fontSize: 16, fontWeight: FontWeight.w600,
                  color: V2Colors.textMuted)),
            ],
          ),
        ),
        if (entry.pulse != null) ...[
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.favorite_rounded, size: 14, color: V2Colors.bp),
            const SizedBox(width: 4),
            Text('Pulse ${entry.pulse} bpm',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: V2Colors.bp)),
          ]),
        ],
      ]),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'normal':   return const Color(0xFF047857);
      case 'elevated': return const Color(0xFFB45309);
      case 'stage1':   return const Color(0xFFB45309);
      case 'stage2':   return const Color(0xFFB91C1C);
      case 'crisis':   return const Color(0xFFB91C1C);
      default:         return V2Colors.textMuted;
    }
  }
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
        const Icon(Icons.favorite_outline, size: 32, color: V2Colors.textMuted),
        const SizedBox(height: 8),
        Text('No readings yet',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: V2Colors.textMuted)),
        const SizedBox(height: 2),
        Text('Tap + Log reading to add your first',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12, color: V2Colors.textMuted)),
      ])),
    );
  }
}

// ─── 7-day trend chart ─────────────────────────────────────────────────
class _SevenDayTrend extends StatelessWidget {
  final List<FlSpot> sysSpots;
  final List<FlSpot> diaSpots;
  const _SevenDayTrend({required this.sysSpots, required this.diaSpots});

  @override
  Widget build(BuildContext context) {
    final all = [...sysSpots, ...diaSpots];
    final maxY = all.isEmpty ? 140.0
        : (all.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 10).clamp(80.0, 200.0);
    final minY = all.isEmpty ? 60.0
        : (all.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 10).clamp(40.0, maxY - 20);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: V2Colors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('7-day trend', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          _LegendDot(color: V2Colors.bp, label: 'Sys'),
          const SizedBox(width: 12),
          _LegendDot(color: V2Colors.bp.withValues(alpha: 0.45), label: 'Dia'),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 160,
          child: all.isEmpty
              ? Center(child: Text('No data yet',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: V2Colors.textMuted)))
              : LineChart(LineChartData(
                  minX: 0, maxX: 6,
                  minY: minY, maxY: maxY,
                  gridData: FlGridData(show: true, drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                          color: V2Colors.border, strokeWidth: 1, dashArray: [3, 3])),
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
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(days[i],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10, fontWeight: FontWeight.w700,
                                color: V2Colors.textMuted)),
                        );
                      },
                    )),
                  ),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: [
                    _lineBar(sysSpots, V2Colors.bp),
                    _lineBar(diaSpots, V2Colors.bp.withValues(alpha: 0.45)),
                  ],
                )),
        ),
      ]),
    );
  }

  LineChartBarData _lineBar(List<FlSpot> spots, Color color) {
    if (spots.isEmpty) {
      return LineChartBarData(spots: const [], color: color);
    }
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: 2.5,
      dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) =>
          FlDotCirclePainter(radius: 3, color: color, strokeWidth: 0)),
      belowBarData: BarAreaData(show: true,
          color: color.withValues(alpha: 0.08)),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    const SizedBox(width: 4),
    Text(label, style: GoogleFonts.plusJakartaSans(
        fontSize: 11, fontWeight: FontWeight.w700, color: V2Colors.textMuted)),
  ]);
}

// ─── History list ──────────────────────────────────────────────────────
class _HistoryList extends StatelessWidget {
  final List<BpEntry> entries;
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

  Future<void> _confirmDelete(BuildContext context, BpEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete reading?'),
        content: Text('${e.systolic}/${e.diastolic} mmHg · ${_formatTimestamp(e.recordedAt)}'),
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
          Text('No readings yet',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: V2Colors.textMuted)),
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
                    color: V2Colors.bpSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.favorite_rounded, size: 20, color: V2Colors.bp),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('${e.systolic}/${e.diastolic}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18, fontWeight: FontWeight.w800,
                              color: V2Colors.text)),
                        const SizedBox(width: 4),
                        Text('mmHg',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12, fontWeight: FontWeight.w600,
                              color: V2Colors.textMuted)),
                        const Spacer(),
                        Text(e.statusLabel,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: _statusColor(e.status))),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(_formatTimestamp(e.recordedAt) +
                        (e.pulse != null ? ' · Pulse ${e.pulse}' : ''),
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

  Color _statusColor(String status) {
    switch (status) {
      case 'normal':   return const Color(0xFF047857);
      case 'elevated': return const Color(0xFFB45309);
      case 'stage1':   return const Color(0xFFB45309);
      case 'stage2':   return const Color(0xFFB91C1C);
      case 'crisis':   return const Color(0xFFB91C1C);
      default:         return V2Colors.textMuted;
    }
  }
}

// ─── Add sheet ─────────────────────────────────────────────────────────
typedef _BpSaveCallback = Future<void> Function({
  required int systolic,
  required int diastolic,
  int? pulse,
  required String session,
  List<String>? entryContext,
  required bool medicationTaken,
});

class _AddSheet extends StatefulWidget {
  final _BpSaveCallback onSave;
  const _AddSheet({required this.onSave});
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _sysCtrl = TextEditingController();
  final _diaCtrl = TextEditingController();
  final _pulseCtrl = TextEditingController();
  String _session = 'morning';
  bool _medTaken = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _sysCtrl.dispose();
    _diaCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final sys = int.tryParse(_sysCtrl.text.trim());
    final dia = int.tryParse(_diaCtrl.text.trim());
    if (sys == null || dia == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter systolic and diastolic')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        systolic: sys,
        diastolic: dia,
        pulse: int.tryParse(_pulseCtrl.text.trim()),
        session: _session,
        entryContext: null,
        medicationTaken: _medTaken,
      );
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
          decoration: BoxDecoration(
            color: V2Colors.borderStrong,
            borderRadius: BorderRadius.circular(999)),
        )),
        const SizedBox(height: 18),
        Text('Log reading', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: _NumField(
            label: 'Sys', unit: 'mmHg',
            controller: _sysCtrl,
            hint: '120',
          )),
          const SizedBox(width: 12),
          Expanded(child: _NumField(
            label: 'Dia', unit: 'mmHg',
            controller: _diaCtrl,
            hint: '80',
          )),
        ]),
        const SizedBox(height: 12),
        _NumField(
          label: 'Pulse', unit: 'bpm',
          controller: _pulseCtrl,
          hint: '72',
        ),
        const SizedBox(height: 18),
        Text('Session',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: FontWeight.w700, color: V2Colors.textMuted)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, children: [
          for (final s in const ['morning', 'afternoon', 'evening', 'night'])
            ChoiceChip(
              label: Text(s),
              selected: _session == s,
              onSelected: (_) => setState(() => _session = s),
              selectedColor: V2Colors.bpSoft,
              labelStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700, fontSize: 12,
                color: _session == s ? V2Colors.bp : V2Colors.textMuted),
              side: BorderSide.none,
              backgroundColor: V2Colors.surfaceAlt,
            ),
        ]),
        const SizedBox(height: 16),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _medTaken,
          onChanged: (v) => setState(() => _medTaken = v),
          title: Text('Medication taken',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w600, color: V2Colors.text)),
          activeColor: V2Colors.bp,
        ),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity,
          child: FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: V2Colors.bp,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isSaving
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save', style: TextStyle(
                  fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}

class _NumField extends StatelessWidget {
  final String label;
  final String unit;
  final String hint;
  final TextEditingController controller;
  const _NumField({required this.label, required this.unit, required this.hint, required this.controller});
  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12, fontWeight: FontWeight.w700, color: V2Colors.textMuted)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: hint,
          suffixText: unit,
          filled: true,
          fillColor: V2Colors.surfaceAlt,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 18, fontWeight: FontWeight.w700, color: V2Colors.text),
      ),
    ]);
  }
}

// ─── FAB ───────────────────────────────────────────────────────────────
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
        backgroundColor: V2Colors.bp,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        icon: const Icon(Icons.add_rounded),
        label: Text('Log reading',
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

// Local formatTimestamp shim
String _formatTimestamp(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(dt.year, dt.month, dt.day);
  final hm = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  if (d == today) return 'Today · $hm';
  if (d == today.subtract(const Duration(days: 1))) return 'Yesterday · $hm';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} · $hm';
}
