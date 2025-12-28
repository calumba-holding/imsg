#!/usr/bin/env bash
set -euo pipefail

SQLITE_PACKAGE=".build/checkouts/SQLite.swift/Package.swift"

if [[ ! -f "$SQLITE_PACKAGE" ]]; then
  exit 0
fi

chmod u+w "$SQLITE_PACKAGE" || true

python - <<'PY'
from pathlib import Path
path = Path('.build/checkouts/SQLite.swift/Package.swift')
text = path.read_text()
if 'PrivacyInfo.xcprivacy' in text:
    raise SystemExit(0)
needle = 'exclude: [\n            "Info.plist"\n        ]'
replacement = 'exclude: [\n            "Info.plist",\n            "PrivacyInfo.xcprivacy"\n        ]'
if needle in text:
    text = text.replace(needle, replacement)
    path.write_text(text)
PY
