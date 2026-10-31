"""Read-only static obstruction, NOT a finite-time/acceptance impossibility proof."""
import json
from fractions import Fraction as F
from pathlib import Path
import unittest

ROOT=Path(__file__).resolve().parents[1]
SOURCE='253102b4750d'
SPAWN=ROOT/'tests/fixtures/m1_articulated_execution'/SOURCE/'idle-Slug-spawn.json'
SIN_MAX=F(13,50) # sin(15deg) < .26
COS_MIN=F(24,25) # cos(15deg) > .96

class StaticSupport(unittest.TestCase):
 def setUp(self):
  self.spawn=json.loads(SPAWN.read_text(),parse_float=F)
  self.b=self.spawn['rig']['physical']['bodies']
 def test_trigonometric_enclosures_are_exact(self):
  den=10**15;lo2=F(1414213562373095,den);lo6=F(2449489742783178,den);hi6=F(2449489742783179,den)
  self.assertLess(lo2*lo2,2);self.assertLess(lo6*lo6,6);self.assertGreater(hi6*hi6,6)
  self.assertLess((hi6-lo2)/4,SIN_MAX);self.assertGreater((lo6+lo2)/4,COS_MIN)
 def test_actual_pinned_geometry_and_free_foot(self):
  self.assertEqual([b['mass'] for b in self.b],[F(77,100),F(12,25),F(3,10)])
  self.assertEqual([b['length'] for b in self.b],[F(7,20),F(3,10),F(1,4)])
  self.assertEqual(len(self.spawn['rig']['physical']['angular_joints']),1)
  self.assertEqual(self.spawn['state']['identity']['tower']['terrain']['cell'],F(1,4))
  self.assertIn('if bodies[index].kind not in ["motor", "passive"]:',(ROOT/'core/sim/actuated_load_probe.gd').read_text())
 def test_only_lower_foot_sample_can_contact_within_15deg(self):
  h,m,f=self.b;slop=F(1,50);foot_b=f['radius']-slop
  self.assertGreater(foot_b+f['length']*COS_MIN/2,f['radius']+slop)
  self.assertGreater(foot_b+f['length']*COS_MIN,m['radius']+slop)
  self.assertGreater(foot_b+(f['length']+m['length'])*COS_MIN-h['length']*SIN_MAX,h['radius']+slop)
 def test_free_foot_static_moment_requires_vertical_axis(self):
  # Sum Fx=0 => terrain tangent force=0. Sum Fy=0 => terrain N=M*g.
  # Foot moment about its pin A = g*Lf*(M-mf/2)*sin(delta_foot).
  total=sum(b['mass'] for b in self.b);foot=self.b[2]
  coefficient=28*foot['length']*(total-foot['mass']/2)
  self.assertEqual(coefficient,F(49,5));self.assertGreater(coefficient,0)
  # Within +/-15deg sin(delta)=0 only at delta=0; no foot angular actuator.
 def test_vertical_free_foot_cannot_balance_upper_mass_inside_15deg(self):
  h,m,f=self.b;total=sum(b['mass']for b in self.b)
  a=h['mass']*h['length']/2
  b=(h['mass']+m['mass']/2)*m['length']
  gap_lower=(a*COS_MIN-b*SIN_MAX)/total
  self.assertEqual(gap_lower,F(2529,77500))
  self.assertGreater(gap_lower,F(3,100))
  self.assertEqual(28*total*gap_lower,F(17703,12500))

if __name__=='__main__':unittest.main(verbosity=2)
