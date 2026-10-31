"""Independent exact matrix checks of damped H/support response, not native proof."""
import unittest
from test_articulated_mobility_analysis import F,slug,frame,mobility,dot,contact_row

def response(bodies,parents,impulse,r):
 w,h,g=frame(bodies,parents);old,_=mobility(w,h,g,impulse)
 m=sum(b[2]for b in bodies);t=[sum(impulse[d::3])/m for d in [0,1]]
 return [r*v+(1-r)*(t[d%3]if d%3!=2 else 0)for d,v in enumerate(old)]

class Matrix(unittest.TestCase):
 def setUp(self):self.b=slug();self.p=[-1,0,1];self.w,self.h,self.g=frame(self.b,self.p)
 def test_hinge_nullspace(self):
  v=response(self.b,self.p,[F(i-4,7)for i in range(9)],F(1,5));self.assertEqual([dot(h,v)for h in self.h],[0]*4)
 def test_symmetric(self):
  a=[F(i-4,7)for i in range(9)];b=[F((-1)**i,9)for i in range(9)]
  self.assertEqual(dot(a,response(self.b,self.p,b,F(1,5))),dot(b,response(self.b,self.p,a,F(1,5))))
 def test_nonnegative(self):
  for r in [F(0),F(1,5),F(1)]:
   a=[F(i-4,7)for i in range(9)];self.assertGreaterEqual(dot(a,response(self.b,self.p,a,r)),0)
 def test_total_contact_impulse_preserved(self):
  a=[F(i-4,7)for i in range(9)];v=response(self.b,self.p,a,F(1,5))
  for d in [0,1]:self.assertEqual(sum(b[2]*v[3*i+d]for i,b in enumerate(self.b)),sum(a[d::3]))
 def test_contact_gram_spd(self):
  n=contact_row(self.b,2,F(1),(F(0),F(1)));t=contact_row(self.b,2,F(1),(-F(1),F(0)))
  for r in [F(0),F(1,5),F(1)]:
   a=response(self.b,self.p,n,r);b=response(self.b,self.p,t,r)
   self.assertGreater(dot(n,a)*dot(t,b)-dot(n,b)**2,0)
 def test_rest_not_restituted_from_gravity(self):
  old=F(0);free=old-F(28,60);e=F(1,50)
  self.assertGreater(-e*min(free,0),0);self.assertEqual(-e*min(old,0),0)
 def test_real_impact_keeps_authored_restitution(self):self.assertEqual(-F(1,50)*min(F(-1),0),F(1,50))
 def test_zero_and_full_loss_limits(self):
  a=[F(i-4,7)for i in range(9)]
  self.assertEqual(response(self.b,self.p,a,F(1)),mobility(self.w,self.h,self.g,a)[0])
  self.assertEqual(response(self.b,self.p,a,F(0))[2::3],[0]*3)
 def test_spd_does_not_imply_incremental_kinetic_passivity(self):
  # Counterexample selected AFTER closed V12; this is algebra, not a new world.
  r=F(1,5);knn=ktt=1+r/2;knt=r/2;vn=F(1);vt=-F(1,2)
  det=knn*ktt-knt*knt;jn=(-vn*ktt+vt*knt)/det
  self.assertLess(jn,0);jn=F(0);jt=-vt/ktt
  vx=-F(3,2)-jt;omega=2-r*jt/2
  self.assertEqual(vx+omega,0);self.assertGreater(3-omega,0)
  before=(F(3,2)**2+3**2+2*2**2)/2
  after=(vx*vx+3**2+2*omega**2)/2
  self.assertEqual(after-before,F(293,484))
if __name__=='__main__':unittest.main(verbosity=2)
