#!/usr/bin/env python3
"""NEW assembled runner barriers with a labelled test double; ZERO engine ticks."""
import json,os,shutil,subprocess,unittest
import test_contact_composition_runner as previous

class ArticulatedExecutionRunner(previous.CompositionRunnerTests):
    def setUp(self):
        super().setUp()
        for name in ['tests/run_m1_articulated_execution.sh','scripts/publish_m1_articulated_execution.py',
                     'tests/physics_fix/actuated_articulated_candidate.gd',
                     'tests/physics_fix/articulated_terrain_candidate.gd',
                     'tests/physics_fix/test_articulated_execution.gd',
                     'tests/physics_fix/test_articulated_cap_identity.gd']:
            target=self.root/name;target.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(previous.primitive.ROOT/name,target)
        fake=self.fake.read_text().replace('M1_CONTACT_COMPOSITION_REPORT_DIR','M1_ARTICULATED_EXECUTION_REPORT_DIR')
        marker="stage='import' if '--import' in args"
        component="""if any('test_articulated_cap_identity.gd' in a for a in args):
 if os.environ.get('DOUBLE_COMPONENT_ERROR')=='1': print('SCRIPT ERROR: TEST DOUBLE component failure')
 if '--check-only' not in args and os.environ.get('DOUBLE_COMPONENT_NO_SUMMARY')!='1':
  print('Articulated cap identity: 7 checks, 0 failures')
 sys.exit(0)
"""
        self.fake.write_text(fake.replace(marker,component+marker))

    def run_double(self,**extra):
        env=dict(os.environ,GODOT=str(self.fake),DOUBLE_CALLS=str(self.calls),
                 M1_ARTICULATED_EXECUTION_REPORT_DIR=str(self.root/'exports/contact-candidate-units'))
        env.update(extra)
        result=subprocess.run(['bash','tests/run_m1_articulated_execution.sh'],cwd=self.root,env=env,text=True,capture_output=True)
        calls=[json.loads(line) for line in self.calls.read_text().splitlines()]
        stages=['import' if '--import' in a else 'compile' if '--check-only' in a else 'units' for a in calls if '--version' not in a and not any('test_articulated_cap_identity.gd' in v for v in a)]
        return result,stages

    def test_dirty_checkout_not_claimed_as_source_commit(self):
        result,_=self.run_double()
        self.assertEqual(result.returncode,0,result.stderr)
        data=json.loads((self.root/'exports/contact-candidate-units/source.json').read_text())
        self.assertTrue(data['checkout_dirty'])
        self.assertIsNone(data['source_commit'])

    def test_component_error_stops_before_world(self):
        result,stages=self.run_double(DOUBLE_COMPONENT_ERROR='1')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_incomplete_component_suite_stops_before_world(self):
        result,stages=self.run_double(DOUBLE_COMPONENT_NO_SUMMARY='1')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_both_component_stages_precede_world(self):
        result,_=self.run_double()
        self.assertEqual(result.returncode,0,result.stderr)
        calls=[json.loads(line) for line in self.calls.read_text().splitlines()]
        scripts=[a[a.index('--script')+1:] for a in calls if '--script' in a]
        self.assertEqual(len(scripts),4)
        self.assertIn('test_articulated_execution.gd',scripts[0][0])
        self.assertIn('test_articulated_cap_identity.gd',scripts[1][0])
        self.assertIn('test_articulated_cap_identity.gd',scripts[2][0])
        self.assertIn('test_articulated_execution.gd',scripts[3][0])

if __name__=='__main__':unittest.main(verbosity=2)
