#!/usr/bin/env python3
"""R16 F49/F50 summary falsification, NOT physical evidence."""
from copy import deepcopy
import unittest
from test_load_trace import fixture
from load_phase_report import phase_magnitudes
from load_legal_report import accepted_view, validate_spawn
from load_long_report import spawn_comparison


def phase_fixture():
    r=fixture()[:1]
    for b in r[0]['feet']+r[0]['other_bodies']:
        b['position_delta_wu'].update(angular=[.03,0.,0.,0.],self_contact=[.04,0.,0.,0.],hinge=[-.07,0.,0.,0.])
    r[0].update(diagnostic_actuated=True,drive_events=[{'impulse':1.}],
        angular_joints=[{'impulse':0.}],angular_limit_events=[{'joint':0,'impulse':-1.}],
        self_contact_events=[{'first':0,'second':1,'x':2.,'y':0.},{'first':0,'second':1,'x':-2.,'y':0.}],
        self_impulses_ns=[{'x':0.,'y':0.} for _ in range(3)])
    return r


class PhaseSpawnControls(unittest.TestCase):
    def test_raw_magnitudes_survive_cancelling_folded_hinge(self):
        r=phase_fixture();before=deepcopy(r)
        m=phase_magnitudes(r);a=accepted_view(r)
        self.assertEqual(m['angular']['max_abs_position_delta_wu'],.03)
        self.assertEqual(m['self_contact']['max_abs_position_delta_wu'],.04)
        self.assertAlmostEqual(a[0]['feet'][0]['position_delta_wu']['hinge'][0],0.)
        self.assertEqual(m['angular']['max_abs_impulse'],1.)
        self.assertEqual(m['angular']['max_abs_tick_net_impulse'],0.)
        self.assertEqual(m['self_contact']['max_impulse_magnitude'],2.)
        self.assertEqual(m['self_contact']['max_body_net_impulse_magnitude'],0.)
        self.assertEqual(r,before)

    def test_forged_impulse_sums_rejected(self):
        r=phase_fixture();r[0]['angular_joints'][0]['impulse']=.1
        with self.assertRaises(ValueError):phase_magnitudes(r)
        r=phase_fixture();r[0]['self_impulses_ns'][0]['x']=.1
        with self.assertRaises(ValueError):phase_magnitudes(r)

    def test_absent_or_nonfinite_telemetry_not_reported_as_zero(self):
        r=phase_fixture();del r[0]['self_contact_events']
        with self.assertRaises(KeyError):phase_magnitudes(r)
        r=phase_fixture();r[0]['drive_events'][0]['impulse']=float('nan')
        with self.assertRaises(ValueError):phase_magnitudes(r)

    def test_raised_clearance_rederived_from_raw_capsules_not_root_claim(self):
        rows=fixture()[:1];bs=rows[0]['feet']+rows[0]['other_bodies']
        lowest=min(min(b['start_ay'],b['start_by'])-b['radius_wu'] for b in bs)
        root=next(b for b in bs if b['part']==0)['start_ay']
        for b in bs:
            b['start_ay']+=.21-lowest;b['start_by']+=.21-lowest
        rows[0].update(diagnostic_spawn_y_wu=root+.21-lowest,diagnostic_authored_bottom_wu=lowest-root,diagnostic_lowest_initial_surface_wu=.21)
        validate_spawn(rows,clearance=.21)
        with self.assertRaises(ValueError):validate_spawn(rows)
        rows[0]['feet'][0]['start_by']-=1.
        with self.assertRaises(ValueError):validate_spawn(rows,clearance=.21)

    def test_spawn_comparison_defers_nonsettled_means(self):
        def case(value):
            return {'status':'OBSERVED','spawn_root_y_wu':value,'zero_input_drift':{
                'mean_com_dx_wu_tick':value,'convergence':{'settled':False,'last300_vx_range_wu_s':[0.,1.]}}}
        names=['baseline-after','baseline-after-raised'];cases=dict(zip(names,[case(.61),case(.81)]))
        r=spawn_comparison(cases,dict.fromkeys(names,[]),'baseline')
        self.assertFalse(r['both_windows_settled'])
        self.assertIsNone(r['settled_difference_wu_tick'])
        self.assertFalse(r['F41_closed'])
        self.assertIn('DEFERRED',r['interpretation'])


if __name__=='__main__':unittest.main(verbosity=2)
