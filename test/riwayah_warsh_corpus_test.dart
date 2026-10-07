import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qcf_quran/qcf_quran.dart';

Map<String, dynamic> _object(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

List<Map<String, dynamic>> _rows(String path) =>
    (jsonDecode(File(path).readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();

class _FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final localPath = key.replaceFirst('packages/qcf_quran/', '');
    final bytes = await File(localPath).readAsBytes();
    return ByteData.sublistView(bytes);
  }
}

void main() {
  test(
    'Warsh page regions cover the complete source corpus without Hafs IDs',
    () {
      final manifest = _object('assets/warsh/manifest.json');
      final source = _rows(manifest['textAsset'] as String);
      final sourceByReference = <(int, int), Map<String, dynamic>>{
        for (final ayah in source)
          (ayah['sura_no'] as int, ayah['aya_no'] as int): ayah,
      };
      expect(source, hasLength(6214));
      expect(sourceByReference, hasLength(6214));
      expect(source.where((ayah) => ayah['sura_no'] == 2), hasLength(285));
      expect(source.first['aya_text'], startsWith('اِ۬لْحَمْدُ'));
      expect(manifest['ayahCount'], source.length);

      final pages = (manifest['pages'] as List).cast<Map<String, dynamic>>();
      expect(pages, hasLength(604));
      expect(manifest['pageCount'], pages.length);
      expect(
        pages.map((page) => page['number']),
        orderedEquals(List.generate(604, (index) => index + 1)),
      );
      final covered = <(int, int)>{};
      final fragmentPages = <(int, int), Set<int>>{};
      for (final page in pages) {
        final number = page['number'] as int;
        final regions = _rows(page['geometryAsset'] as String);
        expect(regions, isNotEmpty, reason: 'Empty Warsh page $number');
        expect(regions, hasLength(page['ayahRegionCount'] as int));
        final viewBox = (page['viewBox'] as List).cast<num>();
        expect(viewBox, hasLength(4));
        expect(viewBox[2], greaterThan(0));
        expect(viewBox[3], greaterThan(0));
        for (final region in regions) {
          final reference = (
            region['surahNumber'] as int,
            region['ayahNumber'] as int,
          );
          expect(
            sourceByReference.containsKey(reference),
            isTrue,
            reason: 'Unknown $reference on Warsh page $number',
          );
          expect(region['polygon'], isA<String>());
          expect((region['polygon'] as String).trim(), isNotEmpty);
          final sourcePages = RegExp(r'\d+')
              .allMatches(sourceByReference[reference]!['page'] as String)
              .map((match) => int.parse(match.group(0)!));
          expect(
            sourcePages,
            contains(number),
            reason: 'Warsh $reference is on a different source page',
          );
          covered.add(reference);
          fragmentPages.putIfAbsent(reference, () => <int>{}).add(number);
        }
        if (page['svgAsset'] != null) {
          expect(File(page['svgAsset'] as String).existsSync(), isTrue);
        }
        expect(Uri.parse(page['svgUri'] as String).scheme, 'https');
      }
      expect(covered, unorderedEquals(sourceByReference.keys));

      final splitSource = source.where(
        (ayah) => RegExp(r'\d+').allMatches(ayah['page'] as String).length > 1,
      );
      expect(splitSource, isNotEmpty);
      for (final ayah in splitSource) {
        final reference = (ayah['sura_no'] as int, ayah['aya_no'] as int);
        final expectedPages = RegExp(r'\d+')
            .allMatches(ayah['page'] as String)
            .map((match) => int.parse(match.group(0)!));
        expect(
          fragmentPages[reference],
          unorderedEquals(expectedPages),
          reason: 'Missing continuation of Warsh $reference',
        );
      }
      expect(File(manifest['fontAsset'] as String).existsSync(), isTrue);
    },
  );

  test(
    'Warsh loader preserves source text and parses every page region',
    () async {
      final manifest = _object('assets/warsh/manifest.json');
      final source = _rows(manifest['textAsset'] as String);
      final mushaf = await WarshMushaf.load(bundle: _FileAssetBundle());
      expect(mushaf.verseCount, 6214);
      expect(mushaf.pageCount, 604);
      for (final original in source) {
        final verse = mushaf.getVerse(
          original['sura_no'] as int,
          original['aya_no'] as int,
        );
        expect(verse.text, original['aya_text']);
        expect(verse.juzNumber, original['jozz']);
        expect(verse.reference.riwayah, QuranRiwayah.warsh);
      }
      for (var pageNumber = 1; pageNumber <= 604; pageNumber++) {
        final page = await mushaf.loadPage(pageNumber);
        expect(page.pageNumber, pageNumber);
        for (final region in page.regions) {
          final bounds = region.path.getBounds();
          expect(
            bounds.isEmpty,
            isFalse,
            reason: 'Empty polygon on page $pageNumber: ${region.reference}',
          );
          expect(
            bounds.left.isFinite &&
                bounds.top.isFinite &&
                bounds.right.isFinite &&
                bounds.bottom.isFinite,
            isTrue,
          );
          expect(
            bounds.overlaps(page.viewBox),
            isTrue,
            reason: 'Polygon outside page $pageNumber: ${region.reference}',
          );
        }
      }
      expect(mushaf.getPageNumber(2, 285), greaterThan(1));
      expect(() => mushaf.getVerse(2, 286), throwsArgumentError);
    },
  );
}
