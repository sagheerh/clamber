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
"$GODOT" --headless --editor --import
"$GODOT" --headless --run-tests
