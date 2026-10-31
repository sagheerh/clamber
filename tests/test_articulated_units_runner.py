#!/usr/bin/env python3
"""Shell routing with a labelled TEST DOUBLE; zero engine/creature ticks."""
import json
import os
import shutil
import subprocess
import unittest
import test_contact_candidate_runner as primitive


class ArticulatedRunnerTests(primitive.CandidateRunnerTests):
    def setUp(self):
        super().setUp()
        for name in ['tests/run_m1_articulated_units.sh',
                     'tests/physics_fix/articulated_mobility_candidate.gd',
                     'tests/physics_fix/test_articulated_mobility_candidate.gd']:
            target = self.root / name
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(primitive.ROOT / name, target)
        fake = self.fake.read_text().replace('Unadopted rigid contact units: ', 'M1 articulated mobility units: ')
        fake = fake.replace("os.environ.get('DOUBLE_COUNT','31')", "os.environ.get('DOUBLE_COUNT','42')")
        self.fake.write_text(fake)

    def run_double(self, **extra):
        env = dict(os.environ, GODOT=str(self.fake), DOUBLE_CALLS=str(self.calls),
                   M1_ARTICULATED_REPORT_DIR=str(self.root / 'exports/contact-candidate-units'))
        env.update(extra)
        result = subprocess.run(['bash', 'tests/run_m1_articulated_units.sh'],
                                cwd=self.root, env=env, text=True, capture_output=True)
        calls = [json.loads(line) for line in self.calls.read_text().splitlines()]
        stages = ['import' if '--import' in a else 'compile' if '--check-only' in a else 'units'
                  for a in calls if '--version' not in a]
        return result, stages

    def test_nonzero_unit_status_is_preserved(self):
        result, _ = self.run_double(DOUBLE_EXIT_STAGE='units')
        self.assertEqual(result.returncode, 7)
        self.assertEqual((self.root / 'exports/contact-candidate-units/exit-code.txt').read_text(), '7\n')

    def test_zip_has_no_invented_source_commit(self):
        result, _ = self.run_double()
        self.assertEqual(result.returncode, 0, result.stderr)
        data = json.loads((self.root / 'exports/contact-candidate-units/source.json').read_text())
        self.assertIsNone(data['source_commit'])
        self.assertIsNone(data['checkout_head'])
        self.assertEqual(len(data['candidate_sha256']), 4)

    def test_dirty_git_head_cannot_be_claimed_as_candidate_commit(self):
        subprocess.run(['git', 'init', '--quiet', '--initial-branch=arena/f43f36ab-clamber'], cwd=self.root, check=True)
        subprocess.run(['git', '-c', 'user.name=TEST DOUBLE', '-c', 'user.email=test-double@invalid',
                        'commit', '--quiet', '--allow-empty', '-m', 'test fixture ONLY'], cwd=self.root, check=True)
        result, _ = self.run_double()
        self.assertEqual(result.returncode, 0, result.stderr)
        data = json.loads((self.root / 'exports/contact-candidate-units/source.json').read_text())
        self.assertTrue(data['checkout_dirty'])
        self.assertIsNotNone(data['checkout_head'])
        self.assertIsNone(data['source_commit'])


if __name__ == '__main__':
    unittest.main(verbosity=2)
