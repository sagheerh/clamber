#!/usr/bin/env bash
# R25 one adoption increment: no automatic retry/retune; independent gate jobs.
set -euo pipefail
cd "$(dirname "$0")/.."
mode="${1:?brace/ac202/fa5}"; folder="${M1_R25_REPORT_DIR:?}"; mkdir -p "$folder"
case "$("${GODOT:?}" --version)" in 4.7.2.stable*) ;; *) exit 1;; esac
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/import.log"; then cat "$folder/import.log"; exit 1; fi
status=0
if [[ "$mode" == brace ]]; then
  "$GODOT" --headless --script res://tests/sim/test_r25_brace.gd -- "--report-dir=$folder" > "$folder/engine.log" 2>&1 || status=$?
else
  "$GODOT" --headless --script res://tests/sim/test_r25_independent.gd -- "--report-dir=$folder" "--mode=$mode" > "$folder/engine.log" 2>&1 || status=$?
fi
grep -E 'SCRIPT ERROR:|ERROR:|FAIL|M1 R25' "$folder/engine.log" || true
if grep -Eq 'SCRIPT ERROR:|ERROR:|FAIL|Parse Error:' "$folder/engine.log"; then status=1; fi
report_status=0
if [[ "$mode" == brace ]]; then python3 tests/load_r25_report.py "$folder" || report_status=$?
else python3 tests/r25_independent_report.py "$mode" "$folder" || report_status=$?; fi
[[ "$status" == 0 && "$report_status" == 0 ]]
