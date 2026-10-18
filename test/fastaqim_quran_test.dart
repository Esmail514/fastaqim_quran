import 'package:flutter_test/flutter_test.dart';

import 'package:fastaqim_quran/fastaqim_quran.dart';

void main() {
  test('convertToArabicNumber converts western digits to Arabic-Indic', () {
    expect(convertToArabicNumber('123'), '١٢٣');
  });
}
