#!/usr/bin/env python3
"""R16 adversarial diagnostic-gate controls, never physical/FA evidence."""
from copy import deepcopy
import json
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from load_trace_report import analyze, sustained_support
from test_load_trace import fixture
from test_contact_trace import contact_fixture


class R16Gate(unittest.TestCase):
    def test_landing_impact_only_does_not_pass(self):
        for ticks in ([19], list(range(4, 9))):
            rows = fixture()
            for tick in ticks: rows[tick]['feet'][0]['gripping'] = True
            r = analyze(rows)
            self.assertTrue(r['loaded_grip_ticks'])
            self.assertTrue(r['momentum_ledger_verified'])
            self.assertFalse(r['foot_load_path_exercised'])
            self.assertEqual(r['sustained_support_gate']['grip_fraction'], 0)
            self.assertEqual(r['FA-5'], 'NOT RUN')

    def _row(self, shares, grip):
        return {'tick': 599, 'feet': [dict(grounded=True, gripping=g, measured_reaction_n=s, positional_cleanup_n=9999.) for s, g in zip(shares, grip)],
                'other_bodies': [dict(grounded=True, measured_reaction_n=1-sum(shares))]}

    def test_positive_control_majority_loaded_grip_not_fa5(self):
        rows = fixture()
        for r in rows[300:]: r['feet'][0]['gripping'] = True
        r = analyze(rows)
        self.assertTrue(r['foot_load_path_exercised'])
        self.assertEqual(r['sustained_support_gate']['loaded_majority_grip_ticks'], list(range(300,600)))
        self.assertEqual(r['FA-5'], 'NOT RUN')

    def test_exact_half_fails_no_epsilon(self):
        self.assertFalse(sustained_support([self._row([.5], [True])])['passed'])
        self.assertTrue(sustained_support([self._row([.5000000000000001], [True])])['passed'])

    def test_aggregate_feet_majority_cannot_fake_single_foot_majority(self):
        self.assertFalse(sustained_support([self._row([.3, .3], [True, True])])['passed'])

    def test_share_and_grip_must_coincide_same_foot_and_tick(self):
        self.assertFalse(sustained_support([self._row([.2, .7], [True, False])])['passed'])
        a, b = self._row([.7], [False]), self._row([.2], [True])
        self.assertFalse(sustained_support([a, b])['passed'])

    def test_ungrounded_and_zero_reaction_and_cleanup_cannot_pass(self):
        r = self._row([.8], [True]); r['feet'][0]['grounded'] = False
        self.assertFalse(sustained_support([r])['passed'])
        self.assertFalse(sustained_support([self._row([0.], [True])])['passed'])

    def test_only_last300_counts(self):
        rows = fixture(); rows[299]['feet'][0]['gripping'] = True
        self.assertFalse(analyze(rows)['foot_load_path_exercised'])
        rows[300]['feet'][0]['gripping'] = True
        self.assertTrue(analyze(rows)['foot_load_path_exercised'])

    def test_actual_cli_fails_landing_only_without_bypass(self):
        rows = contact_fixture()
        for tick in range(4, 9): rows[tick]['feet'][0]['gripping'] = True
        with tempfile.TemporaryDirectory() as folder:
            p = Path(folder)
            (p/'rows.jsonl').write_text(''.join(json.dumps(r)+'\n' for r in rows))
            run = subprocess.run([sys.executable, str(Path(__file__).with_name('load_trace_report.py')), str(p/'rows.jsonl'), str(p/'summary.json')], capture_output=True, text=True)
            self.assertEqual(run.returncode, 1, run.stderr)
            r = json.loads((p/'summary.json').read_text())
            self.assertTrue(r['momentum_ledger_verified'])
            self.assertTrue(r['loaded_grip_ticks'])
            self.assertFalse(r['foot_load_path_exercised'])
            self.assertIn('sustained majority foot support', run.stdout)


if __name__ == '__main__': unittest.main(verbosity=2)
