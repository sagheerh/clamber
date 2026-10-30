#!/usr/bin/env python3
"""Reporter/protocol controls, never synthetic runtime qualifying evidence."""
from pathlib import Path
import unittest
from load_inert_report import validate_parameters,inert_premise,resource


def parameters():
    r={'motor_gain':0.,'diagnostic_motor_limit_max_deg':90.,'diagnostic_pose':'after','diagnostic_spawn_lift_wu':0.}
    for key,name in [('motor_limit_min_deg','motors_limit_min_deg'),
        ('angular_impulse_limit_rad_s','physics_max_constraint_angular_impulse_rad_s'),
        ('motor_stiffness','motors_joint_stiffness'),('motor_damping','motors_joint_damping'),
        ('passive_stiffness','physics_passive_stiffness'),('static_slip_wu_s','physics_static_slip_wu_s'),
        ('linear_damping','physics_linear_damping')]:r['diagnostic_'+key]=resource(name)
    return r


class InertControls(unittest.TestCase):
    def test_only_missing_cell_authorized(self):
        r=parameters();validate_parameters([r])
        for key in r:
            forged=dict(r);forged[key]='forged'
            with self.assertRaises(ValueError):validate_parameters([forged])
    def test_no_band_or_drive_setting_substitutes_for_measured_inertness(self):
        drive={'all6000_requested_exact_zero':True,'all6000_applied_exact_zero':True}
        limit={'all6000_limit_engaged_ticks':0,'limit_block_exact_zero_all6000':True}
        self.assertTrue(inert_premise(drive,limit))
        for key in drive:
            forged=dict(drive);forged[key]=False;self.assertFalse(inert_premise(forged,limit))
        for key,val in [('all6000_limit_engaged_ticks',1),('limit_block_exact_zero_all6000',False)]:
            forged=dict(limit);forged[key]=val;self.assertFalse(inert_premise(drive,forged))
    def test_one_runtime_call_and_no_sweep_runner(self):
        s=Path('tests/run_m1_inert.sh').read_text()
        self.assertEqual(s.count('--script res://tests/sim/test_coupled_load.gd'),1)
        self.assertIn('--motor-gain-zero --motor-stop-wide',s)
        self.assertNotIn('run_arm',s);self.assertNotIn('--angular-bound-one',s)
    def test_committed40_stays40(self):
        self.assertEqual(resource('motors_limit_max_deg'),40.)
        self.assertEqual(resource('physics_max_constraint_angular_impulse_rad_s'),30.) # R25 approved adoption; band40 unchanged

if __name__=='__main__':unittest.main(verbosity=2)
