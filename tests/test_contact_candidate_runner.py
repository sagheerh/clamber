#!/usr/bin/env python3
"""Shell routing/error-barrier tests with a TEST DOUBLE, zero real engine ticks."""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]


class CandidateRunnerTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        shutil.copytree(ROOT / 'core', self.root / 'core')
        for name in ['tests/run_m1_contact_candidate.sh', 'tests/source_provenance.py',
                     'tests/fixtures/source_manifest.json',
                     'tests/physics_fix/rigid_contact_candidate.gd',
                     'tests/physics_fix/test_rigid_contact_candidate.gd']:
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(ROOT / name, target)
        self.fake = self.root / 'test-double.py'
        self.calls = self.root / 'test-double-calls.jsonl'
        self.fake.write_text('''#!/usr/bin/env python3
import json,os,sys
from pathlib import Path
args=sys.argv[1:]
with Path(os.environ['DOUBLE_CALLS']).open('a') as f:f.write(json.dumps(args)+'\\n')
if '--version' in args:
 print(os.environ.get('DOUBLE_VERSION','4.7.2.stable.official.ed1daf0bf'));sys.exit(0)
stage='import' if '--import' in args else 'compile' if '--check-only' in args else 'units'
if stage == os.environ.get('DOUBLE_ERROR_STAGE'):
 print('SCRIPT ERROR: intentional TEST DOUBLE error, zero engine ticks')
if stage=='units': print('Unadopted rigid contact units: '+os.environ.get('DOUBLE_COUNT','31')+' checks, 0 failures')
sys.exit(7 if stage == os.environ.get('DOUBLE_EXIT_STAGE') else 0)
''')
        self.fake.chmod(0o755)

    def run_double(self, **extra):
        env = dict(os.environ, GODOT=str(self.fake), DOUBLE_CALLS=str(self.calls))
        env.update(extra)
        result = subprocess.run(['bash', 'tests/run_m1_contact_candidate.sh'],
                                cwd=self.root, env=env, text=True, capture_output=True)
        calls = [json.loads(line) for line in self.calls.read_text().splitlines()]
        stages = ['import' if '--import' in a else 'compile' if '--check-only' in a else 'units'
                  for a in calls if '--version' not in a]
        return result, stages

    def test_logged_import_error_stops_before_compile(self):
        result, stages = self.run_double(DOUBLE_ERROR_STAGE='import')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(stages, ['import'])

    def test_nonzero_import_stops_before_compile(self):
        result, stages = self.run_double(DOUBLE_EXIT_STAGE='import')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(stages, ['import'])

    def test_logged_compile_error_stops_before_units(self):
        result, stages = self.run_double(DOUBLE_ERROR_STAGE='compile')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(stages, ['import', 'compile'])

    def test_nonzero_compile_stops_before_units(self):
        result, stages = self.run_double(DOUBLE_EXIT_STAGE='compile')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(stages, ['import', 'compile'])

    def test_logged_unit_error_cannot_be_a_pass(self):
        result, stages = self.run_double(DOUBLE_ERROR_STAGE='units')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(stages, ['import', 'compile', 'units'])

    def test_incomplete_unit_count_cannot_be_a_pass(self):
        result, _ = self.run_double(DOUBLE_COUNT='30')
        self.assertNotEqual(result.returncode, 0)

    def test_wrong_engine_rejected_before_import(self):
        result, stages = self.run_double(DOUBLE_VERSION='wrong')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(stages, [])

    def test_existing_evidence_is_not_overwritten(self):
        folder = self.root / 'exports/contact-candidate-units'
        folder.mkdir(parents=True)
        sentinel = folder / 'retain.txt'
        sentinel.write_text('retain failure')
        result, stages = self.run_double()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(stages, [])
        self.assertEqual(sentinel.read_text(), 'retain failure')

    def test_success_route_only_not_engine_evidence(self):
        result, stages = self.run_double()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(stages, ['import', 'compile', 'units'])


if __name__ == '__main__': unittest.main(verbosity=2)
