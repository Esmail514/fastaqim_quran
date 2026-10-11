import 'package:flutter/widgets.dart';

/// Helper to map surah numbers or "surahXXX" strings to font glyphs.
class SurahFontHelper {
  /// The font family name used for surah names.
  static const String fontFamily = 'surahname';

  /// Maps a surah number (1-114) to the bundled font's Unicode glyph.
  static String getSurahGlyph(int surahNumber) {
    if (surahNumber < 1 || surahNumber > 114) return '';

    // The bundled surah-name-v2 cmap assigns surah 102 to E102 instead of
    // E066. Unicode glyphs also avoid its missing "surah033" ligature.
    return String.fromCharCode(
      surahNumber == 102 ? 0xe102 : 0xe000 + surahNumber,
    );
  }

  /// Processes a string to replace "surahXXX" patterns with the correct font glyphs.
  static TextSpan formatSurahText(
    String text, {
    TextStyle? style,
    String? package = 'mushaf_riwayat',
  }) {
    final RegExp regExp = RegExp(r'surah(\d{3})');
    final List<InlineSpan> children = [];
    int lastMatchEnd = 0;

    for (final Match match in regExp.allMatches(text)) {
      if (match.start > lastMatchEnd) {
        children.add(TextSpan(text: text.substring(lastMatchEnd, match.start)));
      }

      final String surahNumStr = match.group(1)!;
      final int surahNumber = int.parse(surahNumStr);

      children.add(
        TextSpan(
          text: getSurahGlyph(surahNumber),
          style: (style ?? const TextStyle()).copyWith(
            fontFamily: fontFamily,
            package: package,
          ),
        ),
      );

      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      children.add(TextSpan(text: text.substring(lastMatchEnd)));
    }

    return TextSpan(children: children, style: style);
  }
}
