# Local Git and maintenance

Display name: **Riwayat Quran — روايات القرآن**. Dart package name:
**`qcf_quran`**. Its import/asset namespace is deliberately unchanged.
`pubspec.yaml` currently retains upstream homepage/repository/issue links;
these identify the original project, not a newly published fork.

## Independent repository

The `.git/` directory in this package is a separate **local** repository
with initial branch `main`. It has no configured remote. It stores this
package, its meaningful assets, example and documentation. Build output,
dependency caches, local credentials, diagnostics and generated HTML are
ignored; the files are not deleted.

The surrounding Fastaqim repository also tracks this folder. Initializing
the inner Git repository does not remove those parent-tracked files or turn
the directory into a submodule. Run Git from this package root to operate on
the package history. A parent commit does not save the inner repository's
`.git/` history. Keep a separate clone or bundle as a history backup.

```sh
git rev-parse --show-toplevel
git status --short
git diff
git add README.md README.ar.md docs
git commit -m "docs: describe package behavior"
git log --oneline
```

Use explicit paths to stage additional code/assets after reviewing them.
For a recoverable history backup outside this folder:

```sh
git bundle create ../qcf_quran-backup.bundle --all
```

If you later create your own remote repository, configure its actual URL:

```sh
git remote add origin YOUR_REPOSITORY_URL
git push -u origin main
```

The placeholder is not a command to execute unchanged. Do not push this
edition to the original author's repository or overwrite existing histories.

## Verification

```sh
flutter pub get
flutter analyze --no-preamble --no-fatal-infos
flutter test
```

Then, from `example/`:

```sh
flutter pub get
flutter test
flutter run
```

Only format Dart files intentionally changed. Avoid formatting source data
or modifying Quran assets while doing documentation work.

## Generated API documentation

```sh
python tool/build_docs.py
```

Requires Python 3.11+ and Dart on PATH. If Dart is elsewhere, use
`python tool/build_docs.py --dart PATH_TO_DART`. The wrapper resolves README
guide links to the original local Markdown/license files without changing them.

Open `docs/generated/index.html`. Recreate it after interface changes; the
generated directory is deliberately excluded from Git. Do not assume older
HTML describes the latest package source.

## Preparing a future release

1. Review the current `Unreleased` changes and compatibility notes, including
   `quranText` being read-only `final` rather than a `const` expression.
2. Run package/example tests, analysis and relevant manual checks from
   [VALIDATION.md](VALIDATION.md).
3. Preserve asset manifests, source notices, hashes and attribution.
4. Set the intended new version and update `CHANGELOG.md` only when actually
   preparing that release; the current docs do not imply a new published version.
5. Replace upstream metadata with the real fork URLs if a fork is published.
6. Run `flutter pub publish --dry-run` to inspect packaging before deciding
   whether to publish. Publishing itself is a separate deliberate action.

Do not advertise all Warsh artwork as bundled, every audio reader as complete,
or automated test coverage as an independent Quranic certification.
