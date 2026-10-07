import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_riwayat/mushaf_riwayat.dart';

void main() {
  testWidgets('bundled Warsh artwork renders real ink and matching ayah hits', (
    tester,
  ) async {
    final mushaf = (await tester.runAsync(() => WarshMushaf.load()))!;
    final taps = <QuranAyahReference>[];
    final samples = <(int, Offset, int, int)>[
      (1, const Offset(120, 52), 1, 1),
      (2, const Offset(100, 52), 2, 1),
      (3, const Offset(150, 20), 2, 5),
    ];
    final boundaryKey = GlobalKey();
    for (final (number, sourcePoint, surah, verse) in samples) {
      final page = await mushaf.loadPage(number);
      taps.clear();
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: Scaffold(
            body: RepaintBoundary(
              key: boundaryKey,
              child: WarshPage(
                key: ValueKey(number),
                pageNumber: number,
                mushaf: mushaf,
                onAyahTap: taps.add,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      // SVG decoding may finish on an isolate after the geometry is available.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      final picture = find.descendant(
        of: find.byType(WarshPage),
        matching: find.byType(GestureDetector),
      );
      expect(picture, findsOneWidget);
      final pictureRect = tester.getRect(picture);
      final target =
          pictureRect.topLeft +
          Offset(
            (sourcePoint.dx - page.viewBox.left) /
                page.viewBox.width *
                pictureRect.width,
            (sourcePoint.dy - page.viewBox.top) /
                page.viewBox.height *
                pictureRect.height,
          );
      await tester.tapAt(target);
      await tester.pump();
      expect(taps, [
        QuranAyahReference(
          riwayah: QuranRiwayah.warsh,
          surahNumber: surah,
          verseNumber: verse,
        ),
      ]);

      await tester.runAsync(() async {
        final boundary =
            boundaryKey.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1);
        final rgba =
            (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        final bytes = rgba.buffer.asUint8List();
        var darkPixels = 0;
        for (var index = 0; index < bytes.length; index += 4) {
          if (bytes[index] < 180 &&
              bytes[index + 1] < 180 &&
              bytes[index + 2] < 180 &&
              bytes[index + 3] > 200) {
            darkPixels++;
          }
        }
        expect(
          darkPixels,
          greaterThan(1000),
          reason: 'Page $number contains no rendered Quran artwork',
        );
        final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        final output = File('build/warsh-page-$number.png');
        output.parent.createSync(recursive: true);
        output.writeAsBytesSync(png.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
}
