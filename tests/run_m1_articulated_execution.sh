#!/usr/bin/env bash
# UNADOPTED composed rows, not historical captures and not M1 acceptance.
set -euo pipefail
cd "$(dirname "$0")/.."
: "${GODOT:?Set checksum-verified official 4.7.2 engine}"
: "${M1_ARTICULATED_EXECUTION_REPORT_DIR:?Set fresh evidence directory}"
[[ "$("$GODOT" --version)" == '4.7.2.stable.official.ed1daf0bf' ]]
python3 tests/source_provenance.py
# Freeze checkout identity BEFORE creating untracked evidence; never label a
# dirty workspace's candidate as the clean HEAD commit.
export M1_ARTICULATED_CHECKOUT_CONTEXT="$(python3 - <<'PYCTX'
import json,subprocess
from pathlib import Path
head=dirty=None
if Path('.git').exists():
 head=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()
 dirty=bool(subprocess.check_output(['git','status','--porcelain','--untracked-files=all'],text=True).strip())
print(json.dumps(dict(checkout_head=head,checkout_dirty=dirty)))
PYCTX
)"
folder="$M1_ARTICULATED_EXECUTION_REPORT_DIR"
mkdir -p "$(dirname "$folder")"
mkdir "$folder"
finish() {
 local code=$?
 printf '%s\n' "$code" > "$folder/exit-code.txt"
 if [[ "$code" != 0 ]]; then
  for log in "$folder"/*.log; do
   [[ -f "$log" ]] || continue
   echo "=== preserved stage: $(basename "$log") ==="
   tail -n 35 "$log"
  done
 fi
}
trap finish EXIT
python3 - <<'PY'
import hashlib,json,os,subprocess
from pathlib import Path
files=sorted(Path('tests/physics_fix').glob('*.gd'))+[Path('tests/run_m1_articulated_execution.sh'),Path('scripts/publish_m1_articulated_execution.py')]
context=json.loads(os.environ['M1_ARTICULATED_CHECKOUT_CONTEXT'])
data=dict(scope='NEW articulated test-only awake-row substitution in public clock/Sim; not production acceptance or determinism',
 source_commit=context['checkout_head'] if context['checkout_dirty'] is False else None,
 **context,
 source_ci_run=os.getenv('GITHUB_RUN_ID'),core_manifest=json.loads(Path('tests/fixtures/source_manifest.json').read_text()),
 engine_build=subprocess.check_output([os.environ['GODOT'],'--version'],text=True).strip(),
 candidate_sha256={str(p):hashlib.sha256(p.read_bytes()).hexdigest() for p in files})
(Path(os.environ['M1_ARTICULATED_EXECUTION_REPORT_DIR'])/'source.json').write_text(json.dumps(data,indent=2)+'\n')
PY
"$GODOT" --headless --editor --import > "$folder/import.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/import.log"; then
 echo 'STOP: import errors; zero creature ticks.' >&2
 exit 1
fi
"$GODOT" --headless --check-only --script res://tests/physics_fix/test_articulated_execution.gd > "$folder/compile.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/compile.log"; then
 echo 'STOP: compile errors; zero creature ticks.' >&2
 exit 1
fi
# Archived-frame adapter regression first; never advances a creature clock.
"$GODOT" --headless --check-only --script res://tests/physics_fix/test_articulated_cap_identity.gd > "$folder/component-compile.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/component-compile.log"; then
 echo 'STOP: component compile errors; zero creature ticks.' >&2
 exit 1
fi
"$GODOT" --headless --script res://tests/physics_fix/test_articulated_cap_identity.gd > "$folder/components.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/components.log"; then
 echo 'STOP: adapter component errors; zero creature ticks.' >&2
 exit 1
fi
if ! grep -Fxq 'Articulated cap identity: 8 checks, 0 failures' "$folder/components.log"; then
 echo 'STOP: incomplete adapter suite; zero creature ticks.' >&2
 exit 1
fi
"$GODOT" --headless --check-only --script res://tests/physics_fix/test_staged_articulated_components.gd > "$folder/staged-compile.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/staged-compile.log"; then exit 1; fi
timeout 60s "$GODOT" --headless --quit-after 1 --script res://tests/physics_fix/test_staged_articulated_components.gd > "$folder/staged-components.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/staged-components.log"; then exit 1; fi
if ! grep -Fxq 'Staged articulated components: 20 checks, 0 failures' "$folder/staged-components.log"; then exit 1; fi
"$GODOT" --headless --script res://tests/physics_fix/test_articulated_execution.gd -- --report-dir="$folder" > "$folder/engine.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/engine.log"; then
 echo 'STOP: runtime errors; inspect first failure.' >&2
 exit 1
fi
python3 - "$folder/summary.json" <<'PY'
import json,sys
r=json.load(open(sys.argv[1]))
assert r['status']=='CANDIDATE METRICS SATISFIED; NOT ADOPTED'
assert not r['not_run_arms']
assert set(r['arms'])=={'idle-Slug','length-Slug','length-Hopper','length-TwinRoller'}
for k,a in r['arms'].items():
 assert a['ticks']==a['target_ticks']==(600 if k=='idle-Slug' else 7200)
 assert a['termination']=='completed; candidate metrics satisfied'
PY
