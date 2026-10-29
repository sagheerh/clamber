#!/usr/bin/env bash
# R15 component increment + legal paired600/count evidence, NOT runtime acceptance.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
case "$("$GODOT" --version)" in
  4.7.2.stable*) ;;
  *) echo 'ERROR: exact Godot4.7.2 required' >&2; exit 1 ;;
esac
folder="${M1_MECHANICS_REPORT_DIR:-$(mktemp -d)}"
mkdir -p "$folder"
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/import.log"; then
  cat "$folder/import.log"; exit 1
fi
"$GODOT" --headless --script res://tests/sim/test_mechanics.gd 2>&1 | tee "$folder/components.log"
if grep -Eq 'SCRIPT ERROR:|ERROR:|FAIL|Parse Error:|Failed to load script' "$folder/components.log" ||
   ! grep -Eq '^M1 R15 mechanics components: [0-9]+ checks, 0 failures$' "$folder/components.log"; then
  exit 1
fi
for mechanics in baseline actuated; do
  for pose in before after; do
    case_folder="$folder/$mechanics-$pose"
    flags=(--legal-spawn)
    if [[ "$pose" == before ]]; then flags+=(--pre-pose); fi
    if [[ "$mechanics" == actuated ]]; then flags+=(--actuated); fi
    mkdir -p "$case_folder"
    set +e
    "$GODOT" --headless --script res://tests/sim/test_coupled_load.gd -- \
      "--trace=$case_folder/slug-600.jsonl" "${flags[@]}" > "$case_folder/probe.log" 2>&1
    status=$?
    set -e
    if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$case_folder/probe.log" ||
       ! grep -Eq '^M1 load-path components: [0-9]+ checks, 0 failures$' "$case_folder/probe.log"; then
      status=1
    fi
    printf '%s\n' "$status" > "$case_folder/engine-status.txt"
  done
done
python3 tests/load_legal_report.py "$folder"
