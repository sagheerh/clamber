#!/usr/bin/env bash
# Review-pack invariant / scaffold-honesty checks.
# This is NOT M1 runtime evidence. It only proves the scaffold is honest and
# the static A9/invariant guards are in place. Real M1 gates stay NOT RUN.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== M0 static contract tests =="
python3 tests/test_static.py

echo "== Android inspector unit tests =="
python3 tests/test_android_inspection.py

echo "== Shell syntax =="
bash -n tests/run_tests.sh tests/build_android.sh scripts/review_checks.sh

echo "== Review pack + A9 / invariant static scan =="
python3 - <<'PY'
import re
import sys
from pathlib import Path

ROOT = Path('.')
errors = []

def code_only(text: str) -> str:
    # Strip GDScript strings and # comments before scanning code tokens.
    return re.sub(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|#[^\n]*', '', text)

def scan(path: Path, patterns: list[str], label: str) -> None:
    code = code_only(path.read_text())
    for pattern in patterns:
        if re.search(pattern, code):
            errors.append(f"{path}: {label} -> /{pattern}/")

# A9.1 / INV-03 / INV-05: no nondeterministic inputs in sim/run/tower.
INPUT_BANS = [
    r'\brandf\s*\(',
    r'\brandi\s*\(',
    r'\brandomize\s*\(',
    r'Time\.get_ticks_',
    r'Engine\.get_physics_frames',
    r'\b_process\s*\(',
    r'\bdelta\b',
]
for directory in ['core/sim', 'core/run', 'core/tower']:
    for path in (ROOT / directory).rglob('*.gd'):
        scan(path, INPUT_BANS, 'A9.1 forbidden sim input')

# A9.6 / INV-04: transcendental ban inside solver integration/constraint code.
MATH_BANS = [r'\b(sin|cos|tan|pow|exp|atan2)\s*\(']
for path in (ROOT / 'core/sim').rglob('*.gd'):
    scan(path, MATH_BANS, 'A9.6 transcendental in solver')

# INV-01: no Godot physics nodes in core.
NODE_BANS = [r'\b(RigidBody2D|Joint2D|PinJoint2D|DampedSpringJoint2D)\b']
for path in (ROOT / 'core').rglob('*.gd'):
    scan(path, NODE_BANS, 'INV-01 Godot physics node')

# A9.3: RNG must be injected through Sim.setup.
sim = (ROOT / 'core/sim/sim.gd').read_text()
if not re.search(r'func setup\([^)]*seed:\s*int', sim):
    errors.append('core/sim/sim.gd: A9.3 seed is not a Sim.setup parameter')

# A9.2 / INV-05: fixed 1/60 step configured.
project = (ROOT / 'project.godot').read_text()
if 'physics_ticks_per_second=60' not in project:
    errors.append('project.godot: missing fixed 60 Hz physics tick')
tuning = (ROOT / 'core/tuning.tres').read_text()
if not re.search(r'^physics_tick_hz = 60$', tuning, re.M):
    errors.append('core/tuning.tres: physics_tick_hz != 60')

# Full external review pack must be vendored, not paraphrased.
pack = ROOT / 'docs/CLAMBER_REVIEW_AGENT.md'
if not pack.exists():
    errors.append('docs/CLAMBER_REVIEW_AGENT.md: full review pack missing')
else:
    text = pack.read_text()
    for token in ['PART B', 'A9. Determinism deep-check', 'INV-01', 'A12. Output format']:
        if token not in text:
            errors.append(f'docs/CLAMBER_REVIEW_AGENT.md: missing {token!r}')

# M1 acceptance matrix must exist, include all external details, and stay honest.
matrix_path = ROOT / '.review/m1_ac_matrix.md'
if not matrix_path.exists():
    errors.append('.review/m1_ac_matrix.md: missing')
else:
    matrix = matrix_path.read_text()
    required = [
        'AC-201', 'AC-202', 'AC-204', 'Three presets', 'Tick cost',
        'A9 replay', 'A9 two-second stall', 'A9.5 two frame conditions',
        'A9 mandatory falsification', 'Baseline / CI regression',
        'A9.1 static scan', 'INV-01..INV-10',
        '488', 'm1_verdict', 'docs/CLAMBER_REVIEW_AGENT.md',
    ]
    for token in required:
        if token not in matrix:
            errors.append(f'.review/m1_ac_matrix.md: missing required token {token!r}')
    if matrix.count('NOT RUN') < 12:
        errors.append('.review/m1_ac_matrix.md: fewer than 12 NOT RUN gate rows')
    for number, line in enumerate(matrix.splitlines(), 1):
        if re.search(r'\|\s*(Met|PASS(?:ED)?|VERIFIED)\s*\|', line, re.I):
            errors.append(f'.review/m1_ac_matrix.md:{number}: premature passed-gate claim: {line.strip()}')

# CI must actually run this script.
workflows = list((ROOT / '.github/workflows').glob('*.yml'))
if not workflows:
    errors.append('.github/workflows: no workflow files')
if not any('scripts/review_checks.sh' in w.read_text() for w in workflows):
    errors.append('.github/workflows: review_checks.sh is not wired into CI')

if errors:
    print('REVIEW CHECKS FAILED:')
    for error in errors:
        print(' -', error)
    sys.exit(1)
print('A9 / invariant static scan: PASS')
print('M1 scaffold honesty: PASS (all runtime gates NOT RUN)')
PY

echo "== Review checks complete: PASS =="
