import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_riwayat/mushaf_riwayat.dart';

void main() {
  test('page counts use inclusive ranges, not final verse numbers', () {
    expect(getVerseCountByPage(3), 11);
    for (var page = 1; page <= 604; page++) {
      final expected = getPageData(page).fold<int>(
        0,
        (count, range) =>
            count + (range['end'] as int) - (range['start'] as int) + 1,
      );
      expect(getVerseCountByPage(page), expected, reason: 'Page $page');
    }
  });
}
