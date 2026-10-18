import 'dart:convert';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:path_drawing/path_drawing.dart';

import '../riwayah.dart';

/// The unchanged source text and numbering of an ayah in Madinah Warsh.
class WarshVerse {
  final int surahNumber;
  final int verseNumber;
  final String text;
  final int juzNumber;
  final List<int> pageNumbers;

  WarshVerse({
    required this.surahNumber,
    required this.verseNumber,
    required this.text,
    required this.juzNumber,
    required Iterable<int> pageNumbers,
  }) : pageNumbers = List.unmodifiable(pageNumbers) {
    if (surahNumber < 1 ||
        surahNumber > 114 ||
        verseNumber < 1 ||
        juzNumber < 1 ||
        juzNumber > 30 ||
        this.pageNumbers.isEmpty ||
        this.pageNumbers.any((page) => page < 1 || page > 604) ||
        this.pageNumbers.toSet().length != this.pageNumbers.length) {
      throw ArgumentError('Invalid Warsh ayah reference, juz or pages.');
    }
  }

  QuranAyahReference get reference => QuranAyahReference(
    riwayah: QuranRiwayah.warsh,
    surahNumber: surahNumber,
    verseNumber: verseNumber,
  );

  /// Source glyph of the end marker, rendered by the paired Warsh font.
  String get endMarker {
    final value = text.trimRight();
    final expected = String.fromCharCode(0xfbff + verseNumber);
    return value.endsWith(expected) ? expected : '';
  }

  /// A display slice; [text] and the bundled source are never rewritten.
  String get textWithoutEndMarker {
    final marker = endMarker;
    if (marker.isEmpty) return text;
    final value = text.trimRight();
    return value.substring(0, value.length - marker.length).trimRight();
  }

  factory WarshVerse.fromSource(Map<String, dynamic> value) {
    final pageParts = value['page'].toString().split('-');
    final first = int.parse(pageParts.first);
    final last = int.parse(pageParts.last);
    return WarshVerse(
      surahNumber: value['sura_no'] as int,
      verseNumber: value['aya_no'] as int,
      text: value['aya_text'] as String,
      juzNumber: value['jozz'] as int,
      pageNumbers: [for (var p = first; p <= last; p++) p],
    );
  }
}

/// An original polygon covering one ayah's printed lines and end marker.
class WarshAyahRegion {
  final QuranAyahReference reference;
  final String polygon;
  late final Path path = _parsePolygon(polygon);

  WarshAyahRegion({required this.reference, required this.polygon}) {
    if (reference.riwayah != QuranRiwayah.warsh || polygon.trim().isEmpty) {
      throw ArgumentError('A Warsh region requires a Warsh ayah and polygon.');
    }
  }

  static Path _parsePolygon(String value) {
    if (RegExp(r'^[Mm]').hasMatch(value.trim())) {
      return parseSvgPathData(value);
    }
    final numbers =
        value.trim().split(RegExp(r'[\s,]+')).map(double.parse).toList();
    if (numbers.length < 6 ||
        numbers.length.isOdd ||
        numbers.any((v) => !v.isFinite)) {
      throw const FormatException('Invalid Warsh ayah polygon.');
    }
    return Path()..addPolygon([
      for (var i = 0; i < numbers.length; i += 2)
        Offset(numbers[i], numbers[i + 1]),
    ], true);
  }
}

/// Original page artwork and hit regions in the same SVG coordinate space.
class WarshPageData {
  final int pageNumber;
  final Rect viewBox;
  final List<WarshAyahRegion> regions;
  final Uri? svgUri;

  /// Package-relative SVG asset. The first three pages are bundled.
  final String? svgAsset;

  WarshPageData({
    required this.pageNumber,
    required this.viewBox,
    required Iterable<WarshAyahRegion> regions,
    this.svgUri,
    this.svgAsset,
  }) : regions = List.unmodifiable(regions) {
    if (pageNumber < 1 ||
        pageNumber > 604 ||
        viewBox.isEmpty ||
        !viewBox.left.isFinite ||
        !viewBox.top.isFinite ||
        !viewBox.width.isFinite ||
        !viewBox.height.isFinite) {
      throw ArgumentError('Invalid Warsh page number or viewBox.');
    }
  }

  QuranAyahReference? ayahAt(Offset sourcePosition) {
    for (final region in regions) {
      if (region.path.contains(sourcePosition)) return region.reference;
    }
    return null;
  }
}

/// Warsh's independent text, page index and lazy page geometry.
///
/// Loading does not fetch audio or page artwork. Pages 4..604 use pinned
/// network SVGs by default; a widget's picture builder can supply local art.
class WarshMushaf {
  static Future<WarshMushaf>? _defaultLoad;
  static const _manifestAsset =
      'packages/fastaqim_quran/assets/warsh/manifest.json';

  final String editionId;
  final String fontFamily;
  final Map<(int, int), WarshVerse> _verses;
  final Map<int, int> _surahCounts;
  final Map<int, Future<WarshPageData>> _pageCache = {};
  final Map<int, Map<String, dynamic>> _descriptors;
  final AssetBundle? _bundle;

  WarshMushaf._({
    required this.editionId,
    required this.fontFamily,
    required Iterable<WarshVerse> verses,
    required Map<int, Map<String, dynamic>> descriptors,
    AssetBundle? bundle,
  }) : _verses = {
         for (final verse in verses)
           (verse.surahNumber, verse.verseNumber): verse,
       },
       _surahCounts = {},
       _descriptors = descriptors,
       _bundle = bundle {
    for (final verse in _verses.values) {
      _surahCounts.update(verse.surahNumber, (v) => v + 1, ifAbsent: () => 1);
    }
  }

  /// Supply verified custom artwork/geometry, including an entirely offline
  /// edition. References must use the same numbering as the supplied text.
  /// Pages must be numbered consecutively from 1 for PageviewQuran navigation.
  factory WarshMushaf.fromData({
    required Iterable<WarshVerse> verses,
    required Iterable<WarshPageData> pages,
    String editionId = 'custom-warsh',
    String fontFamily = 'QCF_Warsh',
  }) {
    final verseList = verses.toList();
    final pageList = pages.toList();
    if (verseList.map((v) => (v.surahNumber, v.verseNumber)).toSet().length !=
        verseList.length) {
      throw ArgumentError('Custom Warsh verses contain duplicate references.');
    }
    final pageNumbers = pageList.map((p) => p.pageNumber).toSet();
    if (pageNumbers.length != pageList.length ||
        pageNumbers.isEmpty ||
        !List.generate(
          pageList.length,
          (i) => i + 1,
        ).every(pageNumbers.contains)) {
      throw ArgumentError(
        'Custom Warsh pages must be unique and numbered 1..N.',
      );
    }
    final result = WarshMushaf._(
      editionId: editionId,
      fontFamily: fontFamily,
      verses: verseList,
      descriptors: {},
    );
    for (final entry in result._surahCounts.entries) {
      for (var verse = 1; verse <= entry.value; verse++) {
        if (!result._verses.containsKey((entry.key, verse))) {
          throw ArgumentError('Custom Warsh ayah numbering has a gap.');
        }
      }
    }
    for (final verse in verseList) {
      if (!verse.pageNumbers.every(pageNumbers.contains)) {
        throw ArgumentError(
          'A custom Warsh ayah refers to an unavailable page.',
        );
      }
    }
    for (final page in pageList) {
      for (final region in page.regions) {
        final verse = result.getVerse(
          region.reference.surahNumber,
          region.reference.verseNumber,
        );
        if (!verse.pageNumbers.contains(page.pageNumber)) {
          throw ArgumentError(
            'A custom Warsh region is on the wrong ayah page.',
          );
        }
      }
      result._pageCache[page.pageNumber] = Future.value(page);
    }
    return result;
  }

  static Future<WarshMushaf> load({AssetBundle? bundle}) {
    if (bundle != null) return _load(bundle);
    return _defaultLoad ??= _load(rootBundle).catchError((Object error) {
      _defaultLoad = null;
      throw error;
    });
  }

  static Future<WarshMushaf> _load(AssetBundle bundle) async {
    final manifest =
        jsonDecode(await bundle.loadString(_manifestAsset))
            as Map<String, dynamic>;
    final text =
        jsonDecode(
              await bundle.loadString(
                'packages/fastaqim_quran/${manifest['textAsset']}',
              ),
            )
            as List<dynamic>;
    final verses =
        text
            .map((v) => WarshVerse.fromSource(v as Map<String, dynamic>))
            .toList();
    final descriptors = {
      for (final p in manifest['pages'] as List<dynamic>)
        (p as Map<String, dynamic>)['number'] as int: p,
    };
    final result = WarshMushaf._(
      editionId: manifest['editionId'] as String,
      fontFamily: manifest['fontFamily'] as String,
      verses: verses,
      descriptors: descriptors,
      bundle: bundle,
    );
    if (manifest['schemaVersion'] != 1 ||
        manifest['riwayah'] != 'warsh' ||
        manifest['countingSystem'] != 'madani-last' ||
        result.verseCount != manifest['ayahCount'] ||
        descriptors.length != manifest['pageCount'] ||
        result._surahCounts.length != 114 ||
        verses.length != result.verseCount ||
        result.verseCount != 6214 ||
        descriptors.length != 604) {
      throw const FormatException('Warsh source and manifest do not agree.');
    }
    for (final entry in result._surahCounts.entries) {
      for (var v = 1; v <= entry.value; v++) {
        if (!result._verses.containsKey((entry.key, v))) {
          throw const FormatException('Warsh ayah numbering has a gap.');
        }
      }
    }
    return result;
  }

  int get verseCount => _verses.length;
  int get pageCount =>
      _descriptors.isEmpty ? _pageCache.length : _descriptors.length;
  Iterable<WarshVerse> get verses => _verses.values;

  int getVerseCount(int surahNumber) =>
      _surahCounts[surahNumber] ??
      (throw RangeError.range(surahNumber, 1, 114, 'surahNumber'));

  WarshVerse getVerse(int surahNumber, int verseNumber) =>
      _verses[(surahNumber, verseNumber)] ??
      (throw ArgumentError('Unknown Warsh ayah $surahNumber:$verseNumber.'));

  List<int> getPageNumbers(int surahNumber, int verseNumber) =>
      getVerse(surahNumber, verseNumber).pageNumbers;

  int getPageNumber(int surahNumber, int verseNumber) =>
      getPageNumbers(surahNumber, verseNumber).first;

  Future<WarshPageData> loadPage(int pageNumber) {
    if (_pageCache.containsKey(pageNumber)) return _pageCache[pageNumber]!;
    if (!_descriptors.containsKey(pageNumber)) {
      throw RangeError.range(pageNumber, 1, pageCount, 'pageNumber');
    }
    return _pageCache[pageNumber] = _loadPage(pageNumber).catchError((
      Object error,
    ) {
      _pageCache.remove(pageNumber);
      throw error;
    });
  }

  Future<WarshPageData> _loadPage(int pageNumber) async {
    final descriptor = _descriptors[pageNumber]!;
    final raw =
        jsonDecode(
              await _bundle!.loadString(
                'packages/fastaqim_quran/${descriptor['geometryAsset']}',
              ),
            )
            as List<dynamic>;
    final regions =
        raw.map((entry) {
          final value = entry as Map<String, dynamic>;
          final verse = getVerse(
            value['surahNumber'] as int,
            value['ayahNumber'] as int,
          );
          return WarshAyahRegion(
            reference: verse.reference,
            polygon: value['polygon'] as String,
          );
        }).toList();
    final box =
        (descriptor['viewBox'] as List<dynamic>)
            .map((v) => (v as num).toDouble())
            .toList();
    return WarshPageData(
      pageNumber: pageNumber,
      viewBox: Rect.fromLTWH(box[0], box[1], box[2], box[3]),
      regions: regions,
      svgUri: Uri.parse(descriptor['svgUri'] as String),
      svgAsset: descriptor['svgAsset'] as String?,
    );
  }
}
