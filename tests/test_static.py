#!/usr/bin/env python3
"""Dependency-free M0 contract checks. These do NOT replace engine/device tests."""
import re
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path):
    return (ROOT / path).read_text()


def code_only(text):
    # Remove strings and comments before scanning for numeric literals/dependencies.
    return re.sub(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])*\'|#[^\n]*', '', text)


class M0StaticTests(unittest.TestCase):
    def test_tuning_complete_and_single_source(self):
        script = read('core/tuning.gd')
        resource = read('core/tuning.tres')
        exported = re.findall(r'@export var (\w+): (\w+)\s*$', script, re.M)
        values = dict(re.findall(r'^(\w+) = (.+)$', resource, re.M))
        self.assertGreaterEqual(len(exported), 40)
        self.assertEqual(len(exported), len(set(name for name, _ in exported)))
        self.assertEqual(set(values) - {'script'}, {name for name, _ in exported})
        for group in ['Physics', 'Motors', 'Camera', 'Fall', 'Score', 'Economy', 'Generator']:
            self.assertIn(f'@export_group("{group}")', script)
        for name, kind in exported:
            with self.subTest(name=name):
                self.assertIn(f'`{name}`', read('docs/TUNING.md'))
                value = values[name]
                if kind == 'int':
                    self.assertRegex(value, r'^-?\d+$')
                elif kind == 'float':
                    float(value)
                elif kind == 'bool':
                    self.assertIn(value, ('true', 'false'))
                elif kind.startswith('Packed'):
                    self.assertTrue(value.startswith(kind + '('))
        # Normative GDD values, independent of the generated inventory.
        for key, expected in {
            'physics_gravity_wu_s2': '-28.0', 'physics_tick_hz': '60',
            'motors_contraction_deg': '62.0', 'motors_joint_stiffness': '10.0',
            'motors_joint_damping': '0.5443327361211717', 'motors_max_torque': '12.0',
            'fall_checkpoint_drop_wu': '5.0', 'score_fall_penalty': '150',
            'score_second_penalty': '10', 'score_coin_pickup_value': '50',
            'economy_starting_coins': '0', 'generator_baked_days': '90',
        }.items():
            self.assertEqual(values[key], expected)

    def test_core_has_no_numeric_literals_or_ui_platform_dependencies(self):
        for path in (ROOT / 'core').rglob('*.gd'):
            with self.subTest(path=path):
                text = path.read_text()
                code = code_only(text)
                self.assertNotRegex(code, r'(?<![\w])(?:0[xX][\da-fA-F]+|\d+(?:\.\d*)?)')
                self.assertNotRegex(text, r'res://(?:ui|platform)/')
                self.assertNotRegex(code, r'\b(?:Control|Node2D|DisplayServer|RenderingServer|Input|AudioServer)\b')

    def test_sim_guardrails(self):
        for directory in ['core/sim', 'core/run', 'core/tower']:
            for path in (ROOT / directory).glob('*.gd'):
                code = code_only(path.read_text())
                self.assertNotRegex(code, r'\b(?:randf|randi|sin|cos|tan|pow|exp|atan2)\s*\(')
                self.assertNotIn('get_ticks_usec', code)
                self.assertNotRegex(code, r'\bdelta\b')
        for path in ROOT.rglob('*'):
            if path.suffix in ('.gd', '.tscn') and '.tools' not in path.parts:
                self.assertNotRegex(code_only(path.read_text()), r'\b(?:RigidBody2D|Joint2D|PinJoint2D)\b')

    def test_project_and_android_contract(self):
        project = read('project.godot')
        for setting in ['viewport_width=1080', 'viewport_height=2340',
                        'window/handheld/orientation=1', 'window/stretch/mode="canvas_items"',
                        'window/stretch/aspect="keep"', 'renderer/rendering_method="mobile"',
                        'physics_ticks_per_second=60', 'engine_version="4.7.2-stable"']:
            self.assertIn(setting, project)
        self.assertNotIn('[autoload]', project)
        preset = read('export_presets.cfg')
        for setting in ['gradle_build/min_sdk="26"', 'gradle_build/target_sdk="36"',
                        'architectures/arm64-v8a=true', 'gradle_build/export_format=1',
                        'permissions/internet=false']:
            self.assertIn(setting, preset)
        self.assertIn('GODOT_VERSION: 4.7.2-stable', read('.github/workflows/m0.yml'))

    def test_skeleton_and_resource_references(self):
        for path in ['core/sim', 'core/run', 'core/creature', 'core/tower', 'core/econ',
                     'core/data', 'ui/screens', 'ui/components', 'ui/theme', 'platform/android',
                     'art', 'audio', 'data/towers', 'data/creatures', 'tests']:
            self.assertTrue((ROOT / path).is_dir(), path)
        for directory in ['core', 'ui', 'platform', 'tests']:
            for path in (ROOT / directory).rglob('*'):
                if path.suffix not in ('.gd', '.tscn', '.tres'):
                    continue
                for reference in re.findall(r'"res://([^"\n]+)"', path.read_text()):
                    self.assertTrue((ROOT / reference).exists(), f'{path}: {reference}')
        self.assertEqual(list((ROOT / 'ui/screens').glob('*.tscn')), [])
        self.assertIn('NAVY_900 = Color("00192f")', read('ui/theme/tokens.gd'))

    def test_public_interfaces_are_declared(self):
        sim = read('core/sim/sim.gd')
        for signature in [
            'func setup(creature: CreatureModel, tower: TowerData, seed: int, tuning: Tuning) -> void:',
            'func step(input_mask: int) -> void:', 'func get_render_state() -> Array:',
            'func snapshot() -> Dictionary:', 'func restore(s: Dictionary) -> void:',
            'func state_hash() -> int:', 'func result() -> RunResult:',
        ]:
            self.assertIn(signature, sim)
        self.assertIn('static func encode(c: CreatureModel) -> String:', read('core/creature/codec.gd'))
        self.assertIn('static func decode(s: String) -> DecodeResult:', read('core/creature/codec.gd'))


if __name__ == '__main__':
    unittest.main(verbosity=2)
