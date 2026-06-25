import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import '../../models/user.dart';
import 'v2_theme.dart';
import 'preview_v2.dart';
import 'settings_v2.dart';

/// Profile + account screen on the v2 design system.
///
/// Loads user + settings from the API; lets the user pick a theme and sign
/// out. Goal readouts here are read-only — edit them in [SettingsScreen].
class ProfileV2 extends StatefulWidget {
  final VoidCallback? onLogout;

  const ProfileV2({super.key, this.onLogout});

  @override
  State<ProfileV2> createState() => _ProfileV2State();
}

class _ProfileV2State extends State<ProfileV2> {
  User? _user;
  Map<String, dynamic> _settings = {};
  bool _isLoading = true;

  static const _themes = [
    ('dark', '🌙', 'Dark'),
    ('light', '☀️', 'Light'),
    ('pink', '🌸', 'Pink'),
    ('white', '✨', 'White'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();
      final results = await Future.wait([api.getMe(), api.getSettings()]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as User;
        _settings = results[1] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _setTheme(String theme) async {
    final current = _settings['theme'] ?? 'dark';
    if (theme == current) return;
    try {
      final api = ApiService();
      final updated = await api.updateSettings({'theme': theme});
      if (!mounted) return;
      setState(() => _settings = updated);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update theme: $e')),
      );
    }
  }

  Future<void> _logout() async {
    try {
      await ApiService().logout();
    } catch (_) {
      // best-effort — clear local state regardless
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    // Pop everything we pushed (ProfileV2, SettingsV2, …) so the auth
    // swap below lands cleanly on AuthScreen instead of leaving us on top
    // of a stale route.
    if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    if (mounted) widget.onLogout?.call();
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SettingsV2(onLogout: _logout)),
    );
    // Refresh in case settings changed (theme, goals, etc.)
    if (mounted) await _load();
  }

  String? get _userName => _user?.name;
  String? get _userEmail => _user?.email;
  int? get _userYear => _user?.yearOfBirth;
  String? get _userGender => _user?.gender;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: V2Colors.bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    const _TopBar(),
                    const SizedBox(height: 16),
                    _ProfileHero(
                      name: _userName,
                      email: _userEmail,
                      year: _userYear,
                      gender: _userGender,
                    ),
                    const SizedBox(height: 20),
                    const _SectionLabel('Theme'),
                    const SizedBox(height: 12),
                    _ThemeCard(
                      current: _settings['theme'] ?? 'dark',
                      onPick: _setTheme,
                    ),
                    const SizedBox(height: 20),
                    _SectionLabelRow(
                      'Goals',
                      actionLabel: 'Edit',
                      onAction: _openSettings,
                    ),
                    const SizedBox(height: 12),
                    _GoalsCard(
                      waterGoal: _settings['water_goal'] ?? 2500,
                      stepsGoal: _settings['steps_goal'] ?? 10000,
                      bpSys: _settings['bp_systolic_target'] ?? 120,
                      bpDia: _settings['bp_diastolic_target'] ?? 80,
                    ),
                    const SizedBox(height: 20),
                    const _SectionLabel('Account'),
                    const SizedBox(height: 12),
                    _AccountCard(onLogout: _logout),
                  ],
                ),
              ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Profile', style: Theme.of(context).textTheme.headlineMedium),
        const Spacer(),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: V2Colors.surface,
            shape: BoxShape.circle,
            border: Border.all(color: V2Colors.border),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.refresh_rounded,
            size: 20,
            color: V2Colors.text.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(text.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall),
      );
}

class _SectionLabelRow extends StatelessWidget {
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _SectionLabelRow(this.text,
      {this.actionLabel, this.onAction});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Text(text.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall),
          const Spacer(),
          if (actionLabel != null && onAction != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: V2Colors.brand,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        size: 14, color: V2Colors.brand),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String? name;
  final String? email;
  final int? year;
  final String? gender;

  const _ProfileHero({
    required this.name,
    required this.email,
    required this.year,
    required this.gender,
  });

  @override
  Widget build(BuildContext context) {
    final initial = (name?.isNotEmpty == true)
        ? name!.substring(0, 1).toUpperCase()
        : 'U';
    final age = year == null ? '—' : '${DateTime.now().year - year!} yrs';

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
              Container(
                width: 64,
                height: 64,
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
                    fontWeight: FontWeight.w800,
                    fontSize: 26,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'User',
                      style: Theme.of(context).textTheme.headlineMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email ?? '',
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _MetaChip(
                icon: Icons.cake_outlined,
                label: '${year ?? '—'}',
                color: V2Colors.steps,
                soft: V2Colors.stepsSoft,
              ),
              const SizedBox(width: 8),
              _MetaChip(
                icon: Icons.timelapse_rounded,
                label: age,
                color: V2Colors.water,
                soft: V2Colors.waterSoft,
              ),
              const SizedBox(width: 8),
              _MetaChip(
                icon: Icons.person_outline_rounded,
                label: (gender ?? '—').toString(),
                color: V2Colors.weight,
                soft: V2Colors.weightSoft,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color soft;
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.soft,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String current;
  final ValueChanged<String> onPick;
  const _ThemeCard({required this.current, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: V2Colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _ProfileV2State._themes.map((t) {
          final selected = t.$1 == current;
          return _ThemeTile(
            emoji: t.$2,
            label: t.$3,
            selected: selected,
            onTap: () => onPick(t.$1),
          );
        }).toList(),
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ThemeTile({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? V2Colors.brandSoft : V2Colors.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? V2Colors.brand : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? V2Colors.brand : V2Colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalsCard extends StatelessWidget {
  final int waterGoal;
  final int stepsGoal;
  final int bpSys;
  final int bpDia;
  const _GoalsCard({
    required this.waterGoal,
    required this.stepsGoal,
    required this.bpSys,
    required this.bpDia,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: V2Colors.border),
      ),
      child: Column(
        children: [
          _GoalRow(
            icon: Icons.water_drop_rounded,
            color: V2Colors.water,
            soft: V2Colors.waterSoft,
            label: 'Water goal',
            value: '$waterGoal ml',
          ),
          const Divider(
              height: 1, thickness: 1, color: V2Colors.border, indent: 64),
          _GoalRow(
            icon: Icons.directions_walk_rounded,
            color: V2Colors.steps,
            soft: V2Colors.stepsSoft,
            label: 'Steps goal',
            value: '$stepsGoal',
          ),
          const Divider(
              height: 1, thickness: 1, color: V2Colors.border, indent: 64),
          _GoalRow(
            icon: Icons.favorite_rounded,
            color: V2Colors.bp,
            soft: V2Colors.bpSoft,
            label: 'BP target',
            value: '$bpSys / $bpDia mmHg',
          ),
          const Divider(
              height: 1, thickness: 1, color: V2Colors.border, indent: 64),
          const _V2PreviewRow(),
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color soft;
  final String label;
  final String value;
  const _GoalRow({
    required this.icon,
    required this.color,
    required this.soft,
    required this.label,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: V2Colors.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _V2PreviewRow extends StatelessWidget {
  const _V2PreviewRow();
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const V2PreviewScreen()),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: V2Colors.brandSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                size: 20,
                color: V2Colors.brand,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Preview v2 redesign',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text('Direction B — Friendly Wellness (light)',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: V2Colors.textSubtle),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final VoidCallback onLogout;
  const _AccountCard({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: V2Colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: V2Colors.border),
      ),
      child: Column(
        children: [
          _AccountRow(
            icon: Icons.lock_reset_rounded,
            title: 'Change password',
            color: V2Colors.text,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Coming soon — wire to /api/auth/change-password'),
                ),
              );
            },
          ),
          const Divider(
              height: 1, thickness: 1, color: V2Colors.border, indent: 64),
          _AccountRow(
            icon: Icons.logout_rounded,
            title: 'Logout',
            color: const Color(0xFFB91C1C),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;
  const _AccountRow({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}