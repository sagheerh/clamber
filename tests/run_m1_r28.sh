#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mode="${1:?}"; folder="${M1_R28_REPORT_DIR:?}"; mkdir -p "$folder"
case "$("${GODOT:?}" --version)" in 4.7.2.stable*) ;; *) exit 1;; esac
[[ "$(git log -1 --format=%s)" == 'M1: adopt AC-202 post-contact distance reprojection (physics change)' ]]
[[ "$(git rev-parse HEAD)" == "${R28_SOURCE_SHA:?}" ]]
git log -1 --format=%B | grep -F '[R28-once]'
status=0
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1 || status=$?
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:' "$folder/import.log"; then status=1; fi
if [[ "$status" == 0 ]]; then
 "$GODOT" --headless --script res://tests/sim/test_r28.gd -- "--mode=$mode" "--report-dir=$folder" > "$folder/engine.log" 2>&1 || status=$?
fi
python3 - "$folder" "$mode" "$status" <<'PY'
import hashlib,json,os,subprocess,sys
from pathlib import Path
p=Path(sys.argv[1])
def sha(f):
 h=hashlib.sha256()
 with f.open('rb') as s:
  while b:=s.read(1048576):h.update(b)
 return h.hexdigest()
(p/'source.json').write_text(json.dumps(dict(source_commit_sha=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),source_ci_run=os.environ['GITHUB_RUN_ID'],mode=sys.argv[2],engine_status=int(sys.argv[3]),tuning_sha256=sha(Path('core/tuning.tres')),raw_sha256={f.name:sha(f) for f in p.glob('*.jsonl')}),indent=2)+'\n')
print('M1 R28 source: '+(p/'source.json').read_text().replace('\n',''))
PY
report_status=0
python3 tests/r28_report.py "$mode" "$folder" || report_status=$?
if [[ -f "$folder/engine.log" ]] && grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:' "$folder/engine.log"; then cat "$folder/engine.log"; status=1; fi
[[ "$status" == 0 && "$report_status" == 0 ]]
