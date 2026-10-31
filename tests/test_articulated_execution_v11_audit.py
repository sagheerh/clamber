import unittest
from articulated_execution_v11_audit import audit
class Closure(unittest.TestCase):
 @classmethod
 def setUpClass(cls):cls.a=audit()
 def test_full600(self):self.assertEqual((self.a['ticks'],self.a['tick_sequence']),(600,[0,599]))
 def test_finite_status(self):self.assertTrue(self.a['every_row_finite']and self.a['every_status_ok'])
 def test_phase_order(self):self.assertTrue(self.a['exact_actual_stage_order_all600'])
 def test_controller_once(self):self.assertTrue(self.a['one_original_controller_event_per_tick'])
 def test_posture_failure(self):self.assertEqual(self.a['first_posture_violation'],16);self.assertGreater(self.a['max_attitude_deg'],15)
 def test_airborne_failure(self):self.assertEqual(len(self.a['airborne_ticks']),1)
 def test_sleep_not_credited(self):self.assertFalse(self.a['any_sleep']);self.assertLess(self.a['max_still_ticks'],30)
 def test_geometry(self):self.assertEqual(self.a['penetration_violations'],0);self.assertLess(self.a['max_length_wu'],1e-12)
 def test_ledger(self):self.assertLess(self.a['max_momentum_ledger_residual_ns'],1e-12)
 def test_later_arms_blocked(self):self.assertEqual(self.a['summary']['not_run_arms'],['length-Slug','length-Hopper','length-TwinRoller'])
if __name__=='__main__':unittest.main(verbosity=2)
