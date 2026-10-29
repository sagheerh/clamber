#!/usr/bin/env python3
"""Reporter-only controls. Synthetic fixtures do not qualify runtime loads."""
from copy import deepcopy
import unittest
from test_r18_external import fixture
from load_external_report import external_identity, r19_complete_prerequisite
from load_motor_report import thrust_summary, sweep_gate, OWNER_THRUST_LIMIT
from load_trace_report import IDENTITY_EPS


def rows(speed=.02):
    r=fixture(speed)
    for tick in r:
        tick['other_bodies'][0]['mass']=1.
        for end in ('a','b'):
            tick['other_bodies'][0]['start_'+end+'x']=0.
            tick['other_bodies'][0][end+'x']=speed/60
    return r


class R19Controls(unittest.TestCase):
    def test_complete_authorization_never_overwrites_literal_failure(self):
        i=external_identity(rows());before=deepcopy(i)
        self.assertTrue(r19_complete_prerequisite(i)['complete_external_prerequisite_passed'])
        self.assertFalse(i['remedy_authorized_by_requested_gate'])
        self.assertFalse(i['F56_literal_vector_passed']);self.assertEqual(i,before)
    def test_authorized_form_still_aborts_internal_and_forged_damping(self):
        for key in ('internal_impulse_x_ns','drive_internal_impulse_x_ns','damping_impulse_x_ns'):
            r=rows();r[3]['momentum_budget'][key]+=.001
            with self.assertRaises(ValueError):r19_complete_prerequisite(external_identity(r))
    def test_signed_thrust_terminal_identity_not_absolute_contact_sum(self):
        r=rows()
        for tick in r:
            tick['contact_samples'] += [dict(tick['contact_samples'][0],tangential_impulse_ns=.1),
                                       dict(tick['contact_samples'][0],tangential_impulse_ns=-.1)]
        s=thrust_summary(r)
        self.assertAlmostEqual(s['rectified_friction_impulse_per_tick'],.0004)
        self.assertLess(abs(s['prediction_minus_completed_vx_wu_s']),IDENTITY_EPS)
        self.assertAlmostEqual(s['mean_completed_vx_px_s'],3.)
    def test_mass_forgery_and_nonzero_horizontal_normals_rejected(self):
        r=rows();r[1]['other_bodies'][0]['mass']=2.
        with self.assertRaisesRegex(ValueError,'Mass'):thrust_summary(r)
        r=rows();r[1]['contact_samples'][0]['normal_impulse_ns']=.01
        r[1]['contact_samples'][0]['nx']=1.
        with self.assertRaises(ValueError):thrust_summary(r)
    def test_no_collapse_stops_and_owner_boundary_not_widened(self):
        live={'rectified_friction_impulse_per_tick':.0008297,'drift_px_s':3.93}
        for thrust,expected in [(OWNER_THRUST_LIMIT,True),(OWNER_THRUST_LIMIT+1e-15,False),(.0008297,False),(-.0008297,False)]:
            z={'rectified_friction_impulse_per_tick':thrust,'drift_px_s':.084}
            self.assertEqual(sweep_gate(live,z)['continuation_authorized'],expected)
    def test_reporting_does_not_mutate_raw_trace(self):
        r=rows();before=deepcopy(r);thrust_summary(r);self.assertEqual(r,before)

if __name__=='__main__':unittest.main(verbosity=2)
