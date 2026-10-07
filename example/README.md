# Mushaf Riwayat demo

A Flutter application using the local `qcf_quran` package. It demonstrates
Hafs pages, verse ranges, and a Hafs/Warsh reader with narration selection,
page navigation, ayah actions, highlights and audio URL catalogs.

## Run

From this directory:

```sh
flutter pub get
flutter run
```

The path dependency in this example points to the parent package. The example
uses ScreenUtil; the package itself does not require it. Select an installed
Flutter device/platform as usual.

## Read the examples

| File | Demonstrates |
| --- | --- |
| `lib/main.dart` | Demo entry point and navigation |
| `lib/riwayah_mushaf_example.dart` | Narration switch, page jump, ayah sheet, MP3Quran catalogs and EveryAyah URLs |
| `lib/quran_home_page.dart` | Legacy Hafs page reader |
| `lib/qcf_verses_example.dart`, `lib/qcf_verses_example_page.dart` | Verse ranges and layout examples |

This is an integration demo, not a full Quran application. It does not play
or download MP3 files. Warsh pictures after page 3 need internet by default;
failed pictures expose a retry action. Text/font/hit geometry are local.

## Verify

```sh
flutter test
flutter analyze --no-preamble --no-fatal-infos
```

The example has existing informational lints, documented in
[VALIDATION.md](../docs/VALIDATION.md). See [the package README](../README.md)
and [audio integration](../docs/AUDIO.md) before copying demo code into a
production application.
