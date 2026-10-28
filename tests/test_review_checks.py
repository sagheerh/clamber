#!/usr/bin/env python3
import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'scripts'))
from review_static import violations
from check_m0_regression import validate
from check_m1_matrix import validate_matrix, validate_pack, RUNTIME


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


class MatrixGuardTests(unittest.TestCase):
    matrix = (Path(__file__).resolve().parents[1] / '.review/m1_ac_matrix.md').read_text()

    def changed(self, gate, status, evidence):
        lines = self.matrix.splitlines()
        for index, line in enumerate(lines):
            if line.startswith('| ' + gate + ' |'):
                cells = line.split('|')
                cells[3], cells[4] = ' ' + status + ' ', ' ' + evidence + ' '
                lines[index] = '|'.join(cells)
                return '\n'.join(lines)
        self.fail('fixture gate missing: ' + gate)

    def test_current_matrix_and_immutable_pack(self):
        self.assertEqual(validate_matrix(self.matrix), [])
        pack = (Path(__file__).resolve().parents[1] / 'docs/CLAMBER_REVIEW_AGENT.md').read_bytes()
        self.assertEqual(validate_pack(pack), [])
        self.assertTrue(validate_pack(pack + b'provenance\n'))
        self.assertTrue(validate_pack(pack.replace(b'CLAMBER', b'CLAMBeR', 1)))

    def test_each_runtime_row_rejects_every_success_token_with_real_evidence(self):
        for line in self.matrix.splitlines():
            if not line.startswith('| '):
                continue
            gate = line.split('|')[1].strip()
            if not RUNTIME.search(gate):
                continue
            for token in ['Met', 'PASS', 'PASSED', 'VERIFIED', '**verified**']:
                with self.subTest(gate=gate, token=token):
                    errors = validate_matrix(self.changed(gate, token, 'CI40631790078'))
                    self.assertTrue(any('runtime acceptance success claim' in e for e in errors))

    def test_success_hidden_in_evidence_is_rejected(self):
        errors = validate_matrix(self.changed('AC-201', 'NOT RUN', 'VERIFIED CI40631790078'))
        self.assertTrue(any('runtime acceptance success claim' in e for e in errors))

    def test_success_requires_nonempty_non_none_evidence(self):
        for evidence in ['', 'None', '`None`', 'none; no run']:
            with self.subTest(evidence=evidence):
                errors = validate_matrix(self.changed('M0 regression', 'PASS (regression only)', evidence))
                self.assertTrue(any('empty/None evidence' in e for e in errors))

    def test_regression_and_count_floor_exceptions_require_scope_and_citation(self):
        for gate, status in [('M0 regression', 'PASS (regression only)'),
                             ('A8 test-count floor', 'PASS (count floor only)')]:
            for citation in ['CI40631790078', 'commit f51ecd480ce5e5476428740755f2dd33a87a5e79']:
                self.assertEqual(validate_matrix(self.changed(gate, status, citation)), [])
            self.assertTrue(validate_matrix(self.changed(gate, 'PASS', 'CI40631790078')))
            self.assertTrue(validate_matrix(self.changed(gate, status, 'scripts/check_m0_regression.py')))
        self.assertTrue(validate_matrix(self.changed('AC-201', 'PASS (regression only)', 'CI40631790078')))

    def test_not_run_floor_is_falsifiable(self):
        lines, count = [], 0
        for line in self.matrix.splitlines():
            if line.startswith('| ') and 'NOT RUN' in line:
                count += 1
                if count > 11:
                    line = line.replace('NOT RUN', 'PENDING')
            lines.append(line)
        errors = validate_matrix('\n'.join(lines))
        self.assertIn('NOT RUN row floor: 11 < 12', errors)

    def test_status_allowlist_rejects_bypasses_and_empty_in_every_table(self):
        for status in ['COMPLETE', 'DONE', 'GREEN', 'ACCEPTED', 'SOLVED', 'MEASURED (4 s)', '']:
            with self.subTest(status=status):
                errors = validate_matrix(self.changed('AC-201', status, 'CI40636758741'))
                self.assertTrue(any('status not allowlisted' in e for e in errors))
                # A later table or a headerless row must not escape the scan.
                row = f'| AC-201 | synthetic fixture | {status} | CI40636758741 |'
                for gap in ['\n\n', '\n\n## Later table\n\n| Gate / source | Required acceptance evidence | Status | Evidence reference |\n|---|---|---|---|\n']:
                    self.assertTrue(validate_matrix(self.matrix + gap + row))
        for status in ['NOT RUN', 'NOT RUN for M1', 'STATIC CHECK ONLY']:
            self.assertEqual(validate_matrix(self.changed('AC-201', status, 'None')), [])

    def test_missing_table_gate_and_malformed_row_fail_closed(self):
        self.assertTrue(validate_matrix(''))
        row = next(line for line in self.matrix.splitlines() if line.startswith('| AC-201 |'))
        self.assertTrue(validate_matrix(self.matrix.replace(row, '')))
        self.assertTrue(validate_matrix(self.matrix.replace(row, '| AC-201 | NOT RUN |')))


if __name__ == '__main__':
    unittest.main(verbosity=2)
