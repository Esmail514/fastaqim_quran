# Publication records

## Published release — fastaqim_quran 0.1.0

- Package: [fastaqim_quran 0.1.0](https://pub.dev/packages/fastaqim_quran/versions/0.1.0).
- Repository: [Esmail514/fastaqim_quran](https://github.com/Esmail514/fastaqim_quran), public.
- Source commit at upload:
  [`8eff3388ab0243a0e7525fd7ef00b63e02f4106b`](https://github.com/Esmail514/fastaqim_quran/commit/8eff3388ab0243a0e7525fd7ef00b63e02f4106b).
- GitHub release:
  [fastaqim_quran-v0.1.0](https://github.com/Esmail514/fastaqim_quran/releases/tag/fastaqim_quran-v0.1.0),
  tagging that source commit.
- Published timestamp reported by pub.dev: `2026-10-18T10:52:31.369917Z` (UTC).
- Hosted archive SHA-256 reported by pub.dev:
  `3680c24800bc0487f021bec0779b11b9e22d9f2cdad2308e7e43e0161d1caf1e`.
- The publishing command confirmed success, and the
  [package API](https://pub.dev/api/packages/fastaqim_quran) reported version
  `0.1.0`, its archive URL, timestamp and hash.

### Installation

```yaml
dependencies:
  fastaqim_quran: ^0.1.0
```

```dart
import 'package:fastaqim_quran/fastaqim_quran.dart';
```

### Validation and follow-up

Before publication, 97 package tests, 864 Fastaqim application tests and one
example test passed. All three analyzers were clean; the example web build
succeeded. The publication dry run reported zero warnings and a 55 MB archive.
All 1231 package assets retained their original bytes during the rename.
See [Validation](VALIDATION.md).

A separate Flutter project installed exact version `0.1.0` from pub.dev with
no local override or old-name dependency. Its lock file recorded
`source: hosted`, `https://pub.dev` and the archive SHA-256 above. Its package
configuration resolved `fastaqim_quran` to the hosted pub cache.

The hosted smoke test passed for the public `getVerse` API, all 6236 Hafs
corpus rows, Hafs/Warsh manifest counts of 6236/6214 ayahs and 604 pages, and
bundled asset loading: Hafs page 604 font, both Unicode fonts, Warsh page 604
geometry and SVG page 003. This verifies archive delivery and asset
registration; it does not independently certify every rendered page.

The former `mushaf_riwayat` package has not been discontinued or deleted as
part of this record. Its original publication evidence is preserved below.

## Historical published release — mushaf_riwayat 0.1.0

- Package: [mushaf_riwayat 0.1.0](https://pub.dev/packages/mushaf_riwayat/versions/0.1.0).
- Repository: [Esmail514/mushaf_riwayat](https://github.com/Esmail514/mushaf_riwayat), public.
- GitHub release: [v0.1.0](https://github.com/Esmail514/mushaf_riwayat/releases/tag/v0.1.0),
  tagging the source commit used for the hosted archive.
- Source commit at upload: `1fa8528fa6dbb3914ff8124ceecf4202322dfe58`.
- Published timestamp reported by pub.dev: `2026-10-12T06:55:05.442463Z` (UTC).
- Hosted archive SHA-256 reported by pub.dev:
  `62b2cef21f75583da73f5bdcfd45d16dcf105432805f68b56866d1b5c48d2fa9`.
- The CLI confirmed successful upload; the package API and HTML page returned
  HTTP 200 with version `0.1.0`.

### Historical installation

```yaml
dependencies:
  mushaf_riwayat: ^0.1.0
```

```dart
import 'package:mushaf_riwayat/mushaf_riwayat.dart';
```

The pre-publication review, 76 package tests, example test, analyzer, web build
and source checks are recorded in [Validation](VALIDATION.md) and
[Release review](RELEASE_REVIEW.md). The public release preserves component
license notices and the [reported upstream permission](UPSTREAM_PERMISSION.md).

### Verification after the former publication

A separate Flutter project installed exact version `0.1.0` from `https://pub.dev`,
with no local path override. Its lock file recorded `source: hosted` and the
archive SHA-256 above; the package resolved to the hosted pub cache.

Its test passed for the public data API, the 6236-row Hafs corpus, Hafs/Warsh
manifest counts, and bundled asset loading: Hafs page 604 font, both Unicode
fonts, Warsh page 604 geometry, and SVG page 003. This verifies archive delivery
and asset registration; it does not independently certify all rendered pages.

The pub.dev score API reported **155/160** at this verification. Scores can
change when platform analysis or scoring rules change.
