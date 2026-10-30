#!/usr/bin/env python3
"""No simulation; R29 launch/scope/evidence forgery controls."""
import gzip,hashlib,json,subprocess,unittest
from pathlib import Path
class R29Controls(unittest.TestCase):
 def test_core_and_tuning_unchanged(self):
  self.assertEqual(subprocess.check_output(['git','diff','4796ec6','--','core/']),b'')
  self.assertEqual(hashlib.sha256(Path('core/tuning.tres').read_bytes()).hexdigest(),'5f4d0d06564fb3a0847309d83cf5f3c87b9321ea5e2dd87e572e4bd9fe750666')
 def test_push_gate_no_upload_before_measurements(self):
  s=Path('.github/workflows/r29.yml').read_text()
  self.assertIn("github.event_name == 'push'",s);self.assertIn('github.sha == github.event.after',s);self.assertIn('[R29-once-2]',s);self.assertNotIn('upload-artifact',s);self.assertNotIn('workflow_dispatch',s)

 def test_d0_no_readoption_and_same_sampler(self):
  s=Path('tests/sim/test_r29.gd').read_text();self.assertIn('extends "res://tests/sim/test_r28.gd"',s);self.assertIn('_penetration(probe)',s);self.assertNotIn('diagnostic_final_distance_pass =',s);self.assertIn('range(7200)',s)
 def test_d0_original_numbers_and_all_ticks(self):
  e=json.loads(Path('.review/m1_r29_measurement_evidence.json').read_text())
  for g in e['gates']:
   if not g['gate'].startswith('D0/'):continue
   rs=[json.loads(r) for r in gzip.decompress(Path(g['artifact']).read_bytes()).splitlines()]
   self.assertEqual(len(rs),7200);self.assertEqual([r['tick'] for r in rs],list(range(7200)));self.assertEqual(max(r['peak']['penetration_wu'] for r in rs),g['value']['max_penetration_wu'])
   self.assertEqual(g['source_commit_sha'],'819cefc4ce9b66e6f8725d1ed24694e85e8f5154')
 def test_fixed_horizons_no_synthetic_success(self):
  s=Path('tests/sim/test_r29.gd').read_text();self.assertNotIn('func _checked(',s);self.assertIn('func _checked_step(',s);self.assertIn('range(100)',s);self.assertIn('range(10000)',s);self.assertIn('range(10)',s);self.assertIn('"success": null',s)
 def test_owner_workload_and_no_new_threshold(self):
  s=Path('tests/r29_remaining.py').read_text();self.assertIn('ten independent productionSlug',s);self.assertIn("distinctness_threshold=None",s);self.assertIn('NOT MEASURED (owner D07)',s);self.assertIn("v['success_count']=None",s)
if __name__=='__main__':unittest.main(verbosity=2)
