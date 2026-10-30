#!/usr/bin/env python3
"""Synthetic parser falsification; these rows are NOT physics evidence."""
import copy
import contextlib
import io
from pathlib import Path
import sys
import tempfile
import textwrap
from unittest.mock import patch
from urllib.parse import unquote
import unittest
from load_trace_report import analyze


def fixture():
    rows = []
    for tick in range(600):
        rows.append({
            'tick': tick, 'status': 0, 'previous_grounded_feet': 0 if tick == 0 else 1,
            'diagnostic_position_iterations': 6, 'weight_n': 43.4, 'sleep_state': 'awake', 'sleep_implemented': False,
            'sum_applied_load_n': 43.4, 'sum_measured_reaction_n': 43.4,
            'sum_positional_cleanup_n': 0.0,
            'other_bodies': [], 'other_body_reaction_n': 0.0,
            'feet': [{'applied_load_n': 43.4, 'measured_reaction_n': 43.4,
                      'positional_cleanup_n': 0.0, 'penetration_wu': 0.02,
                      'grounded': True, 'gripping': False, 'lowest': True}],
        })
    for row in rows:
        foot = row['feet'][0]
        for part, kind, mass in [(0, 'head', .77), (1, 'motor', .48), (2, 'foot', .30)]:
            body = foot if kind == 'foot' else {
                'applied_load_n': 0.0, 'measured_reaction_n': 0.0,
                'positional_cleanup_n': 0.0, 'grounded': False,
            }
            body.update(part=part, kind=kind, mass=mass, radius_wu=.05,
                        inverse_mass_a=2 / mass, inverse_mass_b=2 / mass,
                        ax=0.0, ay=.03, bx=.25, by=.03, avx=0.0, avy=0.0, bvx=0.0, bvy=0.0,
                        start_ax=0.0, start_ay=.03, start_bx=.25, start_by=.03,
                        start_avy=0.0, start_bvy=0.0,
                        start_avx=0.0, start_bvx=0.0,
                        speed_a_wu_s=0.0, speed_b_wu_s=0.0, com_speed_wu_s=0.0,
                        position_delta_wu={p: [0.0]*4 for p in ("integration", "distance", "hinge", "contact")},
                        bottom_wu=.03 - .05, bottom_start_wu=.03 - .05)
            if kind != 'foot':
                row['other_bodies'].append(body)
        row['momentum_budget'] = {
            'dt_s': 1 / 60, 'momentum_before_y_ns': 0.0, 'momentum_after_y_ns': 0.0,
            'momentum_change_y_ns': 0.0, 'gravity_impulse_y_ns': -43.4 / 60,
            'damping_impulse_y_ns': 0.0, 'clamp_impulse_y_ns': 0.0,
            'internal_impulse_y_ns': 0.0, 'contact_velocity_impulse_y_ns': 43.4 / 60,
            'contact_reported_impulse_y_ns': 43.4 / 60, 'residual_y_ns': 0.0,
            'predicted_support_bias_n': 0.0, 'observed_support_bias_n': 0.0,
        }
    return rows


class LoadTraceTests(unittest.TestCase):
    def test_complete_window(self):
        result = analyze(fixture())
        self.assertTrue(result['force_window_within_owner_tolerance'])
        self.assertEqual(result['ceiling_n'], 0.723)
        self.assertEqual(result['FA-5'], 'NOT RUN')

    def test_partial_rejected(self):
        with self.assertRaises(ValueError):
            analyze(fixture()[:-1])

    def test_wrong_previous_count(self):
        rows = fixture()
        rows[500]['previous_grounded_feet'] = 2
        with self.assertRaises(ValueError):
            analyze(rows)

    def test_claimed_sum_not_trusted(self):
        rows = fixture()
        rows[350]['feet'][0]['measured_reaction_n'] = 8.4
        with self.assertRaises(ValueError):
            analyze(rows)

    def test_positional_cannot_mask_missing_reaction(self):
        rows = fixture()
        rows[350]['feet'][0]['measured_reaction_n'] = 8.4
        rows[350]['sum_measured_reaction_n'] = 8.4
        rows[350]['feet'][0]['positional_cleanup_n'] = 35.0
        rows[350]['sum_positional_cleanup_n'] = 35.0
        self.assertFalse(analyze(rows)['force_window_within_owner_tolerance'])

    def test_two_x_not_divided_away(self):
        rows = fixture()
        for row in rows:
            row['sum_measured_reaction_n'] = 86.8
            row['feet'][0]['measured_reaction_n'] = 86.8
        self.assertFalse(analyze(rows)['force_window_within_owner_tolerance'])

    def test_nonfinite_rejected(self):
        rows = copy.deepcopy(fixture())
        rows[500]['feet'][0]['applied_load_n'] = float('nan')
        with self.assertRaises(ValueError):
            analyze(rows)

    def test_shared_support_not_a_foot_only_force_failure(self):
        rows = fixture()
        for row in rows:
            for key in ('applied_load_n', 'measured_reaction_n'):
                row['feet'][0][key] = 9.4
                row['sum_' + key] = 9.4
                row['other_bodies'][0][key] = 34.0
            row['other_bodies'][0]['grounded'] = True
            row['other_body_reaction_n'] = 34.0
        result = analyze(rows)
        self.assertTrue(result['force_window_within_owner_tolerance'])
        self.assertTrue(result['momentum_ledger_verified'])
        self.assertFalse(result['foot_load_path_exercised'])
        self.assertEqual(result['grip_engagement'], 'grip never engaged')

    def test_airborne_applied_force_cannot_supply_ground_support(self):
        rows = fixture()
        row = rows[350]
        row['feet'][0]['applied_load_n'] = row['sum_applied_load_n'] = 9.4
        row['other_bodies'][0]['applied_load_n'] = 34.0
        self.assertFalse(analyze(rows)['force_window_within_owner_tolerance'])

    def test_literal_ceiling_not_weight_over_60_or_epsilon(self):
        rows = fixture()
        # .7231 is below W/60 but above the owner's literal ceiling.
        for row in rows:
            row['feet'][0]['measured_reaction_n'] = 43.4 + .7231
            row['sum_measured_reaction_n'] = 43.4 + .7231
        self.assertFalse(analyze(rows)['force_window_within_owner_tolerance'])

    def test_missing_body_geometry_rejected(self):
        rows = fixture()
        rows[99]['other_bodies'].pop()
        with self.assertRaises(ValueError):
            analyze(rows)

    def test_wrong_completed_bottom_rejected(self):
        rows = fixture()
        rows[99]['other_bodies'][1]['bottom_wu'] += .01
        with self.assertRaises(ValueError):
            analyze(rows)

    def test_wrong_start_bottom_rejected(self):
        rows = fixture()
        rows[0]['feet'][0]['bottom_start_wu'] += .01
        with self.assertRaises(ValueError):
            analyze(rows)

    def test_wrong_other_body_sum_rejected(self):
        rows = fixture()
        rows[99]['other_body_reaction_n'] = 34.0
        with self.assertRaises(ValueError):
            analyze(rows)

    def test_ledger_claim_not_trusted(self):
        rows = fixture()
        rows[99]['momentum_budget']['residual_y_ns'] = 1.0
        self.assertFalse(analyze(rows)['momentum_ledger_verified'])

    def test_endpoint_momentum_independently_reconstructed(self):
        rows = fixture()
        rows[99]['other_bodies'][0]['avy'] = 1.0
        self.assertFalse(analyze(rows)['momentum_ledger_verified'])

    def test_contact_velocity_delta_independent_of_reported_force(self):
        rows = fixture()
        rows[99]['momentum_budget']['contact_velocity_impulse_y_ns'] *= 2
        self.assertFalse(analyze(rows)['momentum_ledger_verified'])

    def test_synthetic_damping_bias_identity_not_physics_evidence(self):
        rows = fixture()
        for row in rows:
            b = row['momentum_budget']
            extra = .196
            row['feet'][0]['measured_reaction_n'] += extra
            row['sum_measured_reaction_n'] += extra
            b['damping_impulse_y_ns'] = -extra / 60
            b['contact_reported_impulse_y_ns'] += extra / 60
            b['contact_velocity_impulse_y_ns'] += extra / 60
            b['predicted_support_bias_n'] = b['observed_support_bias_n'] = extra
            momentum = extra / (.02 * 60)
            b['momentum_before_y_ns'] = b['momentum_after_y_ns'] = momentum
            for body in row['feet'] + row['other_bodies']:
                for key in ('start_avy', 'start_bvy', 'avy', 'bvy'):
                    body[key] = momentum / 1.55
        result = analyze(rows)
        self.assertTrue(result['force_window_within_owner_tolerance'])
        self.assertTrue(result['momentum_ledger_verified'])
        # Remove measured drag: the unexplained bias must not be waived.
        rows[599]['momentum_budget']['damping_impulse_y_ns'] = 0.0
        self.assertFalse(analyze(rows)['momentum_ledger_verified'])

    def test_false_grip_without_qualifying_applied_channel_rejected(self):
        rows = fixture()
        rows[99]['feet'][0]['gripping'] = True
        rows[99]['feet'][0]['applied_load_n'] = rows[99]['sum_applied_load_n'] = 9.4
        with self.assertRaises(ValueError):
            analyze(rows)

    def test_unchanging_false_grip_is_not_an_engagement_success(self):
        result = analyze(fixture())
        self.assertEqual(result['grip_toggle_ticks'], [])
        self.assertEqual(result['grip_engaged_ticks'], [])
        self.assertFalse(result['foot_load_path_exercised'])

    def test_damping_claim_checked_against_raw_start_momentum_and_resource(self):
        rows = fixture()
        for row in rows:
            extra = .196
            row['feet'][0]['measured_reaction_n'] += extra
            row['sum_measured_reaction_n'] += extra
            b = row['momentum_budget']
            b['contact_reported_impulse_y_ns'] += extra / 60
            b['contact_velocity_impulse_y_ns'] += extra / 60
            b['damping_impulse_y_ns'] = -extra / 60
            b['predicted_support_bias_n'] = b['observed_support_bias_n'] = extra
        # The algebra balances but zero start velocities cannot produce this drag.
        self.assertFalse(analyze(rows)['momentum_ledger_verified'])

    def test_nonconserving_internal_rows_cannot_be_hidden_by_budget_terms(self):
        rows = fixture()
        rows[99]['momentum_budget']['internal_impulse_y_ns'] = .1
        rows[99]['momentum_budget']['clamp_impulse_y_ns'] = -.1
        self.assertFalse(analyze(rows)['momentum_ledger_verified'])

    def test_grip_flag_without_real_reaction_is_not_a_foot_load_path(self):
        rows = fixture()
        for row in rows:
            row['feet'][0]['gripping'] = row['tick'] > 0
            row['feet'][0]['measured_reaction_n'] = row['sum_measured_reaction_n'] = 0.0
            row['other_bodies'][0]['grounded'] = True
            row['other_bodies'][0]['measured_reaction_n'] = row['other_body_reaction_n'] = 43.4
        result = analyze(rows)
        self.assertTrue(result['force_window_within_owner_tolerance'])
        self.assertTrue(result['momentum_ledger_verified'])
        self.assertEqual(result['grip_engagement'], 'grip engaged')
        self.assertFalse(result['foot_load_path_exercised'])

    def test_loaded_grip_parser_control_does_not_upgrade_runtime_acceptance(self):
        rows = fixture()
        for row in rows[1:]:
            row['feet'][0]['gripping'] = True
        result = analyze(rows)
        self.assertTrue(result['foot_load_path_exercised'])
        self.assertEqual(result['FA-5'], 'NOT RUN')

    def test_ci_annotations_exclude_raw_ticks_and_preserve_bounded_engagement_evidence(self):
        workflow = (Path(__file__).resolve().parents[1] / '.github/workflows/m1.yml').read_text()
        load_step = workflow[workflow.index('      - name: Hinged Slug600'):]
        source = textwrap.dedent(load_step.split('          import re, sys\n', 1)[1].split('          PYLOG', 1)[0])
        # Exercise the actual workflow Python, not a duplicate implementation.
        lines = ['M1 Slug tick: ' + 'raw' * 1000] * 600
        import json
        fake_row = fixture()[0]
        lines += ['M1 Slug first: ' + json.dumps(fake_row), 'M1 Slug last: ' + json.dumps(fake_row),
                  'M1 Slug momentum ledger verified: true',
                  'M1 Slug engagement: grip never engaged',
                  'M1 Slug peaks: measured=9.9N', 'M1 Slug F30 BLOCKED: owner pose decision pending']
        output = io.StringIO()
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'console.log'
            path.write_text('\n'.join(lines))
            with patch.object(sys, 'argv', ['workflow', str(path), '1']), contextlib.redirect_stdout(output):
                exec('import re, sys\n' + source, {})
        commands = output.getvalue().splitlines()
        self.assertLessEqual(len(commands), 9)
        messages = [unquote(line.split('::', 2)[2]) for line in commands]
        self.assertTrue(all(len(message) <= 3500 for message in messages))
        combined = '\n'.join(messages)
        self.assertNotIn('M1 Slug tick:', combined)
        for label in ('first:', 'last:', 'momentum ledger verified: true',
                      'engagement: grip never engaged', 'peaks:', 'F30 BLOCKED:'):
            self.assertIn('M1 Slug ' + label, combined)

    def test_single_grip_tick_is_distinguished_from_sustained_support(self):
        rows = fixture()
        rows[350]['feet'][0]['gripping'] = True
        result = analyze(rows)
        self.assertTrue(result['foot_load_path_exercised'])
        self.assertEqual(result['motion']['steady_grip_ticks'], 1)
        self.assertEqual(result['motion']['steady_grip_fraction'], 1 / 300)
        self.assertEqual(result['motion']['steady_foot_support_share_range'], [1.0, 1.0])
        self.assertEqual(result['FA-5'], 'NOT RUN')

    def test_support_share_uses_all_grounded_reaction_and_excludes_cleanup(self):
        rows = fixture()
        for row in rows:
            row['feet'][0]['measured_reaction_n'] = row['sum_measured_reaction_n'] = 8.68
            row['feet'][0]['positional_cleanup_n'] = row['sum_positional_cleanup_n'] = 999.0
            row['other_bodies'][0]['grounded'] = True
            row['other_bodies'][0]['measured_reaction_n'] = row['other_body_reaction_n'] = 34.72
        result = analyze(rows)
        self.assertAlmostEqual(result['motion']['steady_foot_support_share_mean'], .2)
        self.assertEqual(result['motion']['steady_grip_fraction'], 0.0)

    def test_position_ledger_claim_not_trusted(self):
        rows = fixture()
        rows[99]['feet'][0]['position_delta_wu']['hinge'][1] = .002
        self.assertFalse(analyze(rows)['motion']['position_ledger_and_speed_identities_verified'])

    def test_missing_position_phase_rejected(self):
        rows = fixture()
        del rows[99]['other_bodies'][0]['position_delta_wu']['distance']
        with self.assertRaises(ValueError):
            analyze(rows)

    def test_fake_speed_claim_rejected_as_identity_not_sleep_threshold(self):
        rows = fixture()
        rows[99]['feet'][0]['speed_a_wu_s'] = .1
        self.assertFalse(analyze(rows)['motion']['position_ledger_and_speed_identities_verified'])

    def test_decay_profile_reports_nonzero_plateau_without_a_rest_epsilon(self):
        rows = fixture()
        for i, row in enumerate(rows):
            row['momentum_budget']['momentum_after_y_ns'] = 1 / (i+1) if i < 200 else .004
        result = analyze(rows)['motion']
        self.assertEqual(result['first_tick_all_remaining_inside_final_observed_envelope'], 200)
        self.assertEqual(result['first_tick_exact_constant_suffix_at_least_two_rows'], 200)
        self.assertEqual(result['momentum_final_observed_envelope_ns'], [.004, .004])

    def test_zero_ground_support_share_is_undefined_not_divided_or_clipped(self):
        rows = fixture()
        for row in rows:
            row['feet'][0]['measured_reaction_n'] = row['sum_measured_reaction_n'] = 0.0
        result = analyze(rows)['motion']
        self.assertIsNone(result['steady_foot_support_share_range'])
        self.assertEqual(result['steady_undefined_support_share_ticks'], 300)

    def test_sweep_is_observation_only_with_every_sample_and_no_adoption(self):
        import json
        from load_motion_sweep import summarize, ITERATIONS
        with tempfile.TemporaryDirectory() as folder:
            for count in ITERATIONS:
                path = Path(folder) / f'iterations-{count}'
                path.mkdir()
                rows = fixture()
                for row in rows:
                    row['diagnostic_position_iterations'] = count
                (path / 'engine-status.txt').write_text('0')
                (path / 'slug-600.jsonl').write_text(''.join(json.dumps(r) + '\n' for r in rows))
            result = summarize(folder)
        self.assertEqual([c['iterations'] for c in result['cases']], [1, 2, 4, 6, 12, 24])
        self.assertTrue(all(c['status'] == 'OBSERVED' for c in result['cases']))
        self.assertFalse(result['adopted_new_value'])
        self.assertEqual(result['configured_position_iterations'], 6)
        self.assertEqual(result['FA-3'], 'NOT RUN')

    def test_missing_sweep_data_is_not_a_zero_amplitude_result(self):
        from load_motion_sweep import summarize
        with tempfile.TemporaryDirectory() as folder:
            result = summarize(folder)
        self.assertTrue(all(c['status'] == 'NOT COMPLETED' for c in result['cases']))
        self.assertTrue(all('steady_max_endpoint_speed_range_wu_s' not in c for c in result['cases']))

    def _spawn_case(self, folder, height):
        import json
        root = Path(folder) / f'spawn-{height}'
        root.mkdir()
        rows = fixture()
        for row in rows:
            row['diagnostic_spawn_y_wu'] = float(height)
            head = row['other_bodies'][0]
            for key in ('ay', 'by', 'start_ay', 'start_by'):
                head[key] = float(height)
            head['bottom_wu'] = head['bottom_start_wu'] = float(height) - head['radius_wu']
        (root / 'engine-status.txt').write_text('0')
        (root / 'slug-600.jsonl').write_text(''.join(json.dumps(r) + '\n' for r in rows))
        return root, rows

    def test_spawn_all_three_at_configured_six_without_sleep_adoption(self):
        from load_spawn_report import summarize, HEIGHTS
        with tempfile.TemporaryDirectory() as folder:
            for height in HEIGHTS:
                self._spawn_case(folder, height)
            result = summarize(folder)
        self.assertTrue(all(c['status'] == 'OBSERVED' for c in result['cases']))
        self.assertEqual([c['spawn_y_wu'] for c in result['cases']], [.33, .53, .73])
        self.assertEqual(result['configured_position_iterations'], 6)
        self.assertFalse(result['comparison']['rest_or_sleep_definition_adopted'])
        self.assertEqual(result['FA-4'], 'NOT RUN')

    def test_missing_spawn_data_is_not_an_equilibrium(self):
        from load_spawn_report import summarize
        with tempfile.TemporaryDirectory() as folder:
            result = summarize(folder)
        self.assertEqual(result['comparison']['status'], 'INCOMPLETE')
        self.assertTrue(all(c['status'] == 'NOT COMPLETED' for c in result['cases']))
        self.assertTrue(all('last_p_y_ns' not in c for c in result['cases']))

    def test_spawn_rejects_mismatched_height_and_nonzero_initial_motion(self):
        import json
        from load_spawn_report import summarize
        for mode in ('height', 'motion'):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as folder:
                root, rows = self._spawn_case(folder, '0.33')
                if mode == 'height':
                    rows[99]['diagnostic_spawn_y_wu'] = .53
                else:
                    rows[0]['other_bodies'][0]['start_avx'] = .1
                (root / 'slug-600.jsonl').write_text(''.join(json.dumps(r) + '\n' for r in rows))
                result = summarize(folder)
            self.assertEqual(result['cases'][0]['status'], 'NOT COMPLETED')

    def test_spawn_rejects_iteration_change(self):
        import json
        from load_spawn_report import summarize
        with tempfile.TemporaryDirectory() as folder:
            root, rows = self._spawn_case(folder, '0.33')
            for row in rows:
                row['diagnostic_position_iterations'] = 12
            (root / 'slug-600.jsonl').write_text(''.join(json.dumps(r) + '\n' for r in rows))
            result = summarize(folder)
        self.assertEqual(result['cases'][0]['status'], 'NOT COMPLETED')

    def test_spawn_comparison_different_or_same_never_chooses_asleep(self):
        from load_spawn_report import comparison
        for values in ([.1, .2, .3], [.163, .163, .163]):
            cases = [{'status': 'OBSERVED', 'steady_p_y_range_ns': [v, v], 'last_p_y_ns': v} for v in values]
            result = comparison(cases)
            self.assertEqual(result['last300_momentum_envelopes_overlap'], values[0] == values[-1])
            self.assertAlmostEqual(result['last_tick_momentum_spread_ns'], max(values)-min(values))
            self.assertFalse(result['rest_or_sleep_definition_adopted'])

    def test_com_x_reconciliation_not_single_endpoint_velocity_comparison(self):
        from load_spawn_report import x_reconciliation
        row = fixture()[0]
        bodies = row['feet'] + row['other_bodies']
        head = row['other_bodies'][0]
        head['start_avx'] = .12
        dx = (.77 / 2) * .12 * .98 / 60 / 1.55
        for body in bodies:
            for end, index in (('a', 0), ('b', 2)):
                own_integration = body['start_' + end + 'vx'] * .98 / 60
                body[end + 'x'] = body['start_' + end + 'x'] + dx
                body['position_delta_wu']['integration'][index] = own_integration
                body['position_delta_wu']['hinge'][index] = dx - own_integration
        result = x_reconciliation(row)
        self.assertAlmostEqual(result['net_com_x_wu'], result['predictor_from_raw_start_vx_wu'])
        self.assertAlmostEqual(result['phase_com_x_wu']['hinge'], 0.0)
        self.assertEqual(result['completed_vx_dt_com_wu'], 0.0)


if __name__ == '__main__':
    unittest.main(verbosity=2)
