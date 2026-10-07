"""Generate Dart string constants mechanically from unchanged Hafs JSON.

Never normalizes, authors, edits, removes markers from, or combines ayah text.
The generated display and search strings remain exactly the publisher strings.
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets/hafs/source/hafsData_v2-0.json"
OUTPUT = ROOT / "lib/src/data/hafs_source_data.dart"
SOURCE_SHA256 = "d2960b3217962e7e4252abdcece67bea3d6b48271e4cd3af45bbbb2dd5c872ca"
ARCHIVE_SHA256 = "a7b0e5591945712ec5e4d6142938ae4d1e9b49bdc89dff06222789bfebdfd72c"


def dart_literal(value: str) -> str:
    """Quote code points as a Dart literal, without changing their values."""
    result = []
    for character in value:
        if character == "\\":
            result.append("\\\\")
        elif character == "'":
            result.append("\\'")
        elif character == "$":
            result.append("\\$")
        elif ord(character) < 32 or character in ("\u2028", "\u2029"):
            result.append(f"\\u{ord(character):04x}")
        else:
            result.append(character)
    return "'" + "".join(result) + "'"


def generate() -> bytes:
    original = SOURCE.read_bytes()
    assert hashlib.sha256(original).hexdigest() == SOURCE_SHA256, "Canonical Hafs source digest mismatch"
    rows = json.loads(original.decode("utf-8-sig"))
    assert len(rows) == 6236
    keys = [(r["sura_no"], r["aya_no"]) for r in rows]
    assert len(set(keys)) == 6236 and keys == sorted(keys)
    assert [r["id"] for r in rows] == list(range(1, 6237))
    for row in rows:
        assert isinstance(row["aya_text"], str) and isinstance(row["aya_text_emlaey"], str)
        assert row["aya_text"] and row["aya_text_emlaey"]
        assert ord(row["aya_text"][-1]) == 0xFBFF + row["aya_no"], "Publisher end-marker identity mismatch"
    lines = [
        "// GENERATED FILE. Do not edit Qur'anic strings manually.",
        "// Regenerate with: python tool/generate_hafs_source_data.py",
        "// Unchanged publisher member: UthmanicHafs_v2-0 data/hafsData_v2-0.json",
        f"// Source SHA-256: {SOURCE_SHA256}",
        f"// Original archive SHA-256: {ARCHIVE_SHA256}",
        "// https://download.qurancomplex.gov.sa/resources_dev/UthmanicHafs_v2-0.zip",
        "// All display/search strings are mechanically escaped, never normalized.",
        "// Tuple: (native surah number, native ayah number, display text, search text).",
        "const List<(int, int, String, String)> hafsSourceVersesData = [",
    ]
    for row in rows:
        lines.append(
            f"  ({row['sura_no']}, {row['aya_no']}, "
            f"{dart_literal(row['aya_text'])}, {dart_literal(row['aya_text_emlaey'])}),"
        )
    lines.append("];")
    return ("\n".join(lines) + "\n").encode("utf-8")


def main() -> None:
    output = generate()
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_bytes(output)
    assert OUTPUT.read_bytes() == generate(), "Generation is not deterministic"
    print(f"Generated 6236 exact Hafs display/search pairs: {OUTPUT}")
    print(f"Validated all 6236 original end markers against native ayah numbers.")
    print(f"Dart output SHA-256: {hashlib.sha256(output).hexdigest()}")


if __name__ == "__main__":
    main()
