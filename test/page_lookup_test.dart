import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran/qcf_quran.dart';

void main() {
  test(
    'page lookup matches every original range and survives invalidation',
    () {
      for (var pass = 0; pass < 2; pass++) {
        invalidateVerseIndex();
        for (var page = 1; page <= totalPagesCount; page++) {
          for (final range in getPageData(page)) {
            for (
              var verse = range['start'] as int;
              verse <= (range['end'] as int);
              verse++
            ) {
              expect(getPageNumber(range['surah'] as int, verse), page);
            }
          }
        }
      }
    },
  );

  test('invalid references retain the existing error messages', () {
    for (final surah in [-1, 0, 115]) {
      expect(
        () => getPageNumber(surah, 1),
        throwsA('No Surah found with given surahNumber'),
      );
    }
    for (final reference in [(1, 0), (1, 8), (2, 287), (3, -99999)]) {
      expect(
        () => getPageNumber(reference.$1, reference.$2),
        throwsA('Invalid verse number.'),
      );
    }
  });

  test('diagnostic full corpus page lookup timing', () {
    var checksum = 0;
    final timer = Stopwatch()..start();
    for (var pass = 0; pass < 10; pass++) {
      for (final verse in quranText) {
        checksum += getPageNumber(
          verse['surah_number'] as int,
          verse['verse_number'] as int,
        );
      }
    }
    timer.stop();
    expect(checksum, greaterThan(0));
    // ignore: avoid_print
    print('62360 page lookups: ${timer.elapsedMilliseconds}ms');
  });
}
