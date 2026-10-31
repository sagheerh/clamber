"""Independent exact bilateral structural-connector algebra. ZERO engine/world ticks."""
import unittest
from test_articulated_mobility_analysis import F,frame,mobility,project,solve,dot,energy

class RigidPad(unittest.TestCase):
 def setUp(self):
  self.b=[((F(0),F(7,20)),(F(0),F(0)),F(77,100)),
          ((F(0),F(0)),(F(0),-F(3,10)),F(12,25)),
          ((F(0),-F(3,10)),(-F(1,4),-F(3,10)),F(3,10))]
  self.w,self.pins,_=frame(self.b,[-1,0,1])
  self.fixed=[F(0)]*9;self.fixed[5]=-F(1);self.fixed[8]=F(1)
  self.h=self.pins+[self.fixed]
  self.g=self.gram(self.w)
 def gram(self,w):return [[sum(x*a*y for x,a,y in zip(i,w,j))for j in self.h]for i in self.h]
 def test_bilateral_angular_compatibility(self):
  p=[F(0)]*9;p[8]=1;v,_=mobility(self.w,self.h,self.g,p)
  self.assertEqual(dot(self.fixed,v),0)
 def test_connector_root_unconstrained(self):
  p=[F(0)]*9;p[2]=1;v,_=mobility(self.w,self.h,self.g,p)
  self.assertNotEqual(v[2],0)
 def test_real_angular_momentum_not_external_weld(self):
  p=[F(0)]*9;p[2]=1;v,_=mobility(self.w,self.h,self.g,p)
  angular=F(0)
  for i,(a,b,m) in enumerate(self.b):
   x,y=(a[0]+b[0])/2,(a[1]+b[1])/2
   angular+=v[3*i+2]/self.w[3*i+2]+m*(x*v[3*i+1]-y*v[3*i])
  self.assertEqual(angular,1)
 def test_zero_branch_free_foot_negative(self):
  g=[[sum(x*a*y for x,a,y in zip(i,self.w,j))for j in self.pins]for i in self.pins]
  p=[F(0)]*9;p[8]=1;v,_=mobility(self.w,self.pins,g,p)
  self.assertNotEqual(dot(self.fixed,v),0)
 def test_actual_local_drag_and_connector_torque_close(self):
  r=F(1,5);w=[a*(r if i%3==2 else 1)for i,a in enumerate(self.w)]
  raw=[F(i-4,7)for i in range(9)];free=[a*(r if i%3==2 else 1)for i,a in enumerate(raw)]
  g=self.gram(w);out=project(w,self.h,g,free);lam=solve(g,[-dot(row,free)for row in self.h])
  for d in range(9):
   c=(1/r-1)*out[d]/self.w[d]if d%3==2 else F(0)
   pin=sum(row[d]*j for row,j in zip(self.pins,lam))
   self.assertEqual((out[d]-raw[d])/self.w[d]+c-pin,self.fixed[d]*lam[-1])
  self.assertEqual(dot(self.fixed,out),0)
  self.assertLessEqual(energy(self.w,out),energy(self.w,raw))
 def test_neutral_vertical_head_has_positive_restoring_stiffness(self):
  # NOT a world stability/sleep proof: just this local head/gravity linearization.
  head=self.b[0];moment=head[2]*28*F(7,40)
  self.assertEqual(moment,F(3773,1000));self.assertGreater(F(10)-moment,0)

if __name__=='__main__':unittest.main(verbosity=2)
