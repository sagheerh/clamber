import gzip
import json
import unittest
from articulated_execution_v12_audit import audit, audit_rows, finite, FIXTURE

class Closure(unittest.TestCase):
 def setUp(self):
  with gzip.open(FIXTURE/'idle-Slug.jsonl.gz','rt')as f:self.rows=[json.loads(l)for l in f]
 def test_exact_archive(self):
  report=audit();self.assertEqual(report['native_checks'],214);self.assertFalse(report['full600_pass'])
 def test_short_prefix_not_full(self):
  report=audit_rows(self.rows);self.assertEqual(report['committed_ticks'],37);self.assertEqual(report['airborne_ticks'],0);self.assertEqual(report['sleep_ticks'],0)
 def test_truncated(self):
  with self.assertRaises(ValueError):audit_rows(self.rows[:-1])
 def test_duplicate_clock(self):
  self.rows[1]['tick']=0
  with self.assertRaises(ValueError):audit_rows(self.rows)
 def test_nonfinite(self):
  self.rows[2]['state']['physical']['bodies'][1]['a']['y']=float('nan')
  with self.assertRaises(ValueError):audit_rows(self.rows)
 def test_faulty_solver(self):
  self.rows[2]['awake_solver_trace']['status']=30
  with self.assertRaises(ValueError):audit_rows(self.rows)
 def test_missing_phase(self):
  self.rows[2]['awake_solver_trace']['stage_order'].pop()
  with self.assertRaises(ValueError):audit_rows(self.rows)
 def test_omitted_body(self):
  self.rows[2]['state']['physical']['bodies'].pop()
  with self.assertRaises(ValueError):audit_rows(self.rows)
 def test_physical_clock(self):
  self.rows[2]['state']['physical']['ticks']=1
  with self.assertRaises(ValueError):audit_rows(self.rows)
 def test_recursive_scanner(self):self.assertFalse(finite({'x':[{'y':float('inf')}]}));self.assertTrue(finite({'x':[None,False,0.0]}))
if __name__=='__main__':unittest.main(verbosity=2)
