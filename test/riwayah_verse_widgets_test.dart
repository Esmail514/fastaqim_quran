import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran/qcf_quran.dart';

class _LocalWarshBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes =
        await File(key.replaceFirst('packages/qcf_quran/', '')).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}

Future<void> _mount(
  WidgetTester tester,
  Widget child, {
  double width = 500,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: SizedBox(width: width, child: child))),
    ),
  );
  await tester.pumpAndSettle();
}

RenderParagraph _paragraph(WidgetTester tester, Type verseWidget) =>
    tester.renderObject<RenderParagraph>(
      find.descendant(
        of: find.byType(verseWidget),
        matching: find.byType(RichText),
      ),
    );

Offset _pointOnText(RenderParagraph paragraph, String text) {
  final body = paragraph.text.toPlainText();
  final start = body.indexOf(text);
  expect(
    start,
    greaterThanOrEqualTo(0),
    reason: 'Requested text must be visible.',
  );
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: start + text.length),
  );
  final nonEmpty = boxes.where((box) => !box.toRect().isEmpty).toList();
  expect(nonEmpty, isNotEmpty);
  return paragraph.localToGlobal(nonEmpty.first.toRect().center);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late WarshMushaf mushaf;

  setUpAll(() async {
    // The original bundled source is used. Loading it requests neither artwork
    // nor audio; all tests below remain offline.
    mushaf = await WarshMushaf.load(bundle: _LocalWarshBundle());
  });

  testWidgets('QcfVerse renders native Warsh text and paired font', (
    tester,
  ) async {
    final source = mushaf.getVerse(1, 1);
    await _mount(
      tester,
      QcfVerse(
        surahNumber: 1,
        verseNumber: 1,
        riwayah: QuranRiwayah.warsh,
        warshMushaf: mushaf,
      ),
    );
    final paragraph = _paragraph(tester, QcfVerse);
    expect(paragraph.text.toPlainText(), contains(source.textWithoutEndMarker));
    expect(paragraph.text.toPlainText(), contains(source.endMarker));
    expect(source.text, startsWith('اِ۬لْحَمْدُ'));
    expect(paragraph.text.toPlainText(), isNot(contains(getVerse(1, 1))));
    expect(paragraph.text.style!.fontFamily, 'packages/qcf_quran/QCF_Warsh');
    expect(tester.takeException(), isNull);
  });

  testWidgets('QcfVerse keeps taps and long presses with latest callbacks', (
    tester,
  ) async {
    final events = <String>[];
    Widget verse(int number, String tag) => QcfVerse(
      key: const ValueKey('same-warsh-verse'),
      surahNumber: 1,
      verseNumber: number,
      riwayah: QuranRiwayah.warsh,
      warshMushaf: mushaf,
      onTap: () => events.add('$tag:tap:$number'),
      onLongPress: () => events.add('$tag:hold:$number'),
      onLongPressUp: () => events.add('$tag:release:$number'),
    );
    await _mount(tester, verse(1, 'old'));
    var paragraph = _paragraph(tester, QcfVerse);
    var point = _pointOnText(
      paragraph,
      mushaf.getVerse(1, 1).textWithoutEndMarker,
    );
    await tester.tapAt(point);
    await tester.longPressAt(point);
    await tester.pump();
    expect(events, ['old:tap:1', 'old:hold:1', 'old:release:1']);
    await _mount(tester, verse(2, 'latest'));
    paragraph = _paragraph(tester, QcfVerse);
    point = _pointOnText(paragraph, mushaf.getVerse(1, 2).textWithoutEndMarker);
    await tester.tapAt(point);
    await tester.longPressAt(point);
    await tester.pump();
    expect(events, [
      'old:tap:1',
      'old:hold:1',
      'old:release:1',
      'latest:tap:2',
      'latest:hold:2',
      'latest:release:2',
    ]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
    'QcfVerses hidden markers preserve source and identify tapped ayah',
    (tester) async {
      final taps = <(int, int)>[];
      await _mount(
        tester,
        QcfVerses(
          surahNumber: 1,
          firstVerse: 1,
          lastVerse: 4,
          riwayah: QuranRiwayah.warsh,
          warshMushaf: mushaf,
          showVerseNumbers: false,
          fontSize: 22,
          onTap: (surah, verse) => taps.add((surah, verse)),
        ),
        width: 280,
      );
      final paragraph = _paragraph(tester, QcfVerses);
      final displayed = paragraph.text.toPlainText();
      for (var verse = 1; verse <= 4; verse++) {
        final original = mushaf.getVerse(1, verse);
        expect(displayed, contains(original.textWithoutEndMarker));
        expect(displayed, isNot(contains(original.endMarker)));
        expect(original.text.trimRight(), endsWith(original.endMarker));
        await tester.tapAt(
          _pointOnText(paragraph, original.textWithoutEndMarker),
        );
      }
      await tester.pump();
      expect(taps, [(1, 1), (1, 2), (1, 3), (1, 4)]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('QcfVerses marker taps follow Warsh refs and source formatter', (
    tester,
  ) async {
    final taps = <(int, int)>[];
    Widget verses({String Function(int)? formatter}) => QcfVerses(
      key: const ValueKey('same-warsh-range'),
      surahNumber: 1,
      firstVerse: 2,
      lastVerse: 4,
      riwayah: QuranRiwayah.warsh,
      warshMushaf: mushaf,
      fontSize: 22,
      verseNumberFormatter: formatter,
      onTap: (surah, verse) => taps.add((surah, verse)),
    );
    await _mount(tester, verses());
    var paragraph = _paragraph(tester, QcfVerses);
    for (var verse = 2; verse <= 4; verse++) {
      await tester.tapAt(
        _pointOnText(paragraph, mushaf.getVerse(1, verse).endMarker),
      );
    }
    await tester.pump();
    expect(taps, [(1, 2), (1, 3), (1, 4)]);
    await _mount(tester, verses(formatter: (number) => '[$number]'));
    paragraph = _paragraph(tester, QcfVerses);
    for (var verse = 2; verse <= 4; verse++) {
      expect(paragraph.text.toPlainText(), contains('[$verse]'));
      expect(
        paragraph.text.toPlainText(),
        isNot(contains(mushaf.getVerse(1, verse).endMarker)),
      );
    }
    await tester.tapAt(_pointOnText(paragraph, '[3]'));
    await tester.pump();
    expect(taps.last, (1, 3));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Warsh last Baqarah verse renders while Hafs-only 286 is rejected',
    (tester) async {
      expect(mushaf.getVerseCount(2), 285);
      await _mount(
        tester,
        QcfVerse(
          surahNumber: 2,
          verseNumber: 285,
          riwayah: QuranRiwayah.warsh,
          warshMushaf: mushaf,
          fontSize: 16,
        ),
      );
      expect(
        _paragraph(tester, QcfVerse).text.toPlainText(),
        contains(mushaf.getVerse(2, 285).textWithoutEndMarker),
      );
      await _mount(
        tester,
        QcfVerse(
          surahNumber: 2,
          verseNumber: 286,
          riwayah: QuranRiwayah.warsh,
          warshMushaf: mushaf,
        ),
      );
      expect(find.text('رقم الآية غير صالح في رواية ورش'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(QcfVerse),
          matching: find.byType(RichText),
        ),
        findsOneWidget, // The error Text's paragraph, rather than a Quran verse.
      );
      expect(tester.takeException(), isNull);
    },
  );
}
