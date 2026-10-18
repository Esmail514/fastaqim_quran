# Word references and study views

`QuranWordReference` is an immutable identifier containing `riwayah`,
`surahNumber`, `verseNumber`, and the **1-based** `wordPosition`. Its equality,
hash, and `key` include all four values. `ayahReference` returns the enclosing
narration-aware ayah reference.

```dart
const word = QuranWordReference(
  riwayah: QuranRiwayah.hafs,
  surahNumber: 2,
  verseNumber: 2,
  wordPosition: 4,
);
assert(word.key == 'hafs:2:2:4');
```

Use a word position from a verified, edition-compatible word dataset. A word
may have several morphological segments or several QCF glyphs. Space splitting
of publisher text and indexing QCF characters are not interchangeable word
identifiers. Never transfer a Hafs word position to Warsh by matching numbers.

The current package widgets still expose ayah interaction. A host can open a
dedicated Unicode word-study view after selecting an ayah, using its separately
verified word data and retaining the original printed mushaf unchanged. The
identifier alone does not establish a word's grammar, pronunciation, or its
position in printed artwork.

## Requirements before adding printed-page word targets

- Obtain a source that explicitly permits the intended offline packaging and
  redistribution of the word-to-glyph mapping, and preserve its attribution.
- Pin source versions and hashes, compare every mapped ayah to the exact local
  glyph string, and exclude mismatches rather than guessing offsets.
- Keep source text, fonts, and line layout intact. Compute hit boxes from the
  rendered glyph ranges, accounting for inline headers and layout characters.
- Obtain matching word geometry for Warsh SVGs; the existing ayah polygons do
  not describe individual words.

An October 2026 research comparison with Quran.com's regular API found matching
`code_v2` sequences in 6228 of 6236 local Hafs ayahs; eight ayahs differed:
`10:1`, `11:1`, `12:1`, `14:1`, `15:1`, `19:38`, `24:19`, and `26:11`.
This establishes a technical route, not a permission to redistribute that API's
word mapping. No Quran Foundation-derived map or API responses are bundled.

The [Quran Foundation Developer Terms](https://api-docs.quran.com/legal/developer-terms/)
define derived materials, restrict offline copies made from regular API
responses, and address prepackaged content separately from application display.
The [QUL V2 word resource](https://qul.tarteel.ai/resources/quran-script/61)
is another source to evaluate; its existence does not establish compatibility
or redistribution permission for a downloaded resource. Review its actual
source, version, and resource-specific terms before integration.
