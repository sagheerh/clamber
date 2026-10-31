"""Exact isolated support/drag composition, NOT a creature/engine/acceptance run.
Unit mass/inertia, contact at x=-1, incoming (COM_vy,omega)=(-1,-1).
This compares two time discretizations; it does NOT make either normative.
"""
from fractions import Fraction as F
import unittest


def split(r):
    # Free COM-preserving angular contraction, then original undamped mobility.
    vy,omega=F(-1),-r
    j=-(vy-omega)/2
    return vy+j,omega-j,j


def simultaneous(r):
    # Kd rotational mobility r, unchanged global translational mobility1.
    vy,omega=F(-1),-r
    j=-(vy-omega)/(1+r)
    return vy+j,omega-r*j,j


class SupportAnalysis(unittest.TestCase):
    def test_free_authored_fraction(self):
        self.assertEqual(F(1)-F(4,5),F(1,5))
    def test_split_support_restores_rotation(self):
        self.assertEqual(split(F(1,5)),(F(-3,5),F(-3,5),F(2,5)))
    def test_simultaneous_supported_solve(self):
        self.assertEqual(simultaneous(F(1,5)),(F(-1,3),F(-1,3),F(2,3)))
    def test_both_are_passive_and_support_compatible(self):
        for operator in [split,simultaneous]:
            vy,w,j=operator(F(1,5));self.assertEqual(vy-w,0);self.assertGreaterEqual(j,0)
            self.assertLessEqual((vy*vy+w*w)/2,F(1))
    def test_simultaneous_impulse_and_constitutive_ledger(self):
        vy,w,j=simultaneous(F(1,5));k=F(4)
        tau=-k*w
        self.assertEqual(vy+1,j);self.assertEqual(w+1,tau-j)
        self.assertEqual(vy+w+2,tau) # Angular momentum about contact, not COM.
    def test_full_drag_limit_distinguishes_splitting(self):
        self.assertEqual(split(F(0))[1],F(-1,2))
        self.assertEqual(simultaneous(F(0))[1],0)

if __name__=='__main__':unittest.main(verbosity=2)
