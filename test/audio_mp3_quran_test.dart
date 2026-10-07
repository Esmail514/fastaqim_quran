import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qcf_quran/src/audio/quran_audio.dart';
import 'package:qcf_quran/src/riwayah.dart';

void main() {
  test(
    'catalog filters reach API and preserve only matching collections',
    () async {
      final requests = <Uri>[];
      final client = MockClient((request) async {
        requests.add(request.url);
        return _jsonResponse({
          'reciters': [
            {
              'id': 118,
              'name': 'محمود خليل الحصري',
              'letter': 'م',
              'moshaf': [
                _collection(id: 120, riwayah: 2, surahs: '1,2,114'),
                _collection(id: 121, riwayah: 1, surahs: '1,2,114'),
                _collection(id: 122, riwayah: 2, surahs: '1,114'),
              ],
            },
            {
              'id': 119,
              'name': 'قارئ آخر',
              'moshaf': [_collection(id: 123, riwayah: 2, surahs: '2')],
            },
          ],
        });
      });
      final api = Mp3QuranApi(client: client);
      final readers = await api.getReciters(
        language: 'ar',
        reciterId: 118,
        riwayahId: 2,
        surahNumber: 2,
      );
      expect(requests.single.path, '/api/v3/reciters');
      expect(requests.single.queryParameters, {
        'language': 'ar',
        'reciter': '118',
        'rewaya': '2',
        'sura': '2',
      });
      expect(readers.single.name, 'محمود خليل الحصري');
      expect(readers.single.moshafs.map((entry) => entry.id), [120]);
      expect(
        readers.single.moshafs.single.supportedRiwayah,
        QuranRiwayah.warsh,
      );
      expect(
        requests,
        hasLength(1),
      ); // Building URLs makes no recording requests.
      expect(
        readers.single.moshafs.single.surahUri(2).toString(),
        'https://audio.example/warsh/002.mp3',
      );
      expect(requests, hasLength(1));
      api.close();
      client.close();
    },
  );

  test('playlist follows actual sorted surah list, never reported total', () {
    final collection = Mp3QuranMoshaf.fromJson(
      _collection(id: 120, riwayah: 2, surahs: '114,2,1,2'),
    );
    expect(collection.reportedSurahTotal, 114);
    expect(collection.isComplete, isFalse);
    expect(collection.availableSurahs, [1, 2, 114]);
    expect(collection.playlist.map((uri) => uri.path), [
      '/warsh/001.mp3',
      '/warsh/002.mp3',
      '/warsh/114.mp3',
    ]);
    expect(
      () => collection.surahUri(3),
      throwsA(isA<SurahAudioUnavailableException>()),
    );
    expect(() => collection.surahUri(115), throwsRangeError);
    expect(() => collection.availableSurahs.add(3), throwsUnsupportedError);
    final full = Mp3QuranMoshaf(
      id: 7,
      name: 'complete',
      server: Uri.parse('https://audio.example/reader'),
      availableSurahs: List.generate(114, (i) => i + 1),
    );
    expect(full.isComplete, isTrue);
    expect(full.surahUri(1).path, '/reader/001.mp3');
  });

  test(
    'riwayah paths remain separate and unknown riwayat remain available',
    () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/v3/riwayat');
        return _jsonResponse({
          'riwayat': [
            {'id': '1', 'name': 'حفص'},
            {'id': 2, 'name': 'ورش'},
            {'id': 18, 'name': 'ورش — الأزرق'},
            {'id': 10, 'name': 'ورش — الأصبهاني'},
            {'id': 5, 'name': 'رواية أخرى'},
          ],
        });
      });
      final api = Mp3QuranApi(client: client);
      final entries = await api.getRiwayat();
      expect(entries[0].supportedRiwayah, QuranRiwayah.hafs);
      expect(entries[1].warshRoute, Mp3QuranWarshRoute.unspecified);
      expect(entries[2].warshRoute, Mp3QuranWarshRoute.azraq);
      expect(entries[3].warshRoute, Mp3QuranWarshRoute.asbahani);
      expect(entries[4].supportedRiwayah, isNull);
      api.close();
      client.close();
    },
  );

  test('surah names load independently from edition page metadata', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v3/suwar');
      return _jsonResponse({
        'suwar': [
          {'id': 1, 'name': 'الفاتحة', 'start_page': 1, 'end_page': 1},
        ],
      });
    });
    final api = Mp3QuranApi(client: client);
    final surahs = await api.getSurahs();
    expect(surahs.single.number, 1);
    expect(surahs.single.name, 'الفاتحة');
    api.close();
    client.close();
  });

  test(
    'HTTP errors and invalid catalog JSON produce useful failures',
    () async {
      final unavailable = MockClient((request) async => http.Response('', 503));
      final badJson = MockClient((request) async => http.Response('{', 200));
      final badSchema = MockClient(
        (request) async => _jsonResponse({'riwayat': {}}),
      );
      for (final client in [unavailable, badJson, badSchema]) {
        final api = Mp3QuranApi(client: client);
        await expectLater(
          api.getRiwayat(),
          throwsA(isA<Mp3QuranApiException>()),
        );
        api.close();
        client.close();
      }
    },
  );

  test('closing an injected client leaves ownership with caller', () async {
    final client = _TrackingClient();
    final api = Mp3QuranApi(client: client);
    api.close();
    api.close();
    expect(client.wasClosed, isFalse);
    await expectLater(api.getRiwayat(), throwsStateError);
    client.close();
    expect(client.wasClosed, isTrue);
  });

  test(
    'invalid filters and malformed recording directories fail before use',
    () async {
      var requests = 0;
      final client = MockClient((request) async {
        requests++;
        return _jsonResponse({'reciters': []});
      });
      final api = Mp3QuranApi(client: client);
      await expectLater(api.getReciters(surahNumber: 0), throwsRangeError);
      await expectLater(api.getReciters(riwayahId: 0), throwsRangeError);
      await expectLater(api.getReciters(reciterId: -1), throwsRangeError);
      await expectLater(api.getReciters(language: ''), throwsArgumentError);
      expect(requests, 0);
      expect(
        () => Mp3QuranMoshaf.fromJson({
          ..._collection(id: 1, riwayah: 1, surahs: '1'),
          'server': 'file:///tmp/audio',
        }),
        throwsArgumentError,
      );
      expect(
        () => Mp3QuranMoshaf.fromJson(
          _collection(id: 1, riwayah: 1, surahs: '1,115'),
        ),
        throwsFormatException,
      );
      api.close();
      client.close();
    },
  );
}

Map<String, Object> _collection({
  required int id,
  required int riwayah,
  required String surahs,
}) => {
  'id': id,
  'name': 'تلاوة',
  'rewaya_id': riwayah,
  'server': 'https://audio.example/warsh/',
  'surah_total': 114,
  'moshaf_type': 21,
  'surah_list': surahs,
};

http.Response _jsonResponse(Object payload) =>
    http.Response.bytes(utf8.encode(jsonEncode(payload)), 200);

class _TrackingClient extends MockClient {
  _TrackingClient() : super((request) async => _jsonResponse({'riwayat': []}));

  bool wasClosed = false;

  @override
  void close() {
    wasClosed = true;
    super.close();
  }
}
