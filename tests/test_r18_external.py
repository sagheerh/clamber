#!/usr/bin/env python3
"""F56 reporter falsification fixtures ONLY, never runtime qualifying loads."""
from copy import deepcopy
import unittest
from load_external_report import external_identity
from load_trace_report import LINEAR_DAMPING, IDENTITY_EPS


def fixture(speed=.02):
    rows=[]
    for tick in range(300):
        body={'part':0,'inverse_mass_a':2.,'inverse_mass_b':2.}
        budget={}
        for axis in ('x','y'):
            v=speed if axis=='x' else 0.
            for end in ('a','b'):
                body[end+'v'+axis]=v;body['start_'+end+'v'+axis]=v
            for key in ('drive_internal_impulse','clamp_impulse','gravity_impulse','internal_impulse'):
                budget[f'{key}_{axis}_ns']=0.
            budget[f'momentum_before_{axis}_ns']=v
            budget[f'momentum_after_{axis}_ns']=v
            budget[f'damping_impulse_{axis}_ns']=-LINEAR_DAMPING*v
            budget[f'contact_velocity_impulse_{axis}_ns']=LINEAR_DAMPING*v
        rows.append({'tick':tick,'feet':[],'other_bodies':[body],'momentum_budget':budget,
                     'contact_samples':[{'nx':0.,'ny':1.,'normal_impulse_ns':0.,'tangential_impulse_ns':-LINEAR_DAMPING*speed}]})
    return rows


class ExternalIdentityControls(unittest.TestCase):
    def test_damping_balance_does_not_fake_contact_only_pass(self):
        r=external_identity(fixture())
        self.assertTrue(r['internal_rows_and_complete_ledger_verified'])
        self.assertFalse(r['remedy_authorized_by_requested_gate'])
        self.assertFalse(r['F56_literal_lateral_passed'])
        self.assertAlmostEqual(r['axes']['x']['sums']['literal_residual_from_sides'],-.12)
        self.assertEqual(r['ledger_precision_existing'],IDENTITY_EPS)
    def test_stationary_zero_impulse_positive_control(self):
        self.assertTrue(external_identity(fixture(0.))['remedy_authorized_by_requested_gate'])
    def test_forged_raw_contact_cannot_borrow_complete_ledger(self):
        r=fixture();r[10]['contact_samples'][0]['tangential_impulse_ns']*=2
        with self.assertRaisesRegex(ValueError,'contact events'):external_identity(r)
    def test_damping_cannot_be_silently_removed(self):
        r=fixture();r[10]['momentum_budget']['damping_impulse_x_ns']=0.
        with self.assertRaisesRegex(ValueError,'Damping book'):external_identity(r)
    def test_internal_leak_is_stop_not_contact_attribution(self):
        for magnitude,all_ticks in ((.001,False),(.5*IDENTITY_EPS,True)):
            r=fixture()
            for tick in (range(300) if all_ticks else [10]):
                r[tick]['momentum_budget']['internal_impulse_x_ns']=magnitude
            with self.assertRaisesRegex(ValueError,'INTERNAL'):external_identity(r)
    def test_raw_endpoint_and_book_disagreement_rejected(self):
        r=fixture();r[10]['other_bodies'][0]['avx']+=.001
        with self.assertRaisesRegex(ValueError,'raw endpoint'):external_identity(r)
    def test_missing_reordered_and_nonfinite_rejected(self):
        for mode in ('short','reordered','nonfinite'):
            r=fixture()
            if mode=='short':r.pop()
            if mode=='reordered':r[12]['tick']=14
            if mode=='nonfinite':r[12]['other_bodies'][0]['avx']=float('nan')
            with self.assertRaises(ValueError):external_identity(r)
    def test_reporting_does_not_modify_raw_evidence(self):
        r=fixture();before=deepcopy(r);external_identity(r);self.assertEqual(r,before)

if __name__=='__main__':unittest.main(verbosity=2)
