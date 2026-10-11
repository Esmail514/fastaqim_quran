# Performance and troubleshooting

This guide describes current implementation behavior, not a measured guarantee
of frame rate, memory consumption or performance on every device.

## Loading and lifecycle

- `PageviewQuran` uses lazy page building. Its default keep-alive window is
  five pages on either side; Flutter may keep additional transient pages
  while scrolling. It is not an exact global memory cap.
- Hafs lookup uses a lazily built verse index. `searchWords` still scans the
  corpus and caps results at 50; debounce text input in the host app.
- `WarshMushaf.load()` shares the default loading future. It loads local text
  and manifest, not remote SVGs. Geometry is loaded per page and its futures
  are retained in the mushaf object's page cache; keep-alive limits do not
  evict this data cache.
- Warsh rendering loads/decodes artwork separately. Its widget guards stale
  loads and disposes pictures and gesture recognizers during lifecycle changes.
- Keep futures and HTTP clients outside `build`. Dispose externally owned
  controllers/clients in their owners, not inside each rebuild.

## Assets and network

The 1233 existing asset files occupy approximately 66,961,226 bytes (64 MiB)
before compression. APK/AAB size depends on compression, build settings and
the host application; do not equate this measurement with install size.

Hafs pages and Warsh readable text/geometry are local. Default Warsh pictures
for pages 4–604 require internet. There is no persistent disk artwork cache
provided by the package. A host-provided picture builder can supply local
artwork but must preserve the matching geometry and aspect ratio.

`warshLoadingBuilder` accepts your placeholder; a shimmer can be supplied
by the host without adding a shimmer dependency to this package. Failed
default artwork loads show a retry action. Hit regions remain disabled until
the default picture is ready.

## Common problems

| Symptom | Check / solution |
| --- | --- |
| Wrong verse text in an older app | Use the main public import and canonical Hafs helpers, not legacy internal raw data |
| Warsh page works at first, later pages fail offline | Only the first three default pictures are local; provide offline artwork explicitly |
| Text uses strange symbols | QCF glyphs need the corresponding page font; source Unicode text needs its publisher font |
| Dark app, white Quran page | Pass `QcfThemeData.dark()` or a custom theme; brightness is not automatically applied |
| Warsh font-size change has no effect on a printed page | Fixed SVG pictures scale as a whole; use flowing verse widgets for text sizing |
| Wrong tapped ayah in a custom picture | Match `viewBox`, picture bounds and geometry; include negative source coordinates |
| Same numbers produce different Hafs/Warsh passages | Preserve `QuranAyahReference.riwayah`; do not copy references by number alone |
| Surah audio URL rejected | Check `availableSurahs`; reader collections may be incomplete |
| EveryAyah requests a mapping | Supply a verified numbering/timing map; never guess the clip index |
| Negative or invalid page | Validate 1–604, and subtract one only when calling the Flutter controller |
| Fonts missing after integration | Use the actual local package dependency, run `flutter pub get`, rebuild; do not rename its asset prefix |
| Network works in debug but fails in Android release | Verify the main manifest has `android.permission.INTERNET` |

## Profile before changing behavior

Use a real device and `flutter run --profile` in the example or host app.
Check frame timing, decoded pictures, retained page/geometry data and HTTP
activity while navigating many pages. Compare the same device, narration and
navigation sequence. Documentation/tests alone are not performance profiling.
