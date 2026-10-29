#!/usr/bin/env python3
"""Static/forgery controls, NOT numerical runtime/feel acceptance evidence."""
import hashlib,json,math,sys,tempfile,unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))
from check_m1_matrix import validate_matrix,R27_VERDICTS
from r27_report import PLAN,angle_degrees,completed,com,aggregate


class R27Controls(unittest.TestCase):
    def test_pb_bytes_not_changed(self):
        self.assertEqual(hashlib.sha256(Path('core/tuning.tres').read_bytes()).hexdigest(),PLAN['production_tuning_sha256'])
    def test_original_gdd_preserved_and_sleep_named_failed(self):
        self.assertIn('| AC-201 | With no input, a creature settles and sleeps within 4 s | Trace test | P0 |',Path('docs/GDD.md').read_text())
        s=Path('.review/m1_ac_matrix.md').read_text()
        for code in ('AC-201a','AC-201b','AC-201s'):self.assertIn('| '+code+' |',s)
        self.assertIn('FAILED (M1.1 carry-over)',s)
    def test_exact_policy_upgrade_not_blanket_fa_permission(self):
        text=Path('.review/m1_ac_matrix.md').read_text()
        self.assertEqual(validate_matrix(text),[])
        for gate,(status,reference) in R27_VERDICTS.items():
            wrong=text.replace(reference,reference.replace('40904855466','40631790078'))
            self.assertTrue(validate_matrix(wrong))
        self.assertTrue(validate_matrix(text.replace('NOT RUN | Actual success_count unknown','PASS (measured policy coverage) | Actual success_count unknown')))
    def test_one_pass_moved_outside_contact_loop(self):
        s=Path('core/sim/coupled_load_probe.gd').read_text()
        predict=s.split('func _predict_and_project',1)[1].split('func _velocity_contacts',1)[0]
        self.assertNotIn('diagnostic_final_distance_pass',predict)
        contact=s.split('func _velocity_contacts',1)[1].split('func _rigid_velocity',1)[0]
        self.assertEqual(contact.count('if diagnostic_final_distance_pass:'),1)
        self.assertGreater(contact.index('\n\tif diagnostic_final_distance_pass:'),contact.index('_record_length_phase("after_contact_pass_'))
        tail=contact.split('if diagnostic_final_distance_pass:',1)[1]
        self.assertEqual(tail.count('link.project(_tuning)'),1)
        self.assertNotIn('reset_multiplier',tail)
        self.assertNotIn('range(',tail)
    def test_preregistered_horizon_and_scope(self):
        self.assertEqual(PLAN['ac201']['ticks'],600)
        self.assertEqual(PLAN['ac201']['attitude_degrees_max'],15)
        self.assertEqual(PLAN['ac201']['body_length_wu'],.90)
        self.assertEqual(PLAN['ac202']['ticks'],7200)
        self.assertFalse(PLAN['ac202']['default_enabled'])
        self.assertEqual(PLAN['soak']['runs'],200)
        self.assertEqual(PLAN['soak']['ticks_per_run'],7200)
        self.assertEqual(PLAN['soak']['batches']*PLAN['soak']['runs_per_batch'],200)
    def test_vector_angle_not_endpoint_only(self):
        self.assertAlmostEqual(angle_degrees([0.,-1.],[1.,0.]),90.)
        theta=15*math.pi/180
        self.assertAlmostEqual(angle_degrees([1.,0.],[math.cos(theta),math.sin(theta)]),15.)
    def test_actual_com_mass_weighted(self):
        parts=[dict(mass=1.,a=dict(x=0.,y=0.),b=dict(x=0.,y=0.)),dict(mass=3.,a=dict(x=2.,y=0.),b=dict(x=2.,y=0.))]
        self.assertEqual(com(parts),[1.5,0.])
    def test_failure_or_edited_target_cannot_pass(self):
        end=dict(target_ticks=7200,ticks=7200,status=0,failing_tick=None,termination_reason='completed')
        self.assertTrue(completed(end,7200,7200))
        self.assertFalse(completed(dict(end,status=30),7200,7200))
        self.assertFalse(completed(dict(end,failing_tick=7067,ticks=7067,termination_reason='step_failure'),7200,7067))
        with self.assertRaises(ValueError):completed(dict(end,target_ticks=600),7200,600)
    def test_soak_cannot_hide_missing_batches(self):
        with tempfile.TemporaryDirectory() as d:
            with self.assertRaises(ValueError):aggregate(Path(d))


if __name__=='__main__':unittest.main(verbosity=2)
