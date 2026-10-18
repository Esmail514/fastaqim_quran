import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fastaqim_quran/fastaqim_quran.dart';

Future<void> _mount(WidgetTester tester, Widget child, {Size? size}) =>
    tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(
            size: size ?? const Size(500, 900),
            textScaler: const TextScaler.linear(1.25),
          ),
          child: Scaffold(body: child),
        ),
      ),
    );

RichText _text(WidgetTester tester, Type type) => tester.widget<RichText>(
  find.descendant(of: find.byType(type), matching: find.byType(RichText)),
);

void main() {
  const theme = QcfThemeData(
    fontSize: 43,
    showHeader: false,
    showBasmala: false,
  );

  testWidgets(
    'a Hafs verse range does not begin with an inherited page newline',
    (tester) async {
      expect(getVerseQCF(1, 2, verseEndSymbol: false), startsWith('\n'));
      await _mount(
        tester,
        const QcfVerses(
          surahNumber: 1,
          firstVerse: 2,
          lastVerse: 3,
          showVerseNumbers: false,
        ),
      );
      expect(
        _text(tester, QcfVerses).text.toPlainText(),
        isNot(startsWith('\n')),
      );
    },
  );

  testWidgets(
    'Hafs verse and range honor theme size and explicit size priority',
    (tester) async {
      for (final override in <double?>[null, 19]) {
        await _mount(
          tester,
          QcfVerse(
            surahNumber: 1,
            verseNumber: 1,
            theme: theme,
            fontSize: override,
          ),
        );
        expect(_text(tester, QcfVerse).text.style?.fontSize, override ?? 43);
        await _mount(
          tester,
          QcfVerses(
            surahNumber: 1,
            firstVerse: 1,
            lastVerse: 2,
            theme: theme,
            fontSize: override,
          ),
        );
        final text = _text(tester, QcfVerses);
        final verses = (text.text as TextSpan).children!;
        expect(
          verses.every((verse) => verse.style?.fontSize == (override ?? 43)),
          isTrue,
        );
        expect(text.textScaler.scale(20), 25);
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('Hafs page honors font overrides in portrait and landscape', (
    tester,
  ) async {
    for (final size in [const Size(500, 900), const Size(900, 500)]) {
      for (final override in <double?>[null, 19]) {
        await _mount(
          tester,
          QcfPage(pageNumber: 3, theme: theme, fontSize: override),
          size: size,
        );
        expect(_text(tester, QcfPage).text.style?.fontSize, override ?? 43);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
