#!/usr/bin/env bash
# R16 convergence measurement, NOT a bypass of the RED support gate.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
case "$("$GODOT" --version)" in 4.7.2.stable*) ;; *) echo 'ERROR: exact Godot4.7.2 required' >&2; exit 1 ;; esac
folder="${M1_CONVERGENCE_REPORT_DIR:-$(mktemp -d)}"
mkdir -p "$folder"
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/import.log"; then cat "$folder/import.log"; exit 1; fi
for name in actuated-before actuated-after actuated-after-raised baseline-after baseline-after-raised; do
  case_folder="$folder/$name"; mkdir -p "$case_folder"
  ticks=600
  flags=(--legal-spawn)
  if [[ "$name" == actuated-* ]]; then ticks=6000; flags+=(--actuated); fi
  flags+=("--ticks=$ticks")
  if [[ "$name" == actuated-before ]]; then flags+=(--pre-pose); fi
  if [[ "$name" == *-raised ]]; then flags+=(--spawn-lift=0.2); fi
  set +e
  "$GODOT" --headless --script res://tests/sim/test_coupled_load.gd -- "--trace=$case_folder/slug-$ticks.jsonl" "${flags[@]}" > "$case_folder/probe.log" 2>&1
  status=$?
  set -e
  if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$case_folder/probe.log" ||
     ! grep -Eq '^M1 load-path components: 80 checks, 0 failures$' "$case_folder/probe.log"; then status=1; fi
  printf '%s\n' "$status" > "$case_folder/engine-status.txt"
done
python3 tests/load_long_report.py "$folder"
