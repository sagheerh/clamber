#!/usr/bin/env bash
# UNADOPTED primitive candidate only. No AC-201/202/D0/R27/R29 measurement.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${GODOT:?Set GODOT to checksum-verified Godot4.7.2 official ed1daf0bf}"
[[ "$("$GODOT" --version)" == '4.7.2.stable.official.ed1daf0bf' ]]
python3 tests/source_provenance.py
folder="${M1_CONTACT_CANDIDATE_REPORT_DIR:-exports/contact-candidate-units}"
# Refuse to overwrite a prior result; retain failures for review.
mkdir -p "$(dirname "$folder")"
mkdir "$folder"
export M1_CONTACT_CANDIDATE_REPORT_DIR="$folder"
python3 - <<'PY'
import hashlib,json,os,subprocess
from pathlib import Path
files=['tests/physics_fix/rigid_contact_candidate.gd','tests/physics_fix/test_rigid_contact_candidate.gd','tests/run_m1_contact_candidate.sh']
e=dict(scope='unadopted primitive candidate ONLY; NOT assembled-creature acceptance',
       source_head=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip() if Path('.git').exists() else None,
       core_manifest=json.loads(Path('tests/fixtures/source_manifest.json').read_text()),
       candidate_sha256={f:hashlib.sha256(Path(f).read_bytes()).hexdigest() for f in files},
       engine_build=subprocess.check_output([os.environ['GODOT'],'--version'],text=True).strip())
(Path(os.environ['M1_CONTACT_CANDIDATE_REPORT_DIR'])/'source.json').write_text(json.dumps(e,indent=2)+'\n')
PY
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1
! grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/import.log"
"$GODOT" --headless --check-only --script res://tests/physics_fix/test_rigid_contact_candidate.gd > "$folder/compile.log" 2>&1
! grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/compile.log"
"$GODOT" --headless --script res://tests/physics_fix/test_rigid_contact_candidate.gd > "$folder/units.log" 2>&1
cat "$folder/units.log"
! grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|FAIL' "$folder/units.log"
grep -Eq '^Unadopted rigid contact units: 31 checks, 0 failures$' "$folder/units.log"
echo 'Primitive candidate only. No production adoption or AC verdict.'
