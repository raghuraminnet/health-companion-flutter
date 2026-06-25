// Health Companion — Mood tracker (v2 design, v2+ API)
// Patched by Chitti on 2026-06-25 — converted from mock to live API.

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/bp_entry.dart';
import '../../services/api_service.dart';
import 'v2_theme.dart';

class MoodV2 extends StatefulWidget {
  const MoodV2({super.key});
  @override
  State<MoodV2> createState() => _MoodV2State();
}

class _MoodV2State extends State<MoodV2> {
  List<MoodEntry> _entries = [];
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
      final list = await ApiService().getMoodEntries(limit: 200);
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

  Future<void> _add({
    required String mood,
    int? sleepQuality,
    int? energyLevel,
  }) async {
    try {
      await ApiService().addMoodEntry(
        mood: mood,
        sleepQuality: sleepQuality,
        energyLevel: energyLevel,
      );
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
      await ApiService().deleteMoodEntry(id);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  MoodEntry? get _latest => _entries.isEmpty ? null : _entries.first;

  double? get _avgLast7 {
    if (_entries.isEmpty) return null;
    final now = DateTime.now();
    final cutoff = now.subtract(const Duration(days: 7));
    final recent = _entries
        .where((e) => e.recordedAt.toLocal().isAfter(cutoff))
        .where((e) => e.dayRating != null)
        .toList();
    if (recent.isEmpty) return null;
    final sum = recent.map((e) => e.dayRating!).reduce((a, b) => a + b);
    return sum / recent.length;
  }

  List<FlSpot> _spots() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final out = <FlSpot>[];
    for (var i = 6; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dayEntries = _entries.where((e) {
        final r = e.recordedAt.toLocal();
        return r.year == day.year && r.month == day.month && r.day == day.day &&
            e.dayRating != null;
      }).toList()
        ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
      if (dayEntries.isNotEmpty) {
        final last = dayEntries.last;
        out.add(FlSpot((6 - i).toDouble(), last.dayRating!.toDouble()));
      }
    }
    return out;
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: V2Colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _AddSheet(onSave: ({
        required mood,
        sleepQuality,
        energyLevel,
      }) async {
        await ApiService().addMoodEntry(
          mood: mood,
          sleepQuality: sleepQuality,
          energyLevel: energyLevel,
        );
        if (mounted) Navigator.pop(context);
        await _load();
      }),
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
      return _ErrorView(message: _error!, onRetry: _load);
    }
    final latest = _latest;
    final avg = _avgLast7;
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
              if (latest != null) _LatestHero(entry: latest) else const _EmptyHero(),
              const SizedBox(height: 16),
              _StatRow(
                sleep: latest?.sleepQuality,
                energy: latest?.energyLevel,
                avg: avg,
              ),
              const SizedBox(height: 20),
              _SevenDayArea(spots: _spots()),
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

// ─── Shared widgets ──────────────────────────────────────────────────
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

class _LatestHero extends StatelessWidget {
  final MoodEntry entry;
  const _LatestHero({required this.entry});
  @override
  Widget build(BuildContext context) {
    final moodLower = entry.mood.toLowerCase();
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
              color: V2Colors.moodSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(_labelFor(moodLower),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: const Color(0xFFB45309))),
          ),
          const Spacer(),
          Text(_formatTimestamp(entry.recordedAt),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w600,
                color: V2Colors.textMuted)),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          Text(_emojiFor(moodLower), style: const TextStyle(fontSize: 48)),
          const SizedBox(width: 14),
          Expanded(child: Text('Feeling ${entry.mood}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24, fontWeight: FontWeight.w800,
                color: V2Colors.text, height: 1.1))),
        ]),
      ]),
    );
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
        const Icon(Icons.emoji_emotions_outlined, size: 32, color: V2Colors.textMuted),
        const SizedBox(height: 8),
        Text('No moods logged yet',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: V2Colors.textMuted)),
        const SizedBox(height: 2),
        Text('Tap + Log mood to add your first',
            style: GoogleFonts.plusJakartaSans(
                fontSize: 12, color: V2Colors.textMuted)),
      ])),
    );
  }
}

class _StatRow extends StatelessWidget {
  final int? sleep;
  final int? energy;
  final double? avg;
  const _StatRow({required this.sleep, required this.energy, required this.avg});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _StatTile(
        icon: Icons.nightlight_round, label: 'Sleep',
        value: sleep != null ? '${sleep!.toStringAsFixed(1)}/5' : '—',
        color: V2Colors.mood,
      )),
      const SizedBox(width: 10),
      Expanded(child: _StatTile(
        icon: Icons.bolt_rounded, label: 'Energy',
        value: energy != null ? '${energy!.toStringAsFixed(1)}/5' : '—',
        color: V2Colors.mood,
      )),
      const SizedBox(width: 10),
      Expanded(child: _StatTile(
        icon: Icons.bar_chart_rounded, label: '7-day avg',
        value: avg != null ? avg!.toStringAsFixed(1) : '—',
        color: V2Colors.mood,
      )),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatTile({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: V2Colors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 8),
        Text(value, style: GoogleFonts.plusJakartaSans(
            fontSize: 20, fontWeight: FontWeight.w800, color: V2Colors.text)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w700, color: V2Colors.textMuted)),
      ]),
    );
  }
}

class _SevenDayArea extends StatelessWidget {
  final List<FlSpot> spots;
  const _SevenDayArea({required this.spots});
  @override
  Widget build(BuildContext context) {
    final avg = spots.isEmpty
        ? null
        : spots.map((s) => s.y).reduce((a, b) => a + b) / spots.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: V2Colors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('7-day mood', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          if (avg != null) Text('avg ${avg.toStringAsFixed(1)}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: const Color(0xFFB45309))),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: spots.isEmpty
              ? Center(child: Text('No data yet',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, color: V2Colors.textMuted)))
              : LineChart(LineChartData(
                  minX: 0, maxX: 6, minY: 0, maxY: 5,
                  gridData: FlGridData(show: true, drawVerticalLine: false,
                      horizontalInterval: 1,
                      getDrawingHorizontalLine: (v) => FlLine(
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
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: const Color(0xFFB45309),
                      barWidth: 3,
                      dotData: FlDotData(show: true, getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(radius: 4, color: const Color(0xFFB45309), strokeWidth: 0)),
                      belowBarData: BarAreaData(show: true,
                          color: const Color(0xFFB45309).withValues(alpha: 0.12)),
                    ),
                  ],
                )),
        ),
      ]),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final List<MoodEntry> entries;
  final Future<void> Function(String id) onDelete;
  const _HistoryList({required this.entries, required this.onDelete});

  Future<void> _confirmDelete(BuildContext context, MoodEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('${e.mood} · ${_formatTimestamp(e.recordedAt)}'),
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
          Text('No moods yet',
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
        final mood = e.mood.toLowerCase();
        return Column(children: [
          InkWell(
            onLongPress: () => _confirmDelete(context, e),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: V2Colors.moodSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(child: Text(_emojiFor(mood),
                      style: const TextStyle(fontSize: 22))),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(_labelFor(mood),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16, fontWeight: FontWeight.w800,
                            color: V2Colors.text)),
                      if (e.dayRating != null) ...[
                        const SizedBox(width: 8),
                        Text('${e.dayRating}/5',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11, fontWeight: FontWeight.w700,
                              color: V2Colors.textMuted)),
                      ],
                    ]),
                    const SizedBox(height: 2),
                    Text(_formatTimestamp(e.recordedAt) +
                        ((e.sleepQuality != null || e.energyLevel != null)
                            ? ' · sleep ${e.sleepQuality ?? "-"}/5, energy ${e.energyLevel ?? "-"}/5'
                            : ''),
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

class _AddSheet extends StatefulWidget {
  final Future<void> Function({
    required String mood,
    int? sleepQuality,
    int? energyLevel,
  }) onSave;
  const _AddSheet({required this.onSave});
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  String _mood = 'good';
  int _sleep = 4;
  int _energy = 4;
  bool _isSaving = false;

  static const _moods = [
    ('😄', 'energized'), ('😊', 'good'), ('😌', 'calm'),
    ('😣', 'stressed'), ('😟', 'anxious'), ('😢', 'sad'),
  ];

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        mood: _mood,
        sleepQuality: _sleep,
        energyLevel: _energy,
      );
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
          decoration: BoxDecoration(
            color: V2Colors.borderStrong,
            borderRadius: BorderRadius.circular(999)),
        )),
        const SizedBox(height: 18),
        Text('How are you feeling?',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10, runSpacing: 10,
          children: _moods.map((m) {
            final sel = _mood == m.$2;
            return GestureDetector(
              onTap: () => setState(() => _mood = m.$2),
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  color: sel ? V2Colors.moodSoft : V2Colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel ? V2Colors.mood : Colors.transparent,
                    width: 2),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(m.$1, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 2),
                    Text(m.$2,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10, fontWeight: FontWeight.w700,
                          color: sel ? const Color(0xFFB45309) : V2Colors.textMuted)),
                  ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 22),
        _SliderRow(label: 'Sleep quality', value: _sleep,
            min: 1, max: 5,
            onChanged: (v) => setState(() => _sleep = v)),
        _SliderRow(label: 'Energy level', value: _energy,
            min: 1, max: 5,
            onChanged: (v) => setState(() => _energy = v)),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity,
          child: FilledButton(
            onPressed: _isSaving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: V2Colors.mood,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _isSaving
              ? const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save mood',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ]),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const _SliderRow({required this.label, required this.value, required this.min, required this.max, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label, style: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: FontWeight.w700, color: V2Colors.textMuted)),
          const Spacer(),
          Text('$value/$max', style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w800, color: V2Colors.text)),
        ]),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(), max: max.toDouble(),
          divisions: max - min,
          activeColor: V2Colors.mood,
          onChanged: (v) => onChanged(v.round()),
        ),
      ]),
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
        backgroundColor: V2Colors.mood,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        icon: const Icon(Icons.add_rounded),
        label: Text('Log mood',
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

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Colors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.error_outline, size: 48, color: V2Colors.textMuted),
              const SizedBox(height: 12),
              Text('Could not load entries',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(message, style: const TextStyle(color: V2Colors.textMuted, fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────
String _emojiFor(String mood) {
  switch (mood) {
    case 'energized': return '😄';
    case 'good':      return '😊';
    case 'calm':      return '😌';
    case 'stressed':  return '😣';
    case 'anxious':   return '😟';
    case 'sad':       return '😢';
    default:          return '🙂';
  }
}
String _labelFor(String mood) {
  switch (mood) {
    case 'energized': return 'Energized';
    case 'good':      return 'Good';
    case 'calm':      return 'Calm';
    case 'stressed':  return 'Stressed';
    case 'anxious':   return 'Anxious';
    case 'sad':       return 'Sad';
    default:          return mood;
  }
}
String _formatTimestamp(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(dt.year, dt.month, dt.day);
  final hm = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  if (d == today) return 'Today · $hm';
  if (d == today.subtract(const Duration(days: 1))) return 'Yesterday · $hm';
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} · $hm';
}
