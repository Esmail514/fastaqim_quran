import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran/qcf_quran.dart';

List<TextSpan> _verses(WidgetTester tester) {
  final spans = <TextSpan>[];
  final recognizers = <GestureRecognizer>{};
  void collect(InlineSpan span) {
    // The text and its end marker share the same ayah recognizer.
    if (span is TextSpan &&
        span.recognizer != null &&
        recognizers.add(span.recognizer!)) {
      spans.add(span);
    }
    if (span is TextSpan) {
      for (final child in span.children ?? <InlineSpan>[]) {
        collect(child);
      }
    }
  }

  for (final rich in tester.widgetList<RichText>(
    find.descendant(of: find.byType(QcfPage), matching: find.byType(RichText)),
  )) {
    collect(rich.text);
  }
  return spans;
}

void main() {
  testWidgets('switching gesture mode or page releases the old recognizers', (
    tester,
  ) async {
    Future<void> mount(
      int page, {
      VoidCallback? tap,
      VoidCallback? longPress,
    }) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QcfPage(
            pageNumber: page,
            onTap: tap == null ? null : (_, _) => tap(),
            onLongPress: longPress == null ? null : (_, _) => longPress(),
          ),
        ),
      ),
    );
    var calls = 0;
    await mount(1, tap: () => calls++);
    final tap = _verses(tester).first.recognizer;
    expect(tap, isA<TapGestureRecognizer>());
    await mount(1, longPress: () => calls++);
    final longPress = _verses(tester).first.recognizer;
    expect(longPress, isA<LongPressGestureRecognizer>());
    expect(longPress, isNot(same(tap)));
    await mount(2, longPress: () => calls++);
    expect(_verses(tester).first.recognizer, isNot(same(longPress)));
    await mount(2);
    expect(_verses(tester), isEmpty);
    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('page rebuilds reuse recognizers and call the latest callback', (
    tester,
  ) async {
    var calls = 0;
    Future<void> mount(int page, VoidCallback callback) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QcfPage(
            pageNumber: 1,
            currentPage: page,
            onLongPress: (_, _) => callback(),
          ),
        ),
      ),
    );
    await mount(1, () => calls = 1);
    final before = _verses(tester);
    expect(before, hasLength(7));
    await mount(2, () => calls = 2);
    final after = _verses(tester);
    expect(after.length, before.length);
    for (var i = 0; i < before.length; i++) {
      expect(after[i].recognizer, same(before[i].recognizer));
      expect(after[i].text, before[i].text);
    }
    (after.first.recognizer as LongPressGestureRecognizer).onLongPress!();
    expect(calls, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
