#!/usr/bin/env bash
# R18 mandatory F56 prerequisite. A failed literal identity is a real RED gate.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
case "$("$GODOT" --version)" in 4.7.2.stable*) ;; *) echo 'ERROR: exact Godot4.7.2 required' >&2; exit 1 ;; esac
folder="${M1_EXTERNAL_REPORT_DIR:-$(mktemp -d)}"; mkdir -p "$folder"
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/import.log"; then cat "$folder/import.log"; exit 1; fi
set +e
"$GODOT" --headless --script res://tests/sim/test_coupled_load.gd -- --actuated --legal-spawn --ticks=6000 "--trace=$folder/actuated-after-6000.jsonl" > "$folder/probe.log" 2>&1
status=$?
set -e
if [[ "$status" != 0 ]] || grep -Eq 'SCRIPT ERROR:|ERROR:|FAIL|Parse Error:|Failed to load script' "$folder/probe.log" || ! grep -Eq '^M1 load-path components: 80 checks, 0 failures$' "$folder/probe.log"; then tail -45 "$folder/probe.log"; exit 1; fi
python3 tests/load_external_report.py "$folder" "$@"
