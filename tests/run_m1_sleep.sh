#!/usr/bin/env bash
# R14 component and engineering restore-continuation only; NOT full creature gates.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
case "$("$GODOT" --version)" in
  4.7.2.stable*) ;;
  *) echo 'ERROR: exact Godot4.7.2 required' >&2; exit 1 ;;
esac
folder="${M1_SLEEP_REPORT_DIR:-$(mktemp -d)}"
mkdir -p "$folder"
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1
"$GODOT" --headless --script res://tests/sim/test_sleep.gd -- "--report=$folder/sleep-report.json" 2>&1 | tee "$folder/sleep.log"
if grep -Eq 'SCRIPT ERROR:|ERROR:|FAIL|Parse Error:|Failed to load script' "$folder/import.log" "$folder/sleep.log"; then
  cat "$folder/import.log"
  exit 1
fi
python3 - "$folder" <<'PY'
import json,re,sys
from pathlib import Path
root=Path(sys.argv[1])
counts=re.findall(r'^M1 sleep components: (\d+) checks, 0 failures$',(root/'sleep.log').read_text(),re.M)
assert len(counts)==1 and int(counts[0])>=600,'missing/below-floor component completion'
r=json.loads((root/'sleep-report.json').read_text())
assert len(r['rows'])==600 and [x['tick'] for x in r['rows']]==list(range(600))
assert len(r['checkpoint_ticks'])>=2 and r['restore_continuation_tick_comparisons']==sum(600-t for t in r['checkpoint_ticks'])
assert r['wake_ticks']==[180,360] and r['sleep_ticks'] and r['complete_creature_determinism_attempts']==0
print('M1 sleep evidence:600 raw state rows; partial-dwell/asleep restore continuations identical; F42 transition control passes; FA-3/4/5/6 NOT RUN; creature determinism0')
PY
