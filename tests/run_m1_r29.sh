#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
if [[ "${CLAMBER_LOCAL:-}" == 1 ]]; then
 exec python3 tests/r29_local.py "$@"
fi
export R29_FOLDER=tests/fixtures/m1_r29_execution
folder="$R29_FOLDER"
mkdir -p "$folder"
test "$(git rev-parse HEAD)" = "$R29_SOURCE_SHA"
test "$(sha256sum core/tuning.tres | cut -d' ' -f1)" = 5f4d0d06564fb3a0847309d83cf5f3c87b9321ea5e2dd87e572e4bd9fe750666
test -z "$(git diff 4796ec6 -- core/)"
case "$($GODOT --version)" in 4.7.2.stable*) ;; *) exit 1;; esac
python3 - <<'PY'
import json,os
from pathlib import Path
p=Path('.review/m1_r29_measurement_evidence.json');e=json.loads(p.read_text());e['L2_execution']={'source_commit_sha':os.environ['R29_SOURCE_SHA'],'ci_run':os.environ['GITHUB_RUN_ID'],'marker':'[R29-once-2]','authorization':'first executed measurements after L1zero-tick launchincident; no D0 rerun','arms':{}};p.write_text(json.dumps(e,indent=2)+'\n')
PY
failed=0
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1 || failed=1
"$GODOT" --headless --check-only --script res://tests/sim/test_r29.gd > "$folder/compile.log" 2>&1 || failed=1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:' "$folder/compile.log" "$folder/import.log"; then failed=1; fi
for arm in D1 D2 D3 D4 D5; do
 if [[ "$failed" != 0 ]]; then
  export R29_STOPPED_ARM="$arm"
  python3 - <<'PY'
import os,sys
sys.path.insert(0,'tests')
from r29_remaining import gate,P
arm=os.environ['R29_STOPPED_ARM'];gate(arm,'measurement',None,None,'NOT RUN',P,'Stopped after second launch/arm execution failure; inspect compile/engine log and first failure state; no further physical execution')
PY
  continue
 fi
 echo "::notice title=R29 L2 arm::$arm first execution on $R29_SOURCE_SHA"
 status=0
 "$GODOT" --headless --script res://tests/sim/test_r29.gd -- "--mode=$arm" "--report-dir=$folder" > "$folder/$arm-engine.log" 2>&1 || status=$?
 export R29_ENGINE_STATUS="$status"
 python3 tests/r29_remaining.py "$arm" || failed=1
 if [[ "$status" != 0 || -f "$folder/$arm-failure.json" ]]; then failed=1; fi
 python3 - "$arm" "$status" "$failed" <<'PY'
import json,sys
from pathlib import Path
p=Path('.review/m1_r29_measurement_evidence.json');e=json.loads(p.read_text());e['L2_execution']['arms'][sys.argv[1]]={'engine_status':int(sys.argv[2]),'processing_failed':bool(int(sys.argv[3]))};p.write_text(json.dumps(e,indent=2)+'\n')
PY
done
scripts/review_checks.sh > "$folder/D7-static.log" 2>&1
tests/run_tests.sh > "$folder/D7-m0.log" 2>&1
python3 scripts/check_m0_regression.py "$folder/D7-m0.log"
python3 tests/r29_remaining.py final
exit "$failed"
