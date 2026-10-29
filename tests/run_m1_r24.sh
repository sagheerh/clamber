#!/usr/bin/env bash
# R24 time box: three A cells, one B, C from archived data. STOP thereafter.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
case "$("$GODOT" --version)" in 4.7.2.stable*) ;; *) echo 'ERROR: exact Godot4.7.2 required' >&2; exit 1 ;; esac
folder="${M1_R24_REPORT_DIR:?}"; old="${M1_R24_OLD_DIR:?}"; mkdir -p "$folder"
resource_before="$(sha256sum core/tuning.tres)"
git diff --exit-code 7d48ba0 -- core/tuning.tres data/creatures/
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/import.log"; then cat "$folder/import.log"; exit 1; fi
for name in A-0.15 A-0.015 A-0.0015 B; do
  mkdir -p "$folder/$name"; flags=(--d09-lurch)
  if [[ "$name" != B ]]; then flags=(--d09-candidate=c40 "--r24-static-slip=${name#A-}"); fi
  status=0
  "$GODOT" --headless --script res://tests/sim/test_coupled_load.gd -- --actuated --legal-spawn --ticks=6000 "${flags[@]}" "--trace=$folder/$name/trace.jsonl" > "$folder/$name/probe.log" 2>&1 || status=$?
  if [[ "$status" != 0 ]] || grep -Eq 'SCRIPT ERROR:|ERROR:|FAIL|Parse Error:|Failed to load script' "$folder/$name/probe.log" || ! grep -Eq '^M1 load-path components: 80 checks, 0 failures$' "$folder/$name/probe.log"; then tail -45 "$folder/$name/probe.log"; exit 1; fi
  [[ "$(sha256sum core/tuning.tres)" == "$resource_before" ]]
done
python3 tests/load_r24_report.py "$folder" "$old"
# STOP. No new hypothesis arm, parameter adoption, brace, or gate credit.
