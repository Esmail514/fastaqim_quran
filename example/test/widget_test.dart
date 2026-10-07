// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:mushaf_riwayat_example/main.dart';

void main() {
  testWidgets('opens the Hafs and Warsh mushaf example', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    final entry = find.text('مصحف حفص وورش — النقر وروابط التلاوات');
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.text('حفص'), findsOneWidget);
    expect(find.text('ورش'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
