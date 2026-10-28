#!/usr/bin/env python3
"""Synthetic parser falsification; these rows are NOT physics evidence."""
import copy
import unittest
from load_trace_report import analyze


def fixture():
    rows = []
    for tick in range(600):
        rows.append({
            'tick': tick, 'status': 0, 'previous_grounded_feet': 0 if tick == 0 else 1,
            'weight_n': 43.4, 'sleep_state': 'awake', 'sleep_implemented': False,
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


if __name__ == '__main__':
    unittest.main(verbosity=2)
