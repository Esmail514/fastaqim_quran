import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:fastaqim_quran/fastaqim_quran.dart';

Future<(Uint8List, int)> _pixels(GlobalKey key) async {
  final boundary =
      key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final result = (Uint8List.fromList(data.buffer.asUint8List()), image.width);
  image.dispose();
  return result;
}

List<int> _crop((Uint8List, int) image, Rect rect, {bool ellipse = false}) => [
  for (var y = rect.top.ceil(); y < rect.bottom.floor(); y++)
    for (var x = rect.left.ceil(); x < rect.right.floor(); x++)
      if (!ellipse ||
          ((x + 0.5 - rect.center.dx) / (rect.width / 2)) *
                      ((x + 0.5 - rect.center.dx) / (rect.width / 2)) +
                  ((y + 0.5 - rect.center.dy) / (rect.height / 2)) *
                      ((y + 0.5 - rect.center.dy) / (rect.height / 2)) <=
              1)
        ...image.$1.sublist((y * image.$2 + x) * 4, (y * image.$2 + x + 1) * 4),
];

void main() {
  late WarshMushaf mushaf;
  final pages = <int, WarshPageData>{};
  setUpAll(() async {
    mushaf = await WarshMushaf.load();
    for (final number in [1, 2, 3]) {
      pages[number] = await mushaf.loadPage(number);
    }
  });
  testWidgets('hidden Warsh ayahs retain original markers without boxes', (
    tester,
  ) async {
    final key = GlobalKey();
    var hidden = false;
    final taps = <QuranAyahReference>[];
    await tester.binding.setSurfaceSize(const Size(414, 920));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    Future<void> mount() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: key,
              child: WarshPage(
                pageNumber: 1,
                mushaf: mushaf,
                theme: const QcfThemeData(
                  horizontalPadding: 0,
                  verticalPadding: 0,
                  pageBackgroundColor: Colors.white,
                ),
                isVerseHidden: (s, v) => hidden && v >= 3,
                onAyahTap: taps.add,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    }

    await mount();
    final page = pages[1]!;
    final artwork = tester.getRect(
      find.descendant(
        of: find.byType(WarshPage),
        matching: find.byType(GestureDetector),
      ),
    );
    Offset screen(Offset source) =>
        artwork.topLeft +
        Offset(
          (source.dx - page.viewBox.left) * artwork.width / page.viewBox.width,
          (source.dy - page.viewBox.top) * artwork.height / page.viewBox.height,
        );
    final original = (await tester.runAsync(() => _pixels(key)))!;
    hidden = true;
    await mount();
    final masked = (await tester.runAsync(() => _pixels(key)))!;
    // Independently recorded source marker centers on the original Fatiha SVG.
    for (final (verse, center) in [
      (3, const Offset(64.17, 85.13)),
      (4, const Offset(67.29, 117.27)),
      (5, const Offset(102.93, 148.88)),
      (6, const Offset(121.38, 180.91)),
      (7, const Offset(71.86, 210.88)),
    ]) {
      final rect = Rect.fromPoints(
        screen(center - const Offset(8.5, 12.5)),
        screen(center + const Offset(8.5, 12.5)),
      );
      final a = _crop(masked, rect, ellipse: true);
      final b = _crop(original, rect, ellipse: true);
      final deltas = [for (var i = 0; i < a.length; i++) (a[i] - b[i]).abs()];
      // Separately compiled vector layers can round edge antialiasing slightly.
      expect(
        deltas,
        everyElement(lessThanOrEqualTo(8)),
        reason: 'Marker $verse',
      );
      await tester.tapAt(screen(center));
      await tester.pump();
      expect(taps.last.verseNumber, verse);
    }
    // Interior and shared polygon edges must be plain page background.
    for (final point in [
      const Offset(140, 117),
      const Offset(160, 148),
      const Offset(130, 132),
      const Offset(110, 175),
    ]) {
      final p = screen(point);
      expect(
        _crop(masked, Rect.fromLTWH(p.dx - 1, p.dy - 1, 3, 3)),
        everyElement(255),
        reason: 'Text or rectangle remains at $point',
      );
    }
    // Save an actual render for visual review of the reported page.
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      final output = File('build/warsh-hidden-markers.png');
      output.parent.createSync(recursive: true);
      output.writeAsBytesSync(png.buffer.asUint8List());
      image.dispose();
    });
    hidden = false;
    await mount();
    expect((await tester.runAsync(() => _pixels(key)))!.$1, original.$1);
    expect(tester.takeException(), isNull);
  });

  for (final pageNumber in [1, 2, 3]) {
    for (final dark in [false, true]) {
      testWidgets('all markers remain on Warsh page $pageNumber, dark=$dark', (
        tester,
      ) async {
        final page = pages[pageNumber]!;
        final source =
            jsonDecode(
                  File(
                    'assets/warsh/pages/${pageNumber.toString().padLeft(3, '0')}.json',
                  ).readAsStringSync(),
                )
                as List;
        final key = GlobalKey();
        var active = false;
        Future<void> mount() async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: RepaintBoundary(
                  key: key,
                  child: WarshPage(
                    pageNumber: pageNumber,
                    mushaf: mushaf,
                    theme: QcfThemeData(
                      horizontalPadding: 0,
                      verticalPadding: 0,
                      pageBackgroundColor:
                          dark ? const Color(0xff151515) : Colors.white,
                      verseTextColor:
                          dark ? const Color(0xffe8e3d4) : Colors.black,
                    ),
                    isVerseHidden: active ? (s, v) => true : null,
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 400)),
          );
          await tester.pumpAndSettle();
          expect(find.byType(CircularProgressIndicator), findsNothing);
        }

        await mount();
        final artworkFinder = find.descendant(
          of: find.byType(WarshPage),
          matching: find.byType(GestureDetector),
        );
        final artwork = tester.getRect(artworkFinder);
        final originalRenderObject = tester.renderObject(artworkFinder);
        Offset screen(Offset point) =>
            artwork.topLeft +
            Offset(
              (point.dx - page.viewBox.left) *
                  artwork.width /
                  page.viewBox.width,
              (point.dy - page.viewBox.top) *
                  artwork.height /
                  page.viewBox.height,
            );
        final original = (await tester.runAsync(() => _pixels(key)))!;
        active = true;
        await mount();
        expect(tester.renderObject(artworkFinder), same(originalRenderObject));
        expect(tester.getRect(artworkFinder), artwork);
        final masked = (await tester.runAsync(() => _pixels(key)))!;
        for (final row in source) {
          if (row['x'] == null) continue; // No marker on an ayah continuation.
          final center = Offset(
            (row['x'] as num).toDouble(),
            (row['y'] as num).toDouble(),
          );
          // Compare the number and inner ornament area; exclude nearby text.
          final rect = Rect.fromPoints(
            screen(center - const Offset(5, 6)),
            screen(center + const Offset(5, 6)),
          );
          final before = _crop(original, rect);
          final after = _crop(masked, rect);
          expect(before.toSet().length, greaterThan(2));
          expect(
            [
              for (var i = 0; i < after.length; i++)
                (after[i] - before[i]).abs(),
            ],
            everyElement(lessThanOrEqualTo(8)),
            reason: 'Page $pageNumber marker ${row['ayahNumber']}',
          );
        }
        active = false;
        await mount();
        expect((await tester.runAsync(() => _pixels(key)))!.$1, original.$1);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('failed network markers retry without replacing the page', (
    tester,
  ) async {
    var requests = 0;
    var available = false;
    await http.runWithClient(
      () async {
        var hidden = false;
        final mushaf = WarshMushaf.fromData(
          verses: [
            WarshVerse(
              surahNumber: 1,
              verseNumber: 1,
              text: 'fixture',
              juzNumber: 1,
              pageNumbers: [1],
            ),
          ],
          pages: [
            WarshPageData(
              pageNumber: 1,
              viewBox: const Rect.fromLTWH(0, 0, 100, 100),
              svgUri: Uri.parse('https://example.test/marker-retry.svg'),
              regions: [
                WarshAyahRegion(
                  reference: const QuranAyahReference(
                    riwayah: QuranRiwayah.warsh,
                    surahNumber: 1,
                    verseNumber: 1,
                  ),
                  polygon: '0,0 100,0 100,100 0,100',
                ),
              ],
            ),
          ],
        );
        Future<void> mount() async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: WarshPage(
                  pageNumber: 1,
                  mushaf: mushaf,
                  isVerseHidden: hidden ? (s, v) => true : null,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
        }

        await mount();
        final artwork = find.descendant(
          of: find.byType(WarshPage),
          matching: find.byType(GestureDetector),
        );
        final original = tester.renderObject(artwork);
        hidden = true;
        await mount();
        expect(requests, 2);
        expect(tester.takeException(), isNull);
        const retry = 'تعذر تحميل أرقام الآيات، إعادة المحاولة';
        expect(find.text(retry), findsOneWidget);
        available = true;
        await tester.tap(find.text(retry));
        await tester.pumpAndSettle();
        expect(find.text(retry), findsNothing);
        expect(requests, 3);
        expect(tester.renderObject(artwork), same(original));
        hidden = false;
        await mount();
        hidden = true;
        await mount();
        expect(requests, 3);
        expect(tester.takeException(), isNull);
      },
      () => MockClient((_) async {
        requests++;
        return http.Response(
          '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
          '<path d="M10 10H90V90H10Z"/>'
          '${available ? '<g id="ayah_markers"><path d="M45 45H55V55H45Z"/></g>' : ''}'
          '</svg>',
          200,
        );
      }),
    );
  });
}
