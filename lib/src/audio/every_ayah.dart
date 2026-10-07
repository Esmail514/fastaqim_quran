import '../riwayah.dart';

/// Clip numbering describes the recording directory, independently of the
/// Arabic text's riwayah. Some Warsh readers use Kufic-numbered clips.
enum EveryAyahNumbering {
  hafsKufic,
  warshMadaniLastWithKnownDifferences,
  warshKufic,
}

class EveryAyahReciter {
  const EveryAyahReciter({
    required this.id,
    required this.name,
    required this.riwayah,
    required this.directory,
    required this.numbering,
  });

  final String id;
  final String name;
  final QuranRiwayah riwayah;

  /// A directory relative to https://everyayah.com/data/.
  final String directory;
  final EveryAyahNumbering numbering;

  /// Directory clip counts checked against published text checksum indexes on
  /// 2026-10-04. Counts alone do not certify audible verse boundaries.
  int clipCount(int surahNumber) {
    _checkSurah(surahNumber);
    return switch (numbering) {
      EveryAyahNumbering.hafsKufic ||
      EveryAyahNumbering.warshKufic => _kuficClipCounts[surahNumber - 1],
      EveryAyahNumbering.warshMadaniLastWithKnownDifferences =>
        _warshAbdulBasitClipCounts[surahNumber - 1],
    };
  }
}

/// A small built-in catalog of published EveryAyah directories. Applications
/// can supply another [EveryAyahReciter] explicitly. This is not a live list of
/// every reader in the service.
abstract final class EveryAyahReciters {
  static const hafsAlafasy = EveryAyahReciter(
    id: 'hafs_alafasy_128',
    name: 'مشاري العفاسي',
    riwayah: QuranRiwayah.hafs,
    directory: 'Alafasy_128kbps',
    numbering: EveryAyahNumbering.hafsKufic,
  );

  static const hafsHusary = EveryAyahReciter(
    id: 'hafs_husary_128',
    name: 'محمود خليل الحصري',
    riwayah: QuranRiwayah.hafs,
    directory: 'Husary_128kbps',
    numbering: EveryAyahNumbering.hafsKufic,
  );

  static const hafsMinshawy = EveryAyahReciter(
    id: 'hafs_minshawy_murattal_128',
    name: 'محمد صديق المنشاوي',
    riwayah: QuranRiwayah.hafs,
    directory: 'Minshawy_Murattal_128kbps',
    numbering: EveryAyahNumbering.hafsKufic,
  );

  static const hafsAbdulBasit = EveryAyahReciter(
    id: 'hafs_abdul_basit_murattal_192',
    name: 'عبد الباسط عبد الصمد',
    riwayah: QuranRiwayah.hafs,
    directory: 'Abdul_Basit_Murattal_192kbps',
    numbering: EveryAyahNumbering.hafsKufic,
  );

  static const warshAbdulBasit = EveryAyahReciter(
    id: 'warsh_abdul_basit_128',
    name: 'عبد الباسط عبد الصمد — ورش',
    riwayah: QuranRiwayah.warsh,
    directory: 'warsh/warsh_Abdul_Basit_128kbps',
    numbering: EveryAyahNumbering.warshMadaniLastWithKnownDifferences,
  );

  static const warshIbrahimAldosary = EveryAyahReciter(
    id: 'warsh_ibrahim_aldosary_128',
    name: 'إبراهيم الدوسري — ورش',
    riwayah: QuranRiwayah.warsh,
    directory: 'warsh/warsh_ibrahim_aldosary_128kbps',
    numbering: EveryAyahNumbering.warshKufic,
  );

  static const warshYassinAlJazaery = EveryAyahReciter(
    id: 'warsh_yassin_al_jazaery_64',
    name: 'ياسين الجزائري — ورش',
    riwayah: QuranRiwayah.warsh,
    directory: 'warsh/warsh_yassin_al_jazaery_64kbps',
    numbering: EveryAyahNumbering.warshKufic,
  );

  static const all = <EveryAyahReciter>[
    hafsAlafasy,
    hafsHusary,
    hafsMinshawy,
    hafsAbdulBasit,
    warshAbdulBasit,
    warshIbrahimAldosary,
    warshYassinAlJazaery,
  ];

  static List<EveryAyahReciter> forRiwayah(QuranRiwayah riwayah) =>
      List<EveryAyahReciter>.unmodifiable(
        all.where((reciter) => reciter.riwayah == riwayah),
      );
}

/// Explicit source-indexed clip, optionally restricted to verified timings.
/// This permits one displayed verse to correspond to several recording files,
/// or to part of a recording; this class does not derive timing information.
class EveryAyahClip {
  const EveryAyahClip({
    required this.surahNumber,
    required this.clipNumber,
    this.start,
    this.end,
  });

  final int surahNumber;
  final int clipNumber;
  final Duration? start;
  final Duration? end;
}

class EveryAyahAudioSegment {
  const EveryAyahAudioSegment({required this.uri, this.start, this.end});

  final Uri uri;
  final Duration? start;
  final Duration? end;

  bool get isPartial => start != null || end != null;
}

/// The caller must verify clip boundaries and any supplied timings. Returning
/// null uses the built-in numbering policy; no guessed numeric conversion is
/// performed for incompatible directories.
typedef VerifiedEveryAyahMapper =
    List<EveryAyahClip>? Function(
      EveryAyahReciter reciter,
      QuranAyahReference ayah,
    );

class EveryAyahMappingRequiredException implements Exception {
  const EveryAyahMappingRequiredException(this.reciter, this.ayah);

  final EveryAyahReciter reciter;
  final QuranAyahReference ayah;

  @override
  String toString() =>
      'EveryAyah reader ${reciter.id} needs a verified clip mapping for '
      '${ayah.riwayah.name} ${ayah.surahNumber}:${ayah.verseNumber}.';
}

/// EveryAyah publishes static MP3 URLs, rather than an ayah REST API. This
/// provider constructs URLs only; it does not download, probe, or play audio.
class EveryAyahProvider {
  EveryAyahProvider({Uri? baseUri, this.verifiedMapper})
    : baseUri = _directory(baseUri ?? Uri.parse('https://everyayah.com/data/'));

  final Uri baseUri;
  final VerifiedEveryAyahMapper? verifiedMapper;

  /// URL for a directory's OWN clip numbering. Do not pass a displayed Warsh
  /// verse here unless its correspondence has been checked. [resolveAyah]
  /// guards the known mismatches for displayed native-numbered references.
  Uri clipUri(
    EveryAyahReciter reciter, {
    required int surahNumber,
    required int clipNumber,
  }) {
    _checkSurah(surahNumber);
    final limit = reciter.clipCount(surahNumber);
    if (clipNumber < 1 || clipNumber > limit) {
      throw RangeError.range(clipNumber, 1, limit, 'clipNumber');
    }
    if (!RegExp(
      r'^[A-Za-z0-9_-]+(?:/[A-Za-z0-9_-]+)*$',
    ).hasMatch(reciter.directory)) {
      throw ArgumentError.value(
        reciter.directory,
        'reciter.directory',
        'Expected a relative EveryAyah directory.',
      );
    }
    final surah = surahNumber.toString().padLeft(3, '0');
    final clip = clipNumber.toString().padLeft(3, '0');
    return baseUri.resolve('${reciter.directory}/$surah$clip.mp3');
  }

  /// Resolves Hafs Kufic or Warsh Madani-last displayed references. For Abdul
  /// Basit Warsh, directory counts agree with that edition in 112 surahs. The
  /// known exceptions, Ash-Shuara (26) and Al-Mulk (67), require verified maps.
  /// Warsh readers with Kufic clip numbering also require maps. This policy
  /// is based on published numbering; it is not an audible-boundary review.
  List<EveryAyahAudioSegment> resolveAyah(
    QuranAyahReference ayah, {
    required EveryAyahReciter reciter,
  }) {
    _checkSurah(ayah.surahNumber);
    final verseCount = _nativeVerseCount(ayah.riwayah, ayah.surahNumber);
    if (ayah.verseNumber < 1 || ayah.verseNumber > verseCount) {
      throw RangeError.range(ayah.verseNumber, 1, verseCount, 'verseNumber');
    }
    if (ayah.riwayah != reciter.riwayah) {
      throw ArgumentError(
        'Displayed ${ayah.riwayah.name} must use a reader of that riwayah.',
      );
    }
    final explicit = verifiedMapper?.call(reciter, ayah);
    if (explicit != null) {
      if (explicit.isEmpty) {
        throw ArgumentError('A verified mapping must contain an audio clip.');
      }
      return List<EveryAyahAudioSegment>.unmodifiable(
        explicit.map((clip) {
          if (clip.surahNumber != ayah.surahNumber) {
            throw ArgumentError('Mapped clips must belong to the same surah.');
          }
          if ((clip.start?.isNegative ?? false) ||
              (clip.end != null &&
                  clip.end! <= (clip.start ?? Duration.zero))) {
            throw ArgumentError('Audio timing must have 0 <= start < end.');
          }
          return EveryAyahAudioSegment(
            uri: clipUri(
              reciter,
              surahNumber: clip.surahNumber,
              clipNumber: clip.clipNumber,
            ),
            start: clip.start,
            end: clip.end,
          );
        }),
      );
    }
    final compatible = switch (reciter.numbering) {
      EveryAyahNumbering.hafsKufic => ayah.riwayah == QuranRiwayah.hafs,
      EveryAyahNumbering.warshMadaniLastWithKnownDifferences =>
        ayah.riwayah == QuranRiwayah.warsh &&
            ayah.surahNumber != 26 &&
            ayah.surahNumber != 67,
      EveryAyahNumbering.warshKufic => false,
    };
    if (!compatible) throw EveryAyahMappingRequiredException(reciter, ayah);
    return List<EveryAyahAudioSegment>.unmodifiable([
      EveryAyahAudioSegment(
        uri: clipUri(
          reciter,
          surahNumber: ayah.surahNumber,
          clipNumber: ayah.verseNumber,
        ),
      ),
    ]);
  }
}

Uri _directory(Uri uri) {
  if ((uri.scheme != 'https' && uri.scheme != 'http') ||
      uri.host.isEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      uri.userInfo.isNotEmpty) {
    throw ArgumentError.value(uri, 'baseUri', 'Expected an HTTP(S) directory.');
  }
  return uri.path.endsWith('/') ? uri : uri.replace(path: '${uri.path}/');
}

void _checkSurah(int surah) {
  if (surah < 1 || surah > 114) {
    throw RangeError.range(surah, 1, 114, 'surahNumber');
  }
}

int _nativeVerseCount(QuranRiwayah riwayah, int surah) {
  if (riwayah == QuranRiwayah.hafs) return _kuficClipCounts[surah - 1];
  // KFGQPC Warsh Madani-last data and this recording directory agree on all
  // surah totals except these two. Do not infer audio mappings from the totals.
  if (surah == 26) return 226;
  if (surah == 67) return 31;
  return _warshAbdulBasitClipCounts[surah - 1];
}

// Sources: https://everyayah.com/data/Alafasy_128kbps/000_checksum.md5
// and the matching Warsh Abdul Basit directory's 000_checksum.md5. Numbered
// clips only; the special AAA=000 files are not Quran ayah references.
const _kuficClipCounts = <int>[
  7,
  286,
  200,
  176,
  120,
  165,
  206,
  75,
  129,
  109,
  123,
  111,
  43,
  52,
  99,
  128,
  111,
  110,
  98,
  135,
  112,
  78,
  118,
  64,
  77,
  227,
  93,
  88,
  69,
  60,
  34,
  30,
  73,
  54,
  45,
  83,
  182,
  88,
  75,
  85,
  54,
  53,
  89,
  59,
  37,
  35,
  38,
  29,
  18,
  45,
  60,
  49,
  62,
  55,
  78,
  96,
  29,
  22,
  24,
  13,
  14,
  11,
  11,
  18,
  12,
  12,
  30,
  52,
  52,
  44,
  28,
  28,
  20,
  56,
  40,
  31,
  50,
  40,
  46,
  42,
  29,
  19,
  36,
  25,
  22,
  17,
  19,
  26,
  30,
  20,
  15,
  21,
  11,
  8,
  8,
  19,
  5,
  8,
  8,
  11,
  11,
  8,
  3,
  9,
  5,
  4,
  7,
  3,
  6,
  3,
  5,
  4,
  5,
  6,
];

const _warshAbdulBasitClipCounts = <int>[
  7,
  285,
  200,
  175,
  122,
  167,
  206,
  76,
  130,
  109,
  121,
  111,
  44,
  54,
  99,
  128,
  110,
  105,
  99,
  134,
  111,
  76,
  119,
  62,
  77,
  227,
  95,
  88,
  69,
  59,
  33,
  30,
  73,
  54,
  46,
  82,
  182,
  86,
  72,
  84,
  53,
  50,
  89,
  56,
  36,
  34,
  39,
  29,
  18,
  45,
  60,
  47,
  61,
  55,
  77,
  99,
  28,
  21,
  24,
  13,
  14,
  11,
  11,
  18,
  12,
  12,
  30,
  52,
  52,
  44,
  30,
  28,
  18,
  55,
  39,
  31,
  50,
  40,
  45,
  42,
  29,
  19,
  36,
  25,
  22,
  17,
  19,
  26,
  32,
  20,
  15,
  21,
  11,
  8,
  8,
  20,
  5,
  8,
  9,
  11,
  10,
  8,
  3,
  9,
  5,
  5,
  6,
  3,
  6,
  3,
  5,
  4,
  5,
  6,
];
