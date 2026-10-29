#!/usr/bin/env python3
"""Classifier falsification only; not convergence evidence for a real creature."""
import unittest
from load_convergence_report import classify, drift_summary
from test_load_trace import fixture


class ConvergenceControls(unittest.TestCase):
    def test_exact_constant_positive_drift_is_settled_not_rest(self):
        c = classify([(0.001, .06)]*300)
        self.assertTrue(c['settled'])
        self.assertEqual(c['settled_mean_vx_wu_s'], .06)
        self.assertEqual(c['exact_period_ticks'], 1)

    def test_monotone_is_transient_not_equilibrium(self):
        c = classify([(i/60000, i/1000) for i in range(600)])
        self.assertEqual(c['classification'], 'monotone transient')
        self.assertIsNone(c['settled_mean_vx_wu_s'])

    def test_changing_oscillation_is_not_settled_by_bounded_range(self):
        c = classify([(i/100000, (-1)**i/(i+1)) for i in range(600)])
        self.assertEqual(c['classification'], 'oscillating transient')
        self.assertGreater(c['vx_change_sign_reversals'], 0)
        self.assertFalse(c['settled'])

    def test_exact_period_reports_nonzero_settled_mean(self):
        c = classify([(.001,.05),(.002,.10)]*150)
        self.assertEqual(c['exact_period_ticks'], 2)
        self.assertAlmostEqual(c['settled_mean_dx_wu_tick'], .0015)

    def test_same_vx_changing_position_drift_does_not_pass(self):
        self.assertFalse(classify([(i/100000,.04) for i in range(300)])['settled'])

    def test_tiny_velocity_change_is_not_epsilon_clipped(self):
        self.assertFalse(classify([(i/1e22,.04+i/1e19) for i in range(300)])['settled'])

    def test_short_or_nonfinite_is_unavailable_not_settled(self):
        for a in ([(0.,0.)]*299, [(0.,float('nan'))]*300):
            with self.assertRaises(ValueError): classify(a)

    def test_count_recurrence_does_not_grant_settlement(self):
        rows=fixture()
        for i,r in enumerate(rows):
            r['contact_counts']=[{'active_count':i%3}]
        d=drift_summary(rows)
        self.assertEqual(d['raw_recurrence_diagnostics']['count_pattern_period_ticks'],3)
        self.assertEqual(d['raw_recurrence_diagnostics']['repeat_lag_vx_max_difference_wu_s'],0.)
        self.assertIn('no settlement',d['raw_recurrence_diagnostics']['meaning'])

    def test_zero_input_has_live_return_label_and_own_units(self):
        rows=fixture()
        for r in rows:r['diagnostic_actuated']=True;r['input_mask']=0
        d=drift_summary(rows)
        self.assertTrue(d['spring_return_live'])
        self.assertIn('NOT UNPOWERED',d['power_description'])
        rows[-1]['input_mask']=1
        with self.assertRaises(ValueError): drift_summary(rows)


if __name__=='__main__': unittest.main(verbosity=2)
