import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fastaqim_quran/fastaqim_quran.dart';

void main() {
  test('surah names use the actual bundled Unicode font mapping', () {
    expect(SurahFontHelper.getSurahGlyph(1), '\ue001');
    expect(SurahFontHelper.getSurahGlyph(33), '\ue021');
    expect(SurahFontHelper.getSurahGlyph(102), '\ue102');
    expect(SurahFontHelper.getSurahGlyph(114), '\ue072');
    expect(SurahFontHelper.getSurahGlyph(0), isEmpty);
    expect(SurahFontHelper.getSurahGlyph(115), isEmpty);

    final formatted = SurahFontHelper.formatSurahText('surah033 surah102');
    final spans = formatted.children!.whereType<TextSpan>().toList();
    expect(spans.map((span) => span.text), ['\ue021', ' ', '\ue102']);
    expect(spans.first.style?.fontFamily, 'packages/fastaqim_quran/surahname');
  });

  testWidgets('headers render the names of surahs 33 and 102 as font glyphs', (
    tester,
  ) async {
    for (final surah in [33, 102]) {
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: HeaderWidget(suraNumber: surah))),
      );
      final text = tester.widget<RichText>(
        find.descendant(
          of: find.byType(HeaderWidget),
          matching: find.byType(RichText),
        ),
      );
      expect(text.text.toPlainText(), SurahFontHelper.getSurahGlyph(surah));
      expect(tester.takeException(), isNull);
    }
  });
}
