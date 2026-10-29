#!/usr/bin/env python3
"""Owner R14 source locks + synthetic report controls, NOT physical acceptance."""
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from test_contact_trace import contact_fixture
from load_pose_report import compare

ROOT=Path(__file__).resolve().parents[1]


class R14OwnerTests(unittest.TestCase):
    def test_only_two_owner_tuning_additions_no_old_resource_change(self):
        raw=(ROOT/'core/tuning.tres').read_bytes()
        # Undo ONLY the four R25 owner-approved replacements before checking the
        # immutable R14 golden bytes; every other old field remains locked.
        for adopted,old in [(b'physics_max_constraint_angular_impulse_rad_s = 30.0',b'physics_max_constraint_angular_impulse_rad_s = 6.0'),
            (b'motors_joint_stiffness = 10.0',b'motors_joint_stiffness = 2400.0'),
            (b'motors_joint_damping = 0.5443327361211717',b'motors_joint_damping = 55.0'),
            (b'motors_max_torque = 12.0',b'motors_max_torque = 1800.0')]:
            self.assertIn(adopted,raw);raw=raw.replace(adopted,old)
        original=b''.join(line for line in raw.splitlines(keepends=True) if not line.startswith((b'sleep_still_displacement_wu =',b'sleep_dwell_ticks =')))
        self.assertEqual(hashlib.sha256(original).hexdigest(),'1da7a06bea943e947f5229e3335573f8e32b567c530b4425f72c5028f84dc490')
        self.assertIn(b'sleep_still_displacement_wu = 0.001\n',raw)
        self.assertIn(b'sleep_dwell_ticks = 30\n',raw)
        schema=(ROOT/'core/tuning.gd').read_text()
        self.assertIn('Owner R14 Decision2 / M1-D12',schema)
        for field in ('sleep_still_displacement_wu','sleep_dwell_ticks'):
            self.assertIn('`'+field+'`',(ROOT/'docs/TUNING.md').read_text())

    def test_catalog_axes_only_and_exact_retained_stub(self):
        hashes={'slug':'2c9236b13126fad7f8754ed2373927ccc47699f63679cd64be64e169087d67e3',
                'hopper':'a53e986e39a1e2d8b8e240fa243044dc374752bf930dcad9ba8672d728d49265',
                'twinroller':'4ec5bf10b4f0077c4858a0408305c66f787b8f0b3a45ced8316ee14c3ab1db64'}
        axes={'slug':['RIGHT','DOWN','DOWN'],
              'hopper':['RIGHT','DOWN','LEFT','DOWN','DOWN','DOWN','DOWN','DOWN'],
              'twinroller':['RIGHT','DOWN','RIGHT','DOWN','DOWN','DOWN']}
        for name,expected in hashes.items():
            d=json.loads((ROOT/f'data/creatures/preset_{name}.json').read_text())
            self.assertEqual([p['axis'] for p in d['parts']],axes[name])
            if name=='twinroller':self.assertEqual(d['parts'][5]['parent'],0)
            for p in d['parts']:p.pop('axis')
            self.assertEqual(hashlib.sha256(json.dumps(d,sort_keys=True).encode()).hexdigest(),expected)

    def test_runtime_report_provenance_not_stale_pending_owner_decisions(self):
        from load_trace_report import diagnostic_summary
        r=diagnostic_summary(contact_fixture())
        self.assertIn('APPROVED',r['owner_decisions'])
        self.assertNotIn('PENDING',' '.join(r['limitations']))
        self.assertFalse(r['foot_load_path_exercised'])
        self.assertTrue(r['momentum_ledger_verified'])

    def _case(self,root,pose):
        folder=Path(root)/pose;folder.mkdir()
        rows=contact_fixture()
        for r in rows:r['diagnostic_pose']=pose
        (folder/'engine-status.txt').write_text('0')
        (folder/'slug-600.jsonl').write_text(''.join(json.dumps(r)+'\n' for r in rows))
        return folder

    def test_paired_report_runs_independent_checks_without_claiming_support_fixed(self):
        with tempfile.TemporaryDirectory() as root:
            for pose in ('before','after'):self._case(root,pose)
            r=compare(root)
        self.assertTrue(all(c['status']=='OBSERVED' for c in r['cases'].values()))
        self.assertEqual(r['cases']['after']['rows'],600)
        self.assertEqual(r['cases']['after']['grip_ticks'],0)
        self.assertFalse(r['F41']['absolute_drift_smaller'])

    def test_incomplete_pair_not_a_zero_residual(self):
        with tempfile.TemporaryDirectory() as root:r=compare(root)
        self.assertNotIn('F41',r)
        self.assertTrue(all(c['status']=='NOT COMPLETED' for c in r['cases'].values()))

    def test_owner_identical_drift_changed_support_trap_not_silently_accepted(self):
        # Classifier-only fake contacts; NOT production/physical evidence.
        with tempfile.TemporaryDirectory() as root:
            for pose in ('before','after'):self._case(root,pose)
            with patch('load_pose_report.save',side_effect=[
                {'steady_mean_com_dx_wu_tick':-7.1752e-6,'steady_grounded_sets':[[0,1,2]]},
                {'steady_mean_com_dx_wu_tick':-7.1752e-6,'steady_grounded_sets':[[2]]}]):
                r=compare(root)
        self.assertTrue(r['F41']['suspicious_identical_drift_different_support'])
        self.assertFalse(r['F41']['absolute_drift_smaller'])


if __name__=='__main__':unittest.main(verbosity=2)
