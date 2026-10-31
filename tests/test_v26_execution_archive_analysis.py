import unittest
from v26_execution_archive_analysis import audit, SOURCE


class V26ExecutionArchiveAnalysis(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.report = audit()

    def test_real_closed_failure_no_completion_relabel(self):
        self.assertEqual(self.report['source_commit'], SOURCE)
        self.assertEqual(self.report['status'], 'CLOSEDFAIL; not adopted')
        self.assertEqual(self.report['twin'], 'NOTRUN')
        self.assertEqual(self.report['hopper_failed_tick'], 369)

    def test_all474_actual_native_prerequisites(self):
        self.assertEqual(self.report['native_execution_job_checks'], 432)
        self.assertEqual(self.report['native_prior_job_checks'], 42)

    def test_original600_not_eventual_sleep_waiver(self):
        idle = self.report['arms']['idle-Slug']
        self.assertTrue(idle['original600']['original4s_pass'])
        self.assertEqual(idle['original600']['first_sleep_tick'], 29)
        self.assertEqual((idle['live_native_awake_audits'], idle['parked_no_new_force']), (30, 570))

    def test_all_slug7200_input_geometry_and_actual_wake(self):
        slug = self.report['arms']['length-Slug']
        self.assertEqual(slug['committed_ticks'], 7200)
        self.assertEqual((slug['live_native_awake_audits'], slug['parked_no_new_force']), (7170, 30))
        self.assertEqual(slug['geometry_input_wake']['first_actual_wake_tick'], 60)

    def test_no_stale_or_failure_force_credit(self):
        self.assertEqual(self.report['native_successful_fresh_force_audits'], 7539)
        hopper = self.report['arms']['length-Hopper']
        self.assertEqual((hopper['live_native_awake_audits'], hopper['parked_no_new_force']), (339, 30))
        self.assertLess(self.report['offline_actual_linear_peak_ns'], 1e-12)

    def test_actual_failure_and_rollback_scope_not_invented(self):
        self.assertEqual(self.report['failure_phase'], 'velocity_pass_0')
        self.assertEqual(self.report['final_constitutive'], 'NOTRUN')
        self.assertTrue(self.report['rollback_snapshot_values_equal'])
        self.assertIn('not all local-torque', ' '.join(self.report['limitations']))


if __name__ == '__main__':
    unittest.main()
