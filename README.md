# Fastaqim Quran — قرآن فاستقم

A Flutter Quran package for fixed mushaf pages, readable publisher text,
narration-aware ayah interaction, and audio URL providers. **Fastaqim Quran**
is its display identity; its Dart package name and public entry point are
**`fastaqim_quran`** and **`lib/fastaqim_quran.dart`**.

This edition currently supports **Hafs and Warsh**. Other narrations are not
implemented. Release `0.1.0` introduces `fastaqim_quran`, replacing the former
`mushaf_riwayat` identity. See [migration](doc/MIGRATION.md),
[CHANGELOG.md](CHANGELOG.md) and the
[historical release record](doc/PUBLISHED_RELEASE.md).

[العربية](README.ar.md) · [Documentation](doc/README.md) ·
[API reference](doc/API.md) · [Demo](example/README.md) ·
[Use policy](USE_POLICY.md) · [Support](SUPPORT.md)

**The complete edition with bundled assets is for non-commercial, charitable
use only.** Component licenses remain in force. Source repository:
[Esmail514/fastaqim_quran](https://github.com/Esmail514/fastaqim_quran).

## Included capabilities

| Feature | Hafs | Warsh |
| --- | --- | --- |
| Surahs / printed pages | 114 / 604 | 114 / 604 |
| Native ayahs | 6236, Kufan count | 6214, Madani-last count |
| Original readable text and Unicode font | Local | Local |
| Fixed page renderer | Local QCF page fonts | SVG pictures and matching hit geometry |
| Default pictures without internet | All pages | Pages 1–3; remaining pictures are online |
| Tap, long press, highlighting | Supported | Supported when picture is ready |
| Audio integration | Catalogs and URLs | Catalogs and URLs with numbering guards |

No audio files, player, tafsir database, bookmarks database or notification
service are included. Flowing verse text and fixed printed page layout are
different display modes. See [assets/data](doc/DATA_AND_ASSETS.md).

## Installation

For the hosted release under the new name:

```yaml
dependencies:
  fastaqim_quran: ^0.1.0
```

Publishing instructions and hosted verification are tracked in
[Publishing](doc/PUBLISHING.md). The local edition can also be used below.

Requires **Dart >=3.7.0 <4.0.0** and **Flutter >=3.29.0**. For a Flutter app
located next to the `custom_packages` directory:

```yaml
dependencies:
  fastaqim_quran:
    path: ../custom_packages/fastaqim_quran
```

Run `flutter pub get`. Adjust `path` if your directory layout differs. Package
fonts/assets are registered automatically; do not copy or rename them.
See [migration](doc/MIGRATION.md) when updating an application that used
`mushaf_riwayat`; imports and direct font/asset package keys must be updated.

## Display a mushaf

```dart
import 'package:flutter/material.dart';
import 'package:fastaqim_quran/fastaqim_quran.dart';

class MushafScreen extends StatelessWidget {
  const MushafScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: PageviewQuran(
      riwayah: QuranRiwayah.hafs, // Or QuranRiwayah.warsh.
      initialPageNumber: 1,
      theme: QcfThemeData.dark(),
      onAyahTap: (reference) {
        // Store reference.key: narration, surah, and native ayah number.
      },
    ),
  );
}
```

Hafs is the default. Use `QcfPage` for one printed page, `QcfVerse` for one
ayah, or `QcfVerses` for an inclusive flowing range within one surah.

## Read the correct text

```dart
final hafs = getVerse(2, 255); // Top-level helpers always use Hafs.
final warsh = await WarshMushaf.load();
final verse = warsh.getVerse(2, 285);
final pages = warsh.getPageNumbers(2, 285);
```

Native Hafs/Warsh ayah numbers may identify different passages. Never reuse
Hafs tafsir or audio references for Warsh by number alone. Differences in ayah
counts do not indicate missing Quran text. [Narration integration](doc/WARSH_INTEGRATION.md).

## Audio URLs

```dart
final api = Mp3QuranApi();
try {
  final readers = await api.getReciters(riwayahId: 1, surahNumber: 1);
  if (readers.isNotEmpty && readers.first.moshafs.isNotEmpty) {
    final url = readers.first.moshafs.first.surahUri(1);
    // Pass url to your application's player.
  }
} finally {
  api.close();
}
```

Display only `availableSurahs` for the selected collection. EveryAyah also
builds clip URLs without downloading recordings; incompatible numbering needs
verified mapping. [Audio guide](doc/AUDIO.md).

## Offline use and performance

Hafs pages, and Warsh text/font/geometry, are local. Default Warsh pictures for
pages 4–604 need internet. For fully offline Warsh pages, supply matching local
artwork through `warshPagePictureBuilder`. Customize the loading state with
`warshLoadingBuilder`, for example using your app's shimmer.

The assets occupy about **64 MiB before compression**, not an APK size estimate.
Keep loading futures outside `build`, manage external controllers/clients,
and profile actual target devices. [Performance guide](doc/PERFORMANCE_AND_TROUBLESHOOTING.md).

## Develop

```sh
flutter pub get
flutter analyze --no-preamble
flutter test
```

Run the demo from `example/` using `flutter run`.
[Contributing](CONTRIBUTING.md) · [Verification](doc/VALIDATION.md) ·
[Git, generated API docs and release preparation](doc/MAINTENANCE.md).

## Origins and rights

The original package is [Mahmoud Atef's qcf_quran](https://github.com/m4hmoud-atef/qcf_quran).
The code retains its [MIT license](LICENSE), and publisher assets retain their
separate rights in [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). Renaming
the display identity does not replace original authorship or asset terms.
The original README also carried this notice, retained here:

> This package and its bundled fonts are NOT for commercial use.

This historical notice does not override MIT rights for code or CC BY 4.0
rights for material covered by that license. The provenance and usage terms
of legacy QCF fonts are documented in the source notices. The maintainer
reports [upstream approval](doc/UPSTREAM_PERMISSION.md) to rebuild, modify
and republish the package; embedded font terms remain intact. This edition
does not grant commercial permission for third-party bundled assets.
The original licenses and asset notices are preserved. Source hashes and
structural tests do not constitute an independent scholarly review of all
Quran letters, page artwork or audible clip boundaries.

## Policy and contact

The package is available to everyone under its component licenses. Preserve
Quran source integrity and attribution; do not tamper with an official release,
impersonate its maintainer or present a modified fork as official. MIT and
CC BY permissions remain in force; [USE_POLICY.md](USE_POLICY.md) explains
the limits of a no-modification policy and welcomes honest criticism.

Maintainer: **Esmail Al-Sayaghi**, Fastaqim.
GitHub: [@Esmail514](https://github.com/Esmail514).
Phone: +967771209666.
Email: [asasesmail514@gmail.com](mailto:asasesmail514@gmail.com) or
[support.fastaqim@gmail.com](mailto:support.fastaqim@gmail.com).
Instagram: [@esmail_sayaghi](https://www.instagram.com/esmail_sayaghi/).
See [SUPPORT.md](SUPPORT.md) for reporting details and
[SECURITY.md](SECURITY.md) for sensitive security reports.
