/// The narration and printed ayah numbering used by a mushaf.
///
/// Hafs uses the existing Kufan corpus. Warsh uses the Madinah Warsh
/// edition and its own ayah numbering; the same numbers need not name
/// the same passage in both editions.
enum QuranRiwayah { hafs, warsh }

/// An ayah reference that retains its narration when passed to an action.
class QuranAyahReference {
  final QuranRiwayah riwayah;
  final int surahNumber;
  final int verseNumber;

  const QuranAyahReference({
    required this.riwayah,
    required this.surahNumber,
    required this.verseNumber,
  }) : assert(surahNumber >= 1 && surahNumber <= 114),
       assert(verseNumber >= 1);

  String get key => '${riwayah.name}:$surahNumber:$verseNumber';

  @override
  bool operator ==(Object other) =>
      other is QuranAyahReference &&
      riwayah == other.riwayah &&
      surahNumber == other.surahNumber &&
      verseNumber == other.verseNumber;

  @override
  int get hashCode => Object.hash(riwayah, surahNumber, verseNumber);

  @override
  String toString() => key;
}
