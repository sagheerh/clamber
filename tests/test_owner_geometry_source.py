#!/usr/bin/env python3
"""Owner-input/source assertions, not runtime feel evidence."""
from decimal import Decimal
from pathlib import Path
import hashlib
import re
import unittest

ROOT = Path(__file__).resolve().parents[1]
EXPECTED = {
    'physics_limb_collision_radius_wu': '0.065', 'physics_passive_collision_radius_wu': '0.085',
    'physics_motor_collision_radius_wu': '0.095', 'physics_foot_collision_radius_wu': '0.050',
    'physics_head_collision_radius_wu': '0.100', 'art_limb_visual_radius_wu': '0.065',
    'art_passive_visual_radius_wu': '0.105', 'art_motor_visual_radius_wu': '0.120',
    'art_foot_visual_radius_wu': '0.065', 'art_head_visual_radius_wu': '0.135',
    'physics_head_mass_per_wu': '2.2', 'physics_head_length_wu': '0.35',
    'physics_grip_normal_force_ratio': '0.40', 'physics_grip_normal_force_floor': '5.0',
    'physics_d10_bend_margin_wu': '0.06', 'feel_readability_px_per_wu': '150.0',
    'feel_min_collision_diameter_px': '15.0', 'feel_min_head_collision_diameter_px': '30.0',
    'feel_limb_aspect_ratio_min': '3.0', 'feel_limb_aspect_ratio_max': '12.0',
    'feel_static_scene_ticks': '600', 'feel_tutorial_runs': '10',
    'feel_tutorial_successes_min': '6', 'feel_tutorial_successes_max': '8',
}


class OwnerGeometrySourceTests(unittest.TestCase):
    def test_owner_constants_exact_and_sourced(self):
        values = dict(re.findall(r'^(\w+) = (.+)$', (ROOT / 'core/tuning.tres').read_text(), re.M))
        inventory = (ROOT / 'docs/TUNING.md').read_text()
        for field, expected in EXPECTED.items():
            with self.subTest(field=field):
                self.assertEqual(Decimal(values[field]), Decimal(expected))
                self.assertIn(f'`{field}` | owner M1-D04 |', inventory)
        self.assertEqual(Decimal(values['physics_foot_grip_bias']), Decimal('1.4'))
        self.assertEqual(Decimal(values['physics_static_slip_wu_s']), Decimal('0.15'))
        self.assertEqual(Decimal(values['physics_head_mass_per_wu']) * Decimal(values['physics_head_length_wu']), Decimal('0.77'))
        self.assertNotRegex((ROOT / 'core/tuning.gd').read_text(), r'@export var \w*head\w*(?:angular|limit)')

    def test_derivation_byte_identity(self):
        data = (ROOT / '.review/M1_B01_CONTACT_GEOMETRY_DERIVATION.md').read_bytes()
        self.assertEqual(hashlib.sha256(data).hexdigest(),
                         '6453508be7cb808f643544ec3f3fdbd6560840876fc070511f4b5f50065dbc5e')
        self.assertEqual(data.count(b'\n'), 281)

    def test_owner_force_ratio_scales_not_old_absolute_force(self):
        # Exact decimal derivation only. This does NOT execute foot contact/slip.
        head = Decimal('2.2') * Decimal('0.35')
        motor = Decimal('1.6') * Decimal('0.30')
        foot = Decimal('1.2') * Decimal('0.25')
        mass = head + motor + foot
        weight = mass * Decimal('28')
        self.assertEqual(mass, Decimal('1.55'))
        self.assertEqual(weight, Decimal('43.40'))
        self.assertEqual(max(Decimal('5'), Decimal('0.40') * weight), Decimal('17.3600'))
        self.assertEqual(max(Decimal('5'), Decimal('0.40') * Decimal('0.01') * Decimal('28')), Decimal('5'))


if __name__ == '__main__':
    unittest.main(verbosity=2)
