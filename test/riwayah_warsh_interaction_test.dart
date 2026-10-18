import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fastaqim_quran/src/qcf_theme_data.dart';
import 'package:fastaqim_quran/src/riwayah.dart';
import 'package:fastaqim_quran/src/warsh/warsh_mushaf.dart';
import 'package:fastaqim_quran/src/warsh/warsh_page.dart';

const _first = QuranAyahReference(
  riwayah: QuranRiwayah.warsh,
  surahNumber: 1,
  verseNumber: 1,
);
const _second = QuranAyahReference(
  riwayah: QuranRiwayah.warsh,
  surahNumber: 1,
  verseNumber: 2,
);
const _viewBox = Rect.fromLTWH(-40, -50, 100, 200);
const _theme = QcfThemeData(horizontalPadding: 0, verticalPadding: 0);

WarshMushaf _fixture() => WarshMushaf.fromData(
  verses: [
    WarshVerse(
      surahNumber: 1,
      verseNumber: 1,
      text: 'fixture 1',
      juzNumber: 1,
      pageNumbers: [1, 2],
    ),
    WarshVerse(
      surahNumber: 1,
      verseNumber: 2,
      text: 'fixture 2',
      juzNumber: 1,
      pageNumbers: [1],
    ),
  ],
  pages: [
    WarshPageData(
      pageNumber: 1,
      viewBox: _viewBox,
      regions: [
        WarshAyahRegion(
          reference: _first,
          polygon:
              'M-20,-30 L0,-30 L0,-10 L-20,-10 Z '
              'M5,10 L30,10 L30,30 L5,30 Z',
        ),
        WarshAyahRegion(
          reference: _second,
          polygon: '-25,80 20,80 20,105 -25,105',
        ),
      ],
    ),
    WarshPageData(
      pageNumber: 2,
      viewBox: _viewBox,
      regions: [
        WarshAyahRegion(
          reference: _first,
          polygon: '-25,80 20,80 20,105 -25,105',
        ),
      ],
    ),
  ],
);

Widget _picture(BuildContext context, WarshPageData page) => ColoredBox(
  key: ValueKey('picture-${page.pageNumber}'),
  color: Colors.white,
);

Offset _onScreen(WidgetTester tester, Offset point, {int page = 1}) {
  final artwork = tester.getRect(find.byKey(ValueKey('picture-$page')));
  return artwork.topLeft +
      Offset(
        (point.dx - _viewBox.left) / _viewBox.width * artwork.width,
        (point.dy - _viewBox.top) / _viewBox.height * artwork.height,
      );
}

Future<void> _mount(
  WidgetTester tester, {
  required WarshMushaf mushaf,
  int pageNumber = 1,
  Size size = const Size(320, 360),
  ValueChanged<QuranAyahReference>? onTap,
  ValueChanged<QuranAyahReference>? onLongPress,
  ValueChanged<QuranAyahReference>? onLongPressUp,
  ValueChanged<QuranAyahReference>? onLongPressCancel,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: WarshPage(
              key: const ValueKey('warsh-page'),
              pageNumber: pageNumber,
              mushaf: mushaf,
              theme: _theme,
              pictureBuilder: _picture,
              onAyahTap: onTap,
              onAyahLongPress: onLongPress,
              onAyahLongPressUp: onLongPressUp,
              onAyahLongPressCancel: onLongPressCancel,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'cancelled Warsh long press retains its original ayah reference',
    (tester) async {
      final cancelled = <QuranAyahReference>[];
      await _mount(
        tester,
        mushaf: _fixture(),
        onLongPressCancel: cancelled.add,
      );
      final gesture = await tester.startGesture(
        _onScreen(tester, const Offset(-10, -20)),
      );
      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      await gesture.up();
      expect(cancelled, [_first]);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unavailable artwork does not leave invisible ayah targets', (
    tester,
  ) async {
    final taps = <QuranAyahReference>[];
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
          regions: [
            WarshAyahRegion(
              reference: _first,
              polygon: '0,0 100,0 100,100 0,100',
            ),
          ],
          // No artwork URI/asset: geometry alone must not become interactive.
        ),
      ],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: WarshPage(pageNumber: 1, mushaf: mushaf, onAyahTap: taps.add),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tapAt(tester.getCenter(find.byType(WarshPage)));
    await tester.pump();
    expect(taps, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scaled negative-origin pages hit both fragments of an ayah', (
    tester,
  ) async {
    final mushaf = _fixture();
    final taps = <QuranAyahReference>[];
    for (final size in [const Size(320, 360), const Size(600, 300)]) {
      taps.clear();
      await _mount(tester, mushaf: mushaf, size: size, onTap: taps.add);
      await tester.tapAt(_onScreen(tester, const Offset(-10, -20)));
      await tester.tapAt(_onScreen(tester, const Offset(15, 20)));
      await tester.tapAt(_onScreen(tester, const Offset(0, 90)));
      // Blank source space and the letterbox outside the artwork are inactive.
      await tester.tapAt(_onScreen(tester, const Offset(40, 60)));
      final outer = tester.getRect(find.byType(WarshPage));
      await tester.tapAt(outer.topLeft + Offset(5, outer.height / 2));
      await tester.pump();
      expect(taps, [_first, _first, _second]);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('tap and long press coexist without an extra tap after release', (
    tester,
  ) async {
    final taps = <QuranAyahReference>[];
    final holds = <QuranAyahReference>[];
    final releases = <QuranAyahReference>[];
    await _mount(
      tester,
      mushaf: _fixture(),
      onTap: taps.add,
      onLongPress: holds.add,
      onLongPressUp: releases.add,
    );
    final point = _onScreen(tester, const Offset(-10, -20));
    await tester.tapAt(point);
    await tester.longPressAt(point);
    await tester.pump();
    expect(taps, [_first]);
    expect(holds, [_first]);
    expect(releases, [_first]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'page changes retain a continuation ID and use latest listeners',
    (tester) async {
      final mushaf = _fixture();
      final events = <(String, QuranAyahReference)>[];
      await _mount(
        tester,
        mushaf: mushaf,
        onTap: (ref) => events.add(('old', ref)),
      );
      await tester.tapAt(_onScreen(tester, const Offset(-10, -20)));
      await _mount(
        tester,
        mushaf: mushaf,
        onTap: (ref) => events.add(('latest', ref)),
      );
      await tester.tapAt(_onScreen(tester, const Offset(-10, -20)));
      await _mount(
        tester,
        mushaf: mushaf,
        pageNumber: 2,
        onTap: (ref) => events.add(('continued', ref)),
      );
      await tester.tapAt(_onScreen(tester, const Offset(0, 90), page: 2));
      expect(events, [
        ('old', _first),
        ('latest', _first),
        ('continued', _first),
      ]);
      await tester.pumpWidget(const SizedBox.shrink());
      expect(tester.takeException(), isNull);
    },
  );
}
