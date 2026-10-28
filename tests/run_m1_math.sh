#!/usr/bin/env bash
# Point/link/integration/clock unit tests only, not M1 creature acceptance.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
case "$("$GODOT" --version)" in
  4.7.2.stable*) ;;
  *) echo 'ERROR: exact Godot 4.7.2-stable required' >&2; exit 1 ;;
esac
logs="$(mktemp -d)"
trap 'rm -rf "$logs"' EXIT
"$GODOT" --headless --editor --import 2>&1 | tee "$logs/import.log"
"$GODOT" --headless --script res://tests/sim/test_math_state.gd 2>&1 | tee "$logs/math.log"
"$GODOT" --headless --script res://tests/sim/test_integration.gd 2>&1 | tee "$logs/integration.log"
if grep -Eq 'SCRIPT ERROR:|Parse Error:|Failed to load script' "$logs/import.log" "$logs/math.log" "$logs/integration.log"; then
  echo 'ERROR: M1 primitive tests emitted engine/script errors' >&2
  exit 1
fi
python3 - "$logs/math.log" "$logs/integration.log" <<'PYRESULT'
import re, sys
counts = []
for path, marker, floor in [(sys.argv[1], 'M1 math foundations', 82),
                            (sys.argv[2], 'M1 integration primitives', 299)]:
    matches = re.findall(r'^' + marker + r': (\d+) checks, 0 failures$', open(path).read(), re.M)
    if len(matches) != 1 or int(matches[0]) < floor:
        raise SystemExit('ERROR: missing/failed/below-floor primitive suite: ' + marker)
    counts.append(int(matches[0]))
print(f'M1 primitive total: {sum(counts)} checks, 0 failures ({counts[0]} point/link + {counts[1]} integration/clock)')
print('M1 acceptance: NOT RUN (primitive fixtures only; no creature/contact/presets/full replay/soak)')
PYRESULT
