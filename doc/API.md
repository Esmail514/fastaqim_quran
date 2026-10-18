# Public API reference

```dart
import 'package:fastaqim_quran/fastaqim_quran.dart';
```

Use this entry point instead of internal `lib/src/` imports. Generated HTML
(`python tool/build_docs.py`) provides exact signatures and all public
members; this guide explains the contracts that matter to a host app.

## References

`QuranRiwayah` has `hafs` and `warsh`. `QuranAyahReference` stores `riwayah`,
`surahNumber` and `verseNumber`; equality, hashing and `key` include narration.
For example, `hafs:2:255` is a different reference from `warsh:2:255`.

`QuranWordReference` adds a **1-based** `wordPosition`, for example
`hafs:2:2:4`. Its `ayahReference` retains the narration and native ayah number.
The position identifies a word in the host's verified word dataset, not a QCF
code point or a space-delimited text token. The reference does not add word hit
targets to the printed page. See [Word references](WORD_REFERENCES.md).

Page/surah/verse numbers are **1-based**. `PageController.jumpToPage` uses a
**0-based** index. Top-level legacy helpers always use Hafs; selecting Warsh
in a widget does not change them.

Constants: `totalPagesCount` = 604, `totalSurahCount` = 114,
`totalJuzCount` = 30, `totalVerseCount` = 6236 (Hafs),
`totalMakkiSurahs` = 89, `totalMadaniSurahs` = 25.

## Widgets

| Widget | Required arguments | Purpose |
| --- | --- | --- |
| `PageviewQuran` | None | RTL paged mushaf; initial page is 1 |
| `QcfPage` | `pageNumber` | Single fixed page |
| `QcfVerse` | `surahNumber`, `verseNumber` | Single ayah |
| `QcfVerses` | `surahNumber`, `firstVerse`, `lastVerse` | Inclusive flowing range in one surah |
| `WarshPage` | `pageNumber` | Direct Warsh SVG page |
| `HeaderWidget` | `suraNumber` | Standalone QCF-style surah heading |

The four main Quran widgets accept `riwayah`, `warshMushaf`, and theme options.
Hafs is the default. `PageviewQuran` and `QcfPage` additionally expose
`warshPagePictureBuilder`, `warshLoadingBuilder`, and narration-aware
`onAyahTap`. Legacy page tap/long-press callbacks use native selected-narration
numbers. `QcfVerse.onTap` is a `VoidCallback`; `QcfVerses.onTap` receives
surah/verse numbers. `QcfVerse.onLongPressDown` receives
`LongPressDownDetails`; the page callbacks use `LongPressStartDetails`.

`sp` and `h` are scale factors (default 1), not an automatic device-scaling
service. ScreenUtil is optional and is only a dependency of the example app.
`fontSize` changes flowing text/QCF text; it does not reflow fixed Warsh SVGs.
For Hafs, the widget's explicit `fontSize` takes priority over `theme.fontSize`,
then the existing responsive default. Flowing `QcfVerses` respects the host
`MediaQuery.textScaler`.

`PageviewQuran` owns its internally created controller. Dispose externally
supplied controllers yourself. `windowSize` defaults to 5 on each side.
An external controller's initial page takes priority on first mount; switching
back to an internal controller preserves the current page. The package never
disposes an externally supplied controller.
When embedding `QcfPage` in another pager, update `currentPage` for correct
keep-alive window behavior.

## Theme

Construct `QcfThemeData()`, `QcfThemeData.dark()` or `QcfThemeData.sepia()`;
customize with `copyWith`. Pass a theme explicitly: host-app brightness does
not automatically choose the package theme.

| Group | Properties |
| --- | --- |
| Text | `verseTextColor`, `verseNumberColor`, `basmalaColor`, `headerTextColor` |
| Background | `pageBackgroundColor`, `verseBackgroundColor`, `verseNumberBackgroundColor`, `headerBackgroundColor` |
| Layout | `horizontalPadding`, `verticalPadding`, `verseHeight`, `verseNumberHeight`, `letterSpacing`, `wordSpacing` |
| Sizing | `fontSize`, `basmalaFontSizeLarge/Small`, `basmalaSpecialFontSizeLarge/Small`, `headerFontSizeLarge/Small` |
| Header | `showHeader`, `headerWidthLarge/Small`, `customHeaderBuilder`, `headerBorderRadius` |
| Builders | `showBasmala`, `basmalaBuilder`, `verseNumberBuilder` |

Highlight callback: `Color? Function(int surahNumber, int verseNumber)`.
`QcfPage.verseBackgroundColor` overrides the theme callback. QCF-only heading,
spacing and verse-number options cannot rearrange a fixed Warsh SVG. Its text
color tints the picture as a whole. A matching custom picture builder is
required for changing the source picture itself.

`copyWith` treats null as “retain the existing value”; passing null does not
clear nullable fields. Prefer `theme` over legacy widget color properties.

## Hafs text

| API | Result |
| --- | --- |
| `getVerse(surah, verse, verseEndSymbol: false)` | Readable text with optional conventional end symbol |
| `getVerseData(surah, verse)` | Six-field record, or null for an unknown reference |
| `getVerseQCF(surah, verse, verseEndSymbol: true)` | Page-specific QCF glyphs |
| `getVerseNumberQCF(surah, verse, ...)` | QCF end-number glyph; legacy optional argument retained |
| `getVerseEndSymbol(verse, arabicNumeral: true)` | Conventional end symbol and digits |
| `HafsText.getSourceVerse(surah, verse)` | Original publisher text including its end-marker glyph |
| `HafsText.getVerse(surah, verse)` | Display slice without the source end marker |
| `HafsText.getSearchVerse(surah, verse)` | Publisher-provided search text |
| `HafsText.fontFamily` | `QCF_HafsUnicode`; use `package: 'fastaqim_quran'` in `TextStyle` |
| `quranText` / `activeQuranText` | Read-only Hafs corpus |
| `invalidateVerseIndex()` | Resets the legacy derived lookup index; normally unnecessary |

The six record fields are `surah_number`, `verse_number`, `content`,
`text_normal`, `qcfData`, `qcfv4data`. QCF glyph strings require the matching
page font; they are not ordinary readable Unicode text.

## Metadata and utilities

| API | Purpose |
| --- | --- |
| `getPageData(page)` | Surah/start/end page ranges |
| `getPageNumber(surah, verse)` | Hafs printed page |
| `getSurahCountByPage(page)`, `getVerseCountByPage(page)` | Page counts |
| `getJuzNumber(surah, verse)` | Juz lookup |
| `getSurahName`, `getSurahNameEnglish`, `getSurahNameArabic` | Names from bundled metadata |
| `getPlaceOfRevelation`, `getVerseCount` | Legacy surah metadata |
| `pageData`, `juz`, `surah` | Exported metadata lists; prefer lookup functions |
| `getFontSize`, `getScreenType`, `ScreenType` | Legacy responsive sizing helpers |
| `SurahFontHelper.getSurahGlyph`, `formatSurahText`, `fontFamily` | Surah-name glyphs and formatted `surahNNN` spans |
| `convertToArabicNumber(String)` | Converts ASCII digits; punctuation is not accepted |
| `normalise`, `removeDiacritics` | Search/comparison only; never rewrite canonical display text |

`searchWords` searches Hafs and returns at most 50 matches. It first searches
`text_normal`, then falls back to readable text if there are no initial matches:

```dart
final matches = searchWords('الرحمن');
final count = matches['occurences']; // Existing API spelling.
final rows = matches['result']; // Each row has suraNumber and verseNumber.
```

There is no top-level Warsh equivalent of this search function. A host app
may search `WarshMushaf.verses`, retaining native references in each result.

## Warsh data

| API | Contract |
| --- | --- |
| `WarshMushaf.load(bundle: ...)` | Async local text/manifest load; shares the default future |
| `WarshMushaf.fromData(...)` | Validates custom pages/references; not a narration converter |
| `editionId`, `fontFamily`, `verseCount`, `pageCount`, `verses` | Metadata and verse iteration |
| `getVerse`, `getVerseCount`, `getPageNumber`, `getPageNumbers` | Native Warsh lookups; a verse may continue across pages |
| `loadPage(page)` | Lazy local geometry; failed loads can be retried |
| `WarshVerse` | Native numbers, text, juz, page list, `reference`, `endMarker`, `textWithoutEndMarker` |
| `WarshPageData` | `pageNumber`, `viewBox`, regions, optional `svgAsset`/`svgUri`; `ayahAt` expects source coordinates |
| `WarshAyahRegion` | Warsh reference, polygon and parsed `Path` |
| `WarshPagePictureBuilder` | `(BuildContext, WarshPageData) -> Widget`; match the assigned rectangle and source coordinates |

`WarshVerseText` is internal and is not exported by the main entry point;
use `QcfVerse`/`QcfVerses` for flowing Warsh text.

Custom `WarshVerse` values require valid surah/juz numbers and nonempty unique
pages within 1–604. `fromData` requires each provided surah's ayah numbers to
start at 1 and be contiguous, every referenced page to be provided, and page
regions to match each ayah's page list. Partial custom data is not a verified
complete Quran edition.

## Audio and errors

See [AUDIO.md](AUDIO.md) for all audio provider/model interfaces.
Legacy helpers sometimes throw strings; newer interfaces use `ArgumentError`,
`RangeError`, `FormatException`, `StateError` and named audio exceptions.
Validate input, show short user-facing failures, and never silently substitute
a different narration when a reference cannot be resolved.
