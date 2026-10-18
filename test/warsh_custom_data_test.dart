import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fastaqim_quran/fastaqim_quran.dart';

WarshVerse _verse(int number, {List<int> pages = const [1]}) => WarshVerse(
  surahNumber: 1,
  verseNumber: number,
  text: 'fixture',
  juzNumber: 1,
  pageNumbers: pages,
);

WarshPageData _page({bool region = false}) => WarshPageData(
  pageNumber: 1,
  viewBox: const Rect.fromLTWH(0, 0, 100, 100),
  regions: [
    if (region)
      WarshAyahRegion(
        reference: _verse(1).reference,
        polygon: '0,0 100,0 100,100 0,100',
      ),
  ],
);

void main() {
  test('Warsh verses reject empty or out-of-bounds page references', () {
    for (final pages in <List<int>>[
      [],
      [0],
      [605],
      [1, 1],
    ]) {
      expect(() => _verse(1, pages: pages), throwsArgumentError);
    }
    expect(() => _verse(0), throwsArgumentError);
  });

  test('custom Warsh data rejects gaps before verse rendering', () {
    expect(
      () => WarshMushaf.fromData(
        verses: [_verse(1), _verse(3)],
        pages: [_page()],
      ),
      throwsArgumentError,
    );
  });

  test('custom Warsh data rejects ayahs pointing to missing pages', () {
    expect(
      () => WarshMushaf.fromData(
        verses: [
          _verse(1, pages: [2]),
        ],
        pages: [_page()],
      ),
      throwsArgumentError,
    );
  });

  test('custom Warsh regions must use the ayah source pages', () {
    final secondPage = WarshPageData(
      pageNumber: 2,
      viewBox: const Rect.fromLTWH(0, 0, 100, 100),
      regions: [],
    );
    expect(
      () => WarshMushaf.fromData(
        verses: [
          _verse(1, pages: [2]),
        ],
        pages: [_page(region: true), secondPage],
      ),
      throwsArgumentError,
    );
    final valid = WarshMushaf.fromData(
      verses: [_verse(1)],
      pages: [_page(region: true)],
    );
    expect(valid.getVerseCount(1), 1);
    expect(valid.getPageNumber(1, 1), 1);
  });
}
