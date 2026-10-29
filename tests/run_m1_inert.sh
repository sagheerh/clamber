#!/usr/bin/env bash
# R22: EXACTLY ONE diagnostic cell. No reference rerun or subsequent sweep.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
case "$("$GODOT" --version)" in 4.7.2.stable*) ;; *) echo 'ERROR: exact Godot4.7.2 required' >&2; exit 1 ;; esac
folder="${M1_INERT_REPORT_DIR:-$(mktemp -d)}"; mkdir -p "$folder"
# Neither physical resource nor authored creature bytes may change.
git diff --exit-code 74c629e -- core/tuning.tres data/creatures/
resource_before="$(sha256sum core/tuning.tres)"
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/import.log"; then cat "$folder/import.log"; exit 1; fi
status=0
"$GODOT" --headless --script res://tests/sim/test_coupled_load.gd -- --actuated --legal-spawn --ticks=6000 --motor-gain-zero --motor-stop-wide "--trace=$folder/actuated-after-6000.jsonl" > "$folder/probe.log" 2>&1 || status=$?
if [[ "$status" != 0 ]] || grep -Eq 'SCRIPT ERROR:|ERROR:|FAIL|Parse Error:|Failed to load script' "$folder/probe.log" || ! grep -Eq '^M1 load-path components: 80 checks, 0 failures$' "$folder/probe.log"; then tail -45 "$folder/probe.log"; exit 1; fi
[[ "$(sha256sum core/tuning.tres)" == "$resource_before" ]]
git diff --exit-code 74c629e -- core/tuning.tres data/creatures/
python3 tests/load_inert_report.py "$folder"
# Process-local90 has exited. STOP; no new arm launched based on any result.
