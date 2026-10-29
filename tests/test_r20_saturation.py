#!/usr/bin/env python3
"""F63 reporter controls ONLY, no synthetic runtime qualifying loads."""
from copy import deepcopy
import unittest
from load_saturation_report import audit_drive, strength, compare, zero_gate, clamp, HZ, LIMIT, TORQUE
from load_trace_report import IDENTITY_EPS


def fixture(gain=.7,stiffness=2400.,q=.5,parent_omega=0.,child_omega=.1):
    def body(part,omega):
        return {'part':part,'inverse_mass_a':2.,'inverse_mass_b':2.,
            'start_ax':0.,'start_ay':0.,'start_bx':1.,'start_by':0.,
            'start_avx':0.,'start_avy':-omega/2,'start_bvx':0.,'start_bvy':omega/2,
            'ax':0.,'ay':0.,'bx':1.,'by':0.,'avx':0.,'avy':-omega/2,'bvx':0.,'bvy':omega/2}
    omega=child_omega-parent_omega;spring=-stiffness*q;damping=-55.*omega
    torque=clamp(spring+damping,-TORQUE*gain,TORQUE*gain);requested=torque/HZ
    minimum=max((parent_omega-LIMIT)/4,(-LIMIT-child_omega)/4)
    maximum=min((parent_omega+LIMIT)/4,(LIMIT-child_omega)/4)
    bound=6./8;applied=clamp(requested,-bound,bound)
    if minimum<=maximum:applied=clamp(clamp(applied,minimum,maximum),-bound,bound)
    event={'kind':'motor','parent_part':0,'child_part':1,'parent_inverse_inertia':4.,'child_inverse_inertia':4.,
        'parent_omega':parent_omega,'child_omega':child_omega,'omega':omega,'q':q,'target':0.,
        'spring_torque':spring,'damping_torque':damping,'torque':torque,'impulse_before':0.,
        'requested_impulse':requested,'impulse_bound':bound,'impulse':applied,'impulse_after':applied,
        'relative_speed_change':applied*8,'tick_net_relative_speed_change':applied*8,
        'speed_minimum_impulse':minimum,'speed_maximum_impulse':maximum}
    return {'tick':0,'feet':[],'other_bodies':[body(0,parent_omega),body(1,child_omega)],
        'diagnostic_angular_impulse_limit_rad_s':6.,'motor_gain':gain,'diagnostic_motor_stiffness':stiffness,
        'drive_events':[event]}


class SaturationControls(unittest.TestCase):
    def test_requested_vs_applied_shows_two_saturating_terms_are_not_falsification(self):
        live=fixture();zero_stiff=fixture(stiffness=0.,child_omega=10.)
        a=audit_drive(live);b=audit_drive(zero_stiff)
        self.assertNotEqual(a['requested'],b['requested']);self.assertEqual(a['applied'],b['applied'])
        self.assertTrue(a['saturated'] and b['saturated'])
    def test_true_gain_zero_is_measured_not_inferred_from_stiffness(self):
        r=fixture(gain=0.);a=audit_drive(r)
        self.assertEqual(a['requested'],0.);self.assertEqual(a['applied'],0.);self.assertFalse(a['saturated'])
        s=strength([r]*300);self.assertEqual(s['saturated_ticks'],0)
    def test_body_speed_clamp_independent_of_constraint_bound(self):
        r=fixture(parent_omega=24.,child_omega=0.,q=1.)
        a=audit_drive(r);self.assertTrue(a['body_speed_limited']);self.assertEqual(a['applied'],0.)
    def test_zero_request_can_still_trigger_absolute_speed_repair_is_not_hidden(self):
        r=fixture(gain=0.,parent_omega=25.,child_omega=0.)
        a=audit_drive(r);self.assertEqual(a['requested'],0.);self.assertNotEqual(a['applied'],0.)
        s=strength([r]*300)
        g=zero_gate({'strength':s,'drift_px_s':0.})
        self.assertFalse(g['zero_drive_verified_at_existing_ledger_precision'])
    def test_forged_requested_bound_applied_and_inertia_rejected(self):
        for k in ('requested_impulse','impulse_bound','impulse','parent_inverse_inertia','speed_minimum_impulse','impulse_before'):
            r=fixture();r['drive_events'][0][k]+=.01
            with self.assertRaises(ValueError):audit_drive(r)
    def test_actual_extent_not_authored_length_controls_inertia_audit(self):
        r=fixture();r['other_bodies'][0]['start_bx']=2.
        with self.assertRaises(ValueError):audit_drive(r)
    def test_teeth_include_each_tick_not_just_equal_means(self):
        a=[deepcopy(fixture()) for _ in range(300)];b=deepcopy(a)
        for i in range(300):
            a[i]['tick']=b[i]['tick']=i
            b[i]['drive_events'][0]['impulse']+=.01 if i%2 else -.01
            b[i]['other_bodies'][0]['ax']+=.02
        c=compare(a,b)
        self.assertEqual(c['last300_applied_changed_above_existing_ledger_precision_ticks'],300)
        self.assertEqual(len(c['per_tick']),300)
        self.assertEqual(c['all_applied_changed_above_existing_ledger_precision_ticks'],300)
        self.assertEqual(c['first_applied_changed_above_existing_ledger_precision_tick'],0)
        self.assertEqual(c['last300_max_abs_endpoint_position_delta_wu'],.02)
    def test_gain_zero_no_collapse_stops_before_bound_and_A(self):
        s=strength([fixture(gain=0.)]*300)
        self.assertFalse(zero_gate({'strength':s,'drift_px_s':3.93})['continue_to_bound_sweep'])
        self.assertTrue(zero_gate({'strength':s,'drift_px_s':0.})['continue_to_bound_sweep'])
    def test_audit_does_not_mutate_physics(self):
        r=fixture();before=deepcopy(r);audit_drive(r);self.assertEqual(r,before)

if __name__=='__main__':unittest.main(verbosity=2)
