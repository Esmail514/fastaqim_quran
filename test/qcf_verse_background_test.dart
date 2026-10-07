import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran/qcf_quran.dart';

void main() {
  for (final color in [
    Colors.transparent,
    const Color(0x0100ff00),
    Colors.green,
    Colors.green.withValues(alpha: 0.0001),
  ]) {
    testWidgets('background preserves 8-bit transparency: $color', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QcfVerse(
              surahNumber: 1,
              verseNumber: 1,
              backgroundColor: color,
            ),
          ),
        ),
      );
      final richText = tester.widget<RichText>(
        find.descendant(
          of: find.byType(QcfVerse),
          matching: find.byType(RichText),
        ),
      );
      final span = richText.text as TextSpan;
      final expected = (color.toARGB32() >> 24) == 0 ? null : color;
      expect(span.style?.backgroundColor, expected);
    });
  }
}
