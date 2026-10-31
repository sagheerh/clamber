"""Exact local angular resolvent identities, NOT native or world acceptance."""
import unittest
from test_articulated_mobility_analysis import F,slug,frame,project,mobility,dot,energy

class Local(unittest.TestCase):
 def setUp(self):
  self.w,self.h,_=frame(slug(),[-1,0,1]);self.r=F(1,5)
  self.a=[w*(self.r if d%3==2 else 1)for d,w in enumerate(self.w)]
  self.g=[[sum(x*w*y for x,w,y in zip(a,self.a,b))for b in self.h]for a in self.h]
  self.raw=[F(i-4,7)for i in range(9)]
  self.free=[v*(self.r if d%3==2 else 1)for d,v in enumerate(self.raw)]
  self.out=project(self.a,self.h,self.g,self.free)
 def test_hinge_constraints(self):self.assertEqual([dot(h,self.out)for h in self.h],[0]*4)
 def test_energy_nonincrease(self):self.assertLessEqual(energy(self.w,self.out),energy(self.w,self.raw))
 def test_local_torque_law(self):
  # M(out-raw)+C*out consists exclusively of H^T multipliers.
  from test_articulated_mobility_analysis import solve
  la=solve(self.g,[-dot(h,self.free)for h in self.h])
  for d,v in enumerate(self.out):
   resistance=(1/self.r-1)*v/self.w[d]if d%3==2 else F(0)
   self.assertEqual((v-self.raw[d])/self.w[d]+resistance,sum(h[d]*l for h,l in zip(self.h,la)))
 def test_momentum_preserved(self):
  for axis in [0,1]:self.assertEqual(sum(v/w for v,w in zip(self.out[axis::3],self.w[axis::3])),sum(v/w for v,w in zip(self.raw[axis::3],self.w[axis::3])))
 def test_derivative_spd(self):
  p=[F(i-4,3)for i in range(9)];v,_=mobility(self.a,self.h,self.g,p);self.assertGreaterEqual(dot(p,v),0)
 def test_derivative_symmetric(self):
  p=[F(i-4,3)for i in range(9)];q=[F((-1)**i,5)for i in range(9)]
  self.assertEqual(dot(p,mobility(self.a,self.h,self.g,q)[0]),dot(q,mobility(self.a,self.h,self.g,p)[0]))
 def test_identity_no_uniform_linear_drag(self):
  v=[F(1),F(2),F(0)]*3;self.assertEqual(project(self.a,self.h,self.g,v),v)
 def test_not_shape_damping(self):
  old=project(self.w,self.h,frame(slug(),[-1,0,1])[2],self.raw)
  m=sum(1/w for w in self.w[0::3]);tx=sum(v/w for v,w in zip(old[0::3],self.w[0::3]))/m;ty=sum(v/w for v,w in zip(old[1::3],self.w[1::3]))/m
  shape=[self.r*v+(1-self.r)*([tx,ty,0][d%3])for d,v in enumerate(old)]
  self.assertNotEqual(shape,self.out)
if __name__=='__main__':unittest.main(verbosity=2)
