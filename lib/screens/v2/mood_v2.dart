import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'v2_theme.dart';
import 'sample_data.dart';

class MoodV2 extends StatelessWidget {
  const MoodV2({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Colors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: const [
            _TopBar(title: 'Mood'),
            SizedBox(height: 12),
            _LatestHero(),
            SizedBox(height: 20),
            _SevenDayArea(),
            SizedBox(height: 20),
            _SectionLabel('History'),
            SizedBox(height: 12),
            _HistoryList(),
          ],
        ),
      ),
      floatingActionButton: _PillFab(
        label: 'Log mood',
        color: V2Colors.mood,
        onTap: () => _showAddSheet(context),
      ),
    );
  }

  static void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: V2Colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => const _AddSheet(),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  const _TopBar({required this.title});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      const _BackBtn(),
      const SizedBox(width: 12),
      Text(title, style: Theme.of(context).textTheme.headlineMedium),
      const Spacer(),
      const _TuneBtn(),
    ]);
  }
}

class _BackBtn extends StatelessWidget {
  const _BackBtn();
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: V2Colors.surface, shape: BoxShape.circle,
          border: Border.all(color: V2Colors.border),
        ),
        child: const Icon(Icons.arrow_back_rounded, size: 20, color: V2Colors.text),
      ),
    );
  }
}

class _TuneBtn extends StatelessWidget {
  const _TuneBtn();
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: V2Colors.surface, shape: BoxShape.circle,
          border: Border.all(color: V2Colors.border),
        ),
        child: const Icon(Icons.tune_rounded, size: 20, color: V2Colors.text),
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

class _LatestHero extends StatelessWidget {
  const _LatestHero();
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
          Text('Today', style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: V2Colors.moodSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Text('😄', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
              Text('Energized',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: const Color(0xFFB45309))),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Container(
            width: 76, height: 76,
            decoration: BoxDecoration(
              color: V2Colors.moodSoft,
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            child: const Text('😄', style: TextStyle(fontSize: 40)),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Feeling energized',
                  style: GoogleFonts.plusJakartaSans(
                      fontSize: 22, fontWeight: FontWeight.w700,
                      color: V2Colors.text, height: 1.1)),
              const SizedBox(height: 6),
              Text('Morning · after coffee',
                  style: Theme.of(context).textTheme.bodyMedium),
            ]),
          ),
        ]),
        const SizedBox(height: 18),
        const Row(children: [
          Expanded(child: _StatTile(
            label: 'Sleep', value: '4.2', unit: '/ 5',
            icon: Icons.bedtime_rounded, color: Color(0xFF8B5CF6),
          )),
          SizedBox(width: 10),
          Expanded(child: _StatTile(
            label: 'Energy', value: '4.6', unit: '/ 5',
            icon: Icons.bolt_rounded, color: Color(0xFFF59E0B),
          )),
        ]),
      ]),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label, value, unit;
  final IconData icon;
  final Color color;
  const _StatTile({required this.label, required this.value, required this.unit,
    required this.icon, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: V2Colors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label.toUpperCase(),
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 10, fontWeight: FontWeight.w700,
                  color: V2Colors.textMuted, letterSpacing: 0.4)),
        ]),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic, children: [
            Text(value,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 22, fontWeight: FontWeight.w800,
                    color: V2Colors.text, letterSpacing: -0.4)),
            const SizedBox(width: 4),
            Text(unit,
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: V2Colors.textSubtle)),
          ]),
      ]),
    );
  }
}

class _SevenDayArea extends StatelessWidget {
  const _SevenDayArea();
  @override
  Widget build(BuildContext context) {
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: V2Colors.moodSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('avg 4.0',
                style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: const Color(0xFFB45309))),
          ),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 130,
          child: LineChart(
            LineChartData(
              minX: 0, maxX: 6, minY: 0, maxY: 5,
              gridData: FlGridData(
                show: true, drawVerticalLine: false,
                horizontalInterval: 1,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: V2Colors.border, strokeWidth: 1, dashArray: [3, 3]),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 24, interval: 1,
                  getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10, color: V2Colors.textSubtle,
                      fontWeight: FontWeight.w600)),
                )),
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 22,
                  getTitlesWidget: (v, _) {
                    const days = ['M','T','W','T','F','S','S'];
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(days[v.toInt()],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10, color: V2Colors.textSubtle,
                          fontWeight: FontWeight.w700)),
                    );
                  },
                )),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: false),
              lineBarsData: [
                LineChartBarData(
                  spots: V2Sample.moodScores.asMap().entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                  isCurved: true, curveSmoothness: 0.4,
                  color: V2Colors.mood, barWidth: 3,
                  dotData: FlDotData(show: true,
                    getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                      radius: 4, color: Colors.white,
                      strokeColor: V2Colors.mood, strokeWidth: 2.5)),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [V2Colors.mood.withValues(alpha: 0.30),
                        V2Colors.mood.withValues(alpha: 0.0)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList();
  @override
  Widget build(BuildContext context) {
    final rows = [
      _Row('😄', 'Energized', '4.6/5 · sleep 4.2', 'Today · 9:00 AM', true),
      _Row('🙂', 'Calm', '3.8/5 · sleep 4.0', 'Yesterday · 10:30 PM', true),
      _Row('😌', 'Calm', '4.0/5 · sleep 4.5', 'Yesterday · 8:00 AM', true),
      _Row('😣', 'Stressed', '2.8/5 · sleep 2.9', 'Fri · 11:00 PM', false),
      _Row('😄', 'Energized', '4.3/5 · sleep 3.8', 'Fri · 8:00 AM', true),
      _Row('😊', 'Good', '4.1/5 · sleep 4.2', 'Thu · 9:00 PM', true),
    ];
    return Container(
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: V2Colors.border),
      ),
      child: Column(children: List.generate(rows.length, (i) {
        final last = i == rows.length - 1;
        final r = rows[i];
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: r.good ? V2Colors.moodSoft : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(r.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.title,
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(r.sub,
                    style: Theme.of(context).textTheme.bodyMedium),
              ])),
              Text(r.when,
                  style: Theme.of(context).textTheme.labelSmall),
            ]),
          ),
          if (!last) const Divider(
              height: 1, thickness: 1,
              color: V2Colors.border, indent: 66),
        ]);
      })),
    );
  }
}

class _Row {
  final String emoji, title, sub, when;
  final bool good;
  _Row(this.emoji, this.title, this.sub, this.when, this.good);
}

class _AddSheet extends StatefulWidget {
  const _AddSheet();
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  String _mood = 'good';
  double _sleep = 4, _energy = 4;
  static const _moods = [
    ('😄', 'energized'), ('😊', 'good'), ('😌', 'calm'),
    ('😣', 'stressed'), ('😟', 'anxious'), ('😢', 'sad'),
  ];
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
          onChanged: (v) => setState(() => _sleep = v)),
        _SliderRow(label: 'Energy level', value: _energy,
          onChanged: (v) => setState(() => _energy = v)),
        const SizedBox(height: 14),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: V2Colors.mood),
            child: const Text('Save mood'),
          )),
      ]),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  const _SliderRow({required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: V2Colors.text)),
          const Spacer(),
          Text('${value.toStringAsFixed(1)} / 5',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: V2Colors.textMuted)),
        ]),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: V2Colors.mood,
            inactiveTrackColor: V2Colors.moodSoft,
            thumbColor: V2Colors.mood,
            overlayColor: V2Colors.mood.withValues(alpha: 0.15),
            trackHeight: 4,
          ),
          child: Slider(
            value: value, min: 1, max: 5, divisions: 8, onChanged: onChanged),
        ),
      ]),
    );
  }
}