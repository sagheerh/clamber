"""Exact actual-capsule-skin contact identities. No native/world ticks."""
from fractions import Fraction as F
import unittest

class Surface(unittest.TestCase):
 def test_normal_arm_unchanged(self):
  x,y=F(2,7),-F(3,11);nx,ny=F(3,5),F(4,5);r=F(1,20)
  self.assertEqual((x-r*nx)*ny-(y-r*ny)*nx,x*ny-y*nx)
 def test_tangent_arm_radius(self):
  x,y=F(2,7),-F(3,11);nx,ny=F(3,5),F(4,5);r=F(1,20)
  self.assertEqual((x-r*nx)*nx+(y-r*ny)*ny,x*nx+y*ny-r)
 def test_actual_slip(self):
  vx,vy,w=F(2,3),F(1,7),F(5,4);nx,ny=F(3,5),F(4,5);r=F(1,20)
  skinvx=vx+w*r*ny;skinvy=vy-w*r*nx
  self.assertEqual(-skinvx*ny+skinvy*nx,-vx*ny+vy*nx-w*r)
 def test_pure_spin_friction(self):
  r=F(1,10);j=r/(1+r*r);vx=-j;w=1-r*j
  self.assertEqual(vx+r*w,0);self.assertEqual(F(1,2)-(vx*vx+w*w)/2,F(1,202))
 def test_rolling_is_identity(self):
  r=F(1,10);omega=F(3,7);vx=-r*omega
  self.assertEqual(-vx-r*omega,0);self.assertNotEqual(-vx,0)
 def test_complete_local_drag_skin_law(self):
  radius=F(1,10);ret=F(1,5);j=ret*radius/(1+ret*radius*radius)
  finalw=ret-ret*radius*j;vx=-j;feedback=(finalw-ret)+radius*j
  self.assertEqual(vx+radius*finalw,0)
  self.assertEqual(-(1-ret)+feedback,-(1/ret-1)*finalw)
  self.assertLess((vx*vx+finalw*finalw)/2,F(1,2))
if __name__=='__main__':unittest.main(verbosity=2)
