#!/usr/bin/env bash
# OWNER R26 last bounded increment. One invocation per mode; no physical retry.
set -euo pipefail
cd "$(dirname "$0")/.."
mode="${1:?d1/d2/fa5}"; folder="${M1_R26_REPORT_DIR:?}"; mkdir -p "$folder"
[[ "$mode" == d1 || "$mode" == d2 || "$mode" == fa5 ]]
case "$("${GODOT:?}" --version)" in 4.7.2.stable*) ;; *) exit 1;; esac
status=0
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1 || status=$?
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/import.log"; then status=1; fi
if [[ "$status" == 0 ]]; then
  "$GODOT" --headless --script res://tests/sim/test_r26_diagnostics.gd -- "--report-dir=$folder" "--mode=$mode" > "$folder/engine.log" 2>&1 || status=$?
fi
# Unconditional runner-level status even if import/script failed before engine init.
python3 - "$folder" "$status" <<'PY'
import hashlib,json,os,subprocess,sys
from pathlib import Path
p=Path(sys.argv[1]); status=int(sys.argv[2])
(p/'source.json').write_text(json.dumps(dict(source_head=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),source_ci_run=os.environ.get('GITHUB_RUN_ID'),tuning_sha256=hashlib.sha256(Path('core/tuning.tres').read_bytes()).hexdigest(),raw_traces_sha256={f.name:hashlib.sha256(f.read_bytes()).hexdigest() for f in p.glob('*.jsonl')}),indent=2)+'\n')
(p/'runner-termination.json').write_text(json.dumps(dict(status=status,termination_reason='engine_returned' if (p/'engine.json').exists() else 'engine_did_not_produce_termination_report', failing_tick=None if status==0 else 'see engine.json, or unavailable before initialization'))+'\n')
PY
report_status=0
python3 tests/r26_report.py "$mode" "$folder" || report_status=$?
if [[ -f "$folder/engine.log" ]] && grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/engine.log"; then status=1; fi
if [[ "$status" != 0 ]]; then tail -45 "$folder/import.log"; tail -45 "$folder/engine.log" 2>/dev/null || true; fi
[[ "$status" == 0 && "$report_status" == 0 ]]
