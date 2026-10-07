import 'package:flutter_test/flutter_test.dart';

import 'package:mushaf_riwayat/mushaf_riwayat.dart';

void main() {
  test('convertToArabicNumber converts western digits to Arabic-Indic', () {
    expect(convertToArabicNumber('123'), '١٢٣');
  });
}
