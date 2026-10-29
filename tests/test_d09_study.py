#!/usr/bin/env python3
"""Reporter controls, never synthetic qualifying loads or adopted tuning."""
import json,math,unittest
from pathlib import Path
from load_d09_report import proposal,CANDIDATES,damping_from_weight,f52_eligibility
from load_saturation_report import audit_drive
from test_r20_saturation import fixture

class StudyControls(unittest.TestCase):
    def test_three_registered_proposals_and_same_bound_ceiling(self):
        triples=[tuple(proposal(n).values()) for n in CANDIDATES]
        self.assertEqual(len(set(triples)),3)
        self.assertTrue(all(proposal(n)['physics_max_constraint_angular_impulse_rad_s']==30. for n in CANDIDATES))
        with self.assertRaises(ValueError):proposal('unknown')
    def test_critical_damping_formula_and_invalid_inputs(self):
        self.assertAlmostEqual(damping_from_weight(40,135),2*math.sqrt(40/135))
        self.assertAlmostEqual(damping_from_weight(40,135)/damping_from_weight(10,135),2)
        for k,w in [(0,1),(1,0),(-1,1),(math.inf,1)]:
            with self.assertRaises(ValueError):damping_from_weight(k,w)
    def test_old_audit_stays_strict_and_candidate_requires_measured_coefficients(self):
        r=fixture();audit_drive(r,motor_damping=55.,max_torque=1800.)
        with self.assertRaises(ValueError):audit_drive(r,motor_damping=1.,max_torque=12.)
    def test_f52_keeps_net_dwell_not_mean_drift(self):
        def rows(dx):
            out=[]
            for t in range(60):
                b={'part':0,'start_ax':t*dx,'start_bx':t*dx,'start_ay':0.,'start_by':0.,'ax':(t+1)*dx,'bx':(t+1)*dx,'ay':0.,'by':0.}
                out.append({'tick':t,'input_mask':0,'feet':[b],'other_bodies':[]})
            return out
        self.assertIsNone(f52_eligibility(rows(.0005))['first_eligible_tick'])
        self.assertEqual(f52_eligibility(rows(0.))['first_eligible_tick'],29)
        self.assertAlmostEqual(f52_eligibility(rows(0.))['derived_drift_line_px_s'],.3)
    def test_d06_is_provisional_fixed_owner_band_and_no_fake_randomness(self):
        p=json.loads(Path('data/towers/provisional_fa6.json').read_text())
        self.assertIn('PROVISIONAL',p['status']);self.assertIn('M1-B04',p['subject_to'])
        self.assertEqual(len(p['script']['segments']),2)
        self.assertIn('do not add noise',p['determinism_note'])

if __name__=='__main__':unittest.main(verbosity=2)
