#!/usr/bin/env bash
# R12 ONLY: fresh600 at each requested spawn, unchanged configured6 iterations.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
case "$("$GODOT" --version)" in
  4.7.2.stable*) ;;
  *) echo 'ERROR: exact Godot 4.7.2-stable required' >&2; exit 1 ;;
esac
folder="${M1_SPAWN_REPORT_DIR:-$(mktemp -d)}"
mkdir -p "$folder"
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/import.log"; then
  cat "$folder/import.log"
  exit 1
fi
for height in 0.33 0.53 0.73; do
  case_folder="$folder/spawn-$height"
  mkdir -p "$case_folder"
  set +e
  "$GODOT" --headless --script res://tests/sim/test_coupled_load.gd -- \
    "--trace=$case_folder/slug-600.jsonl" "--spawn-y=$height" > "$case_folder/probe.log" 2>&1
  status=$?
  set -e
  if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$case_folder/probe.log" ||
     ! grep -Eq '^M1 load-path components: [0-9]+ checks, 0 failures$' "$case_folder/probe.log"; then
    status=1
  fi
  printf '%s\n' "$status" > "$case_folder/engine-status.txt"
done
python3 tests/load_spawn_report.py "$folder"
