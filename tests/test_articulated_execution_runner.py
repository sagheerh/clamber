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
                     'tests/physics_fix/test_articulated_execution.gd']:
            target=self.root/name;target.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(previous.primitive.ROOT/name,target)
        self.fake.write_text(self.fake.read_text().replace('M1_CONTACT_COMPOSITION_REPORT_DIR','M1_ARTICULATED_EXECUTION_REPORT_DIR'))

    def run_double(self,**extra):
        env=dict(os.environ,GODOT=str(self.fake),DOUBLE_CALLS=str(self.calls),
                 M1_ARTICULATED_EXECUTION_REPORT_DIR=str(self.root/'exports/contact-candidate-units'))
        env.update(extra)
        result=subprocess.run(['bash','tests/run_m1_articulated_execution.sh'],cwd=self.root,env=env,text=True,capture_output=True)
        calls=[json.loads(line) for line in self.calls.read_text().splitlines()]
        stages=['import' if '--import' in a else 'compile' if '--check-only' in a else 'units' for a in calls if '--version' not in a]
        return result,stages

    def test_dirty_checkout_not_claimed_as_source_commit(self):
        result,_=self.run_double()
        self.assertEqual(result.returncode,0,result.stderr)
        data=json.loads((self.root/'exports/contact-candidate-units/source.json').read_text())
        self.assertTrue(data['checkout_dirty'])
        self.assertIsNone(data['source_commit'])

if __name__=='__main__':unittest.main(verbosity=2)
