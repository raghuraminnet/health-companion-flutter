import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'v2_theme.dart';
import 'sample_data.dart';

class StepsV2 extends StatelessWidget {
  const StepsV2({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Colors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: const [
            _TopBar(title: 'Steps'),
            SizedBox(height: 12),
            _LatestHero(),
            SizedBox(height: 16),
            _QuickAdd(),
            SizedBox(height: 20),
            _7DayArea(),
            SizedBox(height: 20),
            _SectionLabel('History'),
            SizedBox(height: 12),
            _HistoryList(),
          ],
        ),
      ),
      floatingActionButton: _PillFab(
        label: 'Log steps',
        color: V2Colors.steps,
        onTap: () => _showSheet(context),
      ),
    );
  }

  static void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: V2Colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
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
    const today = 7560.0;
    const goal = 10000.0;
    final pct = today / goal;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
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
                  style: TextStyle(
                    fontSize: 11, color: V2Colors.textMuted,
                    fontWeight: FontWeight.w600)),
            ]),
          ]),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Today',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  const Text('7,560',
                      style: TextStyle(
                        fontSize: 44, fontWeight: FontWeight.w800,
                        color: V2Colors.text, height: 1, letterSpacing: -1.2)),
                  const SizedBox(width: 4),
                  Text('of 10,000',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: V2Colors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.directions_walk_rounded,
                size: 14, color: V2Colors.steps),
              const SizedBox(width: 4),
              Text('2,440 to go',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: V2Colors.steps)),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _QuickAdd extends StatelessWidget {
  const _QuickAdd();
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _QuickBtn('1,000', Icons.directions_walk_rounded)),
      const SizedBox(width: 10),
      Expanded(child: _QuickBtn('2,500', Icons.directions_walk_rounded)),
      const SizedBox(width: 10),
      Expanded(child: _QuickBtn('5,000', Icons.directions_walk_rounded)),
    ]);
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  const _QuickBtn(this.label, this.icon);
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: V2Colors.stepsSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: V2Colors.steps.withValues(alpha: 0.25)),
        ),
        child: Column(children: [
          Icon(icon, color: V2Colors.steps, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w700, color: V2Colors.steps)),
        ]),
      ),
    );
  }
}

class _7DayArea extends StatelessWidget {
  const _7DayArea();
  @override
  Widget build(BuildContext context) {
    final data = V2Sample.steps;
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    final chartMax = ((maxVal + 2000) / 1000).ceil() * 1000.0;
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
          Text('avg 8,643',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: V2Colors.steps)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: LineChart(
            LineChartData(
              minX: 0, maxX: (data.length - 1).toDouble(),
              minY: 0, maxY: chartMax,
              gridData: FlGridData(
                show: true, drawVerticalLine: false,
                horizontalInterval: 3000,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: V2Colors.border, strokeWidth: 1, dashArray: [3, 3]),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 36, interval: 3000,
                  getTitlesWidget: (v, _) {
                    final n = (v / 1000).toInt();
                    return Text('${n}k',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10, color: V2Colors.textSubtle,
                        fontWeight: FontWeight.w600));
                  }),
                ),
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
                  spots: data.asMap().entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                  isCurved: true, curveSmoothness: 0.35,
                  color: V2Colors.steps, barWidth: 3,
                  dotData: FlDotData(show: true,
                    getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                      radius: 4, color: Colors.white,
                      strokeColor: V2Colors.steps, strokeWidth: 2.5)),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [V2Colors.steps.withValues(alpha: 0.30),
                        V2Colors.steps.withValues(alpha: 0.0)],
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
      _SRow('7,560', 'steps', 'Today · 4:30 PM · walk home'),
      _SRow('3,200', 'steps', 'Today · 12:00 PM · lunch break'),
      _SRow('2,100', 'steps', 'Today · 8:30 AM · morning walk'),
      _SRow('11,900', 'steps', 'Yesterday · all day · hike'),
      _SRow('8,450', 'steps', 'Yesterday · by 6:00 PM'),
      _SRow('10,120', 'steps', 'Thu · 9:00 PM · daily total'),
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
                  color: V2Colors.stepsSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_walk_rounded,
                  size: 20, color: V2Colors.steps),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic, children: [
                  Text(r.amount,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        color: V2Colors.text)),
                  const SizedBox(width: 3),
                  Text(r.unit,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: V2Colors.textMuted)),
                ]),
                const SizedBox(height: 2),
                Text(r.when,
                    style: Theme.of(context).textTheme.bodyMedium),
              ])),
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

class _SRow {
  final String amount, unit, when;
  _SRow(this.amount, this.unit, this.when);
}

class _AddSheet extends StatefulWidget {
  const _AddSheet();
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  int _amount = 1000;
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
        Text('Log steps',
            style: Theme.of(context).textTheme.headlineMedium),
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
            Text('steps',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: V2Colors.textMuted)),
          ]),
          const SizedBox(height: 4),
          Text('Tap - or + to adjust by 500',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: V2Colors.textMuted)),
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
              _ChipBtn(
                label: p >= 1000 && p % 1000 == 0
                    ? '${p ~/ 1000}k'
                    : p.toString(),
                onTap: () {
                  setState(() => _amount = p);
                }),
          ]),
        ]),
        const SizedBox(height: 22),
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: V2Colors.steps),
            child: const Text('Add'),
          )),
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
      onTap: onTap, borderRadius: BorderRadius.circular(999),
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
