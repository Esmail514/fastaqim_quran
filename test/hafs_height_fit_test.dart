import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fastaqim_quran/fastaqim_quran.dart';

const _portrait = Size(414, 920);
const _pageTheme = QcfThemeData(
  showHeader: false,
  showBasmala: false,
  verseNumberColor: Color(0xFF2E7D32),
);

// The package's widgets use package-qualified asset names even when this test
// runs from the package itself. Read those same files, rather than substitutes.
class _PackageAssets extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final path = key.replaceFirst('packages/fastaqim_quran/', '');
    final file = File(path);
    if (await file.exists()) {
      return ByteData.sublistView(await file.readAsBytes());
    }
    return rootBundle.load(key);
  }
}

Future<void> _loadFont(String family, String path) async {
  final loader = FontLoader('packages/fastaqim_quran/$family');
  loader.addFont(File(path).readAsBytes().then(_fontData));
  await loader.load();
}

// FontLoader accepts SFNT (TTF/OTF), so decompress the bundled WOFF container.
// The font tables and glyph outlines are copied unchanged from the real asset.
ByteData _fontData(Uint8List bytes) {
  final source = ByteData.sublistView(bytes);
  if (source.getUint32(0) != 0x774f4646) return source;
  final count = source.getUint16(12);
  final output = ByteData(source.getUint32(16));
  output.setUint32(0, source.getUint32(4));
  output.setUint16(4, count);
  var power = 1;
  var selector = 0;
  while (power * 2 <= count) {
    power *= 2;
    selector++;
  }
  output.setUint16(6, power * 16);
  output.setUint16(8, selector);
  output.setUint16(10, count * 16 - power * 16);
  var offset = 12 + count * 16;
  for (var index = 0; index < count; index++) {
    final entry = 44 + index * 20;
    final start = source.getUint32(entry + 4);
    final compressedLength = source.getUint32(entry + 8);
    final length = source.getUint32(entry + 12);
    final compressed = bytes.sublist(start, start + compressedLength);
    final table =
        compressedLength < length
            ? ZLibDecoder().convert(compressed)
            : compressed;
    final destination = 12 + index * 16;
    output.setUint32(destination, source.getUint32(entry));
    output.setUint32(destination + 4, source.getUint32(entry + 16));
    output.setUint32(destination + 8, offset);
    output.setUint32(destination + 12, length);
    output.buffer.asUint8List().setRange(offset, offset + length, table);
    offset = (offset + length + 3) & ~3;
  }
  return output;
}

Future<void> _mount(
  WidgetTester tester, {
  int page = 79,
  bool fit = false,
  Size size = _portrait,
  QcfThemeData theme = _pageTheme,
  GlobalKey? boundaryKey,
  bool Function(int, int)? hidden,
  void Function(int, int)? onTap,
  bool pageview = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  final Widget child =
      pageview
          ? PageviewQuran(
            initialPageNumber: page,
            fitPageHeight: fit,
            theme: theme,
            windowSize: 0,
          )
          : QcfPage(
            pageNumber: page,
            currentPage: page,
            fitPageHeight: fit,
            theme: theme,
            isVerseHidden: hidden,
            onTap: onTap,
            onLongPress: onTap == null ? null : (_, _) {},
          );
  await tester.pumpWidget(
    DefaultAssetBundle(
      bundle: _PackageAssets(),
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size, textScaler: TextScaler.noScaling),
          child: Scaffold(
            backgroundColor: Colors.white,
            body: RepaintBoundary(
              key: boundaryKey,
              child: ColoredBox(color: Colors.white, child: child),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

RenderParagraph _paragraph(WidgetTester tester) =>
    tester.renderObject<RenderParagraph>(
      find
          .descendant(
            of: find.byType(QcfPage).first,
            matching: find.byType(RichText),
          )
          .first,
    );

class _Layout {
  _Layout(RenderParagraph paragraph, this.viewportHeight)
    : text = paragraph.text.toPlainText(includeSemanticsLabels: false),
      style = paragraph.text.style!,
      width = paragraph.size.width,
      origin = paragraph.localToGlobal(Offset.zero),
      boxes = [
        for (
          var offset = 0;
          offset <
              paragraph.text.toPlainText(includeSemanticsLabels: false).length;
          offset++
        )
          ...paragraph
              .getBoxesForSelection(
                TextSelection(baseOffset: offset, extentOffset: offset + 1),
              )
              .map((box) => box.toRect()),
      ],
      lines = _lineRanges(paragraph);

  final String text;
  final TextStyle style;
  final double width;
  final Offset origin;
  final List<Rect> boxes;
  final List<TextRange> lines;
  final double viewportHeight;

  double get bottomGap =>
      viewportHeight -
      origin.dy -
      boxes.map((box) => box.bottom).reduce((a, b) => a > b ? a : b);
}

_Layout _layout(WidgetTester tester, Size size) =>
    _Layout(_paragraph(tester), size.height);

TextPainter _textPainter(RenderParagraph paragraph) {
  final painter = TextPainter(
    text: paragraph.text,
    textAlign: paragraph.textAlign,
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
    locale: paragraph.locale,
    textHeightBehavior: paragraph.textHeightBehavior,
  );
  final spans = <WidgetSpan>[];
  paragraph.text.visitChildren((span) {
    if (span is WidgetSpan) spans.add(span);
    return true;
  });
  final children = <RenderBox>[];
  paragraph.visitChildren((child) {
    if (child is RenderBox) children.add(child);
  });
  painter.setPlaceholderDimensions([
    for (var index = 0; index < children.length; index++)
      PlaceholderDimensions(
        size: children[index].size,
        alignment: spans[index].alignment,
        baseline: spans[index].baseline,
        baselineOffset: 0,
      ),
  ]);
  painter.layout(maxWidth: paragraph.size.width);
  return painter;
}

List<TextRange> _lineRanges(RenderParagraph paragraph) {
  final painter = _textPainter(paragraph);
  final ranges =
      {
        for (
          var offset = 0;
          offset <
              paragraph.text.toPlainText(includeSemanticsLabels: false).length;
          offset++
        )
          painter.getLineBoundary(TextPosition(offset: offset)),
      }.toList();
  painter.dispose();
  return ranges;
}

List<ui.LineMetrics> _lineMetrics(RenderParagraph paragraph) {
  final painter = _textPainter(paragraph);
  final result = painter.computeLineMetrics();
  painter.dispose();
  return result;
}

void _expectSameGlyphGeometry(_Layout before, _Layout after) {
  expect(after.text, before.text);
  expect(after.style.fontFamily, before.style.fontFamily);
  expect(after.style.fontSize, before.style.fontSize);
  expect(after.width, before.width);
  expect(after.lines, before.lines);
  expect(after.boxes.length, before.boxes.length);
  for (var index = 0; index < before.boxes.length; index++) {
    expect(after.boxes[index].left, closeTo(before.boxes[index].left, 0.01));
    expect(after.boxes[index].width, closeTo(before.boxes[index].width, 0.01));
    expect(
      after.boxes[index].height,
      closeTo(before.boxes[index].height, 0.01),
    );
  }
}

Future<void> _preview(GlobalKey key, String name) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
  await Directory('build').create(recursive: true);
  await File('build/$name.png').writeAsBytes(png.buffer.asUint8List());
  image.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final page in [1, 2, 77, 79, 80]) {
      final number = page.toString().padLeft(3, '0');
      await _loadFont(
        'QCF_P$number',
        'assets/fonts/qcf4/QCF4${number}_X-Regular.woff',
      );
    }
    await _loadFont('surahname', 'assets/fonts/surah-name-v2.woff');
  });

  tearDown(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.single;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
  });

  testWidgets(
    'height fitting remains opt in and is forwarded by PageviewQuran',
    (tester) async {
      expect(const QcfPage(pageNumber: 79).fitPageHeight, isFalse);
      expect(const PageviewQuran().fitPageHeight, isFalse);
      await _mount(tester, fit: true, pageview: true);
      final page = tester.widget<QcfPage>(find.byType(QcfPage).first);
      expect(page.fitPageHeight, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'pages 79 and 80 use spare height without changing Quran glyphs or line breaks',
    (tester) async {
      final key = GlobalKey();
      for (final page in [79, 80]) {
        await _mount(tester, page: page, boundaryKey: key);
        final before = _layout(tester, _portrait);
        final originalLines = _lineMetrics(_paragraph(tester));
        await tester.runAsync(() => _preview(key, 'hafs-height-before-$page'));
        await _mount(tester, page: page, fit: true, boundaryKey: key);
        final after = _layout(tester, _portrait);
        final fittedLines = _lineMetrics(_paragraph(tester));
        await tester.runAsync(() => _preview(key, 'hafs-height-after-$page'));

        _expectSameGlyphGeometry(before, after);
        expect(fittedLines.length, originalLines.length);
        expect(after.style.height, greaterThan(before.style.height!));
        expect(after.bottomGap, lessThan(before.bottomGap - 20));
        for (var index = 1; index < originalLines.length; index++) {
          final originalGap =
              originalLines[index].baseline - originalLines[index - 1].baseline;
          final fittedGap =
              fittedLines[index].baseline - fittedLines[index - 1].baseline;
          expect(fittedGap, greaterThanOrEqualTo(originalGap));
          expect(fittedGap - originalGap, lessThanOrEqualTo(6.01));
          expect(fittedGap, lessThanOrEqualTo(originalGap * 1.12 + 0.01));
        }
        await tester.runAsync(() async {
          await File('build/hafs-height-metrics-$page.json').writeAsString(
            const JsonEncoder.withIndent('  ').convert({
              'page': page,
              'viewport': [_portrait.width, _portrait.height],
              'fontSize': before.style.fontSize,
              'lineCount': originalLines.length,
              'before': {
                'top': before.origin.dy,
                'bottomGap': before.bottomGap,
                'lineHeight': before.style.height,
                'baselines':
                    originalLines.map((line) => line.baseline).toList(),
              },
              'after': {
                'top': after.origin.dy,
                'bottomGap': after.bottomGap,
                'lineHeight': after.style.height,
                'baselines': fittedLines.map((line) => line.baseline).toList(),
              },
            }),
          );
        });
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'a very tall screen caps extra spacing rather than stretching lines',
    (tester) async {
      const tall = Size(414, 1400);
      await _mount(tester, size: tall);
      final before = _layout(tester, tall);
      final originalLines = _lineMetrics(_paragraph(tester));
      await _mount(tester, size: tall, fit: true);
      final after = _layout(tester, tall);
      final fittedLines = _lineMetrics(_paragraph(tester));
      _expectSameGlyphGeometry(before, after);
      expect(after.bottomGap, lessThan(before.bottomGap));
      for (var index = 1; index < originalLines.length; index++) {
        final originalGap =
            originalLines[index].baseline - originalLines[index - 1].baseline;
        final fittedGap =
            fittedLines[index].baseline - fittedLines[index - 1].baseline;
        expect(fittedGap - originalGap, lessThanOrEqualTo(6.01));
        expect(fittedGap, lessThanOrEqualTo(originalGap * 1.12 + 0.01));
      }
      expect(after.bottomGap, greaterThan(100));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'fitted ayah tap targets and hidden text retain the same layout',
    (tester) async {
      final taps = <(int, int)>[];
      var hidden = false;
      await _mount(
        tester,
        fit: true,
        hidden: (_, _) => hidden,
        onTap: (s, v) => taps.add((s, v)),
      );
      final before = _layout(tester, _portrait);
      TextSpan? firstAyah;
      _paragraph(tester).text.visitChildren((span) {
        if (span is TextSpan &&
            span.recognizer != null &&
            span.children != null) {
          firstAyah ??= span;
        }
        return true;
      });
      final marker = getVerseNumberQCF(4, 12);
      final markerOffset =
          before.text.indexOf(firstAyah!.text!) + firstAyah!.text!.length;
      expect(markerOffset, greaterThanOrEqualTo(0));
      final markerBox =
          _paragraph(tester)
              .getBoxesForSelection(
                TextSelection(
                  baseOffset: markerOffset,
                  extentOffset: markerOffset + marker.length,
                ),
              )
              .first
              .toRect();
      hidden = true;
      await _mount(
        tester,
        fit: true,
        hidden: (_, _) => hidden,
        onTap: (s, v) => taps.add((s, v)),
      );
      final after = _layout(tester, _portrait);
      _expectSameGlyphGeometry(before, after);
      expect(after.boxes, before.boxes);
      expect(after.origin, before.origin);
      await tester.tapAt(_paragraph(tester).localToGlobal(markerBox.center));
      await tester.pump();
      expect(taps, [(4, 12)]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'short screens, landscape and pages 1 and 2 preserve original layout',
    (tester) async {
      for (final scenario in [
        (79, const Size(414, 550)),
        (79, const Size(900, 414)),
        (1, _portrait),
        (2, _portrait),
      ]) {
        final (page, size) = scenario;
        await _mount(tester, page: page, size: size);
        final before = _layout(tester, size);
        await _mount(tester, page: page, size: size, fit: true);
        final after = _layout(tester, size);
        _expectSameGlyphGeometry(before, after);
        expect(after.style.height, before.style.height);
        expect(after.boxes, before.boxes);
        expect(after.origin, before.origin);
        if (page == 79) {
          final scrollable = tester.state<ScrollableState>(
            find.byType(Scrollable).first,
          );
          expect(scrollable.position.maxScrollExtent, greaterThan(0));
        }
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'a page with a surah header keeps its artwork and basmala geometry',
    (tester) async {
      const size = Size(414, 1020);
      const theme = QcfThemeData();
      await _mount(tester, page: 77, size: size, theme: theme);
      final before = _layout(tester, size);
      final headerSize = tester.getSize(find.byType(HeaderWidget));
      await _mount(tester, page: 77, size: size, theme: theme, fit: true);
      final after = _layout(tester, size);
      _expectSameGlyphGeometry(before, after);
      expect(tester.getSize(find.byType(HeaderWidget)), headerSize);
      expect(after.bottomGap, lessThan(before.bottomGap));
      expect(tester.takeException(), isNull);
    },
  );
}
