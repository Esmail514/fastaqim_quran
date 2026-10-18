import 'package:flutter_test/flutter_test.dart';
import 'package:fastaqim_quran/src/riwayah.dart';

void main() {
  test('word references preserve narration and one-based word position', () {
    const first = QuranWordReference(
      riwayah: QuranRiwayah.hafs,
      surahNumber: 2,
      verseNumber: 2,
      wordPosition: 4,
    );
    const same = QuranWordReference(
      riwayah: QuranRiwayah.hafs,
      surahNumber: 2,
      verseNumber: 2,
      wordPosition: 4,
    );
    const anotherWord = QuranWordReference(
      riwayah: QuranRiwayah.hafs,
      surahNumber: 2,
      verseNumber: 2,
      wordPosition: 5,
    );
    const warsh = QuranWordReference(
      riwayah: QuranRiwayah.warsh,
      surahNumber: 2,
      verseNumber: 2,
      wordPosition: 4,
    );

    expect(first.key, 'hafs:2:2:4');
    expect(first, same);
    expect(first.hashCode, same.hashCode);
    final references = {first, anotherWord, warsh};
    expect(references.add(same), isFalse);
    expect(references, hasLength(3));
    expect(
      first.ayahReference,
      const QuranAyahReference(
        riwayah: QuranRiwayah.hafs,
        surahNumber: 2,
        verseNumber: 2,
      ),
    );
    expect(first.toString(), first.key);
    expect(
      () => QuranWordReference(
        riwayah: QuranRiwayah.hafs,
        surahNumber: 2,
        verseNumber: 2,
        wordPosition: 0,
      ),
      throwsAssertionError,
    );
  });

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
