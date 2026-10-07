import 'package:flutter_test/flutter_test.dart';
import 'package:mushaf_riwayat/src/audio/quran_audio.dart';
import 'package:mushaf_riwayat/src/data/mushaf_riwayat.dart' as hafs;
import 'package:mushaf_riwayat/src/riwayah.dart';

void main() {
  test('Hafs reference resolves to padded EveryAyah URL without network', () {
    final provider = EveryAyahProvider();
    final segments = provider.resolveAyah(
      _ayah(QuranRiwayah.hafs, 2, 255),
      reciter: EveryAyahReciters.hafsAlafasy,
    );
    expect(
      segments.single.uri.toString(),
      'https://everyayah.com/data/Alafasy_128kbps/002255.mp3',
    );
    expect(segments.single.isPartial, isFalse);
    expect(() => segments.clear(), throwsUnsupportedError);
    for (var surah = 1; surah <= 114; surah++) {
      expect(
        EveryAyahReciters.hafsAlafasy.clipCount(surah),
        hafs.getVerseCount(surah),
        reason: 'Hafs directory count for surah $surah',
      );
    }
  });

  test('native-numbered Warsh rejects unknown bounds and known mismatches', () {
    final provider = EveryAyahProvider();
    final reciter = EveryAyahReciters.warshAbdulBasit;
    expect(
      provider
          .resolveAyah(_ayah(QuranRiwayah.warsh, 2, 285), reciter: reciter)
          .single
          .uri
          .path,
      '/data/warsh/warsh_Abdul_Basit_128kbps/002285.mp3',
    );
    expect(
      () => provider.resolveAyah(
        _ayah(QuranRiwayah.warsh, 2, 286),
        reciter: reciter,
      ),
      throwsRangeError,
    );
    for (final surah in [26, 67]) {
      expect(
        () => provider.resolveAyah(
          _ayah(QuranRiwayah.warsh, surah, 1),
          reciter: reciter,
        ),
        throwsA(isA<EveryAyahMappingRequiredException>()),
      );
    }
    expect(reciter.clipCount(26), 227);
    expect(reciter.clipCount(67), 30);
    expect(
      List.generate(
        114,
        (i) => reciter.clipCount(i + 1),
      ).reduce((a, b) => a + b),
      6214,
    );
  });

  test(
    'Kufic-numbered Warsh clips never receive silent numeric conversion',
    () {
      final provider = EveryAyahProvider();
      for (final reciter in [
        EveryAyahReciters.warshIbrahimAldosary,
        EveryAyahReciters.warshYassinAlJazaery,
      ]) {
        expect(
          () => provider.resolveAyah(
            _ayah(QuranRiwayah.warsh, 2, 253),
            reciter: reciter,
          ),
          throwsA(isA<EveryAyahMappingRequiredException>()),
        );
        expect(reciter.clipCount(2), 286);
        expect(
          provider.clipUri(reciter, surahNumber: 2, clipNumber: 255).path,
          endsWith('/002255.mp3'),
        );
      }
    },
  );

  test(
    'explicit verified map supports multiple clips and partial boundaries',
    () {
      final requested = _ayah(QuranRiwayah.warsh, 67, 31);
      final provider = EveryAyahProvider(
        verifiedMapper: (reader, reference) {
          expect(reader.id, EveryAyahReciters.warshAbdulBasit.id);
          expect(reference, requested);
          // Test-only timings; no actual recording boundary is asserted here.
          return const [
            EveryAyahClip(
              surahNumber: 67,
              clipNumber: 29,
              start: Duration(seconds: 1),
              end: Duration(seconds: 2),
            ),
            EveryAyahClip(surahNumber: 67, clipNumber: 30),
          ];
        },
      );
      final segments = provider.resolveAyah(
        requested,
        reciter: EveryAyahReciters.warshAbdulBasit,
      );
      expect(segments, hasLength(2));
      expect(segments.first.uri.path, endsWith('/067029.mp3'));
      expect(segments.first.start, const Duration(seconds: 1));
      expect(segments.first.end, const Duration(seconds: 2));
      expect(segments.first.isPartial, isTrue);
      expect(segments.last.uri.path, endsWith('/067030.mp3'));
    },
  );

  test(
    'explicit mappings cannot use invalid clips, timings or other surahs',
    () {
      final mappings = <List<EveryAyahClip>>[
        [],
        [const EveryAyahClip(surahNumber: 66, clipNumber: 1)],
        [const EveryAyahClip(surahNumber: 67, clipNumber: 31)],
        [
          const EveryAyahClip(
            surahNumber: 67,
            clipNumber: 30,
            start: Duration(seconds: -1),
          ),
        ],
        [
          const EveryAyahClip(
            surahNumber: 67,
            clipNumber: 30,
            start: Duration(seconds: 2),
            end: Duration(seconds: 1),
          ),
        ],
      ];
      for (final mapping in mappings) {
        final provider = EveryAyahProvider(verifiedMapper: (_, _) => mapping);
        expect(
          () => provider.resolveAyah(
            _ayah(QuranRiwayah.warsh, 67, 31),
            reciter: EveryAyahReciters.warshAbdulBasit,
          ),
          throwsArgumentError,
        );
      }
    },
  );

  test('Hafs and Warsh audio cannot accidentally cross riwayat', () {
    final provider = EveryAyahProvider();
    expect(
      () => provider.resolveAyah(
        _ayah(QuranRiwayah.warsh, 1, 1),
        reciter: EveryAyahReciters.hafsAlafasy,
      ),
      throwsArgumentError,
    );
    expect(
      () => provider.resolveAyah(
        _ayah(QuranRiwayah.hafs, 1, 1),
        reciter: EveryAyahReciters.warshAbdulBasit,
      ),
      throwsArgumentError,
    );
    expect(EveryAyahReciters.forRiwayah(QuranRiwayah.warsh), hasLength(3));
  });

  test('special clip zero and escaping directory paths are not ayah URLs', () {
    final provider = EveryAyahProvider();
    expect(
      () => provider.clipUri(
        EveryAyahReciters.hafsAlafasy,
        surahNumber: 1,
        clipNumber: 0,
      ),
      throwsRangeError,
    );
    const escaped = EveryAyahReciter(
      id: 'bad',
      name: 'bad',
      riwayah: QuranRiwayah.hafs,
      directory: '../other',
      numbering: EveryAyahNumbering.hafsKufic,
    );
    expect(
      () => provider.clipUri(escaped, surahNumber: 1, clipNumber: 1),
      throwsArgumentError,
    );
  });
}

QuranAyahReference _ayah(QuranRiwayah riwayah, int surah, int verse) =>
    QuranAyahReference(
      riwayah: riwayah,
      surahNumber: surah,
      verseNumber: verse,
    );
