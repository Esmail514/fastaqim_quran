# Hafs and Warsh data and artwork

## Legacy font redistribution review — 2026-10-11

The 608 font files under `assets/fonts/` are inherited from the original
qcf_quran package and are separate from the two canonical Unicode fonts
documented below. Their complete provenance and redistribution permissions
have not yet been established for this edition.

Embedded `name` table notices in all 604 QCF page fonts require prior printing
and publication permission from King Fahd Glorious Quran Printing Complex;
183 also name DAR ALMARIFA EASY QURAN. Name ID 10 in
`assets/fonts/qcf4/QCF4001_X-Regular.woff` credits additional font features to
named contributors, restricts use to charitable purposes, and prohibits sale.
The `surah-name-v2.woff` name table identifies `qul.tarteel.ai` / IcoMoon but
contains no standalone license. These findings are not permission to
redistribute those fonts. Record applicable published usage terms or written
authorization covering these exact files before a public hosted release;
an applicable public grant can suffice without a separate personal letter.
The code's MIT license does not clear third-party
font rights. See [Publishing](doc/PUBLISHING.md) and [Use policy](USE_POLICY.md).

### Follow-up on the publisher's public permission — 2026-10-11

The maintainer reports that the fonts originate from the Complex and expects
publication to be permitted. This is provenance information, not a new license
grant. The publisher's digital-edition permission reproduced below supports
software and website use for the materials it covers. The remaining task is to
establish its scope for the inherited QCF files and any contributors' additions.

[QUL's QPC V4 resource](https://qul.tarteel.ai/resources/font/240) describes
bundling fonts in applications and serving them from a website or CDN.
[QUL's credits](https://qul.tarteel.ai/credits) distinguish Ayman Siddiqui's
tajweed contributions from the Complex's original fonts and images, and
[QUL's FAQ](https://qul.tarteel.ai/faq) requires checking each resource's
author-specific terms. These pages do not establish a blanket license for all
inherited files in this package. No byte-for-byte match with that download has
been established in this review.

Direct requests to `fonts.qurancomplex.gov.sa` and the publisher's digital
usage-rights page timed out during this follow-up. That access failure proves
neither permission nor prohibition. A source download and its applicable
published terms may resolve this without separate correspondence.

The following provenance applies to its specified assets only.

This package preserves the downloaded Qur'anic source text, font and artwork
without rewriting their letters, marks, glyphs or line layout. The package's
Flutter interaction layer is separate from those files.

## King Fahd Glorious Qur'an Printing Complex

The canonical Warsh text and its paired Unicode font are extracted, byte for
byte, from the publisher's **UthmanicWarsh_v2-1.zip** archive (2022 release).

- Original publisher URL: https://download.qurancomplex.gov.sa/resources_dev/UthmanicWarsh_v2-1.zip
- Accessible archive mirror: https://cdn.quran.ws/KFGQPC/resources/quran-dev/uthmanic-warsh/UthmanicWarsh_v2-1.zip
- Archive SHA-256: `d847a7e7002dfbed5d28db6684fd1d9c3d50b8bb63ad64cb38a46b9dad788b47`
- Original text member: `UthmanicWarsh_v2-1 data/warshData_v2-1.json`
- Original font member: `UthmanicWarsh_v2-1 font/uthmanic_warsh_v21.ttf`
- Distributed as `assets/warsh/source/warshData_v2-1.json` and
  `assets/warsh/fonts/uthmanic_warsh_v21.ttf`.

These publisher materials retain the Complex's own usage terms, reproduced
within `assets/warsh/source/quran-svg/LICENSE` in Arabic and English. The
publisher permits free use in software and websites. The package's code license
does not replace the publisher's rights in its text, fonts or page artwork.

The canonical readable **Hafs** source and its paired Unicode font are also
extracted, byte for byte, from the publisher's **UthmanicHafs_v2-0.zip** archive.
Its existing QCF page glyph records and page fonts are retained separately.

- Original publisher URL: https://download.qurancomplex.gov.sa/resources_dev/UthmanicHafs_v2-0.zip
- Accessible archive mirror: https://cdn.quran.ws/KFGQPC/resources/quran-dev/uthmanic-hafs/UthmanicHafs_v2-0.zip
- Archive SHA-256: `a7b0e5591945712ec5e4d6142938ae4d1e9b49bdc89dff06222789bfebdfd72c`
- Recorded publisher MD5: `cf6841aea5b1d1fd70d032b43ff08278`
- Recorded publisher SHA-1: `36ea5ab0d7ea1702f17ff43f9b50924cccd77ebf`
- Original text member: `UthmanicHafs_v2-0 data/hafsData_v2-0.json`
- Original font member: `UthmanicHafs_v2-0 font/uthmanic_hafs_v20.ttf`
- Distributed as `assets/hafs/source/hafsData_v2-0.json` and
  `assets/hafs/fonts/uthmanic_hafs_v20.ttf`.
- Text SHA-256: `d2960b3217962e7e4252abdcece67bea3d6b48271e4cd3af45bbbb2dd5c872ca`
- Font SHA-256: `d560bbbc7a90a4f4d416d206a5ac48bd8a1ad00273d64d232f16ca54941bd041`

The publisher's `aya_text` display text and `aya_text_emlaey` search text are
both retained exactly as supplied; the package does not derive a new Qur'anic
text by editing one into the other. `assets/hafs/manifest.json` records the
provenance, member paths, hashes and native 6236-ayah Kufan count.

## Quran.ws — Warsh SVG pages and ayah coordinates

Data from **Quran SVG** by Quran.ws, licensed under **CC BY 4.0**.

- Canonical repository: https://github.com/quran-ws/quran-svg
- Pinned commit: `b4155f07e4aea087d2c458069acff9f7c7e749f6`
- Source paths: `mushafs/warsh/kfqc/json/NNN.json` and
  `mushafs/warsh/kfqc/svg/NNN.svg`.
- The 604 per-page coordinate JSON files are distributed unchanged in
  `assets/warsh/pages/`. Only SVG pages 001–003 are bundled; the other artwork
  URLs point to that same pinned commit. Applications may provide their own
  matching page loader for offline use.
- Modified by this package: **no**. A separate `manifest.json` adds package paths,
  original SVG view boxes, coverage information and cryptographic digests.
- The complete upstream licensing notice, publisher terms, provenance and
  coordinate format notes are distributed under
  `assets/warsh/source/quran-svg/`.

The upstream page artwork derives from the Complex's
**1442-ai-warsh.zip** digital Mushaf master files. Its declared original archive
SHA-256 is `2a0c65131dac5a922502fb4740034fb4ffc57792a0b6e5c1cc34c5a3339dd5d7`.
Quran.ws states that its SVGs preserve the original printed letter artwork and
line arrangement, while removing the decorative frame, running header and page
number and redrawing ayah-marker ornaments. These SVGs therefore provide the
printed text layout; they are not photographic copies of every printed page
decoration. The package does not make a claim of a complete scholarly or visual
review of all Quranic source material.

## Reproducibility

`tool/import_warsh_assets.py` imports only data, a font and SVG artwork; it never
fetches audio. It verifies the publisher archive's SHA-256, all 604 original JSON
and SVG Git blob hashes against the pinned repository tree, paired polygon
coordinates, and coverage of all 6214 native Warsh ayahs. Publisher text bytes
are preserved, including their original end-of-ayah glyph code points.

All distributed source and page hashes are recorded in
`assets/warsh/manifest.json`. Structural checks establish identity and coverage;
they do not constitute an independent scholarly certification of every letter
or coordinate.

`tool/import_hafs_assets.py` independently verifies the Hafs publisher archive
hash and imports its original text, font and read-me. It validates 6236 ayahs,
114 surahs, contiguous native ayah numbering, coverage of all 604 pages and the
publisher's existing Hafs search-field identities for 1:1, 1:4 and 2:1. It does
not fetch audio or modify the original QCF renderer's page glyph files.
