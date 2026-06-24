import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:health_companion/screens/v2/bp_v2.dart';
import 'package:health_companion/screens/v2/dashboard_v2.dart';
import 'package:health_companion/screens/v2/mood_v2.dart';
import 'package:health_companion/screens/v2/steps_v2.dart';
import 'package:health_companion/screens/v2/v2_theme.dart';
import 'package:health_companion/screens/v2/water_v2.dart';
import 'package:health_companion/screens/v2/weight_v2.dart';

/// iPhone 14 Pro Max logical size (430 × 932) — wider than iPhone 13 Pro
/// to avoid RenderFlex overflow on the hero cards while still being a
/// realistic phone aspect ratio.
const _surfaceSize = Size(430, 932);

Future<void> _pumpAtPhoneSize(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(_surfaceSize);
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });

  await tester.pumpWidget(
    MaterialApp(
      theme: buildV2LightTheme(),
      debugShowCheckedModeBanner: false,
      home: child,
    ),
  );

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _capture(WidgetTester tester, String fileName) async {
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('goldens/$fileName'),
  );
}

void main() {
  setUpAll(() {
    // Font files are bundled as assets (see pubspec.yaml), so disable
    // google_fonts runtime network fetching to avoid hangs in CI.
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('screenshot: dashboard_v2', (tester) async {
    await _pumpAtPhoneSize(tester, const DashboardV2());
    await _capture(tester, '01_dashboard.png');
  });

  testWidgets('screenshot: mood_v2', (tester) async {
    await _pumpAtPhoneSize(tester, const MoodV2());
    await _capture(tester, '02_mood.png');
  });

  testWidgets('screenshot: water_v2', (tester) async {
    await _pumpAtPhoneSize(tester, const WaterV2());
    await _capture(tester, '03_water.png');
  });

  testWidgets('screenshot: steps_v2', (tester) async {
    await _pumpAtPhoneSize(tester, const StepsV2());
    await _capture(tester, '04_steps.png');
  });

  testWidgets('screenshot: weight_v2', (tester) async {
    await _pumpAtPhoneSize(tester, const WeightV2());
    await _capture(tester, '05_weight.png');
  });

  testWidgets('screenshot: bp_v2', (tester) async {
    await _pumpAtPhoneSize(tester, const BpV2());
    await _capture(tester, '06_bp.png');
  });
}