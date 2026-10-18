import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fastaqim_quran/fastaqim_quran.dart';
import 'package:fastaqim_quran/src/data/quran_text.dart' as legacy;

List<Map<String, dynamic>> _source() =>
    (jsonDecode(
              File('assets/hafs/source/hafsData_v2-0.json').readAsStringSync(),
            )
            as List)
        .cast<Map<String, dynamic>>();

String _readableText(Map<String, dynamic> source) {
  final text = source['aya_text'] as String;
  final marker = String.fromCharCode(0xfbff + (source['aya_no'] as int));
  expect(text.trimRight(), endsWith(marker));
  // The default getVerse contract omits the original font's numeric marker.
  return text
      .trimRight()
      .substring(0, text.trimRight().length - marker.length)
      .trimRight();
}

void main() {
  test(
    'all Hafs readable texts match publisher IDs and preserve QCF artwork',
    () {
      final source = _source();
      expect(source, hasLength(6236));
      expect(quranText, hasLength(source.length));
      final originals = <(int, int), Map>{
        for (final row in legacy.quranText)
          (row['surah_number'] as int, row['verse_number'] as int): row as Map,
      };
      for (final ayah in source) {
        final surah = ayah['sura_no'] as int;
        final verse = ayah['aya_no'] as int;
        final row = getVerseData(surah, verse)!;
        final original = originals[(surah, verse)]!;
        final expectedText = _readableText(ayah);
        expect(row, hasLength(6));
        expect(row['surah_number'], surah);
        expect(row['verse_number'], verse);
        expect(row['content'], expectedText, reason: 'Hafs $surah:$verse text');
        expect(row['text_normal'], ayah['aya_text_emlaey']);
        expect(HafsText.getSourceVerse(surah, verse), ayah['aya_text']);
        expect(HafsText.getSearchVerse(surah, verse), ayah['aya_text_emlaey']);
        expect(getVerse(surah, verse), expectedText);
        expect(row['qcfData'], original['qcfData']);
        expect(row['qcfv4data'], original['qcfv4data']);
        expect(getVerseQCF(surah, verse), original['qcfData']);
        expect(
          getPageNumber(surah, verse),
          ayah['page'],
          reason: 'Hafs page for $surah:$verse',
        );
      }
      expect(
        () => getVerseData(1, 1)!['content'] = 'changed',
        throwsUnsupportedError,
      );
      expect(() => quranText.clear(), throwsUnsupportedError);
    },
  );

  test(
    'Hafs opening, final Baqarah and final surah no longer return Warsh/null',
    () {
      final byReference = <(int, int), Map<String, dynamic>>{
        for (final ayah in _source())
          (ayah['sura_no'] as int, ayah['aya_no'] as int): ayah,
      };
      for (final ref in [(1, 1), (1, 2), (1, 4), (2, 1), (2, 286), (114, 6)]) {
        expect(getVerse(ref.$1, ref.$2), _readableText(byReference[ref]!));
      }
      expect(getVerseData(1, 1)!['text_normal'], 'بسم الله الرحمن الرحيم');
      expect(getVerseData(1, 2)!['text_normal'], 'الحمد لله رب العالمين');
      expect(getVerseData(1, 4)!['text_normal'], 'مالك يوم الدين');
      expect(getVerseData(2, 1)!['text_normal'], 'الم');
      expect(getVerseData(114, 6)!['text_normal'], 'من الجنة والناس');
    },
  );

  test(
    'normal and diacritized Hafs searches return the matching readable ayah',
    () {
      final normal = searchWords('الحمد لله رب العالمين');
      expect(
        normal['result'],
        contains(equals({'suraNumber': 1, 'verseNumber': 2})),
      );
      final firstSource = _source().firstWhere(
        (row) => row['sura_no'] == 1 && row['aya_no'] == 2,
      );
      final diacritized = searchWords(_readableText(firstSource));
      expect(
        diacritized['result'],
        contains(equals({'suraNumber': 1, 'verseNumber': 2})),
      );
      expect(
        diacritized['result'],
        isNot(contains(equals({'suraNumber': 1, 'verseNumber': 1}))),
      );
      final lastSource = _source().last;
      final finalAyah = searchWords(_readableText(lastSource));
      expect(
        finalAyah['result'],
        contains(equals({'suraNumber': 114, 'verseNumber': 6})),
      );
    },
  );
}
