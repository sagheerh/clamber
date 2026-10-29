#!/usr/bin/env python3
"""R28 source/forgery controls, never a substitute for measured penetration."""
import hashlib, json, re, subprocess, sys, unittest
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'scripts'))


class R28Controls(unittest.TestCase):
    def test_tuning_exact_start(self):
        self.assertEqual(Path('core/tuning.tres').read_bytes(),subprocess.check_output(['git','show','fb890fd:core/tuning.tres']))
    def test_exact_one_traversal_with_no_runtime_physics_flag_after_adoption(self):
        s=Path('core/sim/coupled_load_probe.gd').read_text()
        if '## M1-R28-D1 —' not in Path('DECISIONS.md').read_text():
            self.assertEqual(s,subprocess.check_output(['git','show','fb890fd:core/sim/coupled_load_probe.gd'],text=True))
            return
        c=s.split('func _velocity_contacts',1)[1].split('func _rigid_velocity',1)[0]
        self.assertNotIn('if diagnostic_final_distance_pass:',c)
        self.assertEqual(c.count('for link in _links:'),1)
        self.assertEqual(c.count('link.project(_tuning)'),1)
        self.assertIn('\n\tfor link in _links:\n\t\tif link.project(_tuning) != OK:',c)
        self.assertGreater(c.index('\n\tfor link in _links:'),c.index('if _finish_velocities() != OK:'))
        self.assertNotIn('reset_multiplier',c.split('\n\tfor link in _links:')[1])
    def test_only_f47_quarantined(self):
        s=Path('.github/workflows/m1.yml').read_text()
        self.assertEqual(s.count('continue-on-error: true'),1)
        self.assertIn('name: Hinged Slug600 load diagnostic (NOT FA acceptance)\n        continue-on-error: true',s)
        self.assertIn('::',s)
        self.assertIn('M1 Slug diagnostic evidence (not FA acceptance)',s)
    def test_parked_resolver_is_detached(self):
        s=Path('core/sim/sleeping_load_probe.gd').read_text().split('func _grounded_query',1)[1].split('func _parked_velocities',1)[0]
        self.assertIn('CapsuleBody.new()',s)
        self.assertIn('shadows.append(body)',s)
        self.assertIn('CapsuleContact.resolve_tick(\n\t\tshadows,',s)
        self.assertNotIn('_probe.bodies',s)
    def test_measurements_pinned_and_dependents_stop(self):
        s=Path('.github/workflows/m1.yml').read_text()
        for name in ('r28-measure','r28-baseline','r28-idle','r28-characterisation','r28-m0'):
            header=s.split('  '+name+':',1)[1].split('    name:',1)[0]
            self.assertIn('github.sha == inputs.r28_source_sha',header)
            self.assertIn("github.sha == '446d870da5c02ecfc295a19d7f35a8436b3b7fa7'",header)
        self.assertIn('needs: [r28-measure]',s.split('  r28-baseline:',1)[1])
        self.assertIn('needs: [r28-measure]',s.split('  r28-idle:',1)[1])
        self.assertIn('needs: [r28-idle]',s.split('  r28-characterisation:',1)[1])
    def test_stop_is_strict_and_no_physical_clamping(self):
        s=Path('tests/r28_report.py').read_text()
        self.assertIn("maximum['penetration_wu']<.02",s)
        s=Path('tests/sim/test_r28.gd').read_text()
        self.assertNotIn('diagnostic_final_distance_pass =',s)
        self.assertNotIn('candidate_enabled',s)
        self.assertNotIn('body.a.y =',s)
    def test_fixture_horizons_unchanged(self):
        p=json.loads(Path('tests/fixtures/r28_plan.json').read_text())
        self.assertEqual(p['adoption-measure']['ticks'],7200)
        self.assertEqual(p['idle-family']['ticks'],600)
        self.assertEqual(p['ac201a-characterisation']['ticks'],3600)
        self.assertIn('300',p['idle-family']['drift'])
    def test_waveform_sweeps_not_dispatched_as_r28(self):
        s=Path('.github/workflows/m1.yml').read_text()
        for line in s.splitlines():
            if 'workflow_dispatch' in line and 'if:' in line and 'inputs.r28_source_sha' not in line:
                self.fail('unbounded legacy dispatch: '+line)


if __name__=='__main__':unittest.main(verbosity=2)
