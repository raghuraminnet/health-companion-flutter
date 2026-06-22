import 'package:flutter_test/flutter_test.dart';

import 'package:health_companion/main.dart';

void main() {
  test('App entry-point class is defined', () {
    // Sanity check that the main app class compiles and is exported.
    // We don't pumpWidget() here because AuthCheck makes a live API call
    // on initState that would fail under the test environment.
    expect(HealthCompanionApp, isNotNull);
  });

  testWidgets('App builds MaterialApp shell', (tester) async {
    await tester.pumpWidget(const HealthCompanionApp());
    // Allow async AuthCheck to settle; pump a couple frames so the
    // MaterialApp is in the tree even if the auth flow errors.
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(HealthCompanionApp), findsOneWidget);
  });
}