#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""List a .butterkit document's languages and base artboards, in screenshot order.

Usage: python3 list_boards.py "My App.butterkit"

Reads Document.json only and changes nothing. Uses only the standard library.
See ../README.md for the format it reads.
"""
import json
import sys
from pathlib import Path

SUPPORTED_VERSIONS = {1}

if len(sys.argv) != 2:
    sys.exit(__doc__.strip())

package = Path(sys.argv[1])
doc = json.loads((package / "Document.json").read_text(encoding="utf-8"))
if doc.get("schemaVersion") not in SUPPORTED_VERSIONS:
    sys.exit("Unsupported schemaVersion")

ppm = doc.get("pixelsPerMeter", 800)
boards = doc["artboards"]
languages = sorted({
    b["variation"]["code"] for b in boards
    if (b.get("variation") or {}).get("kind") == "language"
})
print("Base language:", doc.get("baseLanguageCode"))
print("Localizations:", ", ".join(languages) or "none")

base = [b for b in boards if not b.get("variation")]
for b in sorted(base, key=lambda b: (b.get("sizePresetID") or "custom", b.get("sequenceIndex") or 0)):
    width, height = (round(v * ppm) for v in b["size"])
    texts = [t["string"] for t in sorted(b["textBlocks"], key=lambda t: t["index"])]
    print(f'{b.get("sizePresetID") or "custom"} #{b.get("sequenceIndex")} {width}x{height} {b["name"]}: {" / ".join(texts)}')
