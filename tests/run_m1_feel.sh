#!/usr/bin/env bash
# Analytic geometry only; runtime feel plans are explicit NOT RUN placeholders.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
case "$("$GODOT" --version)" in
  4.7.2.stable*) ;;
  *) echo 'ERROR: exact Godot 4.7.2-stable required' >&2; exit 1 ;;
esac
logs="$(mktemp -d)"
trap 'rm -rf "$logs"' EXIT
report="${M1_GEOMETRY_REPORT:-$logs/owner-geometry.json}"
"$GODOT" --headless --editor --import 2>&1 | tee "$logs/import.log"
"$GODOT" --headless --script res://tests/feel/test_owner_geometry.gd -- "--report=$report" 2>&1 | tee "$logs/geometry.log"
if grep -Eq 'SCRIPT ERROR:|Parse Error:|Failed to load script' "$logs/import.log" "$logs/geometry.log" ||
   ! grep -Eq '^M1 owner geometry: [0-9]+ checks, 0 failures$' "$logs/geometry.log"; then
  echo 'ERROR: owner geometry harness did not complete cleanly' >&2
  exit 1
fi
python3 - "$report" <<'PYREPORT'
import json, sys
report = json.load(open(sys.argv[1]))
assert report['failures'] == 0
assert report['checks'] >= 127, 'Owner geometry count floor regressed'
assert all(row['status'] == 'PASS (analytic only)' for row in report['analytic'].values())
assert all(row['status'] == 'NOT RUN' and row['observations'] is None for row in report['runtime'])
assert next(row for row in report['runtime'] if row['id'] == 'FA-6')['success_count'] is None
print('M1 geometry report: analytic-only assertions complete; runtime observations remain null/NOT RUN.')
PYREPORT
