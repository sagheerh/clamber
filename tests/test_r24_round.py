#!/usr/bin/env python3
"""Protocol/report controls only; no synthetic qualifying loads."""
import json,math,unittest
from pathlib import Path
from load_r24_report import conditional_allowance,q_samples

class RoundControls(unittest.TestCase):
    def test_allowance_is_conditional_not_an_adopted_tolerance(self):
        self.assertAlmostEqual(conditional_allowance(.15,12.910423565431365),.15*.3/12.910423565431365)
        self.assertAlmostEqual(conditional_allowance(.015,-3),.0015)
        self.assertIsNone(conditional_allowance(.015,0.))
    def test_phase_sampling_does_not_confuse_drive_sample_with_frozen_joint(self):
        def body(part,angle):
            return {'part':part,'start_ax':0.,'start_ay':0.,'start_bx':1.,'start_by':0.,
                'position_delta_wu':{'integration':[0.,0.,math.cos(angle)-1.,math.sin(angle)]}}
        r={'feet':[],'other_bodies':[body(0,0.),body(1,.1)],'drive_events':[{'q':0.}],
            'angular_joints':[{'q':0.,'rest_angle':0.}],
            'angular_position_events':[{'q_rad':0.}], 'angular_limit_events':[{'q_rad':0.}]}
        q=q_samples(r);self.assertAlmostEqual(q[1],.1);self.assertGreater(max(q)-min(q),.09)
    def test_fixed_onset_variance_registered_before_fa6(self):
        p=json.loads(Path('data/towers/provisional_fa6.json').read_text())
        self.assertEqual(p['script']['L_onset_offsets_ticks'],list(range(0,37,4)))
        self.assertEqual(len(p['script']['L_onset_offsets_ticks']),10)
        self.assertEqual(p['script']['seed'],305419896)
        self.assertEqual(p['script']['fixed_total_ticks'],300)
    def test_exact_four_run_protocol_no_d09_repeat(self):
        s=Path('tests/run_m1_r24.sh').read_text()
        self.assertIn('for name in A-0.15 A-0.015 A-0.0015 B',s)
        self.assertEqual(s.count('--script res://tests/sim/test_coupled_load.gd'),1)
        self.assertNotIn('run_m1_d09.sh',s)
    def test_r25_only_owner_authorised_defaults_adopted(self):
        s=Path('core/tuning.tres').read_text()
        for line in ['physics_static_slip_wu_s = 0.15','motors_joint_stiffness = 10.0','physics_max_constraint_angular_impulse_rad_s = 30.0']:
            self.assertIn(line,s)

if __name__=='__main__':unittest.main(verbosity=2)
