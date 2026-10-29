#!/usr/bin/env python3
"""Protocol/forgery controls ONLY, never qualifying runtime evidence."""
import copy,math,unittest
from pathlib import Path
from load_r25_report import verify_brace


def brace_row():
    p=[0.,0.,1.,0.];zero=[0.]*4;full=[0.,-.5,0.,.5];half=[0.,-.25,0.,.25]
    events=[]
    for i in range(3):
        events.append({'parent_part':0,'child_part':1,'parent_positions':p,'child_positions':p,
            'parent_before':zero if i==0 else half,'child_before':full if i==0 else half,
            'parent_after':half,'child_after':half,'omega':1. if i==0 else 0.,'weight':8.,
            'impulse':-.125 if i==0 else 0.,'internal_x_ns':0.,'internal_y_ns':0.})
    return {'feet':[],'other_bodies':[{'part':i,'inverse_mass_a':2.,'inverse_mass_b':2.} for i in (0,1)],
        'brace_events':events,'angular_joints':[{'brace_active':True,'brace_q':0.,'rest_angle':0.}],
        'drive_events':[],'angular_limit_events':[],'angular_position_events':[]}


class AdoptionControls(unittest.TestCase):
    def test_equal_opposite_couple_and_bilateral_formula(self):verify_brace(brace_row())
    def test_fake_hold_impulse_or_momentum_leak_rejected(self):
        for key in ('impulse','internal_x_ns','internal_y_ns','omega','weight'):
            r=brace_row();r['brace_events'][0][key]+=.01
            with self.assertRaises(AssertionError):verify_brace(r)
    def test_world_pin_or_zeroing_not_a_valid_internal_couple(self):
        for k in ('parent_after','child_after'):
            r=brace_row();r['brace_events'][0][k]=[0.]*4
            with self.assertRaises(AssertionError):verify_brace(r)
    def test_missing_velocity_pass_cannot_pass(self):
        r=brace_row();r['brace_events'].pop()
        with self.assertRaises(AssertionError):verify_brace(r)
    def test_no_strength_knob_or_world_anchor_in_hold(self):
        s=Path('core/sim/angular_joint.gd').read_text().split('func hold_velocity()',1)[1].split('func snapshot()',1)[0]
        self.assertIn('-value.omega / value.weight',s)
        self.assertNotIn('apply_impulse(',s)
        self.assertNotIn('clampf(',s)
        self.assertNotIn('stiffness',s)
        self.assertNotIn('velocity_x =',s)
    def test_old_resource_only_four_approved_changes(self):
        import subprocess
        current=Path('core/tuning.tres').read_text()
        old=subprocess.check_output(['git','show','fc33aaa:core/tuning.tres'],text=True)
        changes={'physics_max_constraint_angular_impulse_rad_s':('6.0','30.0'),
            'motors_joint_stiffness':('2400.0','10.0'),'motors_joint_damping':('55.0','0.5443327361211717'),
            'motors_max_torque':('1800.0','12.0')}
        for key,(before,after) in changes.items():old=old.replace(f'{key} = {before}',f'{key} = {after}')
        self.assertEqual(old,current)
    def test_brace_state_validation_is_explicit(self):
        s=Path('core/sim/angular_joint.gd').read_text()
        for code in ['data.get("brace_active") is bool','is_finite(float(data.brace_q))','absf(data.brace_q) <= PI']:
            self.assertIn(code,s)
    def test_parallel_jobs_not_conditioned_on_brace_success(self):
        s=Path('.github/workflows/m1.yml').read_text().split('  r25-independent:',1)[1].split('  r25-baseline:',1)[0]
        self.assertNotIn('needs:',s);self.assertIn('fail-fast: false',s)
        self.assertIn('mode: [ac202, fa5]',s)

if __name__=='__main__':unittest.main(verbosity=2)
