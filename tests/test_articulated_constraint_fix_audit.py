import unittest

from articulated_constraint_fix_audit import audit


class ConstraintFixAudit(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.report = audit()
        cls.results = cls.report['results']

    def test_all_three_are_complete_saved_horizons(self):
        self.assertTrue(all(r['count'] == 600 and r['every_solver_status_ok'] for r in self.results.values()))

    def test_prior_late_angular_defect_and_correction(self):
        self.assertEqual(self.results['V5']['material_upper_excess_frames'], 554)
        self.assertEqual(self.results['V7']['material_upper_excess_frames'], 0)

    def test_penetration_regression_was_not_waived(self):
        self.assertGreater(self.results['V7']['penetration_report_violation_frames'], 0)
        self.assertEqual(self.results['V8']['penetration_report_violation_frames'], 0)

    def test_final_candidate_angles_in_authored_range(self):
        self.assertEqual(self.results['V8']['max_positive_upper_excess_rad'], 0.0)
        self.assertEqual(self.results['V8']['max_positive_lower_excess_rad'], 0.0)

    def test_final_metrics_are_not_acceptance(self):
        arm = self.results['V8']['summary']['arms']['idle-Slug']
        self.assertAlmostEqual(arm['max_attitude_deg'], 36.82450412336463)
        self.assertEqual(arm['first_metric_violation_tick'], 14)
        self.assertFalse(arm['sleep_by_original_4s'])

    def test_stillness_not_invented_from_lower_penetration(self):
        self.assertEqual(self.results['V8']['max_still_ticks'], 4)
        self.assertFalse(self.results['V8']['any_sleep'])

    def test_first_early_failure_not_fixed_by_late_limit_constraint(self):
        self.assertEqual(self.report['first_state_difference_from_v5'], {'V7': 46, 'V8': 20})

    def test_original_long_arm_stop_honored_every_time(self):
        self.assertTrue(all(r['summary']['not_run_arms'] == ['length-Slug', 'length-Hopper', 'length-TwinRoller'] for r in self.results.values()))

    def test_no_fake_exact_world_hinge_claim(self):
        self.assertGreater(self.results['V8']['max_hinge_gap_wu'], 0.0)
        self.assertEqual(self.results['V8']['final_hinge_gap_wu'], 0.0)
        self.assertTrue(any('not every' in s for s in self.report['limitations']))

    def test_no_vacuous_whole_run_angular_stop_credit(self):
        self.assertTrue(any('never reaches' in s for s in self.report['limitations']))


if __name__ == '__main__':
    unittest.main(verbosity=2)
