import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';

void main() {
  testWidgets('Haltestellen-Screen wird angezeigt', (WidgetTester tester) async {
    await tester.pumpWidget(const KaAbfahrtApp());
    await tester.pump();

    expect(
      find.text('Tippen, um Haltestellen zu suchen.'),
      findsOneWidget,
    );
  });
}
