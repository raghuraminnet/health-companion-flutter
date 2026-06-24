import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Direction B: Friendly Wellness
/// Light default, per-metric colors, Plus Jakarta Sans.
class V2Colors {
  // Surface
  static const bg = Color(0xFFFAFAFA);
  static const surface = Colors.white;
  static const surfaceAlt = Color(0xFFF4F4F6);
  static const border = Color(0xFFEBEBEF);
  static const borderStrong = Color(0xFFE0E0E5);

  // Text
  static const text = Color(0xFF0F172A);
  static const textMuted = Color(0xFF64748B);
  static const textSubtle = Color(0xFF94A3B8);

  // Per-metric (used as accent + tinted bg)
  static const bp = Color(0xFFEF4444);
  static const bpSoft = Color(0xFFFEE2E2);
  static const mood = Color(0xFFF59E0B);
  static const moodSoft = Color(0xFFFEF3C7);
  static const water = Color(0xFF06B6D4);
  static const waterSoft = Color(0xFFCFFAFE);
  static const steps = Color(0xFF10B981);
  static const stepsSoft = Color(0xFFD1FAE5);
  static const weight = Color(0xFF8B5CF6);
  static const weightSoft = Color(0xFFEDE9FE);

  // Brand
  static const brand = Color(0xFF6D28D9);
  static const brandSoft = Color(0xFFEDE9FE);
}

class V2Type {
  static TextTheme textTheme(TextTheme base) =>
      GoogleFonts.plusJakartaSansTextTheme(base).copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          fontSize: 44,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
          color: V2Colors.text,
          height: 1.05,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: V2Colors.text,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: V2Colors.text,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: V2Colors.text,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: V2Colors.text,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: V2Colors.text,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: V2Colors.textMuted,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: V2Colors.text,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: V2Colors.textMuted,
          letterSpacing: 0.4,
        ),
      );
}

ThemeData buildV2LightTheme() {
  final base = ThemeData.light(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: V2Colors.bg,
    colorScheme: const ColorScheme.light(
      primary: V2Colors.brand,
      secondary: V2Colors.water,
      surface: V2Colors.surface,
      error: V2Colors.bp,
    ),
    textTheme: V2Type.textTheme(base.textTheme),
    appBarTheme: AppBarTheme(
      backgroundColor: V2Colors.bg,
      foregroundColor: V2Colors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: V2Colors.text,
      ),
    ),
    cardTheme: CardThemeData(
      color: V2Colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: V2Colors.border, width: 1),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: V2Colors.surface,
      elevation: 0,
      height: 76,
      indicatorColor: V2Colors.brandSoft,
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: V2Colors.text,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: V2Colors.surfaceAlt,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: V2Colors.brand, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: V2Colors.text,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}

/// Dark "Focus" theme — direction A accent on B's typography.
ThemeData buildV2DarkTheme() {
  const bg = Color(0xFF0B0B10);
  const surface = Color(0xFF14141C);
  const text = Color(0xFFF5F5F7);

  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: bg,
    colorScheme: const ColorScheme.dark(
      primary: V2Colors.steps,
      secondary: V2Colors.water,
      surface: surface,
      error: V2Colors.bp,
    ),
    textTheme: V2Type.textTheme(base.textTheme).apply(
      bodyColor: text,
      displayColor: text,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg,
      foregroundColor: text,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: Color(0xFF1F1F2A), width: 1),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      elevation: 0,
      height: 76,
      indicatorColor: V2Colors.stepsSoft.withValues(alpha: 0.2),
    ),
  );
}