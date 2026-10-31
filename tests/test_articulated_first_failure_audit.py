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


class V2FailureAudit(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.source_id = 'f7b8fd24d6b89cd4644e7ca559619c20a55f26cd'
        cls.folder = ROOT/'tests/fixtures/m1_articulated_execution'/cls.source_id[:12]
        cls.source = json.loads((cls.folder/'source.json').read_text())
        cls.summary = json.loads((cls.folder/'summary.json').read_text())
        cls.packed = (cls.folder/'idle-Slug.jsonl.gz').read_bytes()
        cls.raw = gzip.decompress(cls.packed)
        cls.rows = [json.loads(s) for s in cls.raw.splitlines()]
        cls.annotations = json.loads((ROOT/'.review/physics_fix/articulated-inspection-41151408137-annotations.json').read_text())
        prefix = 'Archived first-failure inspection: '
        cls.inspection = json.loads(next(a['message'][len(prefix):] for a in cls.annotations if a['message'].startswith(prefix)))

    def test_exact_source_and_unchanged_production_manifest(self):
        self.assertEqual(self.source['source_commit'], self.source_id)
        self.assertIs(self.source['checkout_dirty'], False)
        self.assertEqual(self.source['source_ci_run'], '41150933157')
        self.assertEqual(self.source['core_manifest'], json.loads((ROOT/'tests/fixtures/source_manifest.json').read_text()))

    def test_candidate_hashes_bound_to_historical_source(self):
        for name, expected in self.source['candidate_sha256'].items():
            value = subprocess.check_output(['git', 'show', f'{self.source_id}:{name}'], cwd=ROOT)
            self.assertEqual(hashlib.sha256(value).hexdigest(), expected, name)

    def test_transport_hashes_and_byte_counts(self):
        index = json.loads((self.folder/'transport-index.json').read_text())
        self.assertEqual(index['source_commit'], self.source_id)
        entry = index['raw_traces']['idle-Slug.jsonl']
        for data, prefix in [(self.raw, 'raw'), (self.packed, 'gzip')]:
            self.assertEqual(entry[prefix+'_bytes'], len(data))
            self.assertEqual(entry[prefix+'_sha256'], hashlib.sha256(data).hexdigest())

    def test_fourteen_committed_ticks_then_terminal_failure(self):
        arm = self.summary['arms']['idle-Slug']
        self.assertEqual([r['tick'] for r in self.rows], list(range(14)))
        self.assertEqual((arm['ticks'], arm['failing_tick'], arm['solver_status']), (14, 14, 30))
        self.assertEqual(arm['target_ticks'], 600)
        self.assertEqual(arm['termination'], 'step/nonfinite failure')
        self.assertEqual((self.folder/'exit-code.txt').read_text(), '1\n')

    def test_posture_failed_before_numerical_rejection(self):
        angles = [r['attitude_deg'] for r in self.rows]
        self.assertEqual(next(i for i, a in enumerate(angles) if a > 15.0), 8)
        self.assertEqual(angles[8], 18.41374748886769)
        self.assertEqual(max(angles), 38.97992391219688)
        self.assertEqual(self.summary['arms']['idle-Slug']['max_attitude_deg'], max(angles))

    def test_partial_geometry_is_not_7200_tick_acceptance(self):
        arm = self.summary['arms']['idle-Slug']
        self.assertEqual(max(r['length_peak_wu'] for r in self.rows), arm['max_length_wu'])
        self.assertEqual(max(r['penetration_peak_wu'] for r in self.rows), arm['max_penetration_wu'])
        self.assertFalse(any(r['penetration_peak_wu'] > .02*(1+1e-9) for r in self.rows))
        self.assertEqual(set(self.summary['arms']), {'idle-Slug'})
        self.assertEqual(self.summary['not_run_arms'], ['length-Slug', 'length-Hopper', 'length-TwinRoller'])
        self.assertEqual(arm['first_sleep_tick'], -1)

    def test_native_eight_components_passed_before_world(self):
        self.assertIn('Articulated cap identity: 8 checks, 0 failures', (self.folder/'components.log').read_text())
        self.assertIn('ERROR: Articulated pre-contact velocity block failure', (self.folder/'engine.log').read_text())
        failure = json.loads((self.folder/'idle-Slug-failure.json').read_text())
        self.assertGreater(len(base64.b64decode(failure['full_state_variant_base64'], validate=True)), 10000)
        self.assertEqual(failure['nonfinite'], [])

    def test_native_inspection_not_another_world_run(self):
        jobs = json.loads((ROOT/'.review/physics_fix/articulated-inspection-41151408137-jobs.json').read_text())['jobs']
        self.assertEqual(next(j['conclusion'] for j in jobs if j['name']=='articulated-primitives'), 'success')
        self.assertTrue(all(j['conclusion']=='skipped' for j in jobs if j['name']!='articulated-primitives'))
        self.assertTrue(any(a['message']=='Physics-failure inspection: 10 checks, 0 failures' for a in self.annotations))
        self.assertTrue(any(a['message']=='M1 articulated mobility units: 42 checks, 0 failures' for a in self.annotations))
        self.assertEqual(self.inspection['archived_source'], self.source_id)
        self.assertIn('ZERO WORLD TICKS', self.inspection['scope'])

    def test_native_binary64_guard_subcondition_not_an_epsilon_waiver(self):
        import struct
        report = self.inspection
        e0, e1, change = struct.unpack('<3d', bytes.fromhex(report['energy_f64_le_hex']))
        self.assertEqual((e0, e1, change), (report['before_energy'], report['after_energy'], report['energy_change']))
        self.assertGreater(e1, e0)
        self.assertEqual(change, e1-e0)
        self.assertEqual(change/math.ulp(e0), 2.0)
        self.assertEqual(report['phase'], 'pre-contact hinge velocity')
        self.assertEqual(report['velocity_pass'], 1)
        self.assertEqual(report['max_abs_omega'], .057997757374956584)
        self.assertIn('after_energy > before_energy', (ROOT/'tests/physics_fix/articulated_mobility_candidate.gd').read_text())


if __name__ == '__main__': unittest.main(verbosity=2)
