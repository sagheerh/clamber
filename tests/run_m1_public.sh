#!/usr/bin/env bash
# Phase2 same-build attempt1; runtime rows only move after measured evidence.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
case "$("$GODOT" --version)" in 4.7.2.stable*) ;; *) echo 'ERROR: exact Godot4.7.2 required' >&2; exit 1 ;; esac
folder="${M1_PUBLIC_REPORT_DIR:-$(mktemp -d)}"; mkdir -p "$folder"
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/import.log"; then cat "$folder/import.log"; exit 1; fi
"$GODOT" --headless --script res://tests/sim/test_public_sim.gd -- "--report-dir=$folder" > "$folder/public.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|FAIL|Parse Error:|Failed to load script' "$folder/public.log"; then cat "$folder/public.log"; exit 1; fi
for hz in 30 144; do
  "$GODOT" --headless --fixed-fps "$hz" --script res://tests/sim/test_public_delivery.gd -- "--report-dir=$folder" "--expected-fps=$hz" > "$folder/delivery-$hz.log" 2>&1
  if grep -Eq 'SCRIPT ERROR:|ERROR:|FAIL|Parse Error:|Failed to load script' "$folder/delivery-$hz.log"; then cat "$folder/delivery-$hz.log"; exit 1; fi
done
python3 tests/public_sim_report.py "$folder"
