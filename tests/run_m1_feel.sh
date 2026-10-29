#!/usr/bin/env bash
# Analytic geometry only; runtime feel plans are explicit NOT RUN placeholders.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
case "$("$GODOT" --version)" in
  4.7.2.stable*) ;;
  *) echo 'ERROR: exact Godot 4.7.2-stable required' >&2; exit 1 ;;
esac
logs="$(mktemp -d)"
trap 'rm -rf "$logs"' EXIT
report="${M1_GEOMETRY_REPORT:-$logs/owner-geometry.json}"
"$GODOT" --headless --editor --import 2>&1 | tee "$logs/import.log"
"$GODOT" --headless --script res://tests/feel/test_owner_geometry.gd -- "--report=$report" 2>&1 | tee "$logs/geometry.log"
if grep -Eq 'SCRIPT ERROR:|Parse Error:|Failed to load script' "$logs/import.log" "$logs/geometry.log" ||
   ! grep -Eq '^M1 owner geometry: [0-9]+ checks, 0 failures$' "$logs/geometry.log"; then
  echo 'ERROR: owner geometry harness did not complete cleanly' >&2
  exit 1
fi
python3 - "$report" <<'PYREPORT'
import json, math, sys
report = json.load(open(sys.argv[1]))
assert report['failures'] == 0
assert [(r['preset'], len(r['parts'])) for r in report['authored_preset_bottoms']] == [('Slug', 3), ('Hopper', 8), ('TwinRoller', 6)], 'missing/non-vacuous bottom audit'
for preset in report['authored_preset_bottoms']:
    parts = preset['parts']
    assert [p['part'] for p in parts] == list(range(len(parts)))
    assert all(math.isfinite(p['bottom_wu']) for p in parts)
    expected_flags = [{'non_foot': p['part'], 'foot': f['part'],
                       'gap_wu': f['bottom_wu'] - p['bottom_wu']}
                      for f in parts for p in parts
                      if f['kind'] == 'foot' and p['kind'] != 'foot' and p['bottom_wu'] < f['bottom_wu']]
    flags = preset['non_foot_below_foot']
    assert [(r['non_foot'], r['foot']) for r in flags] == [(r['non_foot'], r['foot']) for r in expected_flags]
    assert all(math.isclose(a['gap_wu'], b['gap_wu'], rel_tol=0, abs_tol=1e-12)
               for a, b in zip(flags, expected_flags))
    exemptions = {'TwinRoller': [5]}.get(preset['preset'], [])
    assert preset['non_support_stub_exemptions'] == exemptions
    assert not [f for f in flags if f['foot'] not in exemptions], 'F36 support-foot pose assertion'
    assert preset['support_violations'] == []
assert report['checks'] >= 131, 'Owner geometry count floor regressed'
assert all(row['status'] == 'PASS (analytic only)' for row in report['analytic'].values())
assert all(row['status'] == 'NOT RUN' and row['observations'] is None for row in report['runtime'])
assert next(row for row in report['runtime'] if row['id'] == 'FA-6')['success_count'] is None
print('M1 geometry report: analytic-only assertions complete; runtime observations remain null/NOT RUN.')
PYREPORT
