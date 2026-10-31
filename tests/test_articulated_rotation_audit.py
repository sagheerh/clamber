import unittest

from articulated_rotation_audit import audit


class RotationAudit(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.report = audit()

    def test_saved_exact_horizon_through_first_posture_failure(self):
        self.assertEqual([r['tick'] for r in self.report['rows']], list(range(15)))

    def test_initial_com_not_over_toe(self):
        self.assertAlmostEqual(self.report['initial_com_x'], 0.2630645161290322)
        self.assertEqual(self.report['initial_toe_x'], 0.35)
        self.assertAlmostEqual(self.report['initial_gravity_torque_nm'], 3.773)

    def test_first_full_gravity_impulse(self):
        self.assertAlmostEqual(self.report['rows'][0]['gravity_angular_impulse'], 3.773 / 60)

    def test_measured_internal_motor_pair_not_net_upright_torque(self):
        self.assertTrue(all(abs(r['motor_internal_angular_impulse']) < 1e-12 for r in self.report['rows']))

    def test_rotation_ledger_closes(self):
        # Offline verification only, NEVER a solver tolerance/guard change.
        self.assertLess(self.report['max_absolute_residual'], 1e-12)

    def test_predicted_momentum_is_not_zeroed(self):
        self.assertTrue(all(r['angular_momentum_after_integration'] > 0.0 for r in self.report['rows']))

    def test_no_active_limit_self_or_clamp_explains_first_crossing(self):
        self.assertTrue(all(not r['angular_limit_engaged'] and r['self_events'] == 0 and r['clamp_x'] == 0 and r['clamp_y'] == 0 for r in self.report['rows']))

    def test_not_a_design_impossibility_or_acceptance_claim(self):
        self.assertIn('NOT acceptance', self.report['scope'])
        self.assertTrue(any('NOT proof' in s for s in self.report['limitations']))


if __name__ == '__main__':
    unittest.main(verbosity=2)
