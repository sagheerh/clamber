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
                     'tests/physics_fix/test_preintegrated_components.gd',
                     'tests/physics_fix/test_force_order_components.gd',
                     'tests/physics_fix/test_damped_support_components.gd',
                     'tests/physics_fix/test_impact_history_components.gd',
                     'tests/physics_fix/test_constitutive_stage_components.gd',
                     'tests/physics_fix/test_local_angular_components.gd',
                     'tests/physics_fix/test_capsule_surface_components.gd']:
            target=self.root/name;target.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(previous.primitive.ROOT/name,target)
        fake=self.fake.read_text().replace('M1_CONTACT_COMPOSITION_REPORT_DIR','M1_ARTICULATED_EXECUTION_REPORT_DIR')
        marker="stage='import' if '--import' in args"
        component="""if any('test_articulated_cap_identity.gd' in a or 'test_staged_articulated_components.gd' in a or 'test_staged_contact_identity.gd' in a or 'test_limited_articulated_components.gd' in a or 'test_assembly_drag_components.gd' in a or 'test_preintegrated_components.gd' in a or 'test_force_order_components.gd' in a or 'test_damped_support_components.gd' in a or 'test_impact_history_components.gd' in a or 'test_constitutive_stage_components.gd' in a or 'test_local_angular_components.gd' in a or 'test_capsule_surface_components.gd' in a for a in args):
 if os.environ.get('DOUBLE_COMPONENT_ERROR')=='1': print('SCRIPT ERROR: TEST DOUBLE component failure')
 if '--check-only' not in args and os.environ.get('DOUBLE_COMPONENT_NO_SUMMARY')!='1':
  if any('test_capsule_surface_components.gd' in a for a in args): print('Capsule surface components: '+os.environ.get('DOUBLE_CAPSULE_SURFACE_COUNT','24')+' checks, 0 failures')
  elif any('test_local_angular_components.gd' in a for a in args): print('Local angular components: '+os.environ.get('DOUBLE_LOCAL_ANGULAR_COUNT','26')+' checks, 0 failures')
  elif any('test_constitutive_stage_components.gd' in a for a in args): print('Constitutive stage components: '+os.environ.get('DOUBLE_CONSTITUTIVE_COUNT','30')+' checks, 0 failures')
  elif any('test_impact_history_components.gd' in a for a in args): print('Impact history components: '+os.environ.get('DOUBLE_IMPACT_COUNT','23')+' checks, 0 failures')
  elif any('test_damped_support_components.gd' in a for a in args): print('Damped support components: '+os.environ.get('DOUBLE_SUPPORT_COUNT','29')+' checks, 0 failures')
  elif any('test_force_order_components.gd' in a for a in args): print('Force-order components: '+os.environ.get('DOUBLE_FORCE_COUNT','14')+' checks, 0 failures')
  elif any('test_preintegrated_components.gd' in a for a in args): print('Preintegrated components: '+os.environ.get('DOUBLE_PREINTEGRATED_COUNT','27')+' checks, 0 failures')
  elif any('test_assembly_drag_components.gd' in a for a in args): print('Assembly angular drag components: '+os.environ.get('DOUBLE_ASSEMBLY_COUNT','26')+' checks, 0 failures')
  elif any('test_limited_articulated_components.gd' in a for a in args): print('Angular limited components: '+os.environ.get('DOUBLE_LIMITED_COUNT','36')+' checks, 0 failures')
  elif any('test_staged_contact_identity.gd' in a for a in args): print('Staged contact identity: 12 checks, 0 failures')
  else: print('Staged articulated components: '+os.environ.get('DOUBLE_STAGED_COUNT','20')+' checks, 0 failures' if any('test_staged_articulated_components.gd' in a for a in args) else 'Articulated cap identity: 8 checks, 0 failures')
 if any('test_capsule_surface_components.gd' in a for a in args) and '--check-only' not in args:
  if os.environ.get('DOUBLE_CAPSULE_SURFACE_ERROR')=='1': print('SCRIPT ERROR: TEST DOUBLE capsule surface error')
  if os.environ.get('DOUBLE_CAPSULE_SURFACE_EXIT')=='1': sys.exit(16)
 if any('test_local_angular_components.gd' in a for a in args) and '--check-only' not in args:
  if os.environ.get('DOUBLE_LOCAL_ANGULAR_ERROR')=='1': print('SCRIPT ERROR: TEST DOUBLE local angular error')
  if os.environ.get('DOUBLE_LOCAL_ANGULAR_EXIT')=='1': sys.exit(15)
 if any('test_constitutive_stage_components.gd' in a for a in args) and '--check-only' not in args:
  if os.environ.get('DOUBLE_CONSTITUTIVE_ERROR')=='1': print('SCRIPT ERROR: TEST DOUBLE constitutive error')
  if os.environ.get('DOUBLE_CONSTITUTIVE_EXIT')=='1': sys.exit(14)
 if any('test_impact_history_components.gd' in a for a in args) and '--check-only' not in args:
  if os.environ.get('DOUBLE_IMPACT_ERROR')=='1': print('SCRIPT ERROR: TEST DOUBLE impact history error')
  if os.environ.get('DOUBLE_IMPACT_EXIT')=='1': sys.exit(13)
 if any('test_damped_support_components.gd' in a for a in args) and '--check-only' not in args:
  if os.environ.get('DOUBLE_SUPPORT_ERROR')=='1': print('SCRIPT ERROR: TEST DOUBLE damped support error')
  if os.environ.get('DOUBLE_SUPPORT_EXIT')=='1': sys.exit(12)
 if any('test_force_order_components.gd' in a for a in args) and '--check-only' not in args:
  if os.environ.get('DOUBLE_FORCE_ERROR')=='1': print('SCRIPT ERROR: TEST DOUBLE force order error')
  if os.environ.get('DOUBLE_FORCE_EXIT')=='1': sys.exit(11)
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
        stages=['import' if '--import' in a else 'compile' if '--check-only' in a else 'units' for a in calls if '--version' not in a and not any('test_articulated_cap_identity.gd' in v or 'test_staged_articulated_components.gd' in v or 'test_staged_contact_identity.gd' in v or 'test_limited_articulated_components.gd' in v or 'test_assembly_drag_components.gd' in v or 'test_preintegrated_components.gd' in v or 'test_force_order_components.gd' in v or 'test_damped_support_components.gd' in v or 'test_impact_history_components.gd' in v or 'test_constitutive_stage_components.gd' in v or 'test_local_angular_components.gd' in v or 'test_capsule_surface_components.gd' in v for v in a)]
        return result,stages

    def test_impact_history_error_stops_before_world(self):
        result,stages=self.run_double(DOUBLE_IMPACT_ERROR='1')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_impact_history_wrong_count_stops_before_world(self):
        result,stages=self.run_double(DOUBLE_IMPACT_COUNT='22')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_impact_history_exit_stops_before_world(self):
        result,stages=self.run_double(DOUBLE_IMPACT_EXIT='1')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_constitutive_error_stops_before_world(self):
        result,stages=self.run_double(DOUBLE_CONSTITUTIVE_ERROR='1')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_constitutive_wrong_count_stops_before_world(self):
        result,stages=self.run_double(DOUBLE_CONSTITUTIVE_COUNT='29')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_constitutive_exit_stops_before_world(self):
        result,stages=self.run_double(DOUBLE_CONSTITUTIVE_EXIT='1')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_local_angular_error_stops_before_world(self):
        result,stages=self.run_double(DOUBLE_LOCAL_ANGULAR_ERROR='1')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_local_angular_wrong_count_stops_before_world(self):
        result,stages=self.run_double(DOUBLE_LOCAL_ANGULAR_COUNT='25')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_local_angular_exit_stops_before_world(self):
        result,stages=self.run_double(DOUBLE_LOCAL_ANGULAR_EXIT='1')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_capsule_surface_error_stops_before_world(self):
        result,stages=self.run_double(DOUBLE_CAPSULE_SURFACE_ERROR='1')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_capsule_surface_wrong_count_stops_before_world(self):
        result,stages=self.run_double(DOUBLE_CAPSULE_SURFACE_COUNT='23')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_capsule_surface_exit_stops_before_world(self):
        result,stages=self.run_double(DOUBLE_CAPSULE_SURFACE_EXIT='1')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

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
        self.assertEqual(len(scripts),26)
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
        self.assertIn('test_force_order_components.gd',scripts[13][0])
        self.assertIn('test_force_order_components.gd',scripts[14][0])
        self.assertIn('test_damped_support_components.gd',scripts[15][0])
        self.assertIn('test_damped_support_components.gd',scripts[16][0])
        self.assertIn('test_impact_history_components.gd',scripts[17][0])
        self.assertIn('test_impact_history_components.gd',scripts[18][0])
        self.assertIn('test_constitutive_stage_components.gd',scripts[19][0])
        self.assertIn('test_constitutive_stage_components.gd',scripts[20][0])
        self.assertIn('test_local_angular_components.gd',scripts[21][0])
        self.assertIn('test_local_angular_components.gd',scripts[22][0])
        self.assertIn('test_capsule_surface_components.gd',scripts[23][0])
        self.assertIn('test_capsule_surface_components.gd',scripts[24][0])
        self.assertIn('test_articulated_execution.gd',scripts[25][0])

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

    def test_support_error_blocks_world(self):
        result,stages=self.run_double(DOUBLE_SUPPORT_ERROR='1')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_support_count_blocks_world(self):
        result,stages=self.run_double(DOUBLE_SUPPORT_COUNT='28')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_support_exit_preserved(self):
        result,stages=self.run_double(DOUBLE_SUPPORT_EXIT='1')
        self.assertEqual(result.returncode,12)
        self.assertEqual(stages,['import','compile'])

    def test_force_error_blocks_world(self):
        result,stages=self.run_double(DOUBLE_FORCE_ERROR='1')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_force_count_blocks_world(self):
        result,stages=self.run_double(DOUBLE_FORCE_COUNT='13')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_force_exit_preserved(self):
        result,stages=self.run_double(DOUBLE_FORCE_EXIT='1')
        self.assertEqual(result.returncode,11)
        self.assertEqual(stages,['import','compile'])

    def test_preintegrated_error_blocks_world(self):
        result,stages=self.run_double(DOUBLE_PREINTEGRATED_ERROR='1')
        self.assertNotEqual(result.returncode,0)
        self.assertEqual(stages,['import','compile'])

    def test_preintegrated_count_blocks_world(self):
        result,stages=self.run_double(DOUBLE_PREINTEGRATED_COUNT='26')
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
