"""Build local API HTML and resolve README links back to package guides."""

from __future__ import annotations

import argparse
import html
import os
from pathlib import Path
import re
import shutil
import subprocess
from urllib.parse import quote, unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs/generated"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dart", default=shutil.which("dart"),
                        help="Dart executable; defaults to the one on PATH")
    args = parser.parse_args()
    if not args.dart:
        parser.error("Dart was not found. Add Flutter to PATH or pass --dart.")
    subprocess.run([args.dart, "doc", "--output", str(OUTPUT)],
                   cwd=ROOT, check=True)
    index = OUTPUT / "index.html"
    fixed = 0

    def fix_link(match: re.Match[str]) -> str:
        nonlocal fixed
        url = urlsplit(html.unescape(match.group(1)))
        if url.scheme or url.netloc or not url.path:
            return match.group(0)
        path = unquote(url.path).replace("\\", "/")
        if (OUTPUT / path).exists():
            return match.group(0)
        source = ROOT / path
        if path.endswith("/index.html") and not source.exists():
            source = ROOT / path.removesuffix("/index.html")
        if not source.is_file() or not source.resolve().is_relative_to(ROOT):
            return match.group(0)
        relative = os.path.relpath(source, OUTPUT).replace("\\", "/")
        target = quote(relative, safe="/")
        if url.query:
            target += "?" + url.query
        if url.fragment:
            target += "#" + url.fragment
        fixed += 1
        return 'href="' + html.escape(target, quote=True) + '"'

    result = re.sub(r'href="([^"]*)"', fix_link,
                    index.read_text(encoding="utf-8"))
    index.write_text(result, encoding="utf-8", newline="\n")
    print(f"Resolved {fixed} local guide links. Open {index}")


if __name__ == "__main__":
    main()
