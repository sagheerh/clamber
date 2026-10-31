import unittest
from articulated_v9_phase_audit import audit, SOURCE
class Audit(unittest.TestCase):
 @classmethod
 def setUpClass(cls):cls.a=audit()
 def test_source(self):self.assertEqual(self.a['source'],SOURCE)
 def test_complete(self):self.assertEqual(self.a['ticks'],600)
 def test_phase(self):
  r=self.a['first_posture_failure'];self.assertEqual(r['tick'],26);self.assertLess(r['integration_deg'],15);self.assertGreater(r['final_deg'],15)
 def test_full_reconstruction(self):self.assertLess(self.a['max_position_reconstruction_residual_wu'],1e-12)
 def test_authored_fraction(self):self.assertLess(self.a['max_drag_rate_arithmetic_residual'],1e-12)
 def test_energy(self):self.assertEqual(self.a['drag_total_energy_increases'],0)
 def test_no_rest_claim(self):self.assertEqual(self.a['max_still_ticks'],4)
if __name__=='__main__':unittest.main(verbosity=2)
