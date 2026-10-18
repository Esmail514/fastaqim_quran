import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fastaqim_quran/fastaqim_quran.dart';

RenderParagraph _paragraph(WidgetTester tester) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byType(QcfPage),
        matching: find.byType(RichText),
      ),
    );

List<TextSpan> _ayahSpans(RenderParagraph paragraph) {
  final result = <TextSpan>[];
  void collect(InlineSpan span) {
    if (span is! TextSpan) return;
    if (span.recognizer != null && span.children != null) {
      result.add(span);
      return;
    }
    for (final child in span.children ?? <InlineSpan>[]) {
      collect(child);
    }
  }

  collect(paragraph.text);
  return result;
}

List<Rect> _glyphBoxes(RenderParagraph paragraph) {
  final text = paragraph.text.toPlainText(includeSemanticsLabels: false);
  return [
    for (var offset = 0; offset < text.length; offset++)
      ...paragraph
          .getBoxesForSelection(
            TextSelection(baseOffset: offset, extentOffset: offset + 1),
          )
          .map((box) => box.toRect()),
  ];
}

Future<int> _darkPixels(GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final bytes = data.buffer.asUint8List();
  var count = 0;
  for (var index = 0; index < bytes.length; index += 4) {
    if (bytes[index] < 180 &&
        bytes[index + 1] < 180 &&
        bytes[index + 2] < 180 &&
        bytes[index + 3] > 200) {
      count++;
    }
  }
  image.dispose();
  return count;
}

Future<List<int>> _pixel(GlobalKey key, Offset local) async {
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final offset = (local.dy.floor() * image.width + local.dx.floor()) * 4;
  final result = data.buffer.asUint8List().sublist(offset, offset + 4);
  image.dispose();
  return result;
}

void main() {
  testWidgets('hidden Hafs text keeps glyph layout, markers and tap targets', (
    tester,
  ) async {
    final taps = <(int, int)>[];
    final key = GlobalKey();
    var hidden = false;
    Future<void> mount() => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: key,
            child: QcfPage(
              pageNumber: 1,
              theme: const QcfThemeData(showHeader: false, showBasmala: false),
              isVerseHidden: (s, v) => hidden && s == 1 && v == 1,
              onTap: (s, v) => taps.add((s, v)),
            ),
          ),
        ),
      ),
    );
    await mount();
    final before = _paragraph(tester);
    final originalText = before.text.toPlainText(includeSemanticsLabels: false);
    final originalBoxes = _glyphBoxes(before);
    final originalInk = await tester.runAsync(() => _darkPixels(key));
    final verseSpans = _ayahSpans(before);
    final originalVisibleStyle = verseSpans.elementAt(1).style;
    final firstMarker = getVerseNumberQCF(1, 1);
    final markerOffset = originalText.indexOf(firstMarker);
    final markerBox =
        before
            .getBoxesForSelection(
              TextSelection(
                baseOffset: markerOffset,
                extentOffset: markerOffset + 1,
              ),
            )
            .first
            .toRect();
    hidden = true;
    await mount();
    final after = _paragraph(tester);
    expect(after.text.toPlainText(includeSemanticsLabels: false), originalText);
    expect(_glyphBoxes(after), originalBoxes);
    expect(
      await tester.runAsync(() => _darkPixels(key)),
      lessThan(originalInk!),
    );
    final afterSpans = _ayahSpans(after);
    final first = afterSpans.first;
    expect(first.style!.color, Colors.transparent);
    expect(first.semanticsLabel, '');
    expect(
      (first.children!.single as TextSpan).style!.color,
      isNot(Colors.transparent),
    );
    expect(afterSpans.elementAt(1).style, originalVisibleStyle);
    expect(after.text.toPlainText(), isNot(contains(first.text!)));
    await tester.tapAt(after.localToGlobal(markerBox.center));
    await tester.pump();
    expect(taps, [(1, 1)]);
    hidden = false;
    await mount();
    expect(_paragraph(tester).text.toPlainText(), originalText);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PageviewQuran forwards ayah visibility to Hafs and Warsh', (
    tester,
  ) async {
    bool hideFirst(int surah, int verse) => surah == 1 && verse == 1;
    for (final riwayah in QuranRiwayah.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PageviewQuran(riwayah: riwayah, isVerseHidden: hideFirst),
          ),
        ),
      );
      final page = tester.widget<QcfPage>(find.byType(QcfPage).first);
      expect(page.isVerseHidden!(1, 1), isTrue);
      expect(page.isVerseHidden!(1, 2), isFalse);
      if (riwayah == QuranRiwayah.warsh) {
        final warsh = tester.widget<WarshPage>(find.byType(WarshPage).first);
        expect(warsh.isVerseHidden, same(hideFirst));
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Warsh masks one ayah without changing geometry or other ink', (
    tester,
  ) async {
    const first = QuranAyahReference(
      riwayah: QuranRiwayah.warsh,
      surahNumber: 1,
      verseNumber: 1,
    );
    const second = QuranAyahReference(
      riwayah: QuranRiwayah.warsh,
      surahNumber: 1,
      verseNumber: 2,
    );
    final mushaf = WarshMushaf.fromData(
      verses: [
        WarshVerse(
          surahNumber: 1,
          verseNumber: 1,
          text: 'first',
          juzNumber: 1,
          pageNumbers: [1, 2],
        ),
        WarshVerse(
          surahNumber: 1,
          verseNumber: 2,
          text: 'second',
          juzNumber: 1,
          pageNumbers: [1],
        ),
      ],
      pages: [
        WarshPageData(
          pageNumber: 1,
          viewBox: const Rect.fromLTWH(-20, -30, 100, 100),
          regions: [
            WarshAyahRegion(
              reference: first,
              polygon:
                  'M-10,-20 L20,-20 L20,10 L-10,10 Z '
                  'M-10,30 L20,30 L20,50 L-10,50 Z',
            ),
            WarshAyahRegion(
              reference: second,
              polygon: '30,20 60,20 60,50 30,50',
            ),
          ],
        ),
        WarshPageData(
          pageNumber: 2,
          viewBox: const Rect.fromLTWH(-20, -30, 100, 100),
          regions: [
            WarshAyahRegion(
              reference: first,
              polygon: '-10,-20 20,-20 20,10 -10,10',
            ),
          ],
        ),
      ],
    );
    final taps = <QuranAyahReference>[];
    final key = GlobalKey();
    var hidden = false;
    var pageNumber = 1;
    // Reuse the same callback to verify a changed hidden set repaints.
    bool hideFirst(int s, int v) => hidden && s == 1 && v == 1;
    Future<void> mount() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 200,
                child: RepaintBoundary(
                  key: key,
                  child: WarshPage(
                    pageNumber: pageNumber,
                    mushaf: mushaf,
                    theme: const QcfThemeData(
                      horizontalPadding: 0,
                      verticalPadding: 0,
                      pageBackgroundColor: Colors.white,
                    ),
                    pictureBuilder:
                        (_, _) => const ColoredBox(color: Colors.black),
                    isVerseHidden: hideFirst,
                    onAyahTap: taps.add,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await mount();
    final originalRect = tester.getRect(find.byType(WarshPage));
    final firstPoint = originalRect.topLeft + const Offset(50, 50);
    expect(await tester.runAsync(() => _pixel(key, const Offset(50, 50))), [
      0,
      0,
      0,
      255,
    ]);
    hidden = true;
    await mount();
    expect(tester.getRect(find.byType(WarshPage)), originalRect);
    expect(await tester.runAsync(() => _pixel(key, const Offset(50, 50))), [
      255,
      255,
      255,
      255,
    ]);
    expect(await tester.runAsync(() => _pixel(key, const Offset(130, 130))), [
      0,
      0,
      0,
      255,
    ]);
    expect(await tester.runAsync(() => _pixel(key, const Offset(50, 145))), [
      255,
      255,
      255,
      255,
    ]);
    await tester.tapAt(firstPoint);
    await tester.pump();
    expect(taps, [first]);
    pageNumber = 2;
    await mount();
    expect(await tester.runAsync(() => _pixel(key, const Offset(50, 50))), [
      255,
      255,
      255,
      255,
    ]);
    hidden = false;
    await mount();
    expect(await tester.runAsync(() => _pixel(key, const Offset(50, 50))), [
      0,
      0,
      0,
      255,
    ]);
    expect(tester.takeException(), isNull);
  });
}
