import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_riwayat/mushaf_riwayat.dart';

const _warshReference = QuranAyahReference(
  riwayah: QuranRiwayah.warsh,
  surahNumber: 1,
  verseNumber: 1,
);

WarshMushaf _mushaf() => WarshMushaf.fromData(
  verses: [
    WarshVerse(
      surahNumber: 1,
      verseNumber: 1,
      text: 'fixture',
      juzNumber: 1,
      pageNumbers: [1, 2],
    ),
  ],
  pages: [
    for (final page in [1, 2])
      WarshPageData(
        pageNumber: page,
        viewBox: const Rect.fromLTWH(0, 0, 100, 200),
        regions: [
          WarshAyahRegion(
            reference: _warshReference,
            polygon: '20,20 80,20 80,100 20,100',
          ),
        ],
      ),
  ],
);

Widget _picture(BuildContext context, WarshPageData page) => ColoredBox(
  key: ValueKey('page-picture-${page.pageNumber}'),
  color: Colors.white,
);

Future<void> _tapHafsMarker(WidgetTester tester) async {
  final finder = find.descendant(
    of: find.byType(QcfPage),
    matching: find.byType(RichText),
  );
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final text = paragraph.text.toPlainText();
  final marker = getVerseNumberQCF(1, 1);
  final start = text.indexOf(marker);
  expect(start, greaterThanOrEqualTo(0));
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: start + marker.length),
  );
  expect(boxes, isNotEmpty);
  await tester.tapAt(paragraph.localToGlobal(boxes.first.toRect().center));
  await tester.pump();
}

Future<void> _tapWarsh(WidgetTester tester, int page) async {
  final artwork = tester.getRect(find.byKey(ValueKey('page-picture-$page')));
  await tester.tapAt(
    artwork.topLeft + Offset(artwork.width / 2, artwork.height / 4),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'QcfPage switches riwayah and returns matching typed references',
    (tester) async {
      final mushaf = _mushaf();
      final typed = <QuranAyahReference>[];
      final legacy = <(int, int)>[];
      Future<void> mount(QuranRiwayah riwayah) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: QcfPage(
                key: const ValueKey('same-page'),
                pageNumber: 1,
                riwayah: riwayah,
                warshMushaf: mushaf,
                warshPagePictureBuilder: _picture,
                theme: const QcfThemeData(
                  showHeader: false,
                  showBasmala: false,
                ),
                onTap: (s, v) => legacy.add((s, v)),
                onAyahTap: typed.add,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      expect(const QcfPage(pageNumber: 1).riwayah, QuranRiwayah.hafs);
      await mount(QuranRiwayah.hafs);
      await _tapHafsMarker(tester);
      await mount(QuranRiwayah.warsh);
      await _tapWarsh(tester, 1);
      await mount(QuranRiwayah.hafs);
      await _tapHafsMarker(tester);
      expect(typed.map((ref) => ref.riwayah), [
        QuranRiwayah.hafs,
        QuranRiwayah.warsh,
        QuranRiwayah.hafs,
      ]);
      expect(
        typed.every((ref) => ref.surahNumber == 1 && ref.verseNumber == 1),
        isTrue,
      );
      expect(legacy, [(1, 1), (1, 1), (1, 1)]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('PageviewQuran forwards Warsh navigation and ayah interactions', (
    tester,
  ) async {
    final controller = PageController();
    addTearDown(controller.dispose);
    final pages = <int>[];
    final typed = <QuranAyahReference>[];
    final legacy = <(int, int)>[];
    expect(const PageviewQuran().riwayah, QuranRiwayah.hafs);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PageviewQuran(
            controller: controller,
            riwayah: QuranRiwayah.warsh,
            warshMushaf: _mushaf(),
            warshPagePictureBuilder: _picture,
            onPageChanged: pages.add,
            onAyahTap: typed.add,
            onTap: (s, v) => legacy.add((s, v)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await _tapWarsh(tester, 1);
    controller.jumpToPage(1);
    await tester.pumpAndSettle();
    await _tapWarsh(tester, 2);
    expect(pages, [2]);
    expect(typed, [_warshReference, _warshReference]);
    expect(legacy, [(1, 1), (1, 1)]);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
