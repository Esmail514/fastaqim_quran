# Data, assets and source layout

## Repository map

| Path | Role |
| --- | --- |
| `lib/qcf_quran.dart` | Public entry point and exports |
| `lib/src/qcf_page.dart`, `quran_pageview.dart` | Fixed page rendering, interaction and paging |
| `lib/src/qcf_verse.dart`, `qcf_verses.dart` | Single/range text widgets |
| `lib/src/qcf_theme_data.dart`, `header_widget.dart`, `helpers/` | Theme, heading and numeral utilities |
| `lib/src/data/` | Hafs corpus, glyphs, source-derived readable text, page/juz/surah metadata |
| `lib/src/riwayah.dart` | Narration-aware references |
| `lib/src/warsh/` | Independent Warsh corpus, geometry and rendering |
| `lib/src/audio/` | MP3Quran catalogs and EveryAyah URL resolution |
| `assets/fonts/` | 604 page font families, basmala, surah-name and number fonts |
| `assets/hafs/` | Publisher manifest, text and paired Unicode font |
| `assets/warsh/` | Publisher manifest/text/font, 604 geometry files, three bundled SVGs and notices |
| `test/` | Data, interaction, rendering and audio-provider tests |
| `example/` | Flutter application demonstrating the public package |
| `tool/` | Reproducible publisher-asset import and Dart-data generation scripts |
| `quran_text.dart` | Retained root-level legacy corpus; not the public import entry point |
| `docs/` | Package documentation |

## Canonical text and glyphs are different

Hafs's `aya_text` and `aya_text_emlaey` come from the unchanged KFGQPC
`hafsData_v2-0.json`. `hafs_source_data.dart` is generated from that source,
while `hafs_text.dart` joins the readable fields to original QCF records by
surah and verse. Use the public corpus, not the preserved legacy raw text
file: its old readable fields mixed Warsh strings with Hafs positions.

QCF glyphs use `QCF_P001` through `QCF_P604`; normal publisher text uses
`QCF_HafsUnicode`. Warsh source text is `warshData_v2-1.json`, with font family
`QCF_Warsh`. When rendering source Unicode text directly, specify
`package: 'qcf_quran'` along with the matching font family.

Both narrations contain 114 surahs and 604 printed pages. Hafs uses 6236
native ayahs; Warsh uses 6214. Never align corpora by array index.

## Manifests and geometry

`assets/hafs/manifest.json` records source archive/member paths, SHA-256
digests, native verse counts, font family and edition identity.
`assets/warsh/manifest.json` also records page view boxes, geometry/SVG hashes,
source URLs, local SVG assets and continuation references.

Warsh has 6218 regions covering 6214 verses; four verses continue across two
pages. Regions are original polygons in each SVG's coordinate space, which
can include negative origins. Apply the same view-box and scale transform to
artwork and interaction. Do not trim or stretch the artwork independently
of those regions.

Only SVGs `001.svg`–`003.svg` are bundled. Other page descriptors use the
pinned upstream commit recorded in the manifest. Text, font and all geometry
are local. The upstream picture removes the printed frame, running header
and page number and redraws ayah ornaments; it is not an identical image of
every decoration of the printed edition.

`.gitattributes` disables text conversion for `assets/**` so Git preserves
publisher bytes, including source notices. Never normalize the source Quran
text or regenerate it from search-normalized strings.

## Import and generation tools

These scripts write assets/source files; do not run them merely to read docs.
Use Python 3.11+ from the package root:

```sh
python tool/import_hafs_assets.py
python tool/generate_hafs_source_data.py
python tool/import_warsh_assets.py
```

| Tool | Reads and writes |
| --- | --- |
| `import_hafs_assets.py` | Downloads a pinned publisher archive; verifies its hash; writes original text/font/read-me and manifest |
| `generate_hafs_source_data.py` | Reads bundled Hafs JSON, verifies the expected digest and end markers, writes deterministic `lib/src/data/hafs_source_data.dart` |
| `import_warsh_assets.py` | Downloads/verifies publisher assets and all 604 source SVG/JSON files; persists all geometry, three SVGs, original text/font/notices and manifest |
| `build_docs.py` | Runs the installed Dart documentation generator and fixes guide links in local HTML; writes only `docs/generated/` |

Importers fetch no audio. Network re-imports can be lengthy. Review diffs and
run corpus/geometry tests before saving regenerated files. Do not update
expected hashes simply to make tests accept an unexplained source change.

See [THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md) for complete provenance,
licenses, hashes and source identities; do not replace it with a generic
package-code license.
