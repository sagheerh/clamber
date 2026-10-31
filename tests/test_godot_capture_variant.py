import base64,gzip,hashlib,json,math,struct,unittest
from pathlib import Path
from godot_capture_variant import decode
ROOT=Path(__file__).resolve().parents[1]
class Inspector(unittest.TestCase):
 def test_two_exact_native_captures(self):
  for source,expected in [('797a85674f31','c41be0285b624d70d00d84e1bedf8b1e935b07beaa7aebd3b1e0d39736365289'),('c801779d1d19','f7933f1a0d3092cd30a44baf1bca98f0cbb990c9b9e06c2b4dcf23daefb242df')]:
   f=ROOT/'tests/fixtures/m1_articulated_execution'/source
   raw=(f/'idle-Slug-failure.json').read_bytes();self.assertEqual(hashlib.sha256(raw).hexdigest(),expected)
   failure=json.loads(raw);full=decode(base64.b64decode(failure['full_state_variant_base64'],validate=True))
   self.assertEqual(full['awake_trace']['phase'],'pre-contact hinge velocity');self.assertEqual(full['awake_trace']['velocity_pass'],0)
   self.assertEqual(full['awake_trace']['stage_order'],['forces','velocity_pass_0'])
   rows=[json.loads(s)for s in gzip.open(f/'idle-Slug.jsonl.gz','rt')]
   self.assertEqual(full['candidate']['bodies'],rows[-1]['state']['physical']['bodies']);self.assertEqual(len(rows),failure['tick'])
 def test_nan_inf_not_sanitized(self):
  self.assertTrue(math.isnan(decode(struct.pack('<Id',0x10003,float('nan')))))
  self.assertEqual(decode(struct.pack('<Id',0x10003,float('inf'))),float('inf'))
 def test_object_refused(self):
  with self.assertRaises(ValueError):decode(struct.pack('<I',24))
 def test_truncated_refused(self):
  with self.assertRaises(ValueError):decode(struct.pack('<I',0x10003))
 def test_trailing_refused(self):
  with self.assertRaises(ValueError):decode(struct.pack('<II',0,0))
 def test_unknown_flags_refused(self):
  with self.assertRaises(ValueError):decode(struct.pack('<II',0x20002,0))
 def test_typed_object_refused(self):
  with self.assertRaises(ValueError):decode(struct.pack('<II',0x1001c,24))
 def test_excessive_count_refused(self):
  with self.assertRaises(ValueError):decode(struct.pack('<II',28,0x7fffffff))
 def test_bool_domain_refused(self):
  with self.assertRaises(ValueError):decode(struct.pack('<II',1,2))
 def test_bound_refused(self):
  with self.assertRaises(ValueError):decode(bytes(2*1024*1024+1))
if __name__=='__main__':unittest.main(verbosity=2)
