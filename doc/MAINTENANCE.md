# Local Git and maintenance

Display name: **Fastaqim Quran — قرآن فاستقم**. Dart package name:
**`fastaqim_quran`**. Imports, font package names and asset keys use this name.
The package folder is `custom_packages/fastaqim_quran`; its local Git history
was preserved during the rename. See [migration](MIGRATION.md) for consumers.
`pubspec.yaml` points to the edition's
[GitHub repository](https://github.com/Esmail514/fastaqim_quran). Release
`0.1.0` is published under this new name, with the reported
[upstream permission](UPSTREAM_PERMISSION.md) preserved. The README retains the
original project's attribution. See [Publishing](PUBLISHING.md).

## Independent repository

The `.git/` directory in this package is a separate **local** repository
with initial branch `main`. Check `git remote -v` before pushing to ensure `origin` targets
the new edition's GitHub repository. It stores this
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
git bundle create ../fastaqim_quran-backup.bundle --all
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

1. Review the release-preparation changes in `CHANGELOG.md` and compatibility notes, including
   `quranText` being read-only `final` rather than a `const` expression.
2. Run package/example tests, analysis and relevant manual checks from
   [VALIDATION.md](VALIDATION.md).
3. Preserve asset manifests, source notices, hashes and attribution.
4. Set the intended new version and update `CHANGELOG.md` only when actually
   preparing that release; the current docs do not imply a new published version.
5. Verify the homepage/repository/issue URLs point to `Esmail514/fastaqim_quran`.
6. Run `flutter pub publish --dry-run` to inspect packaging before deciding
   whether to publish. Publishing itself is a separate deliberate action.

Do not advertise all Warsh artwork as bundled, every audio reader as complete,
or automated test coverage as an independent Quranic certification.
