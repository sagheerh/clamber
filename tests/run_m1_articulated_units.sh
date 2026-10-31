#!/usr/bin/env bash
# New component algebra ONLY. Never launches failed composition or historic arms.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${GODOT:?Set GODOT to checksum-verified official4.7.2.ed1daf0bf}"
[[ "$("$GODOT" --version)" == '4.7.2.stable.official.ed1daf0bf' ]]
python3 tests/source_provenance.py
folder="${M1_ARTICULATED_REPORT_DIR:-exports/articulated-mobility-units}"
mkdir -p "$(dirname "$folder")"
mkdir "$folder"
export M1_ARTICULATED_REPORT_DIR="$folder"
trap 'status=$?; printf "%s\n" "$status" > "$folder/exit-code.txt"' EXIT
python3 - <<'PY'
import hashlib,json,os,subprocess
from pathlib import Path
paths=['tests/physics_fix/articulated_mobility_candidate.gd',
       'tests/physics_fix/test_articulated_mobility_candidate.gd',
       'tests/physics_fix/rigid_contact_candidate.gd','tests/run_m1_articulated_units.sh']
head=None;dirty=None
if Path('.git').exists():
 head=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()
 dirty=bool(subprocess.check_output(['git','status','--porcelain','--untracked-files=all'],text=True).strip())
r=dict(scope='UNADOPTED component algebra ONLY; no world ticks or AC verdict',
       source_commit=head if dirty is False else None,checkout_head=head,checkout_dirty=dirty,
       core_manifest=json.loads(Path('tests/fixtures/source_manifest.json').read_text()),
       candidate_sha256={p:hashlib.sha256(Path(p).read_bytes()).hexdigest() for p in paths},
       engine_build=subprocess.check_output([os.environ['GODOT'],'--version'],text=True).strip())
(Path(os.environ['M1_ARTICULATED_REPORT_DIR'])/'source.json').write_text(json.dumps(r,indent=2)+'\n')
PY
run_stage() {
 local stage="$1"
 shift
 if "$@" > "$folder/$stage.log" 2>&1; then
  :
 else
  local status=$?
  cat "$folder/$stage.log"
  exit "$status"
 fi
 if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script|FAIL' "$folder/$stage.log"; then
  cat "$folder/$stage.log"
  echo "STOP: $stage log error; no later stage executed." >&2
  exit 1
 fi
}
run_stage import "$GODOT" --headless --editor --import
run_stage compile "$GODOT" --headless --check-only --script res://tests/physics_fix/test_articulated_mobility_candidate.gd
run_stage units "$GODOT" --headless --script res://tests/physics_fix/test_articulated_mobility_candidate.gd
cat "$folder/units.log"
grep -Eq '^M1 articulated mobility units: 42 checks, 0 failures$' "$folder/units.log"
echo 'Component primitive gate ONLY; no production selection or complete-creature run.'
