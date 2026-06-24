import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'v2_theme.dart';
import 'sample_data.dart';

class WeightV2 extends StatelessWidget {
  const WeightV2({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Colors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: const [
            _TopBar(title: 'Weight'),
            SizedBox(height: 12),
            _LatestHero(),
            SizedBox(height: 16),
            _StatsRow(),
            SizedBox(height: 20),
            _SevenDayTrend(),
            SizedBox(height: 20),
            _SectionLabel('History'),
            SizedBox(height: 12),
            _HistoryList(),
          ],
        ),
      ),
      floatingActionButton: _PillFab(
        label: 'Log weight',
        color: V2Colors.weight,
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
    final data = V2Sample.weightKg;
    final latest = data.last;
    final prev = data[data.length - 2];
    final delta = latest - prev;
    final trendingDown = delta < 0;
    final deltaStr = (delta >= 0 ? '+' : '') + delta.toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: V2Colors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Today',
              style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: trendingDown ? V2Colors.stepsSoft : V2Colors.moodSoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                trendingDown
                    ? Icons.trending_down_rounded
                    : Icons.trending_up_rounded,
                size: 14,
                color: trendingDown
                    ? const Color(0xFF047857)
                    : const Color(0xFFB45309),
              ),
              const SizedBox(width: 4),
              Text('$deltaStr kg vs last week',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, fontWeight: FontWeight.w700,
                    color: trendingDown
                        ? const Color(0xFF047857)
                        : const Color(0xFFB45309))),
            ]),
          ),
        ]),
        const SizedBox(height: 14),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(latest.toStringAsFixed(1),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 64, fontWeight: FontWeight.w800,
                    color: V2Colors.text, height: 1, letterSpacing: -2)),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('kg',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: V2Colors.textMuted)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(children: [
          const Icon(Icons.calendar_today_rounded,
              size: 14, color: V2Colors.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text('Last weighed this morning',
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      ]),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();
  @override
  Widget build(BuildContext context) {
    final data = V2Sample.weightKg;
    final latest = data.last;
    final oldest = data.first;
    final totalChange = latest - oldest;
    final changeStr = (totalChange >= 0 ? '+' : '') + totalChange.toStringAsFixed(1);
    final down = totalChange < 0;
    return Row(children: [
      Expanded(child: _StatTile(
        label: 'Start', value: oldest.toStringAsFixed(1), unit: 'kg',
        icon: Icons.flag_outlined, color: V2Colors.textMuted,
      )),
      const SizedBox(width: 10),
      Expanded(child: _StatTile(
        label: 'Change', value: changeStr, unit: 'kg',
        icon: down ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
        color: down ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
      )),
      const SizedBox(width: 10),
      const Expanded(child: _StatTile(
        label: 'Goal', value: '70.0', unit: 'kg',
        icon: Icons.track_changes_rounded, color: V2Colors.weight,
      )),
    ]);
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
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: V2Colors.border),
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
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: V2Colors.text, letterSpacing: -0.4)),
          const SizedBox(width: 3),
          Text(unit,
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w600,
                  color: V2Colors.textSubtle)),
        ]),
      ]),
    );
  }
}

class _SevenDayTrend extends StatelessWidget {
  const _SevenDayTrend();
  @override
  Widget build(BuildContext context) {
    final data = V2Sample.weightKg;
    final minVal = data.reduce((a, b) => a < b ? a : b);
    final maxVal = data.reduce((a, b) => a > b ? a : b);
    const pad = 0.5;
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
          Text('avg ${(data.reduce((a, b) => a + b) / data.length).toStringAsFixed(1)} kg',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: V2Colors.weight)),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          height: 130,
          child: LineChart(
            LineChartData(
              minX: 0, maxX: (data.length - 1).toDouble(),
              minY: minVal - pad, maxY: maxVal + pad,
              gridData: FlGridData(
                show: true, drawVerticalLine: false,
                horizontalInterval: 0.5,
                getDrawingHorizontalLine: (_) => const FlLine(
                  color: V2Colors.border, strokeWidth: 1, dashArray: [3, 3]),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true, reservedSize: 36, interval: 0.5,
                  getTitlesWidget: (v, _) => Text(v.toStringAsFixed(1),
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
                  spots: data.asMap().entries
                      .map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                  isCurved: true, curveSmoothness: 0.4,
                  color: V2Colors.weight, barWidth: 3,
                  dotData: FlDotData(show: true,
                    getDotPainter: (s, _, __, ___) => FlDotCirclePainter(
                      radius: 4, color: Colors.white,
                      strokeColor: V2Colors.weight, strokeWidth: 2.5)),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [V2Colors.weight.withValues(alpha: 0.25),
                        V2Colors.weight.withValues(alpha: 0.0)],
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
      _WRow('71.5', 'kg', 'Today · 7:30 AM · morning', '−0.1'),
      _WRow('71.6', 'kg', 'Yesterday · 8:00 AM', '−0.2'),
      _WRow('71.8', 'kg', 'Fri · 8:15 AM', '−0.1'),
      _WRow('71.9', 'kg', 'Thu · 7:45 AM', '−0.1'),
      _WRow('72.0', 'kg', 'Wed · 8:00 AM', '−0.2'),
      _WRow('72.2', 'kg', 'Tue · 7:50 AM', '−0.2'),
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
        final down = r.delta.startsWith('−') || r.delta.startsWith('-');
        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: V2Colors.weightSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.monitor_weight_rounded,
                  size: 20, color: V2Colors.weight),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: down ? V2Colors.stepsSoft : V2Colors.moodSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${r.delta} kg',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11, fontWeight: FontWeight.w700,
                      color: down
                          ? const Color(0xFF047857)
                          : const Color(0xFFB45309))),
              ),
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
  final String amount, unit, when, delta;
  _WRow(this.amount, this.unit, this.when, this.delta);
}

class _AddSheet extends StatefulWidget {
  const _AddSheet();
  @override
  State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  double _weight = 71.5;
  String _unit = 'kg';
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
        Text('Log weight',
            style: Theme.of(context).textTheme.headlineMedium),
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
            Text(_unit,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18, fontWeight: FontWeight.w700,
                  color: V2Colors.textMuted)),
          ]),
          const SizedBox(height: 4),
          Text('Tap - or + to adjust by 0.1',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w600,
                color: V2Colors.textMuted)),
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
              _ChipBtn(label: '$p', onTap: () {
                setState(() => _weight = p);
              }),
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
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: V2Colors.weight),
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
