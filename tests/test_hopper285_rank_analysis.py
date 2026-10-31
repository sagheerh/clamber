"""Immutable failure arithmetic, not a simulator or new attempt."""
import subprocess
import sys
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class Hopper285RankAnalysis(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = subprocess.check_output(
            [sys.executable, 'tests/hopper285_rank_analysis.py'], cwd=ROOT, text=True)

    def test_same_archived_phase_and_rollback(self):
        self.assertIn('"failure_phase": "velocity_pass_0"', self.text)
        self.assertIn('"rollback_state_equal": true', self.text)

    def test_first_normal_solve_not_the_failure(self):
        self.assertIn('ACTIVE [0, 1, 2] lambda [0.6678486891995792', self.text)

    def test_both_old_pivot_orders_reach_singular_supermatrix(self):
        self.assertEqual(self.text.count('RANKFAIL [0, 1, 2, 3]'), 2)

    def test_exact_same_input_proves_false_negative_float_predicate(self):
        self.assertIn('gaps [1.6653345369377348e-16, 1.1102230246251565e-16, 1.6653345369377348e-16, -2.609024107869118e-15]', self.text)
        self.assertIn('gaps [0.0, 0.0, 0.0, 9.595487526228043e-17]', self.text)
        self.assertIn('EXACT SINGULAR [0, 1, 2, 3]', self.text)

    def test_nonzero_restitution_not_waived(self):
        self.assertIn('TARGETS [1.006139616066548e-18,', self.text)


if __name__ == '__main__':
    unittest.main()
