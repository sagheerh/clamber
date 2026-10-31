import unittest
from pathlib import Path
from articulated_posture_audit import audit,ROOT
class PostureAudit(unittest.TestCase):
 def setUp(self):self.r=audit()
 def test_exact_partial_horizon(self):self.assertEqual([r['tick'] for r in self.r['rows']],list(range(14)))
 def test_first_crossing_is_integration(self):self.assertEqual((self.r['first_integration_violation'],self.r['first_final_violation']),(8,8))
 def test_reconstructed_crossing(self):
  r=self.r['rows'][8];self.assertAlmostEqual(r['after_integration_deg'],18.36637192151201,places=12);self.assertAlmostEqual(r['final_deg'],18.41374748886769,places=12)
 def test_ledger_closes_unit_roundoff_only(self):self.assertLess(self.r['max_position_ledger_residual_wu'],1e-12)
 def test_no_angular_or_self_position_push_before_first_violation(self):self.assertTrue(all(not r['angular_position_changed'] and r['self_events']==0 for r in self.r['rows'][:9]))
 def test_linear_momentum_ledger(self):self.assertTrue(all(abs(r['momentum_residual_x'])<1e-12 and abs(r['momentum_residual_y'])<1e-12 for r in self.r['rows']))
 def test_grip_really_lost_before_crossing(self):self.assertTrue(self.r['rows'][5]['gripping']);self.assertFalse(self.r['rows'][6]['gripping'])
 def test_existing_angular_resource_omitted_from_original_path(self):
  for path in (ROOT/'core/sim').glob('*.gd'):self.assertNotIn('physics_angular_damping',path.read_text())
  self.assertIn('physics_angular_damping = 0.8',(ROOT/'core/tuning.tres').read_text())
if __name__=='__main__':unittest.main(verbosity=2)
