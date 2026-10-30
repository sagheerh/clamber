#!/usr/bin/env python3
"""Composed-runner routing regressions with an explicit TEST DOUBLE; zero engine ticks."""
import json
import os
import shutil
import subprocess
import unittest
import test_contact_candidate_runner as primitive


class CompositionRunnerTests(primitive.CandidateRunnerTests):
    def setUp(self):
        super().setUp()
        for name in ['tests/run_m1_contact_composition.sh', 'scripts/publish_m1_contact_composition.py',
                     'tests/physics_fix/actuated_contact_composition.gd',
                     'tests/physics_fix/capsule_contact_composition.gd',
                     'tests/physics_fix/test_contact_composition.gd']:
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(primitive.ROOT / name, target)
        subprocess.run(['git', 'init', '--quiet', '--initial-branch=arena/f43f36ab-clamber'], cwd=self.root, check=True)
        subprocess.run(['git', '-c', 'user.name=TEST DOUBLE', '-c', 'user.email=test-double@invalid',
                        'commit', '--quiet', '--allow-empty', '-m', 'test double fixture ONLY'], cwd=self.root, check=True)
        fake = self.fake.read_text()
        marker = "sys.exit(7 if stage == os.environ.get('DOUBLE_EXIT_STAGE') else 0)"
        addition = '''if stage == 'units' and os.environ.get('DOUBLE_NO_SUMMARY') != '1':
 folder=Path(os.environ['M1_CONTACT_COMPOSITION_REPORT_DIR'])
 names=['idle-Slug','length-Slug','length-Hopper','length-TwinRoller']
 arms={k:dict(ticks=600 if k=='idle-Slug' else 7200,target_ticks=600 if k=='idle-Slug' else 7200,
              termination='completed; candidate metrics satisfied') for k in names}
 if os.environ.get('DOUBLE_COUNT','31') != '31':arms['length-Slug']['ticks']=7199
 if os.environ.get('DOUBLE_MISSING_ARM')=='1':del arms['length-TwinRoller']
 summary=dict(scope='TEST DOUBLE; ZERO ENGINE TICKS',arms=arms,not_run_arms=[],
              status=os.environ.get('DOUBLE_STATUS','CANDIDATE METRICS SATISFIED; NOT ADOPTED'))
 (folder/'summary.json').write_text(json.dumps(summary))
'''
        self.fake.write_text(fake.replace(marker, addition + marker))

    def run_double(self, **extra):
        env = dict(os.environ, GODOT=str(self.fake), DOUBLE_CALLS=str(self.calls),
                   M1_CONTACT_COMPOSITION_REPORT_DIR=str(self.root / 'exports/contact-candidate-units'))
        env.update(extra)
        result = subprocess.run(['bash', 'tests/run_m1_contact_composition.sh'],
                                cwd=self.root, env=env, text=True, capture_output=True)
        calls = [json.loads(line) for line in self.calls.read_text().splitlines()]
        stages = ['import' if '--import' in a else 'compile' if '--check-only' in a else 'units'
                  for a in calls if '--version' not in a]
        return result, stages

    def test_nonzero_unit_exit_preserved(self):
        result, _ = self.run_double(DOUBLE_EXIT_STAGE='units')
        self.assertEqual(result.returncode, 7)
        self.assertEqual((self.root / 'exports/contact-candidate-units/exit-code.txt').read_text(), '7\n')

    def test_missing_summary_not_a_pass(self):
        result, _ = self.run_double(DOUBLE_NO_SUMMARY='1')
        self.assertNotEqual(result.returncode, 0)

    def test_missing_arm_not_a_pass(self):
        result, _ = self.run_double(DOUBLE_MISSING_ARM='1')
        self.assertNotEqual(result.returncode, 0)

    def test_stop_status_not_a_pass(self):
        result, _ = self.run_double(DOUBLE_STATUS='STOP; inspect first failure; NOT ADOPTED')
        self.assertNotEqual(result.returncode, 0)


if __name__ == '__main__':
    unittest.main(verbosity=2)
