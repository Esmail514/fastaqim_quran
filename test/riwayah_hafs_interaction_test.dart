import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_riwayat/mushaf_riwayat.dart';

Offset _markerCenter(WidgetTester tester) {
  final finder = find.descendant(
    of: find.byType(QcfPage),
    matching: find.byType(RichText),
  );
  expect(finder, findsOneWidget);
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final text = paragraph.text.toPlainText();
  final marker = getVerseNumberQCF(1, 1);
  final start = text.indexOf(marker);
  expect(start, greaterThanOrEqualTo(0));
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: start + marker.length),
  );
  expect(boxes, isNotEmpty);
  return paragraph.localToGlobal(boxes.first.toRect().center);
}

void main() {
  testWidgets('Hafs verse marker taps identify its own verse', (tester) async {
    final tapped = <(int, int)>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QcfPage(
            pageNumber: 1,
            theme: const QcfThemeData(showHeader: false, showBasmala: false),
            onTap: (surah, verse) => tapped.add((surah, verse)),
          ),
        ),
      ),
    );

    await tester.tapAt(_markerCenter(tester));
    await tester.pump();
    expect(tapped, [(1, 1)]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Hafs tap and long press coexist and retain latest callbacks', (
    tester,
  ) async {
    final taps = <(String, int, int)>[];
    final holds = <(String, int, int)>[];
    final releases = <(String, int, int)>[];
    final cancels = <(int, int)>[];
    final references = <QuranAyahReference>[];
    Future<void> mount(String label) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QcfPage(
              key: const ValueKey('same-hafs'),
              pageNumber: 1,
              theme: const QcfThemeData(showHeader: false, showBasmala: false),
              onTap: (s, v) => taps.add((label, s, v)),
              onAyahTap: references.add,
              onLongPress: (s, v) => holds.add((label, s, v)),
              onLongPressUp: (s, v) => releases.add((label, s, v)),
              onLongPressCancel: (s, v) => cancels.add((s, v)),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final label in ['first', 'latest']) {
      await mount(label);
      final marker = _markerCenter(tester);
      await tester.tapAt(marker);
      // A short tap can cancel a pending long-press recognizer normally.
      cancels.clear();
      await tester.longPressAt(marker);
      await tester.pump();
      expect(
        cancels,
        isEmpty,
        reason: 'A successful long press must end rather than cancel',
      );
    }
    expect(taps, [('first', 1, 1), ('latest', 1, 1)]);
    expect(holds, [('first', 1, 1), ('latest', 1, 1)]);
    expect(releases, [('first', 1, 1), ('latest', 1, 1)]);
    expect(cancels, isEmpty);
    expect(references, [
      const QuranAyahReference(
        riwayah: QuranRiwayah.hafs,
        surahNumber: 1,
        verseNumber: 1,
      ),
      const QuranAyahReference(
        riwayah: QuranRiwayah.hafs,
        surahNumber: 1,
        verseNumber: 1,
      ),
    ]);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
