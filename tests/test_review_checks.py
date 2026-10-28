#!/usr/bin/env python3
import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from review_static import violations
from check_m0_regression import validate


class ReviewChecksTests(unittest.TestCase):
    def test_banned_sim_sources(self):
        for code in ['randf()', 'randi()', 'randomize()', 'seed(value)', 'randf_range(a, b)',
                     'RandomNumberGenerator.new()', 'Time.get_ticks_usec()', 'Time.get_ticks_msec()',
                     'Engine.get_physics_frames()', 'func _process(delta):\n pass',
                     'sin(value)', 'cos(value)', 'tan(value)', 'pow(a,b)', 'exp(value)', 'atan2(a,b)']:
            with self.subTest(code=code):
                self.assertTrue(violations(code, 'core/sim/example.gd'))

    def test_nested_run_and_tower_sources(self):
        for path in ['core/run/replay/input.gd', 'core/tower/grid/sdf.gd']:
            self.assertTrue(violations('Time.get_ticks_usec()', path))

    def test_physics_nodes_in_scripts_and_scenes(self):
        for node in ['RigidBody2D', 'Joint2D', 'PinJoint2D', 'DampedSpringJoint2D']:
            self.assertTrue(violations('extends ' + node, 'tests/example.gd'))
            self.assertTrue(violations(f'[node name="Body" type="{node}"]', 'ui/example.tscn'))

    def test_comments_strings_and_injected_seed_parameter_allowed(self):
        self.assertEqual(violations('func setup(seed: int):\n pass\n# randf()\nvar text = "sin(0)"', 'core/sim/example.gd'), [])
        self.assertEqual(violations('var text = """randf()\nTime.get_ticks_usec()"""', 'core/sim/example.gd'), [])

    def test_core_numbers_and_dependencies(self):
        self.assertTrue(violations('var mass = 1.0', 'core/creature/example.gd'))
        self.assertTrue(violations('const UI = preload("res://ui/example.gd")', 'core/sim/example.gd'))

    def test_m0_exact_baseline(self):
        self.assertEqual(validate('Ran 6 tests in x\nRan 7 tests in x\nM0: 475 checks, 0 failures\n'), (475, 13))

    def test_engine_floor_cannot_be_hidden_by_more_python_checks(self):
        with self.assertRaises(ValueError):
            validate('Ran 100 tests in x\nM0: 474 checks, 0 failures\n')

    def test_count_errors_or_missing_completion_fail(self):
        for log in ['M0: 475 checks, 0 failures\n', 'Ran 13 tests in x\nM0: 475 checks, 1 failures\n',
                    'Ran 13 tests in x\nSCRIPT ERROR: x\nM0: 475 checks, 0 failures\n',
                    'Ran 13 tests in x\n', 'Ran 12 tests in x\nM0: 476 checks, 0 failures\n']:
            with self.subTest(log=log), self.assertRaises(ValueError):
                validate(log)


if __name__ == '__main__':
    unittest.main(verbosity=2)
