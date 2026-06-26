// Health Companion — Pregnancy tracker (v2 design, v2+ API)
// Patched by Chitti on 2026-06-26.
//
// Design notes:
//   Pregnancy is fundamentally different from the daily trackers (BP/Mood/Water/...).
//   It's a 40-week journey with discrete milestones — the right UX is a timeline,
//   not a "log today's reading" pattern. So this screen has three tabs:
//
//     1. Today       — current week + day, progress ring, baby size, due date countdown, weekly tip
//     2. Timeline    — vertical scroll through all 40 weeks, current one highlighted
//     3. Milestones  — trimester summary + key events
//
// API: ApiService.getPregnancyProfile / savePregnancyProfile / deletePregnancyProfile
// Schema: pregnancy_profiles table holds last_period_date + (auto-computed) due_date

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/pregnancy.dart';
import '../../services/api_service.dart';
import 'v2_theme.dart';

class PregnancyV2 extends StatefulWidget {
  const PregnancyV2({super.key});
  @override
  State<PregnancyV2> createState() => _PregnancyV2State();
}

class _PregnancyV2State extends State<PregnancyV2> with SingleTickerProviderStateMixin {
  PregnancyProfile? _profile;
  bool _isLoading = true;
  String? _error;
  late final TabController _tabs = TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final p = await ApiService().getPregnancyProfile();
      if (!mounted) return;
      setState(() { _profile = p; _isLoading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  Future<void> _save(DateTime lmp) async {
    final due = lmp.add(const Duration(days: 280));
    try {
      final saved = await ApiService().savePregnancyProfile(
        lastPeriodDate: lmp,
        dueDate: due,
      );
      if (!mounted) return;
      setState(() => _profile = saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $e')),
        );
      }
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete pregnancy profile?'),
        content: const Text('This removes your LMP and due date. You can set it up again any time.'),
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
    if (ok != true) return;
    try {
      await ApiService().deletePregnancyProfile();
      if (!mounted) return;
      setState(() => _profile = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: V2Colors.bg,
        body: const SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }
    if (_error != null && _profile == null) {
      return Scaffold(
        backgroundColor: V2Colors.bg,
        body: SafeArea(child: Center(child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: V2Colors.textMuted),
            const SizedBox(height: 12),
            Text('Could not load profile', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(_error!, style: const TextStyle(color: V2Colors.textMuted, fontSize: 12), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _load, child: const Text('Retry')),
          ]),
        ))),
      );
    }
    if (_profile == null) return _SetupView(onSave: _save);

    return Scaffold(
      backgroundColor: V2Colors.bg,
      body: SafeArea(
        child: Column(children: [
          _TopBar(profile: _profile!, onEdit: () => _showEditSheet(), onDelete: _delete),
          _TabBar(controller: _tabs),
          Expanded(child: TabBarView(controller: _tabs, children: [
            _TodayTab(profile: _profile!),
            _TimelineTab(profile: _profile!),
            _MilestonesTab(profile: _profile!),
          ])),
        ]),
      ),
    );
  }

  void _showEditSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: V2Colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _EditSheet(
        initial: _profile!.lastPeriodDate,
        onSave: (lmp) async {
          await _save(lmp);
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }
}

// ─── Top bar ───────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final PregnancyProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TopBar({required this.profile, required this.onEdit, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pregnancy',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 2),
          Text('Due ${_formatDate(profile.dueDate ?? profile.lastPeriodDate.add(const Duration(days: 280)))}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12, fontWeight: FontWeight.w600, color: V2Colors.textMuted)),
        ])),
        _CircleIconBtn(icon: Icons.edit_rounded, onTap: onEdit),
        const SizedBox(width: 8),
        _CircleIconBtn(icon: Icons.delete_outline_rounded, onTap: onDelete),
      ]),
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
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: V2Colors.surface, shape: BoxShape.circle,
          border: Border.all(color: V2Colors.border),
        ),
        child: Icon(icon, size: 18, color: V2Colors.text),
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  final TabController controller;
  const _TabBar({required this.controller});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: V2Colors.border),
      ),
      child: TabBar(
        controller: controller,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: V2Colors.pregnancy,
          borderRadius: BorderRadius.circular(999),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: V2Colors.textMuted,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Today'),
          Tab(text: 'Timeline'),
          Tab(text: 'Milestones'),
        ],
      ),
    );
  }
}

// ─── TAB 1: Today ──────────────────────────────────────────────────────
class _TodayTab extends StatelessWidget {
  final PregnancyProfile profile;
  const _TodayTab({required this.profile});
  @override
  Widget build(BuildContext context) {
    final week = profile.currentWeek;
    final day = profile.currentDayInWeek;
    final due = profile.dueDate ?? profile.lastPeriodDate.add(const Duration(days: 280));
    final daysToDue = due.difference(DateTime.now()).inDays;
    final pct = profile.progressPercentage;
    final trimester = _trimesterOf(week);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        _HeroCard(week: week, day: day, pct: pct, daysToDue: daysToDue, trimester: trimester),
        const SizedBox(height: 16),
        _BabySizeCard(week: week),
        const SizedBox(height: 16),
        _DevelopmentCard(week: week),
        const SizedBox(height: 16),
        _TipCard(week: week),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final int week;
  final int day;
  final double pct;
  final int daysToDue;
  final int trimester;
  const _HeroCard({required this.week, required this.day, required this.pct,
    required this.daysToDue, required this.trimester});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFFFDF2F8), Color(0xFFFCE7F3)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: V2Colors.pregnancy.withValues(alpha: 0.25)),
      ),
      child: Row(children: [
        SizedBox(
          width: 120, height: 120,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: pct / 100,
                strokeWidth: 10,
                backgroundColor: Colors.white.withValues(alpha: 0.6),
                valueColor: const AlwaysStoppedAnimation(V2Colors.pregnancy),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${pct.round()}%',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28, fontWeight: FontWeight.w800,
                    color: V2Colors.pregnancyDeep, height: 1)),
              const Text('complete',
                  style: TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: V2Colors.pregnancyDeep)),
            ]),
          ]),
        ),
        const SizedBox(width: 20),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: V2Colors.pregnancyDeep,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text('Trimester $trimester',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
            ),
            const SizedBox(height: 8),
            Text('Week $week · Day ${day + 1}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: V2Colors.pregnancyDeep, height: 1.1, letterSpacing: -0.4)),
            const SizedBox(height: 6),
            Text(daysToDue > 0
                ? '$daysToDue days to go'
                : (daysToDue == 0 ? 'Due today' : '${daysToDue.abs()} days past due'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w700,
                  color: V2Colors.pregnancyDeep)),
          ],
        )),
      ]),
    );
  }
}

class _BabySizeCard extends StatelessWidget {
  final int week;
  const _BabySizeCard({required this.week});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: V2Colors.border),
      ),
      child: Row(children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(
            color: V2Colors.pregnancySoft,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.child_friendly_rounded, size: 28, color: V2Colors.pregnancyDeep),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Baby is the size of a',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12, fontWeight: FontWeight.w600, color: V2Colors.textMuted)),
            const SizedBox(height: 4),
            Text(_babySize(week),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22, fontWeight: FontWeight.w800,
                  color: V2Colors.text, height: 1.1)),
          ],
        )),
      ]),
    );
  }
}

class _DevelopmentCard extends StatelessWidget {
  final int week;
  const _DevelopmentCard({required this.week});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: V2Colors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: V2Colors.pregnancySoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded, size: 16, color: V2Colors.pregnancyDeep),
          ),
          const SizedBox(width: 10),
          Text('Development this week',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w800, color: V2Colors.text)),
        ]),
        const SizedBox(height: 12),
        Text(_development(week),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w500,
              color: V2Colors.text, height: 1.5)),
      ]),
    );
  }
}

class _TipCard extends StatelessWidget {
  final int week;
  const _TipCard({required this.week});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: V2Colors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.lightbulb_rounded, size: 16, color: Color(0xFFB45309)),
          ),
          const SizedBox(width: 10),
          Text('Tip for week $week',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14, fontWeight: FontWeight.w800, color: V2Colors.text)),
        ]),
        const SizedBox(height: 10),
        ..._tips(week).map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
              padding: EdgeInsets.only(top: 6, right: 6),
              child: Text('•', style: TextStyle(color: V2Colors.pregnancyDeep, fontWeight: FontWeight.w900, fontSize: 16)),
            ),
            Expanded(child: Text(t,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w500, color: V2Colors.text, height: 1.5))),
          ]),
        )),
      ]),
    );
  }
}

// ─── TAB 2: Timeline ───────────────────────────────────────────────────
class _TimelineTab extends StatelessWidget {
  final PregnancyProfile profile;
  const _TimelineTab({required this.profile});
  @override
  Widget build(BuildContext context) {
    final currentWeek = profile.currentWeek;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: 40,
      itemBuilder: (_, i) => _TimelineRow(
        week: i + 1,
        isCurrent: i + 1 == currentWeek,
        isPast: i + 1 < currentWeek,
        isFuture: i + 1 > currentWeek,
        trimester: _trimesterOf(i + 1),
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final int week;
  final bool isCurrent;
  final bool isPast;
  final bool isFuture;
  final int trimester;
  const _TimelineRow({required this.week, required this.isCurrent,
    required this.isPast, required this.isFuture, required this.trimester});
  @override
  Widget build(BuildContext context) {
    final accent = isCurrent
        ? V2Colors.pregnancy
        : isPast
            ? V2Colors.textMuted
            : V2Colors.border;
    final milestone = _milestone(week);
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        // Track + dot
        SizedBox(
          width: 44,
          child: Column(children: [
            const SizedBox(height: 6),
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                color: isCurrent
                    ? V2Colors.pregnancy
                    : (isPast ? V2Colors.pregnancySoft : V2Colors.surface),
                border: Border.all(color: accent, width: 2),
                shape: BoxShape.circle,
              ),
              child: Center(child: Text('$week',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12, fontWeight: FontWeight.w800,
                    color: isCurrent ? Colors.white : V2Colors.text))),
            ),
            Expanded(
              child: Container(
                width: 2,
                color: isFuture ? V2Colors.border : V2Colors.pregnancySoft,
              ),
            ),
          ]),
        ),
        // Content
        Expanded(child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 0, 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCurrent ? V2Colors.pregnancySoft : V2Colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCurrent ? V2Colors.pregnancy.withValues(alpha: 0.4) : V2Colors.border,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('Week $week',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13, fontWeight: FontWeight.w800,
                      color: isCurrent ? V2Colors.pregnancyDeep : V2Colors.text)),
                const SizedBox(width: 8),
                if (isCurrent) Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: V2Colors.pregnancy, borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('NOW',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                ),
                const Spacer(),
                if (milestone != null) Icon(milestone.icon,
                    size: 16, color: V2Colors.pregnancyDeep),
              ]),
              const SizedBox(height: 4),
              Text('Trimester $trimester · ${_babySize(week)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11, fontWeight: FontWeight.w600, color: V2Colors.textMuted)),
              if (milestone != null) ...[
                const SizedBox(height: 8),
                Text(milestone.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: V2Colors.pregnancyDeep, height: 1.4)),
              ],
            ]),
          ),
        )),
      ]),
    );
  }
}

// ─── TAB 3: Milestones ────────────────────────────────────────────────
class _MilestonesTab extends StatelessWidget {
  final PregnancyProfile profile;
  const _MilestonesTab({required this.profile});
  @override
  Widget build(BuildContext context) {
    final currentWeek = profile.currentWeek;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        for (final t in _trimesterSummaries(currentWeek)) _TrimesterCard(summary: t),
        const SizedBox(height: 16),
        Text('KEY MILESTONES',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w800, color: V2Colors.textMuted)),
        const SizedBox(height: 10),
        for (final m in _keyMilestones(currentWeek)) _MilestoneRow(milestone: m),
      ],
    );
  }
}

class _TrimesterCard extends StatelessWidget {
  final _TrimesterSummary summary;
  const _TrimesterCard({required this.summary});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: summary.isCurrent ? V2Colors.pregnancy : V2Colors.border,
          width: summary.isCurrent ? 1.5 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: summary.isCurrent ? V2Colors.pregnancy : V2Colors.surfaceAlt,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text('Trimester ${summary.number}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: summary.isCurrent ? Colors.white : V2Colors.text)),
          ),
          const Spacer(),
          if (summary.isCurrent) Text('YOU ARE HERE',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9, fontWeight: FontWeight.w800, color: V2Colors.pregnancy)),
        ]),
        const SizedBox(height: 8),
        Text('Weeks ${summary.startWeek}–${summary.endWeek}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14, fontWeight: FontWeight.w800, color: V2Colors.text)),
        const SizedBox(height: 4),
        Text(summary.summary,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12, fontWeight: FontWeight.w500, color: V2Colors.textMuted, height: 1.5)),
      ]),
    );
  }
}

class _MilestoneRow extends StatelessWidget {
  final _Milestone milestone;
  const _MilestoneRow({required this.milestone});
  @override
  Widget build(BuildContext context) {
    final passed = milestone.week <= _currentWeekFromProfile(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: passed ? V2Colors.pregnancySoft : V2Colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: V2Colors.border),
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: passed ? V2Colors.pregnancy : V2Colors.surfaceAlt,
            shape: BoxShape.circle,
          ),
          child: Icon(milestone.icon,
              size: 18, color: passed ? Colors.white : V2Colors.textMuted),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Week ${milestone.week} · ${milestone.label}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13, fontWeight: FontWeight.w800, color: V2Colors.text)),
          if (milestone.detail != null) Text(milestone.detail!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11, fontWeight: FontWeight.w500,
                color: V2Colors.textMuted, height: 1.4)),
        ])),
        Text(passed ? '✓' : '',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18, fontWeight: FontWeight.w800, color: V2Colors.pregnancy)),
      ]),
    );
  }
}

// ─── Setup (no profile yet) ───────────────────────────────────────────
class _SetupView extends StatefulWidget {
  final Future<void> Function(DateTime) onSave;
  const _SetupView({required this.onSave});
  @override
  State<_SetupView> createState() => _SetupViewState();
}

class _SetupViewState extends State<_SetupView> {
  DateTime _lmp = DateTime.now().subtract(const Duration(days: 60));
  bool _isSaving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lmp,
      firstDate: DateTime.now().subtract(const Duration(days: 280)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: V2Colors.pregnancy,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: V2Colors.text,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _lmp = picked);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await widget.onSave(_lmp);
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final due = _lmp.add(const Duration(days: 280));
    return Scaffold(
      backgroundColor: V2Colors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const SizedBox(height: 24),
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: V2Colors.pregnancySoft,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.pregnant_woman_rounded,
                  size: 44, color: V2Colors.pregnancyDeep),
            ),
            const SizedBox(height: 24),
            Text('Set up pregnancy tracking',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24, fontWeight: FontWeight.w800, color: V2Colors.text)),
            const SizedBox(height: 6),
            Text('Enter the first day of your last period and we\'ll calculate your due date and weekly progress.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13, fontWeight: FontWeight.w500,
                  color: V2Colors.textMuted, height: 1.5)),
            const SizedBox(height: 24),
            _FieldLabel(label: 'Last period date'),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: V2Colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: V2Colors.border),
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_rounded,
                      size: 18, color: V2Colors.pregnancy),
                  const SizedBox(width: 12),
                  Text(_formatDate(_lmp),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16, fontWeight: FontWeight.w800, color: V2Colors.text)),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            _FieldLabel(label: 'Estimated due date'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: V2Colors.pregnancySoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: V2Colors.pregnancy.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.cake_rounded, size: 18, color: V2Colors.pregnancyDeep),
                const SizedBox(width: 12),
                Text(_formatDate(due),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16, fontWeight: FontWeight.w800, color: V2Colors.pregnancyDeep)),
              ]),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: V2Colors.pregnancy,
                disabledBackgroundColor: V2Colors.pregnancy.withValues(alpha: 0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Start tracking',
                    style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14)),
            ),
          ]),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;
  const _FieldLabel({required this.label});
  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w800, color: V2Colors.textMuted));
  }
}

// ─── Edit sheet (when profile exists) ────────────────────────────────
class _EditSheet extends StatefulWidget {
  final DateTime initial;
  final Future<void> Function(DateTime) onSave;
  const _EditSheet({required this.initial, required this.onSave});
  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late DateTime _lmp = widget.initial;
  bool _isSaving = false;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _lmp,
      firstDate: DateTime.now().subtract(const Duration(days: 280)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _lmp = picked);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    await widget.onSave(_lmp);
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    final due = _lmp.add(const Duration(days: 280));
    return Padding(
      padding: EdgeInsets.only(
          left: 20, right: 20, top: 14,
          bottom: 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(color: V2Colors.borderStrong,
                borderRadius: BorderRadius.circular(999)),
          )),
          const SizedBox(height: 18),
          Text('Edit last period date',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 18),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: V2Colors.surfaceAlt,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 16, color: V2Colors.pregnancy),
                const SizedBox(width: 10),
                Text(_formatDate(_lmp),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15, fontWeight: FontWeight.w700, color: V2Colors.text)),
                const Spacer(),
                Text('Due ${_formatDate(due)}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12, fontWeight: FontWeight.w600, color: V2Colors.textMuted)),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(width: double.infinity,
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: V2Colors.pregnancy,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSaving
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save',
                    style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Domain helpers ──────────────────────────────────────────────────
int _trimesterOf(int week) {
  if (week < 1) return 1;
  if (week <= 13) return 1;
  if (week <= 27) return 2;
  return 3;
}

String _babySize(int week) {
  if (week < 4)  return 'Poppy seed';
  if (week < 8)  return 'Raspberry';
  if (week < 12) return 'Lime';
  if (week < 16) return 'Avocado';
  if (week < 20) return 'Banana';
  if (week < 24) return 'Papaya';
  if (week < 28) return 'Eggplant';
  if (week < 32) return 'Coconut';
  if (week < 36) return 'Romaine lettuce';
  if (week <= 40) return 'Pumpkin';
  return 'Watermelon';
}

String _development(int week) {
  if (week < 4)  return 'Fertilization and implantation occur.';
  if (week < 8)  return 'Heart begins to beat, major organs form.';
  if (week < 12) return 'Baby can open and close fists, fingers fully formed.';
  if (week < 16) return 'Baby can make facial expressions, may suck thumb.';
  if (week < 20) return 'Halfway there! Baby is very active, you may feel movement.';
  if (week < 24) return 'Baby has taste buds, lungs are developing rapidly.';
  if (week < 28) return 'Baby can open eyes, brain is developing fast.';
  if (week < 32) return 'Baby practices breathing, bones are hardening.';
  if (week < 36) return 'Baby is gaining weight rapidly, settling into birth position.';
  if (week <= 40) return 'Baby is full term — ready for birth at any time.';
  return 'Past due date — talk to your provider.';
}

List<String> _tips(int week) {
  if (week < 8)  return [
    'Start taking prenatal vitamins with folic acid.',
    'Avoid alcohol, smoking, and raw foods.',
    'Schedule your first prenatal appointment.',
  ];
  if (week < 13) return [
    'First trimester fatigue is normal — rest when you can.',
    'Stay hydrated, aim for 8-10 glasses of water daily.',
    'Begin light exercise like walking if cleared by your provider.',
  ];
  if (week < 20) return [
    'Energy often returns in the second trimester — enjoy it.',
    'Start thinking about maternity clothes if you haven\'t.',
    'Schedule your anatomy scan around week 18-22.',
  ];
  if (week < 28) return [
    'You may feel first kicks between weeks 18-24.',
    'Consider a prenatal class to prepare for birth.',
    'Sleep on your side (left is best) for better blood flow.',
  ];
  if (week < 32) return [
    'Third trimester starts — keep up regular prenatal visits.',
    'Watch for signs of preterm labor; report any concerns.',
    'Start preparing the nursery and baby essentials.',
  ];
  if (week < 36) return [
    'Baby is gaining weight fast — keep eating well.',
    'Practice breathing techniques for labor.',
    'Pack your hospital bag and finalize your birth plan.',
  ];
  return [
    'Full term — baby could arrive any day.',
    'Watch for signs of labor: contractions, water breaking, bloody show.',
    'Rest as much as possible; you\'ll need energy soon.',
  ];
}

class _Milestone {
  final int week;
  final String label;
  final String? detail;
  final IconData icon;
  const _Milestone(this.week, this.label, this.detail, this.icon);
}

_Milestone? _milestone(int week) {
  for (final m in const [
    _Milestone(6,  'Heartbeat detectable', null, Icons.favorite_rounded),
    _Milestone(8,  'All major organs formed', null, Icons.medical_services_rounded),
    _Milestone(12, 'End of first trimester', null, Icons.flag_rounded),
    _Milestone(16, 'Baby can make faces', null, Icons.emoji_emotions_rounded),
    _Milestone(20, 'Halfway!', null, Icons.celebration_rounded),
    _Milestone(24, 'Viability milestone', null, Icons.health_and_safety_rounded),
    _Milestone(28, 'Third trimester starts', null, Icons.flag_circle_rounded),
    _Milestone(32, 'Bones hardening', null, Icons.directions_walk_rounded),
    _Milestone(36, 'Full term in 4 weeks', null, Icons.event_available_rounded),
    _Milestone(40, 'Due date', null, Icons.cake_rounded),
  ]) {
    if (m.week == week) return m;
  }
  return null;
}

List<_TrimesterSummary> _trimesterSummaries(int currentWeek) {
  final t1 = _TrimesterSummary(1, 1, 13,
    'First trimester — major development, often the toughest on your body.',
    currentWeek >= 1 && currentWeek <= 13);
  final t2 = _TrimesterSummary(2, 14, 27,
    'Second trimester — often the easiest. Energy returns, bump starts showing.',
    currentWeek >= 14 && currentWeek <= 27);
  final t3 = _TrimesterSummary(3, 28, 40,
    'Third trimester — final stretch. Baby grows fast, body prepares for birth.',
    currentWeek >= 28);
  return [t1, t2, t3];
}

class _TrimesterSummary {
  final int number;
  final int startWeek;
  final int endWeek;
  final String summary;
  final bool isCurrent;
  _TrimesterSummary(this.number, this.startWeek, this.endWeek,
      this.summary, this.isCurrent);
}

List<_Milestone> _keyMilestones(int currentWeek) {
  return [
    _Milestone(6,  'Heartbeat detectable', 'First detectable heartbeat on ultrasound.', Icons.favorite_rounded),
    _Milestone(12, 'End of first trimester', 'Miscarriage risk drops significantly.', Icons.flag_rounded),
    _Milestone(20, 'Anatomy scan', 'Detailed ultrasound checks baby\'s development.', Icons.medical_services_rounded),
    _Milestone(24, 'Viability', 'Baby could survive with medical help if born now.', Icons.health_and_safety_rounded),
    _Milestone(28, 'Third trimester begins', 'Baby\'s brain develops rapidly.', Icons.flag_circle_rounded),
    _Milestone(36, 'Full term in 4 weeks', 'Baby is considered early term at 37 weeks.', Icons.event_available_rounded),
    _Milestone(40, 'Estimated due date', 'Most babies arrive within 2 weeks of this date.', Icons.cake_rounded),
  ];
}

int _currentWeekFromProfile(BuildContext context) {
  // Best effort: read from the same state via InheritedWidget fallback to 0
  // (the actual "passed" logic happens via the callback param in the real impl;
  //  for the simple check, we recompute from the page-level state.)
  final state = context.findAncestorStateOfType<_PregnancyV2State>();
  return state?._profile?.currentWeek ?? 0;
}

String _formatDate(DateTime d) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${months[d.month - 1]} ${d.day}, ${d.year}';
}