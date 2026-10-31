import subprocess
import sys
import unittest
from pathlib import Path


class Hopper369RankAnalysis(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.text = subprocess.check_output([sys.executable, 'tests/hopper369_rank_analysis.py'],
                                          cwd=Path(__file__).resolve().parents[1], text=True)

    def test_actual_four_normal_matrix_is_exactly_singular(self):
        self.assertIn('singular (0, 1, 2, 3)', self.text)

    def test_existing_positive_multiplier_face_really_violates_new_contact(self):
        line = next(line for line in self.text.splitlines() if line.startswith('(0, 1, 2)'))
        self.assertIn('negative [] violated [3]', line)
        self.assertIn('-2.5042492949506632e-17', line)

    def test_independent_face_is_unique_strict_kkt_solution(self):
        passes = [line for line in self.text.splitlines() if line.endswith('PASS')]
        self.assertEqual(len(passes), 1)
        self.assertTrue(passes[0].startswith('(1, 2, 3)'))
        self.assertIn('negative [] violated []', passes[0])


if __name__ == '__main__':
    unittest.main()
