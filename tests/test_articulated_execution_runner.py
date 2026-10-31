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
                     'tests/physics_fix/test_articulated_cap_identity.gd',
                     'tests/physics_fix/test_staged_articulated_components.gd',
                     'tests/physics_fix/test_staged_contact_identity.gd',
                     'tests/physics_fix/test_limited_articulated_components.gd',
                     'tests/physics_fix/test_assembly_drag_components.gd',
                     'tests/physics_fix/test_preintegrated_components.gd']:
            target=self.root/name;target.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(previous.primitive.ROOT/name,target)
        fake=self.fake.read_text().replace('M1_CONTACT_COMPOSITION_REPORT_DIR','M1_ARTICULATED_EXECUTION_REPORT_DIR')
        marker="stage='import' if '--import' in args"
        component="""if any('test_articulated_cap_identity.gd' in a or 'test_staged_articulated_components.gd' in a or 'test_staged_contact_identity.gd' in a or 'test_limited_articulated_components.gd' in a or 'test_assembly_drag_components.gd' in a or 'test_preintegrated_components.gd' in a for a in args):
 if os.environ.get('DOUBLE_COMPONENT_ERROR')=='1': print('SCRIPT ERROR: TEST DOUBLE component failure')
 if '--check-only' not in args and os.environ.get('DOUBLE_COMPONENT_NO_SUMMARY')!='1':
  if any('test_preintegrated_components.gd' in a for a in args): print('Preintegrated components: '+os.environ.get('DOUBLE_PREINTEGRATED_COUNT','20')+' checks, 0 failures')
  elif any('test_assembly_drag_components.gd' in a for a in args): print('Assembly angular drag components: '+os.environ.get('DOUBLE_ASSEMBLY_COUNT','26')+' checks, 0 failures')
  elif any('test_limited_articulated_components.gd' in a for a in args): print('Angular limited components: '+os.environ.get('DOUBLE_LIMITED_COUNT','36')+' checks, 0 failures')
  elif any('test_staged_contact_identity.gd' in a for a in args): print('Staged contact identity: 12 checks, 0 failures')
  else: print('Staged articulated components: '+os.environ.get('DOUBLE_STAGED_COUNT','20')+' checks, 0 failures' if any('test_staged_articulated_components.gd' in a for a in args) else 'Articulated cap identity: 8 checks, 0 failures')
 if any('test_preintegrated_components.gd' in a for a in args) and '--check-only' not in args:
  if os.environ.get('DOUBLE_PREINTEGRATED_ERROR')=='1': print('SCRIPT ERROR: TEST DOUBLE preintegration error')
  if os.environ.get('DOUBLE_PREINTEGRATED_EXIT')=='1': sys.exit(10)
 if any('test_assembly_drag_components.gd' in a for a in args) and '--check-only' not in args:
  if os.environ.get('DOUBLE_ASSEMBLY_ERROR')=='1': print('SCRIPT ERROR: TEST DOUBLE assembly runtime error')
  if os.environ.get('DOUBLE_ASSEMBLY_EXIT')=='1': sys.exit(9)
 if any('test_limited_articulated_components.gd' in a for a in args) and '--check-only' not in args:
  if os.environ.get('DOUBLE_LIMITED_ERROR')=='1': print('SCRIPT ERROR: TEST DOUBLE limited runtime error')
  if os.environ.get('DOUBLE_LIMITED_EXIT')=='1': sys.exit(8)
 if any('test_staged_articulated_components.gd' in a for a in args) and '--check-only' not in args:
  if os.environ.get('DOUBLE_STAGED_ERROR')=='1': print('SCRIPT ERROR: TEST DOUBLE staged runtime error')
  if os.environ.get('DOUBLE_STAGED_EXIT')=='1': sys.exit(7)
 sys.exit(0)
"""
        self.fake.write_text(fake.replace(marker,component+marker))

    def run_double(self,**extra):
        env=dict(os.environ,GODOT=str(self.fake),DOUBLE_CALLS=str(self.calls),
                 M1_ARTICULATED_EXECUTION_REPORT_DIR=str(self.root/'exports/contact-candidate-units'))
        env.update(extra)
        result=subprocess.run(['bash','tests/run_m1_articulated_execution.sh'],cwd=self.root,env=env,text=True,capture_output=True)
        calls=[json.loads(line) for line in self.calls.read_text().splitlines()]
        stages=['import' if '--import' in a else 'compile' if '--check-only' in a else 'units' for a in calls if '--version' not in a and not any('test_articulated_cap_identity.gd' in v or 'test_staged_articulated_components.gd' in v or 'test_staged_contact_identity.gd' in v or 'test_limited_articulated_components.gd' in v or 'test_assembly_drag_components.gd' in v or 'test_preintegrated_components.gd' in v for v in a)]
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
        self.assertEqual(len(scripts),14)
        self.assertIn('test_articulated_execution.gd',scripts[0][0])
        self.assertIn('test_articulated_cap_identity.gd',scripts[1][0])
        self.assertIn('test_articulated_cap_identity.gd',scripts[2][0])
        self.assertIn('test_staged_articulated_components.gd',scripts[3][0])
        self.assertIn('test_staged_articulated_components.gd',scripts[4][0])
        self.assertIn('test_staged_contact_identity.gd',scripts[5][0])
        self.assertIn('test_staged_contact_identity.gd',scripts[6][0])
        self.assertIn('test_limited_articulated_components.gd',scripts[7][0])
        self.assertIn('test_limited_articulated_components.gd',scripts[8][0])
        self.assertIn('test_assembly_drag_components.gd',scripts[9][0])
        self.assertIn('test_assembly_drag_components.gd',scripts[10][0])
        self.assertIn('test_preintegrated_components.gd',scripts[11][0])
        self.assertIn('test_preintegrated_components.gd',scripts[12][0])
        self.assertIn('test_articulated_execution.gd',scripts[13][0])

    def test_staged_runtime_error_stops_before_world(self):
        result,stages=self.run_double(DOUBLE_STAGED_ERROR='1')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])
        self.assertFalse((self.root/'exports/contact-candidate-units/engine.log').exists())

    def test_staged_nonzero_exit_is_preserved(self):
        result,stages=self.run_double(DOUBLE_STAGED_EXIT='1')
        self.assertEqual(result.returncode,7)
        self.assertEqual(stages,['import','compile'])
        self.assertEqual((self.root/'exports/contact-candidate-units/exit-code.txt').read_text(),'7\n')

    def test_staged_incomplete_count_stops_before_world(self):
        result,stages=self.run_double(DOUBLE_STAGED_COUNT='19')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_limited_runtime_error_blocks_world(self):
        result,stages=self.run_double(DOUBLE_LIMITED_ERROR='1')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_limited_incomplete_count_blocks_world(self):
        result,stages=self.run_double(DOUBLE_LIMITED_COUNT='35')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_limited_nonzero_exit_preserved(self):
        result,stages=self.run_double(DOUBLE_LIMITED_EXIT='1')
        self.assertEqual(result.returncode,8)
        self.assertEqual(stages,['import','compile'])

    def test_preintegrated_error_blocks_world(self):
        result,stages=self.run_double(DOUBLE_PREINTEGRATED_ERROR='1')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_preintegrated_count_blocks_world(self):
        result,stages=self.run_double(DOUBLE_PREINTEGRATED_COUNT='19')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_preintegrated_exit_preserved(self):
        result,stages=self.run_double(DOUBLE_PREINTEGRATED_EXIT='1')
        self.assertEqual(result.returncode,10)
        self.assertEqual(stages,['import','compile'])

    def test_assembly_error_blocks_world(self):
        result,stages=self.run_double(DOUBLE_ASSEMBLY_ERROR='1')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_assembly_incomplete_blocks_world(self):
        result,stages=self.run_double(DOUBLE_ASSEMBLY_COUNT='25')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_assembly_exit_preserved(self):
        result,stages=self.run_double(DOUBLE_ASSEMBLY_EXIT='1')
        self.assertEqual(result.returncode,9)
        self.assertEqual(stages,['import','compile'])

    def test_staged_runtime_has_quit_bound(self):
        result,_=self.run_double()
        self.assertEqual(result.returncode,0,result.stderr)
        calls=[json.loads(line) for line in self.calls.read_text().splitlines()]
        call=next(a for a in calls if any('test_staged_articulated_components.gd' in v for v in a) and '--check-only' not in a)
        self.assertEqual(call[call.index('--quit-after')+1],'1')

if __name__=='__main__':unittest.main(verbosity=2)
