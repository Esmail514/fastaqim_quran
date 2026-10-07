# Contributing to Riwayat Quran

The public package name stays `qcf_quran`. Work from this package root;
the nested local repository is separate from the surrounding app history.

## Make a focused change

1. Inspect the exported interface, related implementation and tests.
2. Keep Hafs defaults and existing compatible imports unless a documented
   breaking release is intended.
3. For a bug, reproduce the failure with an appropriate existing/new test,
   apply the smallest fix, and run the test again.
4. Update relevant documentation and the `Unreleased` changelog.
5. Run `flutter analyze --no-preamble --no-fatal-infos` and `flutter test`.
   If the example changes, also run its tests from `example/`.
6. Review `git diff` and stage explicit files before committing.

## Quran data integrity

- Never normalize, reword or manually “correct” publisher display text.
- Retain native narration/counting-system references everywhere.
- Search transformations must stay separate from canonical source text.
- Source upgrades require reviewed provenance, original hashes and complete
  corpus/geometry checks. Do not update a test digest to hide a mismatch.
- Use matching source picture and hit geometry. Review continuation verses
  and coordinate transforms when changing Warsh interaction.
- Never infer audio mapping solely from matching numeric references.

Preserve `LICENSE` and `THIRD_PARTY_NOTICES.md`. New dependencies or caches
need a concrete reason; existing functionality should not be rewritten during
documentation work. Do not stage generated build output or credentials.

Read [maintenance](docs/MAINTENANCE.md), [API](docs/API.md),
[data/assets](docs/DATA_AND_ASSETS.md), and [verification](docs/VALIDATION.md)
before changing their corresponding parts.
