import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fastaqim_quran/src/warsh/warsh_marker_svg.dart';

void main() {
  test(
    'marker extraction keeps nested transforms and paths, excludes text',
    () {
      const root = '<svg viewBox="-20 -30 100 100">';
      const outer = '<g transform="matrix(1.3333 0 0 -1.3333 -136 482)">';
      const marker =
          '<g id="ayah_markers"><g class="ayah-mark">'
          '<g transform="translate(157 205)"><path d="M0 0 L2 3"/></g>'
          '<path d="M3 4 L5 6"/></g></g>';
      final source =
          '$root<path id="hit-region" d="M0 0 L100 100"/>'
          '$outer<path id="quran-text" d="M5 6 L7 8"/>'
          '$marker<g><path id="header" d="M2 3 L4 5"/></g></g></svg>';
      final extracted = warshMarkerSvg(source);
      expect(extracted, '$root$outer$marker<g></g></g></svg>');
      expect(extracted, isNot(contains('quran-text')));
      expect(extracted, isNot(contains('hit-region')));
      expect(extracted, isNot(contains('header')));
    },
  );

  test(
    'bundled marker layers copy original paths and every marker unchanged',
    () {
      for (final page in ['001', '002', '003']) {
        final source = File('assets/warsh/svg/$page.svg').readAsStringSync();
        final extracted = warshMarkerSvg(source);
        final markerStart = source.indexOf('<g id="ayah_markers"');
        expect(markerStart, greaterThan(0));
        // Paths inside the retained marker group are copied byte-for-byte.
        for (final path in RegExp(r'<path\b[^>]*>').allMatches(extracted)) {
          expect(source, contains(path.group(0)!));
          expect(path.group(0), isNot(contains('ayahPolygon')));
        }
        expect(RegExp(r'<path\b').allMatches(extracted).length, greaterThan(5));
        expect(
          RegExp(r'class="ayah-mark"').allMatches(extracted).length,
          RegExp(r'class="ayah-mark"').allMatches(source).length,
        );
        expect(extracted.length, lessThan(source.length));
        expect(
          RegExp(r'<g\b').allMatches(extracted).length,
          RegExp(r'</g>').allMatches(extracted).length,
        );
        expect(extracted, contains('matrix(1.3333 0 0 -1.3333'));
      }
    },
  );

  test('missing or incomplete marker layers fail explicitly', () {
    for (final source in [
      '<svg><g><path d="M0 0 L2 3"/></g></svg>',
      '<svg><g id="ayah_markers"><path d="M0 0 L2 3"/></svg>',
      '<g id="ayah_markers"></g>',
    ]) {
      expect(() => warshMarkerSvg(source), throwsFormatException);
    }
  });
}
