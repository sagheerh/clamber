#!/usr/bin/env bash
# Historical R25 independent fixture runner; NOT the R26 repaired F77 fixtures.
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "${CLAMBER_LOCAL:-}" == 1 ]]; then
 python3 tests/source_provenance.py
fi
mode="${1:?ac202/fa5}"; folder="${M1_R25_REPORT_DIR:?}"; mkdir -p "$folder"
case "$("${GODOT:?}" --version)" in 4.7.2.stable*) ;; *) exit 1;; esac
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/import.log"; then cat "$folder/import.log"; exit 1; fi
status=0
[[ "$mode" == ac202 || "$mode" == fa5 ]]
"$GODOT" --headless --script res://tests/sim/test_r25_independent.gd -- "--report-dir=$folder" "--mode=$mode" > "$folder/engine.log" 2>&1 || status=$?
grep -E 'SCRIPT ERROR:|ERROR:|FAIL|M1 R25' "$folder/engine.log" || true
if grep -Eq 'SCRIPT ERROR:|ERROR:|FAIL|Parse Error:' "$folder/engine.log"; then status=1; fi
report_status=0
python3 tests/r25_independent_report.py "$mode" "$folder" || report_status=$?
[[ "$status" == 0 && "$report_status" == 0 ]]
