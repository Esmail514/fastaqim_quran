# Audio integration

The package provides **catalog data and URLs**, not playback. It contains no
MP3 files, background audio service, downloading queue, cache, notifications,
or offline audio storage. Those belong to the consuming application.

## MP3Quran: complete surah recordings

```dart
final api = Mp3QuranApi();
try {
  final readers = await api.getReciters(riwayahId: 1, surahNumber: 1);
  if (readers.isNotEmpty && readers.first.moshafs.isNotEmpty) {
    final moshaf = readers.first.moshafs.first;
    final url = moshaf.surahUri(1);
    // Hand url to your player; only list moshaf.availableSurahs in your UI.
  }
} finally {
  api.close();
}
```

| Interface | Members / behavior |
| --- | --- |
| `Mp3QuranApi` | Optional `client`, `baseUri`, `timeout` (30 seconds by default) |
| `getRiwayat(language: 'ar')` | Narration catalog |
| `getSurahs(language: 'ar')` | Surah catalog |
| `getReciters(...)` | Filters: `language`, `reciterId`, `riwayahId`, `surahNumber`; filters collections as well as readers |
| `close()` | Idempotent; closes only a client created by this provider |
| `Mp3QuranRiwayah` | `id`, `name`, `fromJson`, narration metadata getters |
| `Mp3QuranSurah` | `number`, `name`, `fromJson` |
| `Mp3QuranReciter` | `id`, `name`, optional `letter`, `moshafs`, `fromJson` |
| `Mp3QuranMoshaf` | `id`, `name`, `server`, optional `riwayahId`, `moshafType`, `reportedSurahTotal`, `availableSurahs` |
| Collection helpers | `supportedRiwayah`, `warshRoute`, `isComplete`, `hasSurah`, `surahUri`, `playlist`, `fromJson` |
| `Mp3QuranWarshRoute` | `unspecified`, `azraq`, `asbahani` |
| `Mp3QuranApiException` | Catalog error: `message`, optional `uri`/`statusCode` |
| `SurahAudioUnavailableException` | Requested surah is absent from the collection |

Available surahs come from the actual `surah_list`, not the reported total.
`playlist` contains available surahs in Quran order; `isComplete` requires
all 114. Building a URL does not verify the remote MP3 exists or is playable.
If you inject an HTTP client, you retain responsibility for closing it.

The built-in mapping recognizes Hafs `1`, general Warsh `2`, Warsh Azraq `18`
and Warsh Asbahani `10`. These are service-specific identifiers, not interchangeable
reader IDs. Retrieve the catalog when displaying narration labels.

## EveryAyah: ayah clip recordings

```dart
final segments = EveryAyahProvider().resolveAyah(
  const QuranAyahReference(
    riwayah: QuranRiwayah.hafs,
    surahNumber: 2,
    verseNumber: 255,
  ),
  reciter: EveryAyahReciters.hafsAlafasy,
);
final uri = segments.single.uri;
```

| Interface | Members / behavior |
| --- | --- |
| `EveryAyahProvider` | Optional `baseUri`, `verifiedMapper`; URL generation is synchronous and does not fetch audio |
| `resolveAyah(reference, reciter: ...)` | Returns one or more `EveryAyahAudioSegment` values |
| `clipUri(reciter, surahNumber: ..., clipNumber: ...)` | Source clip number, **not** a displayed ayah-number conversion |
| `EveryAyahReciter` | `id`, `name`, `riwayah`, `directory`, `numbering`, `clipCount(surah)` |
| `EveryAyahReciters` | `hafsAlafasy`, `hafsHusary`, `hafsMinshawy`, `hafsAbdulBasit`, `warshAbdulBasit`, `warshIbrahimAldosary`, `warshYassinAlJazaery`, `all`, `forRiwayah` |
| `EveryAyahNumbering` | `hafsKufic`, `warshMadaniLastWithKnownDifferences`, `warshKufic` |
| `EveryAyahClip` | `surahNumber`, `clipNumber`, optional `start`/`end` |
| `EveryAyahAudioSegment` | `uri`, optional `start`/`end`, `isPartial` |
| `VerifiedEveryAyahMapper` | App callback returning verified source clips or null |
| `EveryAyahMappingRequiredException` | Mapping absent for an incompatible numbering system; holds `reciter`/`ayah` |

Hafs references can use compatible Hafs clips directly. Warsh Abdul Basit
requires verified mapping for Ash-Shuara (26) and Al-Mulk (67). Warsh Aldosary
and Yassin clips use Kufic numbering and require verified mapping for native
Warsh references. Do not bypass that guard by passing the displayed number to
`clipUri`. A narration mismatch is rejected.

A verified mapper must return clips from the same surah. Timing must satisfy
`0 <= start < end` when an end is supplied. Play every returned segment in
order and honor supplied time boundaries. Matching clip counts alone do not
establish audible verse boundaries; timings need actual verification.

## Network configuration and failure handling

For Android release builds using network pictures/catalogs/audio, declare
`android.permission.INTERNET` in the main application manifest. The example
also enables the macOS network-client entitlement. Other platforms must allow
the corresponding HTTPS requests in their host configuration.

Keep catalog futures outside `build`, close providers when their owner exits,
and display a retry action after network failures. Do not show raw exception
messages or assume every reader has every surah. The provider does not send
Supabase requests and needs no Supabase configuration.
