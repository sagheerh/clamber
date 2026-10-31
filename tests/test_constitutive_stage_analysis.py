"""Exact single-contact implicit energy identity. Not native/world acceptance."""
from fractions import Fraction as F
import unittest


def solve(vy, omega, r):
    # unit mass/inertia, normal at x=-1, C=(0,1/r-1)
    dv = [vy, r * omega]
    j = max(F(0), -(dv[0] - dv[1]) / (1 + r))
    return dv[0] + j, dv[1] - r * j, j


class Implicit(unittest.TestCase):
    def test_analytic(self):
        self.assertEqual(solve(F(-1), F(-1), F(1, 5)), (-F(1, 3), -F(1, 3), F(2, 3)))

    def test_actual_energy_identity(self):
        for r in [F(1, 100), F(1, 5), F(1, 2), F(1)]:
            for vy, omega in [(F(-1), F(-1)), (F(-3), F(2)), (F(1), F(-2)), (F(0), F(0))]:
                y, w, j = solve(vy, omega, r)
                change = (y*y + w*w - vy*vy - omega*omega)/2
                physical_work = j*(y-w)
                loss = (1/r-1)*w*w + ((y-vy)**2+(w-omega)**2)/2
                self.assertEqual(change, physical_work-loss)
                self.assertLessEqual(change, 0)

    def test_normal_complementarity(self):
        for vy in range(-3, 4):
            for omega in range(-3, 4):
                y, w, j = solve(F(vy), F(omega), F(1, 5))
                self.assertGreaterEqual(y-w, 0)
                self.assertGreaterEqual(j, 0)
                self.assertEqual(j*(y-w), 0)

    def test_original_zero_loss(self):
        self.assertEqual(solve(F(-1), F(-1), F(1)), (F(-1), F(-1), F(0)))

    def test_no_gravity_rebound(self):
        self.assertEqual(solve(-F(28, 60), F(0), F(1, 5))[0:2], (-F(7, 90), -F(7, 90)))

    def test_ulp_not_budgeted(self):
        before=F.from_float(1.0)**2
        after=F.from_float(1.0000000000000002)**2
        self.assertGreater(after, before)

if __name__ == '__main__':
    unittest.main(verbosity=2)
