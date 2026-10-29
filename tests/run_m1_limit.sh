#!/usr/bin/env bash
# R21 diagnostics ONLY, ordered wide stop then weaker bound; no adopted tuning.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
case "$("$GODOT" --version)" in 4.7.2.stable*) ;; *) echo 'ERROR: exact Godot4.7.2 required' >&2; exit 1 ;; esac
folder="${M1_LIMIT_REPORT_DIR:-$(mktemp -d)}"; mkdir -p "$folder"
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/import.log"; then cat "$folder/import.log"; exit 1; fi
run_arm() {
  local name="$1"; shift
  local case_folder="$folder/$name"; mkdir -p "$case_folder"
  local status=0
  "$GODOT" --headless --script res://tests/sim/test_coupled_load.gd -- --actuated --legal-spawn --ticks=6000 "$@" "--trace=$case_folder/actuated-after-6000.jsonl" > "$case_folder/probe.log" 2>&1 || status=$?
  if [[ "$status" != 0 ]] || grep -Eq 'SCRIPT ERROR:|ERROR:|FAIL|Parse Error:|Failed to load script' "$case_folder/probe.log" || ! grep -Eq '^M1 load-path components: 80 checks, 0 failures$' "$case_folder/probe.log"; then tail -45 "$case_folder/probe.log"; return 1; fi
}
resource_before="$(sha256sum core/tuning.tres)"
run_arm reference
# R21 arm1: isolated process/duplicate; never modify the committed40degree resource.
run_arm wide90 --motor-stop-wide
[[ "$(sha256sum core/tuning.tres)" == "$resource_before" ]]
# R21 arm2 starts fresh at40degrees; only the bound changes6->1.
run_arm bound1 --angular-bound-one
[[ "$(sha256sum core/tuning.tres)" == "$resource_before" ]]
python3 tests/load_limit_report.py "$folder"
