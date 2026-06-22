import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'v2_theme.dart';
import 'sample_data.dart';

class BpV2 extends StatelessWidget {
  const BpV2({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Colors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: const [
            _TopBar(),
            SizedBox(height: 12),
            _LatestHero(),
            SizedBox(height: 20),
            _7DayTrend(),
            SizedBox(height: 20),
            _SectionLabel('History'),
            SizedBox(height: 12),
            _HistoryList(),
          ],
        ),
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 54,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddSheet(context),
          backgroundColor: V2Colors.bp,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          icon: const Icon(Icons.add_rounded),
          label: Text('Log reading',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 14,
              )),
        ),
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
  const _TopBar();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleIconBtn(icon: Icons.arrow_back_rounded, onTap: () {}),
        const SizedBox(width: 12),
        Text('Blood Pressure',
            style: Theme.of(context).textTheme.headlineMedium),
        const Spacer(),
        _CircleIconBtn(icon: Icons.tune_rounded, onTap: () {}),
      ],
    );
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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: V2Colors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: V2Colors.border),
        ),
        child: Icon(icon, size: 20, color: V2Colors.text),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Latest reading',
                  style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: V2Colors.stepsSoft,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('Normal',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF047857),
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('120',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    color: V2Colors.text,
                    height: 1,
                    letterSpacing: -2,
                  )),
              Padding(
                padding: const EdgeInsets.only(left: 4, right: 14),
                child: Text('/',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 36,
                      fontWeight: FontWeight.w600,
                      color: V2Colors.textSubtle,
                    )),
              ),
              Text('76',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    color: V2Colors.text,
                    height: 1,
                    letterSpacing: -2,
                  )),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('mmHg',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: V2Colors.textMuted,
                    )),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  size: 14, color: V2Colors.textMuted),
              const SizedBox(width: 6),
              Text('Today · 7:42 AM',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(width: 14),
              const Icon(Icons.favorite_outline_rounded,
                  size: 14, color: V2Colors.textMuted),
              const SizedBox(width: 6),
              Text('Pulse 72 bpm',
                  style: Theme.of(context).textTheme.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }
}

class _7DayTrend extends StatelessWidget {
  const _7DayTrend();
  @override
  Widget build(BuildContext context) {
    final sys = V2Sample.bpSys;
    final dia = V2Sample.bpDia;
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
          Row(
            children: [
              Text('7-day trend',
                  style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              _LegendDot(color: V2Colors.bp, label: 'Sys'),
              const SizedBox(width: 12),
              _LegendDot(color: const Color(0xFFFB7185), label: 'Dia'),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                minX: 0, maxX: (sys.length - 1).toDouble(),
                minY: 70, maxY: 135,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: V2Colors.border,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 20,
                      getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: V2Colors.textSubtle,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, _) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(days[v.toInt()],
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                color: V2Colors.textSubtle,
                                fontWeight: FontWeight.w700,
                              )),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: sys.asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: V2Colors.bp,
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) =>
                          FlDotCirclePainter(
                        radius: 3,
                        color: Colors.white,
                        strokeColor: V2Colors.bp,
                        strokeWidth: 2,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: V2Colors.bp.withValues(alpha: 0.08),
                    ),
                  ),
                  LineChartBarData(
                    spots: dia.asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: const Color(0xFFFB7185),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: V2Colors.textMuted,
            )),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList();
  @override
  Widget build(BuildContext context) {
    final rows = [
      _HistRow('120/76', '72 bpm', 'Today · 7:42 AM', true),
      _HistRow('121/78', '70 bpm', 'Yesterday · 9:10 PM', true),
      _HistRow('122/78', '74 bpm', 'Yesterday · 8:00 AM', true),
      _HistRow('124/79', '76 bpm', 'Fri · 9:15 PM', true),
      _HistRow('126/80', '78 bpm', 'Fri · 8:30 AM', false),
      _HistRow('128/82', '80 bpm', 'Thu · 9:30 PM', false),
    ];
    return Container(
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: V2Colors.border),
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final last = i == rows.length - 1;
          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 36,
                      decoration: BoxDecoration(
                        color: rows[i].normal
                            ? V2Colors.steps
                            : V2Colors.mood,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(rows[i].bp,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: V2Colors.text,
                              )),
                          const SizedBox(height: 2),
                          Text(rows[i].when,
                              style:
                                  Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(rows[i].pulse,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: V2Colors.textMuted,
                            )),
                        const SizedBox(height: 2),
                        Text(rows[i].normal ? 'Normal' : 'Elevated',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: rows[i].normal
                                  ? const Color(0xFF047857)
                                  : const Color(0xFFB45309),
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              if (!last)
                const Divider(
                    height: 1, thickness: 1, color: V2Colors.border, indent: 38),
            ],
          );
        }),
      ),
    );
  }
}

class _HistRow {
  final String bp;
  final String pulse;
  final String when;
  final bool normal;
  _HistRow(this.bp, this.pulse, this.when, this.normal);
}

class _AddSheet extends StatelessWidget {
  const _AddSheet();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: 20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: V2Colors.borderStrong,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Log a reading',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _NumField(label: 'Systolic', unit: 'mmHg')),
              const SizedBox(width: 12),
              Expanded(child: _NumField(label: 'Diastolic', unit: 'mmHg')),
            ],
          ),
          const SizedBox(height: 12),
          _NumField(label: 'Pulse', unit: 'bpm'),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Save reading'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  final String label;
  final String unit;
  const _NumField({required this.label, required this.unit});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: V2Colors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: V2Colors.textMuted,
                letterSpacing: 0.4,
              )),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text('—',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: V2Colors.text,
                  )),
              const SizedBox(width: 6),
              Text(unit,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: V2Colors.textSubtle,
                  )),
            ],
          ),
        ],
      ),
    );
  }
}