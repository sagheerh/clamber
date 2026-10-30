#!/usr/bin/env bash
# Production definitions and contact component tests only, NOT coupled FA-5.
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
"$GODOT" --headless --script res://tests/sim/test_contacts.gd 2>&1 | tee "$logs/contacts.log"
if grep -Eq 'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script' "$logs/import.log" "$logs/contacts.log"; then
  echo 'ERROR: M1 contact primitives emitted engine/script errors' >&2
  exit 1
fi
python3 - "$logs/contacts.log" <<'PYRESULT'
import re, sys
text = open(sys.argv[1]).read()
counts = re.findall(r'^M1 contact primitives: (\d+) checks, 0 failures$', text, re.M)
if len(counts) != 1 or int(counts[0]) < 237:
    raise SystemExit('ERROR: missing/failed/below-floor contact unit suite (237 minimum)')
if len(re.findall(r'^M1 controlled foot:', text, re.M)) != 4:
    raise SystemExit('ERROR: missing controlled load response traces')
print('M1 contact units verified; controlled loads are NOT whole-creature FA-5 evidence')
PYRESULT
