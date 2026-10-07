"""Import unchanged KFGQPC Hafs text and its paired Unicode font.

This adds readable text assets; it never rewrites the existing QCF page glyphs.
No audio is downloaded. Run with Python 3.11+ from any directory.
"""

from __future__ import annotations

import collections
import hashlib
import io
import json
from pathlib import Path
import tempfile
import urllib.request
import zipfile


ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "hafs"
ARCHIVE_NAME = "UthmanicHafs_v2-0.zip"
OFFICIAL_URL = f"https://download.qurancomplex.gov.sa/resources_dev/{ARCHIVE_NAME}"
MIRROR_URL = f"https://cdn.quran.ws/KFGQPC/resources/quran-dev/uthmanic-hafs/{ARCHIVE_NAME}"
ARCHIVE_SHA256 = "a7b0e5591945712ec5e4d6142938ae4d1e9b49bdc89dff06222789bfebdfd72c"
TEXT_MEMBER = "UthmanicHafs_v2-0 data/hafsData_v2-0.json"
FONT_MEMBER = "UthmanicHafs_v2-0 font/uthmanic_hafs_v20.ttf"
README_MEMBER = "UthmanicHafs_v2-0 data/read.me"


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def write(relative: str, data: bytes) -> str:
    path = ASSETS / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(data)
    return f"assets/hafs/{relative}"


def main() -> None:
    cached_archive = Path(tempfile.gettempdir()) / f"mushaf_riwayat_{ARCHIVE_NAME}"
    if cached_archive.exists() and digest(cached_archive.read_bytes()) == ARCHIVE_SHA256:
        archive = cached_archive.read_bytes()
    else:
        request = urllib.request.Request(MIRROR_URL, headers={"User-Agent": "qcf-quran-hafs-source-importer"})
        with urllib.request.urlopen(request, timeout=90) as response:
            archive = response.read()
    assert digest(archive) == ARCHIVE_SHA256, "Hafs publisher archive digest mismatch"
    with zipfile.ZipFile(io.BytesIO(archive)) as publisher:
        text = publisher.read(TEXT_MEMBER)
        font = publisher.read(FONT_MEMBER)
        read_me = publisher.read(README_MEMBER)
    rows = json.loads(text.decode("utf-8-sig"))
    assert len(rows) == 6236
    assert [r["id"] for r in rows] == list(range(1, 6237))
    by_surah = collections.defaultdict(list)
    for row in rows:
        by_surah[row["sura_no"]].append(row["aya_no"])
        assert isinstance(row["page"], int) and 1 <= row["page"] <= 604
        assert row["aya_text"] and row["aya_text_emlaey"]
    assert sorted(by_surah) == list(range(1, 115))
    assert set(r["page"] for r in rows) == set(range(1, 605))
    for ayahs in by_surah.values():
        assert ayahs == list(range(1, len(ayahs) + 1))
    lookup = {(r["sura_no"], r["aya_no"]): r for r in rows}
    # These are comparisons to the publisher's existing search field, not
    # transformations or authored replacements for the Qur'anic display text.
    assert lookup[(1, 1)]["aya_text_emlaey"] == "بسم الله الرحمن الرحيم"
    assert lookup[(1, 4)]["aya_text_emlaey"] == "مالك يوم الدين"
    assert lookup[(2, 1)]["aya_text_emlaey"] == "الم"
    assert len(by_surah[2]) == 286
    text_asset = write("source/hafsData_v2-0.json", text)
    font_asset = write("fonts/uthmanic_hafs_v20.ttf", font)
    readme_asset = write("source/read.me", read_me)
    manifest = {
        "schemaVersion": 1,
        "editionId": "hafs-kfgqpc-uthmanic-v2-0",
        "riwayah": "hafs",
        "countingSystem": "kufi",
        "pageCount": 604,
        "ayahCount": 6236,
        "textAsset": text_asset,
        "textSha256": digest(text),
        "fontAsset": font_asset,
        "fontSha256": digest(font),
        "fontFamily": "QCF_HafsUnicode",
        "readmeAsset": readme_asset,
        "readmeSha256": digest(read_me),
        "sourceArchive": {
            "uri": MIRROR_URL,
            "officialUri": OFFICIAL_URL,
            "sha256": ARCHIVE_SHA256,
            "bytes": len(archive),
            "textMember": TEXT_MEMBER,
            "fontMember": FONT_MEMBER,
            "note": "Archive matches the mirror's recorded publisher MD5 cf6841aea5b1d1fd70d032b43ff08278 and SHA-1 36ea5ab0d7ea1702f17ff43f9b50924cccd77ebf. Text/font members are copied without normalization or edits.",
        },
        "surahAyahCounts": [len(by_surah[n]) for n in range(1, 115)],
        "note": "Readable Unicode Hafs source only. Existing QCF glyph records and page fonts remain unchanged.",
    }
    write("manifest.json", (json.dumps(manifest, ensure_ascii=False, indent=2) + "\n").encode())
    print("Imported original Hafs source: 6236 ayahs, 114 surahs, 604 pages.")
    print(f"Text {len(text):,} bytes SHA256 {digest(text)}")
    print(f"Font {len(font):,} bytes SHA256 {digest(font)}")


if __name__ == "__main__":
    main()
