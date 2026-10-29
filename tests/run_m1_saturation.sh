#!/usr/bin/env bash
# R20 diagnostic ONLY. Never change resource defaults or proceed past gain0 STOP.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
case "$("$GODOT" --version)" in 4.7.2.stable*) ;; *) echo 'ERROR: exact Godot4.7.2 required' >&2; exit 1 ;; esac
folder="${M1_SATURATION_REPORT_DIR:-$(mktemp -d)}"; mkdir -p "$folder"
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/import.log"; then cat "$folder/import.log"; exit 1; fi
run_arm() {
  local name="$1"; shift
  local case_folder="$folder/$name"; mkdir -p "$case_folder"
  local status=0
  "$GODOT" --headless --script res://tests/sim/test_coupled_load.gd -- --actuated --legal-spawn --ticks=6000 "$@" "--trace=$case_folder/actuated-after-6000.jsonl" > "$case_folder/probe.log" 2>&1 || status=$?
  if [[ "$status" != 0 ]] || grep -Eq 'SCRIPT ERROR:|ERROR:|FAIL|Parse Error:|Failed to load script' "$case_folder/probe.log" || ! grep -Eq '^M1 load-path components: 80 checks, 0 failures$' "$case_folder/probe.log"; then tail -45 "$case_folder/probe.log"; return 1; fi
}
run_arm reference
# Historical VOID arm remeasured with actual impulse telemetry, not a new remedy.
run_arm stiffness0_record --motor-spring-off
run_arm gain0 --motor-gain-zero
python3 tests/load_saturation_report.py "$folder" zero-drive
# set -e above enforces the owner STOP before this second diagnostic.
run_arm bound1 --angular-bound-one
python3 tests/load_saturation_report.py "$folder" bound
