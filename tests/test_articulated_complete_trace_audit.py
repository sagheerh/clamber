import unittest

from articulated_complete_trace_audit import audit


class CompleteTraceAudit(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.report = audit()

    def test_exact_full_horizon_without_solver_failure(self):
        self.assertEqual(self.report["tick_count"], 600)
        self.assertTrue(self.report["all_solver_status_ok"])

    def test_first_posture_failure_not_fixed(self):
        self.assertEqual(self.report["first_final_violation"], 14)
        self.assertEqual(self.report["first_integration_violation"], 14)

    def test_rest_not_fixed(self):
        self.assertFalse(self.report["any_sleep"])
        self.assertEqual(self.report["max_still_ticks"], 14)

    def test_original_stop_blocks_every_long_arm(self):
        self.assertEqual(self.report["summary"]["not_run_arms"],
                         ["length-Slug", "length-Hopper", "length-TwinRoller"])
        self.assertIn("NOT ADOPTED", self.report["summary"]["status"])

    def test_native_joint_bounds_reopen_late_not_first_posture_cause(self):
        self.assertEqual(self.report["first_native_angular_limit_violation"], 46)
        self.assertEqual(self.report["native_angular_limit_violation_ticks"], 554)
        self.assertGreater(self.report["max_native_upper_excess_rad"], 0.06)
        self.assertGreater(self.report["first_native_angular_limit_violation"],
                           self.report["first_final_violation"])

    def test_last_angular_pass_corrected_then_later_operations_reopened(self):
        sample = next(r for r in self.report["samples"] if r["tick"] == 100)
        # Offline reconstruction check only: NEVER a runtime solver tolerance.
        self.assertLess(abs(sample["last_angular_q_reconstructed_rad"] - sample["upper_rad"]), 1e-12)
        self.assertGreater(sample["final_q_native_rad"] - sample["upper_rad"], 0.05)

    def test_late_foot_load_does_not_qualify_grip(self):
        samples = [r for r in self.report["samples"] if r["tick"] >= 60]
        self.assertTrue(all(not r["gripping"] and r["foot_applied_n"] < 17.36 for r in samples))

    def test_quiet_velocity_does_not_erase_recorded_position_creep(self):
        sample = next(r for r in self.report["samples"] if r["tick"] == 100)
        # Offline evidence comparisons, NOT runtime rest/velocity allowances.
        self.assertLess(abs(sample["foot_b_final_vx"]), 1e-15)
        self.assertGreater(sample["foot_b_step_dx"], 5e-5)
        self.assertGreater(sample["foot_b_phase_dx"]["contact"], 0.004)
        self.assertLess(sample["foot_b_phase_dx"]["hinge"], -0.004)
        self.assertLess(abs(sum(sample["foot_b_phase_dx"].values()) - sample["foot_b_step_dx"]), 1e-12)

    def test_full600_not_production_ac202_or_acceptance(self):
        arm = self.report["summary"]["arms"]["idle-Slug"]
        self.assertAlmostEqual(arm["max_attitude_deg"], 51.5092822123154)
        self.assertFalse(arm["sleep_by_original_4s"])
        self.assertNotIn("length-Slug", self.report["summary"]["arms"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
