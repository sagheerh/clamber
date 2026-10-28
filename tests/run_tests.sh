#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
python3 tests/test_static.py
python3 tests/test_android_inspection.py
GODOT="${GODOT:-godot}"
if ! command -v "$GODOT" >/dev/null 2>&1; then
  echo "ERROR: Godot 4.7.2-stable required. Set GODOT=/absolute/path/to/godot." >&2
  exit 127
fi
version="$("$GODOT" --version)"
case "$version" in
  4.7.2.stable*) ;;
  *) echo "ERROR: Expected 4.7.2.stable, got $version" >&2; exit 1 ;;
esac
# Populate global class cache from a clean checkout before loading custom resources.
logs="$(mktemp -d)"
trap 'rm -rf "$logs"' EXIT
"$GODOT" --headless --editor --import 2>&1 | tee "$logs/import.log"
if grep -Eq 'SCRIPT ERROR:|Parse Error:|Failed to load script' "$logs/import.log"; then
  echo "ERROR: Godot import reported script compilation errors." >&2
  exit 1
fi
"$GODOT" --headless --run-tests 2>&1 | tee "$logs/runtime.log"
if grep -Eq 'SCRIPT ERROR:|Parse Error:|Failed to load script' "$logs/runtime.log" ||
   ! grep -Eq '^M0: [0-9]+ checks, 0 failures$' "$logs/runtime.log"; then
  echo "ERROR: Godot did not complete a clean M0 test run." >&2
  exit 1
fi
