import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran/src/riwayah.dart';

void main() {
  test('bookmarks with equal numbers in Hafs and Warsh remain distinct', () {
    const hafs = QuranAyahReference(
      riwayah: QuranRiwayah.hafs,
      surahNumber: 1,
      verseNumber: 1,
    );
    const warsh = QuranAyahReference(
      riwayah: QuranRiwayah.warsh,
      surahNumber: 1,
      verseNumber: 1,
    );
    const sameWarsh = QuranAyahReference(
      riwayah: QuranRiwayah.warsh,
      surahNumber: 1,
      verseNumber: 1,
    );
    final bookmarks = <QuranAyahReference, String>{
      hafs: 'Hafs opening',
      warsh: 'Warsh opening',
    };

    expect(bookmarks, hasLength(2));
    expect(bookmarks[sameWarsh], 'Warsh opening');
    expect(hafs.key, isNot(warsh.key));
    expect(warsh, sameWarsh);
  });
}
