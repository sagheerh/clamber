#!/usr/bin/env bash
# Three proposals, four cells + one proposed lurch each. STOP BEFORE ADOPTION.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
case "$("$GODOT" --version)" in 4.7.2.stable*) ;; *) echo 'ERROR: exact Godot4.7.2 required' >&2; exit 1 ;; esac
folder="${M1_D09_REPORT_DIR:-$(mktemp -d)}"; mkdir -p "$folder"
resource_before="$(sha256sum core/tuning.tres)"
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/import.log"; then cat "$folder/import.log"; exit 1; fi
for candidate in c10 c20 c40; do
  for cell in both stop_only drive_only inert lurch; do
    case_folder="$folder/$candidate/$cell"; mkdir -p "$case_folder"
    flags=()
    case "$cell" in
      stop_only) flags+=(--motor-gain-zero) ;;
      drive_only) flags+=(--motor-stop-wide) ;;
      inert) flags+=(--motor-gain-zero --motor-stop-wide) ;;
      lurch) flags+=(--d09-lurch) ;;
    esac
    status=0
    "$GODOT" --headless --script res://tests/sim/test_coupled_load.gd -- --actuated --legal-spawn --ticks=6000 "--d09-candidate=$candidate" "${flags[@]}" "--trace=$case_folder/trace.jsonl" > "$case_folder/probe.log" 2>&1 || status=$?
    if [[ "$status" != 0 ]] || grep -Eq 'SCRIPT ERROR:|ERROR:|FAIL|Parse Error:|Failed to load script' "$case_folder/probe.log" || ! grep -Eq '^M1 load-path components: 80 checks, 0 failures$' "$case_folder/probe.log"; then tail -45 "$case_folder/probe.log"; exit 1; fi
    [[ "$(sha256sum core/tuning.tres)" == "$resource_before" ]]
  done
done
python3 tests/load_d09_report.py "$folder"
# STOP. No adoption, changed baseline, release-hold, or further search.
