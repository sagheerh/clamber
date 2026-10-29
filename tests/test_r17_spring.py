#!/usr/bin/env python3
import unittest
from load_spring_report import joint_summary

class SpringControls(unittest.TestCase):
    def rows(self, kind='motor', passive=0.):
        return [{'diagnostic_motor_stiffness':2400.,'diagnostic_passive_stiffness':passive,
                 'drive_events':[{'kind':kind,'channel':'L' if kind=='motor' else '',
                 'q':.1,'target':0.,'spring_torque':-240. if kind=='motor' else -passive*.1,
                 'damping_torque':-55. if kind=='motor' else 0.,'torque':-295. if kind=='motor' else -passive*.1}]} for _ in range(300)]
    def test_zero_passive_does_not_disable_motor_return(self):
        result=joint_summary(self.rows())[0]
        self.assertEqual(result['mean_spring_torque'],-240.)
        self.assertEqual(result['mean_damping_torque'],-55.)
    def test_passive_zero_contribution(self):
        self.assertEqual(joint_summary(self.rows('passive'))[0]['mean_spring_torque'],0.)
    def test_forged_contribution_rejected(self):
        rows=self.rows();rows[0]['drive_events'][0]['spring_torque']=0.
        with self.assertRaises(ValueError):joint_summary(rows)

if __name__=='__main__':unittest.main(verbosity=2)
