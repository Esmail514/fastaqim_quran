import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qcf_quran/qcf_quran.dart';

// Exercise the separate demo app without adding it as a package dependency.
// ignore: avoid_relative_lib_imports
import '../example/lib/riwayah_mushaf_example.dart';

void main() {
  testWidgets(
    'example reads clicked Hafs ayah and requests only chosen catalog',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final requests = <Uri>[];
      final client = MockClient((request) async {
        requests.add(request.url);
        expect(request.url.path, '/api/v3/reciters');
        expect(request.url.queryParameters['rewaya'], '1');
        expect(request.url.queryParameters['sura'], '1');
        return _readerResponse();
      });
      await tester.pumpWidget(
        MaterialApp(
          home: RiwayahMushafExample(
            audioApiFactory: () => Mp3QuranApi(client: client),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(requests, isEmpty);
      final pageView = tester.widget<PageviewQuran>(find.byType(PageviewQuran));
      pageView.onAyahTap!(
        const QuranAyahReference(
          riwayah: QuranRiwayah.hafs,
          surahNumber: 1,
          verseNumber: 1,
        ),
      );
      await tester.pumpAndSettle();
      final ayahText = tester.widget<SelectableText>(
        find.byKey(const ValueKey('selected-ayah-text')),
      );
      expect(ayahText.data, getVerse(1, 1));
      expect(ayahText.data, startsWith('بِسۡمِ'));
      expect(ayahText.style!.fontFamily, 'packages/qcf_quran/QCF_HafsUnicode');
      expect(requests, isEmpty);
      await tester.tap(find.text('رابط تلاوة الآية'));
      await tester.pumpAndSettle();
      expect(
        find.text('https://everyayah.com/data/Alafasy_128kbps/001001.mp3'),
        findsOneWidget,
      );
      expect(requests, isEmpty);
      await tester.ensureVisible(find.text('جلب القراء للسورة'));
      await tester.tap(find.text('جلب القراء للسورة'));
      await tester.pumpAndSettle();
      expect(requests, hasLength(1));
      expect(find.text('https://audio.example/hafs/001.mp3'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      client.close();
    },
  );

  testWidgets(
    'closing example sheet during catalog load avoids later setState',
    (tester) async {
      tester.view.physicalSize = const Size(600, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final pending = Completer<http.Response>();
      final client = MockClient((_) => pending.future);
      await tester.pumpWidget(
        MaterialApp(
          home: RiwayahMushafExample(
            audioApiFactory: () => Mp3QuranApi(client: client),
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester.widget<PageviewQuran>(find.byType(PageviewQuran)).onAyahTap!(
        const QuranAyahReference(
          riwayah: QuranRiwayah.hafs,
          surahNumber: 1,
          verseNumber: 1,
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('جلب القراء للسورة'));
      await tester.tap(find.text('جلب القراء للسورة'));
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
      pending.complete(_readerResponse());
      await tester.pump();
      expect(tester.takeException(), isNull);
      client.close();
    },
  );
}

http.Response _readerResponse() => http.Response.bytes(
  utf8.encode(
    jsonEncode({
      'reciters': [
        {
          'id': 1,
          'name': 'قارئ تجريبي',
          'moshaf': [
            {
              'id': 1,
              'name': 'حفص',
              'rewaya_id': 1,
              'server': 'https://audio.example/hafs/',
              'surah_total': 1,
              'surah_list': '1',
            },
          ],
        },
      ],
    }),
  ),
  200,
);
