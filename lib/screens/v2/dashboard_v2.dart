import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../services/session.dart';
import 'v2_theme.dart';
import 'sample_data.dart';
import 'profile_v2.dart';


class DashboardV2 extends StatefulWidget {
  const DashboardV2({super.key});

  @override
  State<DashboardV2> createState() => _DashboardV2State();
}

class _DashboardV2State extends State<DashboardV2> {
  String _initial = 'D';
  String _name = 'there';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final api = ApiService();
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token != null) api.setToken(token);
      final user = await api.getMe();
      if (!mounted) return;
      setState(() {
        _name = user.name.split(' ').first;
        _initial = user.name.isNotEmpty
            ? user.name.substring(0, 1).toUpperCase()
            : 'D';
      });
    } catch (_) {
      // Demo fallback stays as-is.
    }
  }

  Future<void> _logout() async {
    try {
      await ApiService().logout();
    } catch (_) {
      // Best-effort — clear local state regardless.
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    // Flip the global auth signal — AuthCheck will rebuild into AuthScreen.
    setAuthed(false);
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProfileV2(onLogout: _logout)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Colors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          children: [
            _Header(name: _name, onAvatar: _openProfile, initial: _initial),
            const SizedBox(height: 20),
            const _HeroScore(),
            const SizedBox(height: 24),
            const _SectionLabel('Today'),
            const SizedBox(height: 12),
            const _MetricGrid(),
            const SizedBox(height: 24),
            const _SectionLabel('Recent entries'),
            const SizedBox(height: 12),
            const _RecentList(),
          ],
        ),
      ),
      floatingActionButton: const _PillFab(),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  final String initial;
  final VoidCallback onAvatar;
  const _Header({
    required this.name,
    required this.initial,
    required this.onAvatar,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Good day, $name 👋',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 4),
              Text(_today(),
                  style: Theme.of(context).textTheme.headlineMedium),
            ],
          ),
        ),
        const _CircleIcon(
          icon: Icons.search_rounded,
          bg: V2Colors.surface,
          border: V2Colors.border,
        ),
        const SizedBox(width: 8),
        _Avatar(initial: initial, onTap: onAvatar),
      ],
    );
  }

  String _today() {
    final now = DateTime.now();
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[now.weekday - 1]}, '
        '${months[now.month - 1]} ${now.day}';
  }
}

class _Avatar extends StatelessWidget {
  final String initial;
  final VoidCallback onTap;
  const _Avatar({required this.initial, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [V2Colors.brand, V2Colors.weight],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          initial,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color border;
  const _CircleIcon({required this.icon, required this.bg, required this.border});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border),
      ),
      child: Icon(icon, size: 20, color: V2Colors.text),
    );
  }
}

class _HeroScore extends StatelessWidget {
  const _HeroScore();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1B4B), Color(0xFF4338CA)],
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department_rounded,
                        size: 14, color: Color(0xFFFBBF24)),
                    const SizedBox(width: 4),
                    Text(
                      '7-day streak',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              const Icon(Icons.more_horiz_rounded, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: _RingPainter(progress: 0.82),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('82',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            )),
                        Text('/ 100',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Wellness Score',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        )),
                    const SizedBox(height: 4),
                    Text('Looking great',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        )),
                    const SizedBox(height: 6),
                    Text('+6 vs last week',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFA5B4FC),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 56,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                minX: 0, maxX: 6,
                minY: 60, maxY: 95,
                lineBarsData: [
                  LineChartBarData(
                    spots: V2Sample.moodScores
                        .asMap()
                        .entries
                        .map((e) => FlSpot(
                            e.key.toDouble(), 60.0 + e.value * 7.0))
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: Colors.white,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.35),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
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

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});
  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - stroke) / 2;

    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = Colors.white.withValues(alpha: 0.15);
    canvas.drawCircle(center, radius, bg);

    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..shader = const SweepGradient(
        colors: [Color(0xFFFBBF24), Color(0xFFF472B6), Color(0xFFA78BFA)],
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.progress != progress;
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

class _MetricGrid extends StatelessWidget {
  const _MetricGrid();
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.95,
      children: [
        _MetricCard(
          label: 'Blood Pressure',
          value: '120/76',
          unit: 'mmHg',
          delta: '-4',
          positive: true,
          icon: Icons.favorite_rounded,
          color: V2Colors.bp,
          soft: V2Colors.bpSoft,
          chart: V2Sample.bpSys,
        ),
        _MetricCard(
          label: 'Mood',
          value: '4.2',
          unit: '/ 5',
          delta: '+0.3',
          positive: true,
          icon: Icons.emoji_emotions_rounded,
          color: V2Colors.mood,
          soft: V2Colors.moodSoft,
          chart: V2Sample.moodScores,
        ),
        _MetricCard(
          label: 'Water',
          value: '2.1',
          unit: 'L today',
          delta: '+200 ml',
          positive: true,
          icon: Icons.water_drop_rounded,
          color: V2Colors.water,
          soft: V2Colors.waterSoft,
          chart: V2Sample.waterMl,
        ),
        _MetricCard(
          label: 'Steps',
          value: '7,560',
          unit: 'today',
          delta: '+12%',
          positive: true,
          icon: Icons.directions_walk_rounded,
          color: V2Colors.steps,
          soft: V2Colors.stepsSoft,
          chart: V2Sample.steps,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String delta;
  final bool positive;
  final IconData icon;
  final Color color;
  final Color soft;
  final List<double> chart;
  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.delta,
    required this.positive,
    required this.icon,
    required this.color,
    required this.soft,
    required this.chart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: V2Colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: positive
                      ? V2Colors.stepsSoft
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      positive
                          ? Icons.arrow_drop_up_rounded
                          : Icons.arrow_drop_down_rounded,
                      size: 16,
                      color: positive
                          ? const Color(0xFF047857)
                          : const Color(0xFFB91C1C),
                    ),
                    Text(delta,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: positive
                              ? const Color(0xFF047857)
                              : const Color(0xFFB91C1C),
                        )),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: V2Colors.text,
                      letterSpacing: -0.4,
                    )),
              ),
              const SizedBox(width: 4),
              Text(unit,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: V2Colors.textSubtle,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 26,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                minX: 0, maxX: (chart.length - 1).toDouble(),
                minY: chart.reduce(math.min) - 1,
                maxY: chart.reduce(math.max) + 1,
                lineBarsData: [
                  LineChartBarData(
                    spots: chart
                        .asMap()
                        .entries
                        .map((e) =>
                            FlSpot(e.key.toDouble(), e.value))
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: color,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withValues(alpha: 0.15),
                    ),
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

class _RecentList extends StatelessWidget {
  const _RecentList();
  @override
  Widget build(BuildContext context) {
    final items = [
      _RecentItem(
        icon: Icons.favorite_rounded,
        color: V2Colors.bp,
        soft: V2Colors.bpSoft,
        title: 'Blood Pressure',
        sub: '120 / 76 mmHg · Normal',
        when: '2h ago',
      ),
      _RecentItem(
        icon: Icons.water_drop_rounded,
        color: V2Colors.water,
        soft: V2Colors.waterSoft,
        title: 'Water',
        sub: '500 ml · morning glass',
        when: '3h ago',
      ),
      _RecentItem(
        icon: Icons.emoji_emotions_rounded,
        color: V2Colors.mood,
        soft: V2Colors.moodSoft,
        title: 'Mood',
        sub: 'Energized · sleep 4/5',
        when: '5h ago',
      ),
    ];
    return Container(
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: V2Colors.border),
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final last = i == items.length - 1;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: items[i].soft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(items[i].icon,
                          size: 18, color: items[i].color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(items[i].title,
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 2),
                          Text(items[i].sub,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ),
                    ),
                    Text(items[i].when,
                        style: Theme.of(context).textTheme.labelSmall),
                  ],
                ),
              ),
              if (!last)
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: V2Colors.border,
                  indent: 64,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _RecentItem {
  final IconData icon;
  final Color color;
  final Color soft;
  final String title;
  final String sub;
  final String when;
  _RecentItem({
    required this.icon,
    required this.color,
    required this.soft,
    required this.title,
    required this.sub,
    required this.when,
  });
}

class _PillFab extends StatelessWidget {
  const _PillFab();
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 54,
      child: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: V2Colors.text,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Log entry',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}