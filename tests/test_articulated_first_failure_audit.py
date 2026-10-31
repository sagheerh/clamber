#!/usr/bin/env python3
"""Audit immutable partial evidence ONLY. Never invokes Godot or creates world ticks."""
import base64
import gzip
import hashlib
import json
import math
from pathlib import Path
import subprocess
import unittest

ROOT = Path(__file__).resolve().parents[1]
SOURCE = '6b48e638c368579abcef1a59289809d6b8b7a158'
FOLDER = ROOT / 'tests/fixtures/m1_articulated_execution' / SOURCE[:12]


class FirstFailureAudit(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source = json.loads((FOLDER/'source.json').read_text())
        cls.index = json.loads((FOLDER/'transport-index.json').read_text())
        cls.summary = json.loads((FOLDER/'summary.json').read_text())
        cls.raw = gzip.decompress((FOLDER/'idle-Slug.jsonl.gz').read_bytes())
        cls.rows = [json.loads(s) for s in cls.raw.splitlines()]

    def test_source_clean_and_exact(self):
        self.assertEqual(self.source['source_commit'], SOURCE)
        self.assertEqual(self.source['checkout_head'], SOURCE)
        self.assertIs(self.source['checkout_dirty'], False)
        self.assertEqual(self.source['source_ci_run'], '41150287513')
        self.assertEqual(self.index['source_commit'], SOURCE)

    def test_candidate_hashes_match_historical_git_source_not_current_code(self):
        for name, expected in self.source['candidate_sha256'].items():
            actual = subprocess.check_output(['git', 'show', f'{SOURCE}:{name}'], cwd=ROOT)
            self.assertEqual(hashlib.sha256(actual).hexdigest(), expected, name)

    def test_transport_integrity(self):
        expected = self.index['raw_traces']['idle-Slug.jsonl']
        packed = (FOLDER/'idle-Slug.jsonl.gz').read_bytes()
        self.assertEqual(expected['raw_bytes'], len(self.raw))
        self.assertEqual(expected['raw_sha256'], hashlib.sha256(self.raw).hexdigest())
        self.assertEqual(expected['gzip_bytes'], len(packed))
        self.assertEqual(expected['gzip_sha256'], hashlib.sha256(packed).hexdigest())

    def test_two_frames_not_600_or_determinism_evidence(self):
        self.assertEqual([r['tick'] for r in self.rows], [0, 1])
        arm = self.summary['arms']['idle-Slug']
        self.assertEqual((arm['ticks'], arm['target_ticks'], arm['failing_tick']), (2, 600, 2))
        self.assertEqual(arm['solver_status'], 30)
        self.assertEqual(self.summary['status'], 'STOP; inspect first failure; NOT ADOPTED')
        self.assertEqual((FOLDER/'exit-code.txt').read_text(), '1\n')

    def test_later_arms_not_run(self):
        self.assertEqual(set(self.summary['arms']), {'idle-Slug'})
        self.assertEqual(self.summary['not_run_arms'], ['length-Slug', 'length-Hopper', 'length-TwinRoller'])
        self.assertEqual(list(FOLDER.glob('length-*')), [])

    def test_compile_success_and_specific_post_cap_error(self):
        self.assertIn('4.7.2.stable.official.ed1daf0bf', self.source['engine_build'])
        for name in ['import', 'compile']:
            text = (FOLDER/(name+'.log')).read_text()
            for error in ['SCRIPT ERROR:', 'ERROR:', 'Parse Error:']:
                self.assertNotIn(error, text)
        self.assertIn('ERROR: Articulated post-cap reconciliation failure', (FOLDER/'engine.log').read_text())

    def test_full_variant_failure_is_retained_not_json_null(self):
        failed = json.loads((FOLDER/'idle-Slug-failure.json').read_text())
        self.assertEqual(failed['tick'], 2)
        self.assertEqual(failed['status'], 30)
        self.assertEqual(failed['nonfinite'], [])
        self.assertGreater(len(base64.b64decode(failed['full_state_variant_base64'], validate=True)), 10000)

    def test_last_committed_speeds_below_original_cap_not_failing_work_state(self):
        values = []
        for body in self.rows[-1]['state']['physical']['bodies']:
            a, b = body['a'], body['b']
            dx, dy = b['x']-a['x'], b['y']-a['y']
            omega = (dx*(b['velocity_y']-a['velocity_y'])-dy*(b['velocity_x']-a['velocity_x']))/(dx*dx+dy*dy)
            self.assertLess(abs(omega), 24.0)
            values.append(omega)
        self.assertEqual(values, [2.4070941984621723, 0.5564046657230058, -0.4764001351019629])
        # No assertion about the unobserved tick2 work state or its rejection energy.

    def test_finite_full_partial_trace(self):
        def walk(value):
            if isinstance(value, float): self.assertTrue(math.isfinite(value))
            elif isinstance(value, dict):
                for v in value.values(): walk(v)
            elif isinstance(value, list):
                for v in value: walk(v)
        for row in self.rows: walk(row)

    def test_geometry_metrics_and_all_bodies_present(self):
        peak = 0.0
        for row in self.rows:
            bodies = row['state']['physical']['bodies']
            self.assertEqual([b['kind'] for b in bodies], ['head', 'motor', 'foot'])
            for body in bodies:
                a, b = body['a'], body['b']
                peak = max(peak, abs(math.hypot(b['x']-a['x'], b['y']-a['y'])-body['length']))
            self.assertEqual(row['input_mask'], 0)
        self.assertEqual(peak, self.summary['arms']['idle-Slug']['max_length_wu'])
        self.assertEqual(max(r['attitude_deg'] for r in self.rows), self.summary['arms']['idle-Slug']['max_attitude_deg'])
        self.assertEqual(max(r['penetration_peak_wu'] for r in self.rows), self.summary['arms']['idle-Slug']['max_penetration_wu'])


if __name__ == '__main__': unittest.main(verbosity=2)
