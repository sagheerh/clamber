import unittest
from candidate_runtime_archive_analysis import audit, SOURCE


class CandidateRuntimeArchiveAnalysis(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.report = audit()

    def test_pinned_complete_native_matrix(self):
        self.assertEqual(self.report["source_commit"], SOURCE)
        self.assertEqual(self.report["native_checks"], 207)
        self.assertEqual(self.report["native_awake_audits"], 66)

    def test_independent_actual_linear_and_contact_impulses(self):
        r = self.report["max_absolute_residuals"]
        self.assertLess(r["linear_tick_ns"], 1e-12)
        self.assertLess(r["contact_linear_ns"], 1e-12)

    def test_actual_pose_angular_and_material_equations(self):
        r = self.report["max_absolute_residuals"]
        self.assertLess(r["contact_angular_ns_wu"], 1e-12)
        self.assertLess(r["angular_material_ns_wu"], 1e-12)

    def test_positive_clamp_all_three_not_a_zero_budget_fake(self):
        self.assertEqual(self.report["saved_positive_clamp_samples"], 3)
        r = self.report["max_absolute_residuals"]
        self.assertLess(r["positive_clamp_ns"], 1e-12)
        self.assertEqual(r["positive_clamp_velocity_wu_s"], 0.0)

    def test_no_fake_full_capture_or_gameplay_clamp_claim(self):
        self.assertEqual(self.report["saved_first_awake_samples"], 3)
        self.assertLess(self.report["saved_first_awake_samples"], self.report["native_awake_audits"])
        self.assertIn("not a gameplay/integration run", " ".join(self.report["limitations"]))

    def test_no_fa3_credit_from_vacuous_grip(self):
        self.assertEqual(self.report["sampled_grip_eligible_observations"], 0)
        self.assertIn("No FA3", " ".join(self.report["limitations"]))
        self.assertIn("ZERO new ticks", self.report["scope"])


if __name__ == "__main__":
    unittest.main()
