import 'package:flutter_test/flutter_test.dart';
import 'package:fastaqim_quran/fastaqim_quran.dart';

void main() {
  test('indexed reads preserve all six fields for all 6236 source records', () {
    expect(quranText.length, 6236);
    for (final original in quranText) {
      final row = getVerseData(
        original['surah_number'] as int,
        original['verse_number'] as int,
      );
      expect(row, original);
      expect(row!.length, 6);
    }
  });

  test('invalid references cannot collide with another indexed verse', () {
    expect(getVerseData(0, 1), isNull);
    expect(getVerseData(115, 1), isNull);
    expect(getVerseData(1, 0), isNull);
    expect(getVerseData(1, 8), isNull);
    expect(getVerseData(1, 100001), isNull);
    expect(getVerseData(3, -99999), isNull);
  });

  test('returned records cannot mutate the rendering index', () {
    final row = getVerseData(1, 1)!;
    expect(() => row['content'] = 'changed', throwsUnsupportedError);
    expect(getVerseData(1, 1), quranText.first);
    invalidateVerseIndex();
    expect(getVerseData(1, 1), quranText.first);
  });

  test('QCF glyph lookups reject references with colliding packed keys', () {
    for (final (surah, verse) in [(0, 100001), (1, 100001), (3, -99999)]) {
      expect(() => getVerseQCF(surah, verse), throwsA(isA<String>()));
      expect(() => getVerseNumberQCF(surah, verse), throwsA(isA<String>()));
    }
    expect(getVerseQCF(1, 1), quranText.first['qcfData']);
    expect(getVerseNumberQCF(1, 1), isNotEmpty);
  });
}
