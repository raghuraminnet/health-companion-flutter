import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'v2_theme.dart';
import 'sample_data.dart';

class WaterV2 extends StatelessWidget {
  const WaterV2({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Colors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: const [
            _TopBar(title: 'Water'),
            SizedBox(height: 12),
            _LatestHero(),
            SizedBox(height: 16),
            _QuickAdd(),
            SizedBox(height: 20),
            _7DayBars(),
            SizedBox(height: 20),
            _SectionLabel('History'),
            SizedBox(height: 12),
            _HistoryList(),
          ],
        ),
      ),
      floatingActionButton: _PillFab(
        label: 'Log water',
        color: V2Colors.water,
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

class _LatestHero extends StatelessWidget {
  const _LatestHero();
  @override
  Widget build(BuildContext context) {
    const today = 2100.0;
    const goal = 2500.0;
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
                  const Text('2.1',
                      style: TextStyle(
                        fontSize: 44, fontWeight: FontWeight.w800,
                        color: V2Colors.text, height: 1, letterSpacing: -1.2)),
                  const SizedBox(width: 4),
                  Text('L of 2.5 L',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: V2Colors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.water_drop_rounded,
                size: 14, color: V2Colors.water),
              const SizedBox(width: 4),
              Text('400 ml to go',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: V2Colors.water)),
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
      Expanded(child: _QuickBtn('250 ml', Icons.local_drink_rounded, V2Colors.water)),
      const SizedBox(width: 10),
      Expanded(child: _QuickBtn('500 ml', Icons.local_drink_rounded, V2Colors.water)),
      const SizedBox(width: 10),
      Expanded(child: _QuickBtn('1 glass', Icons.water_drop_rounded, V2Colors.water)),
    ]);
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  const _QuickBtn(this.label, this.icon, this.color);
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: V2Colors.waterSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }
}

class _7DayBars extends StatelessWidget {
  const _7DayBars();
  @override
  Widget build(BuildContext context) {
    final data = V2Sample.waterMl;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: V2Colors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('7-day intake', style: Theme.of(context).textTheme.titleMedium),
          const Spacer(),
          Text('avg 2.1 L',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: V2Colors.water)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: BarChart(
            BarChartData(
              maxY: 3000,
              gridData: FlGridData(
                show: true, drawVerticalLine: false,
                horizontalInterval: 1000,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: V2Colors.border, strokeWidth: 1, dashArray: [3, 3]),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 32, interval: 1000,
                  getTitlesWidget: (v, _) {
                    final n = (v / 1000);
                    return Text(n == n.toInt() ? '${n.toInt()}L' : '',
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
              barTouchData: BarTouchData(enabled: false),
              barGroups: List.generate(data.length, (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i],
                    color: V2Colors.water,
                    width: 18,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6), bottom: Radius.circular(2)),
                  ),
                ],
              )),
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
      _WRow('500', 'ml', '12:30 PM · lunch', true),
      _WRow('250', 'ml', '10:15 AM · coffee', true),
      _WRow('350', 'ml', '8:00 AM · morning glass', true),
      _WRow('500', 'ml', 'Yesterday · 8:00 PM', true),
      _WRow('500', 'ml', 'Yesterday · 3:00 PM', true),
      _WRow('300', 'ml', 'Yesterday · 11:00 AM', true),
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
                  color: V2Colors.waterSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.water_drop_rounded,
                  size: 20, color: V2Colors.water),
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

class _WRow {
  final String amount, unit, when;
  _WRow(this.amount, this.unit, this.when, _);
}

class _AddSheet extends StatefulWidget {
  const _AddSheet();
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  int _amount = 250;
  String _unit = 'ml';
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
        Text('Log water',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 22),
        Center(child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic, children: [
            Text('$_amount',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 64, fontWeight: FontWeight.w800,
                  color: V2Colors.water, height: 1, letterSpacing: -2)),
            const SizedBox(width: 6),
            Text(_unit,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: V2Colors.textMuted)),
          ]),
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
        SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: V2Colors.water),
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