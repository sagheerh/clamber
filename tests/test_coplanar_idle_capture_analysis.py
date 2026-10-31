"""Offline positive/negative controls; ZERO engine/public ticks."""
import copy
import gzip
import json
import unittest
from coplanar_idle_analysis import ROOT, SOURCES, audit, audit_rows, audit_slug_geometry, audit_geometry_rows


class CoplanarIdleCaptureAnalysis(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.folder = ROOT/'tests/fixtures/m1_articulated_execution/f101721f17cf'
        cls.rows = [json.loads(line) for line in gzip.open(cls.folder/'idle-Slug.jsonl.gz', 'rt')]
        cls.spawn = json.loads((cls.folder/'idle-Slug-spawn.json').read_text())
        cls.report = json.loads((cls.folder/'idle-Slug-summary.json').read_text())

    def test_actual_changed_sources_pass_idle_but_not_long_run_or_adoption(self):
        for name in SOURCES:
            with self.subTest(source=name):
                result = audit(ROOT/'tests/fixtures/m1_articulated_execution'/name)
                self.assertEqual(result['first_sleep_tick'], 29)
                self.assertEqual(result['max_attitude_deg'], 0.0)
                self.assertEqual(result['net_com_wu'], 0.0)
                if name in ['bccae29d24ad', 'c49fcc66ee9f']:
                    self.assertIsNone(result['subsequent_slug_failure'])
                    self.assertEqual(result['subsequent_hopper_failure'], 5 if name == 'bccae29d24ad' else 256)
                else:
                    self.assertIn(result['subsequent_slug_failure'], [214, 247])

    def test_complete_slug_geometry_real_input_and_wake(self):
        for name in ['bccae29d24ad', 'c49fcc66ee9f']:
            result = audit_slug_geometry(ROOT/'tests/fixtures/m1_articulated_execution'/name)
            self.assertEqual(result['ticks'], 7200)
            self.assertEqual(result['first_actual_wake_tick'], 60)

    def test_long_incomplete_is_not7200(self):
        with self.assertRaisesRegex(ValueError, 'full7200'):
            audit_geometry_rows([])

    def test_short599_is_not600(self):
        with self.assertRaisesRegex(ValueError, 'full600'):
            audit_rows(self.rows[:-1], self.spawn, self.report)

    def test_duplicate_tick_rejected(self):
        rows = copy.deepcopy(self.rows)
        rows[200]['tick'] -= 1
        with self.assertRaisesRegex(ValueError, 'tick/input'):
            audit_rows(rows, self.spawn, self.report)

    def test_fake_sleep_report_rejected(self):
        report = dict(self.report, first_sleep_tick=245)
        with self.assertRaisesRegex(ValueError, 'independently agree'):
            audit_rows(self.rows, self.spawn, report)

    def test_hidden_motion_rejected_even_when_report_stays_green(self):
        rows = copy.deepcopy(self.rows)
        rows[10]['state']['physical']['bodies'][0]['a']['x'] += .1
        with self.assertRaisesRegex(ValueError, 'posture'):
            audit_rows(rows, self.spawn, self.report)

    def test_fake_ground_flags_rejected(self):
        rows = copy.deepcopy(self.rows)
        for body in rows[0]['state']['physical']['bodies']:
            body['grounded'] = False
        with self.assertRaisesRegex(ValueError, 'airborne'):
            audit_rows(rows, self.spawn, self.report)

    def test_sleep_nonzero_velocity_rejected(self):
        rows = copy.deepcopy(self.rows)
        rows[400]['state']['physical']['bodies'][2]['b']['velocity_x'] = 1e-12
        with self.assertRaisesRegex(ValueError, 'zero velocities'):
            audit_rows(rows, self.spawn, self.report)

    def test_anchor_motion_rejected_even_with_fake_green_sleep_metrics(self):
        rows = copy.deepcopy(self.rows)
        for endpoint in ['a', 'b']:
            rows[400]['state']['physical']['bodies'][2][endpoint]['x'] += .0011
        with self.assertRaisesRegex(ValueError, 'actual anchored'):
            audit_rows(rows, self.spawn, self.report)

    def test_premature_sleep_cannot_fabricate_thirty_tick_dwell(self):
        rows = copy.deepcopy(self.rows)
        rows[0]['state']['sleep']['asleep'] = True
        rows[0]['state']['sleep']['still_ticks'] = 30
        with self.assertRaisesRegex(ValueError, 'dwell count'):
            audit_rows(rows, self.spawn, self.report)

    def test_hidden_nonfinite_rejected(self):
        rows = copy.deepcopy(self.rows)
        rows[500]['awake_solver_trace']['injected_nonfinite'] = float('nan')
        with self.assertRaisesRegex(ValueError, 'finite'):
            audit_rows(rows, self.spawn, self.report)


if __name__ == '__main__':
    unittest.main()
