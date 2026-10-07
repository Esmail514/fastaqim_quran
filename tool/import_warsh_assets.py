"""Import pinned Warsh artwork metadata and untouched publisher text/font.

No audio is fetched. Run from any directory with Python 3.11+.
Only the first three SVG pages are bundled; other pages use pinned source URLs.
All 604 SVG files are fetched transiently to verify geometry and record hashes.
"""

from __future__ import annotations

import concurrent.futures
import gzip
import hashlib
import io
import json
from pathlib import Path
import re
import time
import urllib.request
import xml.etree.ElementTree as ET
import zipfile


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "warsh"
SVG_COMMIT = "b4155f07e4aea087d2c458069acff9f7c7e749f6"
SVG_REPO = "https://github.com/quran-ws/quran-svg"
RAW = f"https://raw.githubusercontent.com/quran-ws/quran-svg/{SVG_COMMIT}"
PACK_URL = "https://cdn.quran.ws/KFGQPC/resources/quran-dev/uthmanic-warsh/UthmanicWarsh_v2-1.zip"
PACK_SHA256 = "d847a7e7002dfbed5d28db6684fd1d9c3d50b8bb63ad64cb38a46b9dad788b47"
SOURCE_JSON = "UthmanicWarsh_v2-1 data/warshData_v2-1.json"
SOURCE_FONT = "UthmanicWarsh_v2-1 font/uthmanic_warsh_v21.ttf"
TEXT_SHA256 = "c6017e688cc599d88f6fdb1a19cafc9c51d024b3530955f1a878f17d26b9bcbc"
FONT_SHA256 = "b436fb89e1d26f827cd6a3c4d632fb68a49cc954c4ac90699a9502da25555230"
README_SHA256 = "fdd2782afccfabdd380cf0706a0601a09f8d1cc048a7ac5f663b3a4bf59ad36a"


def fetch(url: str) -> bytes:
    for attempt in range(4):
        try:
            request = urllib.request.Request(url, headers={"User-Agent": "qcf-quran-warsh-source-importer", "Accept-Encoding": "gzip"})
            with urllib.request.urlopen(request, timeout=70) as response:
                data = response.read()
                return gzip.decompress(data) if response.headers.get("Content-Encoding") == "gzip" else data
        except Exception:
            if attempt == 3:
                raise
            time.sleep(attempt + 1)
    raise AssertionError("unreachable")


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def git_blob_sha1(data: bytes) -> str:
    return hashlib.sha1(f"blob {len(data)}\0".encode() + data).hexdigest()


def write(relative: str, data: bytes) -> str:
    target = ASSETS / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(data)
    return f"assets/warsh/{relative}"


def polygon_numbers(value: str) -> list[float]:
    return [float(n) for n in re.findall(r"-?\d+(?:\.\d+)?", value)]


def import_page(number: int, expected: dict[str, str]) -> dict:
    stem = f"{number:03d}"
    json_path = f"mushafs/warsh/kfqc/json/{stem}.json"
    svg_path = f"mushafs/warsh/kfqc/svg/{stem}.svg"
    metadata = fetch(f"{RAW}/{json_path}")
    artwork = fetch(f"{RAW}/{svg_path}")
    assert git_blob_sha1(metadata) == expected[json_path], f"source JSON hash mismatch p{number}"
    assert git_blob_sha1(artwork) == expected[svg_path], f"source SVG hash mismatch p{number}"
    entries = json.loads(metadata)
    svg = ET.fromstring(artwork)
    box = [float(n) for n in svg.attrib["viewBox"].split()]
    assert len(box) == 4 and box[2] > 0 and box[3] > 0
    paths = [node for node in svg if node.attrib.get("class") == "ayahPolygon"]
    assert len(entries) == len(paths), f"geometry count mismatch p{number}"
    for entry, node in zip(entries, paths):
        assert int(node.attrib["surah"]) == entry["surahNumber"]
        assert int(node.attrib["ayah"]) == entry["ayahNumber"]
        # Opening pages use a point list in JSON, an M/L/Z path in SVG.
        assert polygon_numbers(node.attrib["d"]) == polygon_numbers(entry["polygon"])
    geometry_asset = write(f"pages/{stem}.json", metadata)
    svg_asset = write(f"svg/{stem}.svg", artwork) if number <= 3 else None
    return {
        "number": number,
        "viewBox": box,
        "geometryAsset": geometry_asset,
        "geometrySha256": sha256(metadata),
        "svgUri": f"{RAW}/{svg_path}",
        "svgSha256": sha256(artwork),
        "svgBytes": len(artwork),
        "svgAsset": svg_asset,
        "ayahRegionCount": len(entries),
    }


def main() -> None:
    print("Importing pinned Warsh assets; no audio is fetched.", flush=True)
    existing_text = ASSETS / "source/warshData_v2-1.json"
    existing_font = ASSETS / "fonts/uthmanic_warsh_v21.ttf"
    existing_read_me = ASSETS / "source/read.me"
    if (existing_text.exists() and existing_font.exists() and existing_read_me.exists()
            and sha256(existing_text.read_bytes()) == TEXT_SHA256
            and sha256(existing_font.read_bytes()) == FONT_SHA256
            and sha256(existing_read_me.read_bytes()) == README_SHA256):
        text, font, read_me = existing_text.read_bytes(), existing_font.read_bytes(), existing_read_me.read_bytes()
    else:
        archive = fetch(PACK_URL)
        assert sha256(archive) == PACK_SHA256, "publisher archive digest mismatch"
        with zipfile.ZipFile(io.BytesIO(archive)) as publisher:
            text = publisher.read(SOURCE_JSON)
            font = publisher.read(SOURCE_FONT)
            read_me = publisher.read("UthmanicWarsh_v2-1 data/read.me")
    assert sha256(text) == TEXT_SHA256, "publisher text member digest mismatch"
    assert sha256(font) == FONT_SHA256, "publisher font member digest mismatch"
    assert sha256(read_me) == README_SHA256, "publisher read.me member digest mismatch"
    records = json.loads(text.decode("utf-8-sig"))
    assert len(records) == 6214
    expected_ayahs = {(r["sura_no"], r["aya_no"]) for r in records}
    assert len(expected_ayahs) == 6214
    text_asset = write("source/warshData_v2-1.json", text)
    font_asset = write("fonts/uthmanic_warsh_v21.ttf", font)
    write("source/read.me", read_me)
    print("Verified publisher text and paired font.", flush=True)
    for relative in ("LICENSE", "NOTICE.md", "docs/PROVENANCE.md", "docs/FORMAT.md", "LICENSES/CC-BY-4.0.txt"):
        existing_notice = ASSETS / f"source/quran-svg/{relative}"
        if not existing_notice.exists():
            write(f"source/quran-svg/{relative}", fetch(f"{RAW}/{relative}"))
    tree = json.loads(fetch(f"https://api.github.com/repos/quran-ws/quran-svg/git/trees/{SVG_COMMIT}?recursive=1"))
    expected = {x["path"]: x["sha"] for x in tree["tree"] if x["type"] == "blob"}
    for relative in ("LICENSE", "NOTICE.md", "docs/PROVENANCE.md", "docs/FORMAT.md", "LICENSES/CC-BY-4.0.txt"):
        notice_bytes = (ASSETS / f"source/quran-svg/{relative}").read_bytes()
        assert git_blob_sha1(notice_bytes) == expected[relative], f"source notice hash mismatch {relative}"
    pages = []
    print("Verifying all 604 matching SVG pages and ayah geometry.", flush=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=20) as pool:
        pending = [pool.submit(import_page, number, expected) for number in range(1, 605)]
        for future in concurrent.futures.as_completed(pending):
            pages.append(future.result())
            if len(pages) % 50 == 0:
                print(f"Verified {len(pages)}/604 Warsh pages", flush=True)
    pages.sort(key=lambda p: p["number"])
    actual_ayahs = set()
    fragments = []
    for page in pages:
        entries = json.loads((ROOT / page["geometryAsset"]).read_bytes())
        for region in entries:
            key = (region["surahNumber"], region["ayahNumber"])
            actual_ayahs.add(key)
            if region.get("continuation"):
                fragments.append([page["number"], *key])
    assert actual_ayahs == expected_ayahs, f"coverage mismatch: missing={expected_ayahs-actual_ayahs}; extra={actual_ayahs-expected_ayahs}"
    manifest = {
        "schemaVersion": 1,
        "editionId": "warsh-kfgqpc-madinah-1442",
        "riwayah": "warsh",
        "countingSystem": "madani-last",
        "pageCount": 604,
        "ayahCount": 6214,
        "textAsset": text_asset,
        "textSha256": sha256(text),
        "fontAsset": font_asset,
        "fontSha256": sha256(font),
        "fontFamily": "QCF_Warsh",
        "sourceArchive": {"uri": PACK_URL, "sha256": PACK_SHA256,
                          "officialUri": "https://download.qurancomplex.gov.sa/resources_dev/UthmanicWarsh_v2-1.zip",
                          "textMember": SOURCE_JSON, "fontMember": SOURCE_FONT},
        "artworkSource": {"repository": SVG_REPO, "commit": SVG_COMMIT,
                          "originalArchive": "1442-ai-warsh.zip",
                          "originalArchiveSha256": "2a0c65131dac5a922502fb4740034fb4ffc57792a0b6e5c1cc34c5a3339dd5d7",
                          "note": "Upstream preserves printed glyph artwork and line layout; removes the decorative frame, running header and printed page number; redraws ayah marker ornaments. The package does not edit the downloaded artwork or publisher text."},
        "continuations": fragments,
        "pages": pages,
    }
    write("manifest.json", (json.dumps(manifest, ensure_ascii=False, indent=2) + "\n").encode())
    print(f"Imported 604 pages, {len(actual_ayahs)} ayahs, {len(fragments)} continuation fragments.", flush=True)
    print(f"Remote SVG artwork total: {sum(p['svgBytes'] for p in pages):,} bytes; bundled opening samples only.", flush=True)


if __name__ == "__main__":
    main()
