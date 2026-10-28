#!/usr/bin/env bash
# Primitive math unit tests only, not M1 creature/replay/soak acceptance.
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
if grep -Eq 'SCRIPT ERROR:|Parse Error:|Failed to load script' "$logs/import.log" "$logs/math.log" ||
   ! grep -Eq '^M1 math foundations: [0-9]+ checks, 0 failures$' "$logs/math.log"; then
  echo 'ERROR: M1 primitive math test did not complete cleanly' >&2
  exit 1
fi
