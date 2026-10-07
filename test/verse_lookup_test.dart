import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_riwayat/mushaf_riwayat.dart';

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
}
