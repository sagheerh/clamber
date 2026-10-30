#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
folder=tests/fixtures/m1_r29_raw
mkdir -p "$folder"
export R29_FOLDER="$folder"
test "$(git rev-parse HEAD)" = "$R29_SOURCE_SHA"
test "$(sha256sum core/tuning.tres | cut -d' ' -f1)" = 5f4d0d06564fb3a0847309d83cf5f3c87b9321ea5e2dd87e572e4bd9fe750666
test -z "$(git diff 4796ec6 -- core/)"
test -z "$(git diff fb890fd -- core/)"
case "$($GODOT --version)" in 4.7.2.stable*) ;; *) exit 1;; esac
if [[ -f .review/m1_r29_launch.json ]]; then
 "$GODOT" --headless --editor --import > "$folder/remaining-import.log" 2>&1
 if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:' "$folder/remaining-import.log"; then exit 1; fi
 for arm in D1 D2 D3 D4 D5; do
  echo "::notice title=R29 arm launch::$arm once on $R29_SOURCE_SHA"
  status=0
  "$GODOT" --headless --script res://tests/sim/test_r29.gd -- "--mode=$arm" "--report-dir=$folder" > "$folder/$arm-engine.log" 2>&1 || status=$?
  export R29_ENGINE_STATUS="$status"
  python3 tests/r29_remaining.py "$arm"
  # Nonfinite/status failure stops later physical arms; never heal or retry.
  if [[ -f "$folder/$arm-failure.json" ]]; then break; fi
 done
 scripts/review_checks.sh > "$folder/D7-static.log" 2>&1
 tests/run_tests.sh > "$folder/D7-m0.log" 2>&1
 python3 scripts/check_m0_regression.py "$folder/D7-m0.log"
 python3 tests/r29_remaining.py final
 exit 0
fi
scripts/review_checks.sh > "$folder/start-static.log" 2>&1
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:' "$folder/import.log"; then exit 1; fi
tests/run_tests.sh > "$folder/start-m0.log" 2>&1
python3 scripts/check_m0_regression.py "$folder/start-m0.log"
python3 tests/r29_report.py start
set +e
"$GODOT" --headless --script res://tests/sim/test_r29.gd -- --mode=D0 "--report-dir=$folder" > "$folder/D0-engine.log" 2>&1
status=$?
set -e
export R29_ENGINE_STATUS="$status"
python3 tests/r29_report.py D0
