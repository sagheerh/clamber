#!/usr/bin/env python3
"""Reporter-only negative controls, not synthetic runtime qualifying loads."""
from copy import deepcopy
import math
import unittest
from load_limit_report import audit_limits, limit_summary, turned, relative_q, predictions, LOWER, DEGREE_RADIANS
from load_motor_report import resource


def fixture(upper_deg=40.):
    p=[0.,0.,1.,0.];c=[0.,0.,math.cos(1.),math.sin(1.)]
    upper=upper_deg*DEGREE_RADIANS;error=1.-min(1.,upper)
    pa=turned(p,error/2) if error else list(p)
    ca=turned(c,-error/2) if error else list(c)
    def body(part,before,after):
        b={'part':part,'inverse_mass_a':2.,'inverse_mass_b':2.,
           'position_delta_wu':{'angular':[b-a for a,b in zip(before,after)]}}
        b.update({'start_'+k:v for k,v in zip(('ax','ay','bx','by'),before)})
        return b
    projection={'joint':0,'sequence':0,'parent_part':0,'child_part':1,'q_rad':1.,
        'lower_rad':LOWER,'upper_rad':upper,'error_rad':error,
        'parent_before':p,'child_before':c,'parent_after':pa,'child_after':ca}
    q=relative_q(pa,ca,0.)
    velocity=[{'joint':0,'sequence':i,'parent_part':0,'child_part':1,'q_rad':q,'omega_rad_s':0.,
        'lower_rad':LOWER,'upper_rad':upper,'engaged':False,'impulse_before':0.,'impulse_after':0.,'impulse':0.,
        'parent_positions':pa,'child_positions':ca,'parent_velocities':[0.]*4,'child_velocities':[0.]*4}
        for i in range(int(resource('physics_velocity_passes')))]
    return {'feet':[],'other_bodies':[body(0,p,pa),body(1,c,ca)],'angular_position_events':[projection],
        'angular_limit_events':velocity,'angular_joints':[{'rest_angle':0.,'lower':LOWER,'upper':upper}],
        'diagnostic_position_iterations':1,'diagnostic_motor_limit_max_deg':upper_deg,'drive_events':[{'q':1.}]}


class LimitControls(unittest.TestCase):
    def test_projection_and_phase_units_are_separate_and_match_endpoints(self):
        a=audit_limits(fixture())
        self.assertTrue(a['engaged']);self.assertAlmostEqual(a['requested_abs_rotation_rad'],1.-40*DEGREE_RADIANS)
        self.assertAlmostEqual(a['observed_abs_rotation_rad'],a['requested_abs_rotation_rad'])
        self.assertNotAlmostEqual(a['angular_phase_net_l1_wu'],a['requested_abs_rotation_rad'])
    def test_wide_zero_error_means_exactly_no_projection(self):
        s=limit_summary([fixture(90.)]*300)
        self.assertEqual(s['limit_engaged_ticks'],0)
        for k in ('requested_abs_projection_rad_sum','angular_phase_net_l1_wu_sum','angular_projection_path_l1_wu_sum'):
            self.assertEqual(s[k],0.)
        self.assertTrue(s['limit_block_exact_zero_all6000'])
    def test_forged_error_phase_points_or_missing_iteration_rejected(self):
        for mode in ('error','phase','points','missing'):
            r=fixture()
            if mode=='error':r['angular_position_events'][0]['error_rad']=0.
            if mode=='phase':r['other_bodies'][0]['position_delta_wu']['angular'][0]+=.01
            if mode=='points':r['angular_position_events'][0]['child_after'][0]+=.01
            if mode=='missing':r['angular_position_events']=[]
            with self.assertRaises(ValueError):audit_limits(r)
    def test_velocity_engagement_is_not_inferred_from_nonzero_impulse(self):
        r=fixture();e=r['angular_limit_events'][0];p=e['child_positions'];x=p[2]-p[0];y=p[3]-p[1]
        e['omega_rad_s']=.5;e['q_rad']=40*DEGREE_RADIANS;e['engaged']=True
        e['child_velocities']=[.25*y,-.25*x,-.25*y,.25*x]
        a=audit_limits(r);self.assertTrue(a['velocity_engaged']);self.assertFalse(a['nonzero_block'])
        e['engaged']=False
        with self.assertRaises(ValueError):audit_limits(r)
    def test_forged_drive_q_and_limit_band_rejected(self):
        for mode in ('q','band'):
            r=fixture()
            if mode=='q':r['drive_events'][0]['q']+=.1
            else:r['angular_joints'][0]['upper']+=.1
            with self.assertRaises(ValueError):audit_limits(r)
    def test_zero_error_projection_cannot_hide_motion(self):
        r=fixture(90.);r['angular_position_events'][0]['parent_after'][0]+=.001
        with self.assertRaisesRegex(ValueError,'Zero-error'):audit_limits(r)
    def test_wrong_prediction_does_not_get_a_fitted_story(self):
        def arms(removed,drift,weak):
            limits={'limit_engaged_ticks':0 if removed else 300,
                    'requested_abs_projection_rad_sum':0. if removed else 3.,'limit_block_exact_zero_last300':removed}
            return {'reference':{'drift_px_s':3.9345},'wide90':{'drift_px_s':drift,'limits':limits},'bound1':{'drift_px_s':weak}}
        a=predictions(arms(True,3.9,2.));self.assertTrue(a['F64_necessary_stop_cause_falsified'])
        self.assertTrue(a['bound_drift_fell_sign_prediction_inverted'])
        self.assertFalse(predictions(arms(False,.2,4.))['wide_limit_removed_last300'])
        self.assertTrue(predictions(arms(True,.2,4.))['bound_brake_ordering'])
        self.assertFalse(predictions(arms(True,.02,4.))['F64_necessary_stop_cause_falsified'])
    def test_default_stop_remains40_and_audit_never_mutates_data(self):
        self.assertEqual(resource('motors_limit_max_deg'),40.)
        r=fixture();before=deepcopy(r);audit_limits(r);self.assertEqual(r,before)

if __name__=='__main__':unittest.main(verbosity=2)
