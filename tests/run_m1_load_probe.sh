#!/usr/bin/env bash
# Raw hinged Slug diagnostic: owner force failures are real failures, never waived.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
case "$("$GODOT" --version)" in
  4.7.2.stable*) ;;
  *) echo 'ERROR: exact Godot 4.7.2-stable required' >&2; exit 1 ;;
esac
folder="${M1_LOAD_REPORT_DIR:-$(mktemp -d)}"
mkdir -p "$folder"
"$GODOT" --headless --editor --import 2>&1 | tee "$folder/import.log"
"$GODOT" --headless --script res://tests/sim/test_coupled_load.gd -- "--trace=$folder/slug-600.jsonl" 2>&1 | tee "$folder/probe.log"
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/import.log" "$folder/probe.log"; then
  echo 'ERROR: Slug diagnostic emitted script/engine errors' >&2
  exit 1
fi
python3 - "$folder/probe.log" <<'PYRESULT'
import re, sys
text = open(sys.argv[1]).read()
counts = re.findall(r'^M1 load-path components: (\d+) checks, 0 failures$', text, re.M)
if len(counts) != 1 or int(counts[0]) < 80:
    raise SystemExit('ERROR: missing/failed/below-floor load-path components (80 minimum)')
PYRESULT
python3 tests/load_trace_report.py "$folder/slug-600.jsonl" "$folder/slug-summary.json"
