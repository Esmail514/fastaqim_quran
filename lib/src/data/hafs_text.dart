import 'hafs_source_data.dart';
import 'quran_text.dart' as legacy;

/// Original KFGQPC Hafs v2.0 readable text, independent of page font glyphs.
/// The bundled JSON is preserved byte-for-byte; the generated Dart records
/// make the existing synchronous helpers available without an asset await.
abstract final class HafsText {
  static const fontFamily = 'QCF_HafsUnicode';

  static final Map<(int, int), (String, String)> _source = {
    for (final (surah, verse, text, searchText) in hafsSourceVersesData)
      (surah, verse): (text, searchText),
  };

  /// Source text including its end-marker glyph, using [fontFamily].
  static String getSourceVerse(int surahNumber, int verseNumber) =>
      _row(surahNumber, verseNumber).$1;

  /// Publisher-provided imlaei search text, without generating Quran wording.
  static String getSearchVerse(int surahNumber, int verseNumber) =>
      _row(surahNumber, verseNumber).$2;

  /// A display slice without the numbered end marker; source text is intact.
  static String getVerse(int surahNumber, int verseNumber) {
    final source = getSourceVerse(surahNumber, verseNumber).trimRight();
    final marker = String.fromCharCode(0xfbff + verseNumber);
    return source.endsWith(marker)
        ? source.substring(0, source.length - marker.length).trimRight()
        : source;
  }

  static (String, String) _row(int surahNumber, int verseNumber) =>
      _source[(surahNumber, verseNumber)] ??
      (throw ArgumentError('Unknown Hafs ayah $surahNumber:$verseNumber.'));
}

/// The public Hafs corpus retains its six-field shape and original page glyphs.
/// Legacy readable fields had Warsh text joined by array position, including
/// null text in the final 22 records. These two fields now come from Hafs's
/// original publisher source, joined explicitly by surah and ayah number.
final List quranText = _buildHafsCorpus();

List _buildHafsCorpus() {
  if (hafsSourceVersesData.length != 6236 || HafsText._source.length != 6236) {
    throw StateError('Invalid Hafs source coverage.');
  }
  return List.unmodifiable([
    for (final row in legacy.quranText)
      Map<String, dynamic>.unmodifiable({
        ...Map<String, dynamic>.from(row as Map),
        'content': HafsText.getVerse(
          row['surah_number'] as int,
          row['verse_number'] as int,
        ),
        'text_normal': HafsText.getSearchVerse(
          row['surah_number'] as int,
          row['verse_number'] as int,
        ),
      }),
  ]);
}
