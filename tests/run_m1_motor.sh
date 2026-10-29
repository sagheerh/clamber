#!/usr/bin/env bash
# R19 authorized motor2400/0 falsification ONLY; damping/resource untouched.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
case "$("$GODOT" --version)" in 4.7.2.stable*) ;; *) echo 'ERROR: exact Godot4.7.2 required' >&2; exit 1 ;; esac
folder="${M1_MOTOR_REPORT_DIR:-$(mktemp -d)}"; mkdir -p "$folder"
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/import.log"; then cat "$folder/import.log"; exit 1; fi
for name in motor2400 motor0; do
  case_folder="$folder/$name"; mkdir -p "$case_folder"
  flags=(); if [[ "$name" == motor0 ]]; then flags+=(--motor-spring-off); fi
set +e
"$GODOT" --headless --script res://tests/sim/test_coupled_load.gd -- --actuated --legal-spawn --ticks=6000 "${flags[@]}" "--trace=$case_folder/actuated-after-6000.jsonl" > "$case_folder/probe.log" 2>&1
status=$?
set -e
if [[ "$status" != 0 ]] || grep -Eq 'SCRIPT ERROR:|ERROR:|FAIL|Parse Error:|Failed to load script' "$case_folder/probe.log" || ! grep -Eq '^M1 load-path components: 80 checks, 0 failures$' "$case_folder/probe.log"; then tail -45 "$case_folder/probe.log"; exit 1; fi
done
python3 tests/load_motor_report.py "$folder"
