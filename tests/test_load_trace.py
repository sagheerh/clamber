#!/usr/bin/env python3
"""Synthetic parser falsification; these rows are NOT physics evidence."""
import copy
import unittest
from load_trace_report import analyze


def fixture():
    rows = []
    for tick in range(600):
        rows.append({
            'tick': tick, 'status': 0, 'previous_grounded_feet': 0 if tick == 0 else 1,
            'weight_n': 43.4, 'sleep_state': 'awake', 'sleep_implemented': False,
            'sum_applied_load_n': 43.4, 'sum_measured_reaction_n': 43.4,
            'sum_positional_cleanup_n': 0.0,
            'feet': [{'applied_load_n': 43.4, 'measured_reaction_n': 43.4,
                      'positional_cleanup_n': 0.0, 'penetration_wu': 0.02,
                      'grounded': True, 'gripping': False}],
        })
    return rows


class LoadTraceTests(unittest.TestCase):
    def test_complete_window(self):
        result = analyze(fixture())
        self.assertTrue(result['force_window_within_owner_tolerance'])
        self.assertEqual(result['ceiling_n'], 0.723)
        self.assertEqual(result['FA-5'], 'NOT RUN')

    def test_partial_rejected(self):
        with self.assertRaises(ValueError):
            analyze(fixture()[:-1])

    def test_wrong_previous_count(self):
        rows = fixture()
        rows[500]['previous_grounded_feet'] = 2
        with self.assertRaises(ValueError):
            analyze(rows)

    def test_claimed_sum_not_trusted(self):
        rows = fixture()
        rows[350]['feet'][0]['measured_reaction_n'] = 8.4
        with self.assertRaises(ValueError):
            analyze(rows)

    def test_positional_cannot_mask_missing_reaction(self):
        rows = fixture()
        rows[350]['feet'][0]['measured_reaction_n'] = 8.4
        rows[350]['sum_measured_reaction_n'] = 8.4
        rows[350]['feet'][0]['positional_cleanup_n'] = 35.0
        rows[350]['sum_positional_cleanup_n'] = 35.0
        self.assertFalse(analyze(rows)['force_window_within_owner_tolerance'])

    def test_two_x_not_divided_away(self):
        rows = fixture()
        for row in rows:
            row['sum_measured_reaction_n'] = 86.8
            row['feet'][0]['measured_reaction_n'] = 86.8
        self.assertFalse(analyze(rows)['force_window_within_owner_tolerance'])

    def test_nonfinite_rejected(self):
        rows = copy.deepcopy(fixture())
        rows[500]['feet'][0]['applied_load_n'] = float('nan')
        with self.assertRaises(ValueError):
            analyze(rows)


if __name__ == '__main__':
    unittest.main(verbosity=2)
