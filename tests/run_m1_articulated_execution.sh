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
"$GODOT" --headless --check-only --script res://tests/physics_fix/test_staged_contact_identity.gd > "$folder/contact-identity-compile.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/contact-identity-compile.log"; then exit 1; fi
timeout 60s "$GODOT" --headless --quit-after 1 --script res://tests/physics_fix/test_staged_contact_identity.gd > "$folder/contact-identity.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/contact-identity.log"; then exit 1; fi
if ! grep -Fxq 'Staged contact identity: 12 checks, 0 failures' "$folder/contact-identity.log"; then exit 1; fi
# NEW simultaneous angular/hinge/contact component gate: ZERO world ticks.
"$GODOT" --headless --check-only --script res://tests/physics_fix/test_limited_articulated_components.gd > "$folder/limited-compile.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/limited-compile.log"; then exit 1; fi
timeout 60s "$GODOT" --headless --quit-after 1 --script res://tests/physics_fix/test_limited_articulated_components.gd > "$folder/limited-components.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/limited-components.log"; then exit 1; fi
if ! grep -Fxq 'Angular limited components: 36 checks, 0 failures' "$folder/limited-components.log"; then exit 1; fi
# NEW authored angular-DOF constitutive gate; no world ticks on any failure.
"$GODOT" --headless --check-only --script res://tests/physics_fix/test_assembly_drag_components.gd > "$folder/assembly-drag-compile.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/assembly-drag-compile.log"; then exit 1; fi
timeout 60s "$GODOT" --headless --quit-after 1 --script res://tests/physics_fix/test_assembly_drag_components.gd > "$folder/assembly-drag-components.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/assembly-drag-components.log"; then exit 1; fi
if ! grep -Fxq 'Assembly angular drag components: 26 checks, 0 failures' "$folder/assembly-drag-components.log"; then exit 1; fi
# NEW one/two-pass dependency components, BEFORE any public world ticks.
"$GODOT" --headless --check-only --script res://tests/physics_fix/test_preintegrated_components.gd > "$folder/preintegrated-compile.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/preintegrated-compile.log"; then exit 1; fi
timeout 60s "$GODOT" --headless --quit-after 1 --script res://tests/physics_fix/test_preintegrated_components.gd > "$folder/preintegrated-components.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/preintegrated-components.log"; then exit 1; fi
if ! grep -Fxq 'Preintegrated components: 27 checks, 0 failures' "$folder/preintegrated-components.log"; then exit 1; fi
# Existing-motion loss vs full fresh-force components; ZERO public clocks.
"$GODOT" --headless --check-only --script res://tests/physics_fix/test_force_order_components.gd > "$folder/force-order-compile.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/force-order-compile.log"; then exit 1; fi
timeout 60s "$GODOT" --headless --quit-after 1 --script res://tests/physics_fix/test_force_order_components.gd > "$folder/force-order-components.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/force-order-components.log"; then exit 1; fi
if ! grep -Fxq 'Force-order components: 14 checks, 0 failures' "$folder/force-order-components.log"; then exit 1; fi
# Coupled support constitutive and impact-history controls, no public clock.
"$GODOT" --headless --check-only --script res://tests/physics_fix/test_damped_support_components.gd > "$folder/damped-support-compile.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/damped-support-compile.log"; then exit 1; fi
timeout 60s "$GODOT" --headless --quit-after 1 --script res://tests/physics_fix/test_damped_support_components.gd > "$folder/damped-support-components.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/damped-support-components.log"; then exit 1; fi
if ! grep -Fxq 'Damped support components: 29 checks, 0 failures' "$folder/damped-support-components.log"; then exit 1; fi
# Pre-force Newton impact law with unchanged passive mobility, BEFORE public ticks.
"$GODOT" --headless --check-only --script res://tests/physics_fix/test_impact_history_components.gd > "$folder/impact-history-compile.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/impact-history-compile.log"; then exit 1; fi
timeout 60s "$GODOT" --headless --quit-after 1 --script res://tests/physics_fix/test_impact_history_components.gd > "$folder/impact-history-components.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/impact-history-components.log"; then exit 1; fi
if ! grep -Fxq 'Impact history components: 23 checks, 0 failures' "$folder/impact-history-components.log"; then exit 1; fi
# New complete physical operator gate; any error/partial tally forbids world.
"$GODOT" --headless --check-only --script res://tests/physics_fix/test_constitutive_stage_components.gd > "$folder/constitutive-compile.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/constitutive-compile.log"; then exit 1; fi
timeout 60s "$GODOT" --headless --quit-after 1 --script res://tests/physics_fix/test_constitutive_stage_components.gd > "$folder/constitutive-components.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/constitutive-components.log"; then exit 1; fi
if ! grep -Fxq 'Constitutive stage components: 30 checks, 0 failures' "$folder/constitutive-components.log"; then exit 1; fi
# Local per-body angular resistance: independently verified, before public ticks.
"$GODOT" --headless --check-only --script res://tests/physics_fix/test_local_angular_components.gd > "$folder/local-angular-compile.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/local-angular-compile.log"; then exit 1; fi
timeout 60s "$GODOT" --headless --quit-after 1 --script res://tests/physics_fix/test_local_angular_components.gd > "$folder/local-angular-components.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/local-angular-components.log"; then exit 1; fi
if ! grep -Fxq 'Local angular components: 26 checks, 0 failures' "$folder/local-angular-components.log"; then exit 1; fi
# Actual capsule skin velocity/torque controls, before public clock.
"$GODOT" --headless --check-only --script res://tests/physics_fix/test_capsule_surface_components.gd > "$folder/capsule-surface-compile.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/capsule-surface-compile.log"; then exit 1; fi
timeout 60s "$GODOT" --headless --quit-after 1 --script res://tests/physics_fix/test_capsule_surface_components.gd > "$folder/capsule-surface-components.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/capsule-surface-components.log"; then exit 1; fi
if ! grep -Fxq 'Capsule surface components: 24 checks, 0 failures' "$folder/capsule-surface-components.log"; then exit 1; fi
# Owner-authorized structural-pad controls, before public clock.
"$GODOT" --headless --check-only --script res://tests/physics_fix/test_rigid_pad_components.gd > "$folder/rigid-pad-compile.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/rigid-pad-compile.log"; then exit 1; fi
timeout 60s "$GODOT" --headless --quit-after 1 --script res://tests/physics_fix/test_rigid_pad_components.gd > "$folder/rigid-pad-components.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/rigid-pad-components.log"; then exit 1; fi
if ! grep -Fxq 'Rigid pad components: 24 checks, 0 failures' "$folder/rigid-pad-components.log"; then exit 1; fi
# Real support complementarity/rollback/limit controls, before public clock.
"$GODOT" --headless --check-only --script res://tests/physics_fix/test_support_manifold_components.gd > "$folder/support-manifold-compile.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/support-manifold-compile.log"; then exit 1; fi
timeout 60s "$GODOT" --headless --quit-after 1 --script res://tests/physics_fix/test_support_manifold_components.gd > "$folder/support-manifold-components.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/support-manifold-components.log"; then exit 1; fi
if ! grep -Fxq 'Support manifold components: 29 checks, 0 failures' "$folder/support-manifold-components.log"; then exit 1; fi
# Derived physical stance proof, before public clock; all previous barriers remain.
"$GODOT" --headless --check-only --script res://tests/physics_fix/test_coplanar_pad_components.gd > "$folder/coplanar-pad-compile.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/coplanar-pad-compile.log"; then exit 1; fi
timeout 60s "$GODOT" --headless --quit-after 1 --script res://tests/physics_fix/test_coplanar_pad_components.gd > "$folder/coplanar-pad-components.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/coplanar-pad-components.log"; then exit 1; fi
if ! grep -Fxq 'Coplanar pad components: 31 checks, 0 failures' "$folder/coplanar-pad-components.log"; then exit 1; fi
# NEW single final-geometry constitutive phase gate, before ANY public world tick.
"$GODOT" --headless --check-only --script res://tests/physics_fix/test_final_geometry_components.gd > "$folder/final-geometry-compile.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/final-geometry-compile.log"; then exit 1; fi
timeout 60s "$GODOT" --headless --quit-after 1 --script res://tests/physics_fix/test_final_geometry_components.gd > "$folder/final-geometry-components.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/final-geometry-components.log"; then exit 1; fi
if ! grep -Fxq 'Final geometry components: 57 checks, 0 failures' "$folder/final-geometry-components.log"; then exit 1; fi
# Exact tensile-normal rank trap regression; final new gate before public clock.
"$GODOT" --headless --check-only --script res://tests/physics_fix/test_dual_feasible_components.gd > "$folder/dual-feasible-compile.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/dual-feasible-compile.log"; then exit 1; fi
timeout 60s "$GODOT" --headless --quit-after 1 --script res://tests/physics_fix/test_dual_feasible_components.gd > "$folder/dual-feasible-components.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/dual-feasible-components.log"; then exit 1; fi
if ! grep -Fxq 'Dual feasible components: 6 checks, 0 failures' "$folder/dual-feasible-components.log"; then exit 1; fi
# Exact285 false-violation rank trap and arithmetic negatives, ZERO ticks.
"$GODOT" --headless --check-only --script res://tests/physics_fix/test_twofold_components.gd > "$folder/twofold-compile.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/twofold-compile.log"; then exit 1; fi
timeout 60s "$GODOT" --headless --quit-after 1 --script res://tests/physics_fix/test_twofold_components.gd > "$folder/twofold-components.log" 2>&1
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$folder/twofold-components.log"; then exit 1; fi
if ! grep -Fxq 'Twofold active components: 10 checks, 0 failures' "$folder/twofold-components.log"; then exit 1; fi
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
