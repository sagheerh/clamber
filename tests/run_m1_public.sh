#!/usr/bin/env bash
# Phase2 same-build attempt1; runtime rows only move after measured evidence.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
case "$("$GODOT" --version)" in 4.7.2.stable*) ;; *) echo 'ERROR: exact Godot4.7.2 required' >&2; exit 1 ;; esac
folder="${M1_PUBLIC_REPORT_DIR:-$(mktemp -d)}"; mkdir -p "$folder"
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/import.log"; then cat "$folder/import.log"; exit 1; fi
set +e
"$GODOT" --headless --script res://tests/sim/test_public_sim.gd -- "--report-dir=$folder" > "$folder/public.log" 2>&1
status=$?
set -e
if [[ "$status" != 0 ]]; then
  grep -E 'ERROR|FAIL|M1 public Sim checks:' "$folder/public.log" | head -35 || true
  python3 - "$folder/public-sim-report.json" <<'PYREPORT'
import json,sys
from pathlib import Path
if Path(sys.argv[1]).exists():
    r=json.loads(Path(sys.argv[1]).read_text());r.pop('per_tick_digests',None)
    print('M1 public failed report: '+json.dumps(r,separators=(',',':')))
PYREPORT
  exit "$status"
fi
if grep -Eq 'SCRIPT ERROR:|ERROR:|FAIL|Parse Error:|Failed to load script' "$folder/public.log"; then cat "$folder/public.log"; exit 1; fi
python3 - "$folder" <<'PYREPLAY'
import hashlib,json,sys
from pathlib import Path
folder=Path(sys.argv[1]);r=json.loads((folder/'public-sim-report.json').read_text())
r.pop('per_tick_digests',None)
streams=[(folder/f'replay-{i}.bin').read_bytes() for i in range(3)]
assert streams[0] and all(b==streams[0] for b in streams), 'raw replay byte comparison failed'
r['independent_full_stream_sha256']=hashlib.sha256(streams[0]).hexdigest()
print('M1 public replay measurement: '+json.dumps(r,separators=(',',':')))
PYREPLAY
for hz in 30 144; do
  set +e
  "$GODOT" --headless --fixed-fps "$hz" --script res://tests/sim/test_public_delivery.gd -- "--report-dir=$folder" "--expected-fps=$hz" > "$folder/delivery-$hz.log" 2>&1
  status=$?
  set -e
  if [[ "$status" != 0 ]]; then cat "$folder/delivery-$hz.log"; exit "$status"; fi
  grep '^M1 public delivery:' "$folder/delivery-$hz.log" || true
  if grep -Eq 'SCRIPT ERROR:|ERROR:|FAIL|Parse Error:|Failed to load script' "$folder/delivery-$hz.log"; then cat "$folder/delivery-$hz.log"; exit 1; fi
done
python3 tests/public_sim_report.py "$folder"
