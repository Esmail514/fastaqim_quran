## 0.1.0 — Fastaqim Quran

- Rename the package from `mushaf_riwayat` to `fastaqim_quran`, the public entry
  point to `fastaqim_quran.dart`, and the local folder to
  `custom_packages/fastaqim_quran`.
- Update application/example imports, font and asset package keys, repository
  metadata and bilingual migration guides. Preserve public APIs, original
  authorship, component licenses and Quran source assets.

- Reuse the supplied Warsh loading placeholder while self-recitation markers
  load, keeping the host app's shimmer consistent with page loading.
- Add opt-in `fitPageHeight` to Hafs page renderers: use bounded line spacing
  and balanced margins on tall portrait viewports while retaining Quran glyph
  sizes, text, line breaks, and ayah interaction. Keep short pages, landscape,
  overflowing text, and Warsh artwork at their original layout.
- Add optional `isVerseHidden` to page renderers for self-recitation: preserve
  Hafs glyph layout and visible ayah markers, and mask Warsh ayahs using their
  original regions while retaining their original number/ornament artwork
  without region outlines.
- Keep hidden text out of Hafs semantics and preserve tap/long-press callbacks
  and whole-ayah identity across Warsh page continuations.


## 0.1.0 — mushaf_riwayat (published 2026-10-12)

First Mushaf Riwayat release.

- Add a bilingual use policy and maintainer support/security contacts,
  preserving MIT and third-party permissions and documenting the limits of
  modification restrictions.
- Add release preparation and review documentation, and publishing exclusions
  for generated/private files and the duplicate historical root corpus.
- Designate the complete edition for non-commercial charitable use, preserving
  component licenses and recording the maintainer's reported upstream approval
  to rebuild, modify and republish the package.
- Fix controller replacement, Hafs font-size priorities and range text scaling,
  surah heading glyphs, invalid-reference key collisions, keep-alive updates,
  and Warsh long-press cancellation and custom-data validation.
- Wrap malformed MP3Quran catalog fields in `Mp3QuranApiException`, keep example
  verse ranges valid, and resolve the existing analyzer diagnostics.

- Rename the local edition to Mushaf Riwayat (مصحف الروايات) with the Dart
  package name `mushaf_riwayat` and public entry `mushaf_riwayat.dart`.
- Migrate the example, Fastaqim integration and font/asset package keys to
  the new name, preserving the API, Quran data, font families and local Git history.
- Add bilingual getting-started guides, public API/audio/assets/performance
  documentation, contributor and maintenance guides, and expansion criteria.
- Prepare independent local Git tracking while preserving publisher asset bytes.

- Add Warsh to the existing rendering widgets with narration-aware ayah taps,
  original Warsh text/font, and matching fixed SVG page layouts and hit regions.
- Keep Hafs as the default and preserve its data helpers and source assets.
- Correct the pre-existing readable Hafs corpus, which joined Warsh strings
  to Hafs glyph records by position. Use original KFGQPC Hafs text/search fields
  keyed by surah and ayah, while preserving QCF page glyphs and numbering.
- Allow ayah taps and long presses together in both page views.
- Add online MP3Quran catalogs/surah URLs and EveryAyah clip URL providers,
  with explicit errors where verified Warsh numbering conversions are required.
- Add a two-riwayah example, source notices, and integration documentation.
- Bundle Warsh artwork for pages 1–3; use pinned online artwork for other pages.

The following versions describe the original qcf_quran release history.

## 0.0.5

- Feat: Update Surah font and adjust alignments.
- Docs: Add Open Source and Non-Commercial Use disclaimer.

## 0.0.4

- Misc: Version bump.

## 0.0.3

- Fix: Improve bismillah rendering with proper spacing and line handling
- Fix: Correct verse text formatting with proper spacing after first character

## 0.0.2
 
- Docs: Fix README images to absolute raw GitHub URLs so they render on pub.dev
- Docs: Fix Arabic README language link; add QCF fonts overview and video link
- Chore: Normalize hyphens in pubspec description to ASCII
 
## 0.0.1
 
- Initial release with per-page QCF fonts (604 pages), `QcfVerse` and `PageviewQuran` widgets, data helpers, and example app.
