# Publication records

## Fastaqim Quran 0.1.0 — release preparation

The package is being renamed to `fastaqim_quran`. The source repository is
[planned here](https://github.com/Esmail514/fastaqim_quran). This section records
preparation only; the archive hash, source commit and hosted verification for
the new name must be recorded after a successful upload. The evidence below
belongs exclusively to the former package name.

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
