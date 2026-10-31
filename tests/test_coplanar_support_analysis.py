"""Independent exact static balance, NOT an engine, feel, sleep or device verdict."""
from fractions import Fraction as F
import unittest


class CoplanarSupportAnalysis(unittest.TestCase):
    def test_stance_is_derived_from_actual_capsules_not_angle_fit(self):
        length, motor_radius, foot_radius = F('0.25'), F('0.095'), F('0.05')
        drop = motor_radius-foot_radius
        ratio = drop/length
        span_squared = length*length-drop*drop
        self.assertEqual(ratio, F(9, 50))
        self.assertGreater(span_squared, 0)
        # Parent end at y: toe end at y-drop; both real skin bottoms identical.
        self.assertEqual(-drop-foot_radius, -motor_radius)

    def test_slug_has_genuine_positive_supports_at_neutral_head(self):
        masses = [F('.77'), F('.48'), F('.30')]
        gravity = F(28)
        weight = sum(masses)*gravity
        # Toe x=-span, foot COM x=-span/2, other COMs x=0.
        # Taking moments about the motor support cancels unknown nonzero span.
        toe = masses[2]*gravity/2
        motor = weight-toe
        self.assertEqual(toe, F('4.2'))
        self.assertEqual(motor, F('39.2'))
        self.assertGreater(toe, 0)
        self.assertGreater(motor, 0)
        self.assertEqual(toe+motor, weight)
        self.assertEqual(toe-masses[2]*gravity/2, 0)
        # COM lies STRICTLY inside actual support interval; no external couple.
        com_fraction = masses[2]/(2*sum(masses))
        self.assertTrue(0 < com_fraction < 1)

    def test_no_fabricated_qualifying_grip_load(self):
        weight = F('1.55')*28
        threshold = max(F(5), F('.40')*weight)
        toe = F('.30')*28/2
        self.assertEqual(threshold, F('17.36'))
        self.assertLess(toe, threshold)
        # Static equilibrium is not a claim of qualifying dynamic foot grip.
        self.assertLess(toe, 5)

    def test_original_horizontal_pad_is_not_coplanar(self):
        self.assertEqual(F('.095')-F('.05'), F('.045'))
        self.assertNotEqual(-F('.095'), -F('.05'))


if __name__ == '__main__':
    unittest.main()
