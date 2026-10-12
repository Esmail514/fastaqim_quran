# Local Git and maintenance

Display name: **Mushaf Riwayat — مصحف الروايات**. Dart package name:
**`mushaf_riwayat`**. Imports, font package names and asset keys use this name.
The package folder is `custom_packages/mushaf_riwayat`; its local Git history
was preserved during the rename. See [migration](MIGRATION.md) for consumers.
`pubspec.yaml` points to the edition's
[GitHub repository](https://github.com/Esmail514/mushaf_riwayat), currently
prepared for public publication at the maintainer's request, with the reported
[upstream permission](UPSTREAM_PERMISSION.md) documented. The README retains the
original project's attribution. See [Publishing](PUBLISHING.md).

## Independent repository

The `.git/` directory in this package is a separate **local** repository
with initial branch `main`. Its `origin` is the edition's GitHub repository.
It stores this
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
git add README.md README.ar.md doc
git commit -m "docs: describe package behavior"
git log --oneline
```

Use explicit paths to stage additional code/assets after reviewing them.
For a recoverable history backup outside this folder:

```sh
git bundle create ../mushaf_riwayat-backup.bundle --all
```

The configured remote can be checked and updated normally:

```sh
git remote -v
git push -u origin main
```

Do not push this edition to the original author's repository or overwrite
existing histories. Preserve upstream attribution and component license notices.

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

Open `doc/generated/index.html`. Recreate it after interface changes; the
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
5. Add the actual fork's homepage/repository/issue URLs once they exist.
6. Run `flutter pub publish --dry-run` to inspect packaging before deciding
   whether to publish. Publishing itself is a separate deliberate action.

Do not advertise all Warsh artwork as bundled, every audio reader as complete,
or automated test coverage as an independent Quranic certification.
