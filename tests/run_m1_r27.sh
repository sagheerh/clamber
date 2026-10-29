#!/usr/bin/env bash
# R27 one candidate/configuration; separately authorised stability/static/soak.
set -euo pipefail
cd "$(dirname "$0")/.."
mode="${1:?ac201/ac202/fa3/soak}"; batch="${2:--1}"
folder="${M1_R27_REPORT_DIR:?}"; mkdir -p "$folder"
[[ "$mode" == ac201 || "$mode" == ac202 || "$mode" == fa3 || "$mode" == soak ]]
case "$("${GODOT:?}" --version)" in 4.7.2.stable*) ;; *) exit 1;; esac
status=0
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1 || status=$?
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/import.log"; then status=1; fi
if [[ "$status" == 0 ]]; then
  "$GODOT" --headless --script res://tests/sim/test_r27.gd -- "--mode=$mode" "--batch=$batch" "--report-dir=$folder" > "$folder/engine.log" 2>&1 || status=$?
fi
python3 - "$folder" "$mode" "$batch" "$status" <<'PY'
import hashlib,json,os,subprocess,sys
from pathlib import Path
p=Path(sys.argv[1])
def sha(f):
 h=hashlib.sha256()
 with f.open('rb') as stream:
  while b:=stream.read(1<<20):h.update(b)
 return h.hexdigest()
(p/'source.json').write_text(json.dumps(dict(source_head=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),source_ci_run=os.environ.get('GITHUB_RUN_ID'),mode=sys.argv[2],batch=int(sys.argv[3]),tuning_sha256=sha(Path('core/tuning.tres')),plan_sha256=sha(Path('tests/fixtures/r27_plan.json')),raw_sha256={f.name:sha(f) for f in p.glob('*.jsonl')}),indent=2)+'\n')
(p/'runner-termination.json').write_text(json.dumps(dict(status=int(sys.argv[4]),termination_reason='engine_returned' if (p/'engine.json').exists() else 'initialization_failure', failing_tick='see per-fixture engine termination' if (p/'engine.json').exists() else None))+'\n')
PY
report_status=0
python3 tests/r27_report.py "$mode" "$folder" "$batch" || report_status=$?
if [[ -f "$folder/engine.log" ]] && grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/engine.log"; then status=1; fi
if [[ "$status" != 0 ]]; then tail -35 "$folder/import.log"; tail -35 "$folder/engine.log" 2>/dev/null || true; fi
[[ "$status" == 0 && "$report_status" == 0 ]]
