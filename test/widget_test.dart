import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kago/main.dart';

/// Phone-shaped surface so trip search (header + form + expanded results) lays out without overflow.
Future<void> _pumpApp(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() async {
    await tester.binding.setSurfaceSize(null);
  });
  await tester.pumpWidget(const KaAbfahrtApp());
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Haltestellen tab shows empty search hint', (WidgetTester tester) async {
    await _pumpApp(tester);

    expect(
      find.text('Tippen, um Haltestellen zu suchen.'),
      findsOneWidget,
    );
  });

  testWidgets('Verbindung tab shows trip search subtitle', (WidgetTester tester) async {
    await _pumpApp(tester);

    await tester.tap(find.text('Verbindung'));
    await tester.pumpAndSettle();

    expect(find.text('Von Haltestelle zu Haltestelle'), findsOneWidget);
  });
}
