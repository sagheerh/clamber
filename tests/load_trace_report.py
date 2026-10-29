#!/usr/bin/env python3
"""Raw Slug diagnostic: all-contact conservation is separate from F30 foot-path blocker."""
import json
import math
import re
from pathlib import Path
import sys
from load_motion_report import motion_profile

WEIGHT_N = 43.4
CEILING_N = 0.723  # Owner literal, NOT rounded upward to W/60.
# Read the actual resource; this is a diagnostic identity, not a new tuning default.
LINEAR_DAMPING = float(re.search(r'^physics_linear_damping = (.+)$',
    (Path(__file__).resolve().parents[1] / 'core/tuning.tres').read_text(), re.M)[1])
IDENTITY_EPS = 1e-12  # Float64 bookkeeping only; NEVER added to force acceptance.


def close(a, b):
    return math.isclose(a, b, rel_tol=0, abs_tol=IDENTITY_EPS)


def body_momentum(bodies, start=False):
    result = 0.0
    prefix = 'start_' if start else ''
    for body in sorted(bodies, key=lambda b: b['part']):
        for end in ('a', 'b'):
            result += body[prefix + end + 'vy'] / body['inverse_mass_' + end]
    return result


def sustained_support(rows):
    """R16/F47 diagnostic gate, NOT FA-5. No physics/tuning change.

    Last300 must contain a grounded, gripping foot with positive velocity-level
    reaction supplying STRICTLY more than half ALL grounded reaction at that
    SAME tick. Landing-only grip, split support and positional cleanup cannot pass.
    """
    window = rows[-300:]
    majority_ticks = []
    shares = []
    for r in window:
        total = math.fsum(b['measured_reaction_n'] for b in r['feet'] + r['other_bodies'] if b['grounded'])
        candidates = [(f, f['measured_reaction_n'] / total) for f in r['feet'] if f['grounded']] if total > 0 else []
        shares.extend(share for _, share in candidates)
        if any(f['gripping'] and f['measured_reaction_n'] > 0 and share > .50 for f, share in candidates):
            majority_ticks.append(r['tick'])
    fraction = sum(any(f['gripping'] for f in r['feet']) for r in window) / len(window)
    return {'definition': 'last300 grip fraction>0 AND same-tick grounded gripping positive-reaction single-foot share>0.50',
            'window_ticks': [window[0]['tick'], window[-1]['tick']],
            'grip_fraction': fraction, 'max_single_foot_grounded_support_share': max(shares, default=0.0),
            'loaded_majority_grip_ticks': majority_ticks,
            'passed': fraction > 0 and bool(majority_ticks)}


def analyze(rows):
    if len(rows) != 600:
        raise ValueError(f'Expected all 600 raw rows, got {len(rows)}')
    previous = 0
    toggles = []
    engaged = []
    loaded_grip = []
    last_grip = None
    totals = []
    ledgers = []
    for tick, row in enumerate(rows):
        if row['tick'] != tick or row['status'] != 0:
            raise ValueError('Missing/reordered/failed tick')
        if row['previous_grounded_feet'] != previous:
            raise ValueError('N is not the previous completed tick count')
        if not math.isfinite(row['weight_n']) or abs(row['weight_n'] - WEIGHT_N) > 1e-12:
            raise ValueError('Not the unchanged Slug weight')
        if row['sleep_state'] not in ('awake', 'asleep') or not isinstance(row['sleep_implemented'], bool):
            raise ValueError('Missing explicit sleep state/scope')
        bodies = row['feet'] + row['other_bodies']
        if sorted(b['part'] for b in bodies) != [0, 1, 2]:
            raise ValueError('Missing/duplicate Slug body telemetry')
        for body in bodies:
            geometry_keys = ('mass', 'radius_wu', 'inverse_mass_a', 'inverse_mass_b',
                             'ax', 'ay', 'bx', 'by', 'avx', 'avy', 'bvx', 'bvy',
                             'start_ax', 'start_ay', 'start_bx', 'start_by',
                             'start_avy', 'start_bvy', 'bottom_wu', 'bottom_start_wu')
            if not all(math.isfinite(body[k]) for k in geometry_keys):
                raise ValueError('Non-finite body geometry/motion')
            if any(body[k] <= 0 for k in ('mass', 'radius_wu', 'inverse_mass_a', 'inverse_mass_b')):
                raise ValueError('Invalid body mass/radius')
            if not close(body['bottom_wu'], min(body['ay'], body['by']) - body['radius_wu']):
                raise ValueError('Completed bottom does not match endpoints/radius')
            if not close(body['bottom_start_wu'], min(body['start_ay'], body['start_by']) - body['radius_wu']):
                raise ValueError('Start bottom does not match endpoints/radius')
            if not isinstance(body['grounded'], bool):
                raise ValueError('Missing actual post-resolve grounded flag')
            if not all(math.isfinite(body[k]) and body[k] >= 0 for k in
                       ('applied_load_n', 'measured_reaction_n', 'positional_cleanup_n')):
                raise ValueError('Non-finite/negative force channel')
        for key in ('applied_load_n', 'measured_reaction_n', 'positional_cleanup_n'):
            values = [foot[key] for foot in row['feet']]
            if not values or row['sum_' + key] != math.fsum(values):
                raise ValueError('Trace sum does not match raw foot channels')
        if row['other_body_reaction_n'] != math.fsum(b['measured_reaction_n'] for b in row['other_bodies']):
            raise ValueError('Other-body sum does not match raw channels')
        for foot in row['feet']:
            if not isinstance(foot['gripping'], bool) or not isinstance(foot['lowest'], bool):
                raise ValueError('Missing actual post-resolve flags')
            if not math.isfinite(foot['penetration_wu']):
                raise ValueError('Missing raw penetration')
            if previous == 0 and foot['gripping']:
                raise ValueError('N0 illegally gripped')
            if foot['gripping'] and (not foot['grounded'] or not foot['lowest'] or
                                     foot['applied_load_n'] < max(5, .40 * WEIGHT_N / previous)):
                raise ValueError('Grip claims not backed by eligibility/qualifying real channel')
        grip = tuple(foot['gripping'] for foot in row['feet'])
        if any(grip):
            engaged.append(tick)
        if any(f['gripping'] and f['measured_reaction_n'] > 0 for f in row['feet']):
            loaded_grip.append(tick)
        if last_grip is not None and last_grip != grip:
            toggles.append(tick)
        last_grip = grip
        previous = sum(foot['grounded'] for foot in row['feet'])
        totals.append({key: math.fsum(b[key] for b in bodies if b['grounded'])
                       for key in ('applied_load_n', 'measured_reaction_n')})
        # Independent reconstruction from raw endpoint velocities, not claimed totals.
        budget = row['momentum_budget']
        if not all(math.isfinite(value) for value in budget.values()) or budget['dt_s'] != 1 / 60:
            raise ValueError('Invalid fixed-tick momentum budget')
        dt = budget['dt_s']
        before = body_momentum(bodies, True)
        after = body_momentum(bodies)
        change = after - before
        contact = math.fsum(b['measured_reaction_n'] for b in bodies) * dt
        damping = budget['damping_impulse_y_ns']
        clamp = budget['clamp_impulse_y_ns']
        internal = budget['internal_impulse_y_ns']
        residual = change - (budget['gravity_impulse_y_ns'] + damping + clamp + internal + contact)
        predicted = (change - damping - clamp - internal) / dt
        observed = contact / dt - WEIGHT_N
        expected = {
            'momentum_before_y_ns': before, 'momentum_after_y_ns': after,
            'momentum_change_y_ns': change, 'gravity_impulse_y_ns': -WEIGHT_N * dt,
            'damping_impulse_y_ns': -LINEAR_DAMPING * before,
            'contact_reported_impulse_y_ns': contact, 'residual_y_ns': residual,
            'predicted_support_bias_n': predicted, 'observed_support_bias_n': observed,
        }
        ledgers.append({
            'claimed_terms_match_raw': all(close(budget[k], v) for k, v in expected.items()),
            'residual_y_ns': residual,
            'contact_cross_error_ns': budget['contact_velocity_impulse_y_ns'] - contact,
            'bias_error_n': observed - predicted,
            'internal_impulse_y_ns': internal,
        })
    window = rows[300:]
    steady_totals = totals[300:]
    maxima = {
        'all_grounded_applied_vs_weight_n': max(abs(r['applied_load_n'] - WEIGHT_N) for r in steady_totals),
        'all_grounded_reaction_vs_weight_n': max(abs(r['measured_reaction_n'] - WEIGHT_N) for r in steady_totals),
        'all_grounded_applied_vs_reaction_n': max(abs(r['applied_load_n'] - r['measured_reaction_n']) for r in steady_totals),
    }
    ledger_good = all(r['claimed_terms_match_raw'] and abs(r['residual_y_ns']) <= IDENTITY_EPS and
                      abs(r['contact_cross_error_ns']) <= IDENTITY_EPS and
                      abs(r['bias_error_n']) <= IDENTITY_EPS and
                      abs(r['internal_impulse_y_ns']) <= IDENTITY_EPS for r in ledgers)
    motion, _ = motion_profile(rows, close)
    support_gate = sustained_support(rows)
    iterations = {r['diagnostic_position_iterations'] for r in rows}
    if len(iterations) != 1 or next(iter(iterations)) <= 0:
        raise ValueError('Mixed/invalid diagnostic iteration count')
    return {
        'diagnostic_position_iterations': next(iter(iterations)),
        'motion': motion,
        'scope': 'hinged engineering load probe, NOT FA acceptance or determinism',
        'rows': len(rows), 'steady_window_ticks': [300, 599], 'ceiling_n': CEILING_N,
        'invariant': 'ALL grounded contacts vs weight; foot-only vs weight ONLY for sole-foot support',
        'max_absolute_errors_n': maxima,
        'force_window_within_owner_tolerance': all(v <= CEILING_N for v in maxima.values()),
        'momentum_ledger_verified': ledger_good,
        'source_linear_damping': LINEAR_DAMPING,
        'ledger_identity_epsilon': IDENTITY_EPS,
        'ledger_maxima': {key: max(abs(r[key]) for r in ledgers)
                          for key in ('residual_y_ns', 'contact_cross_error_ns', 'bias_error_n', 'internal_impulse_y_ns')},
        'steady_momentum_budget_ranges': {
            key: [min(r['momentum_budget'][key] for r in window),
                  max(r['momentum_budget'][key] for r in window)]
            for key in window[0]['momentum_budget']
        },
        'bias_equation': 'R-W=(dP_y-J_damping-J_clamp-J_internal)/dt; gravity=-W*dt; no force correction',
        'grip_engaged_ticks': engaged,
        'grip_engagement': 'grip engaged' if engaged else 'grip never engaged',
        'foot_load_path_exercised': support_gate['passed'],
        'sustained_support_gate': support_gate,
        'loaded_grip_ticks': loaded_grip,
        'grip_toggle_ticks': toggles,
        'steady_ranges_n': {
            key: [min(r[key] for r in window), max(r[key] for r in window)]
            for key in ('sum_applied_load_n', 'sum_measured_reaction_n', 'sum_positional_cleanup_n')
        },
        'all_terrain_reaction_range_n': [min(r['measured_reaction_n'] for r in steady_totals),
                                         max(r['measured_reaction_n'] for r in steady_totals)],
        'peak_foot_applied_n': max(f['applied_load_n'] for r in rows for f in r['feet']),
        'peak_foot_measured_n': max(f['measured_reaction_n'] for r in rows for f in r['feet']),
        'steady_peak_foot_measured_n': max(f['measured_reaction_n'] for r in window for f in r['feet']),
        'first': rows[0], 'last': rows[-1],
        'limitations': ['F30 authored pose decision PENDING; no pose/radius/angular-limit changes',
                        'free rotational hinges; angular limits/motors/self-response absent',
                        'sleep is not implemented; all rows remain awake'],
        'FA-3': 'NOT RUN', 'FA-4': 'NOT RUN', 'FA-5': 'NOT RUN', 'FA-6': 'NOT RUN',
        'complete_creature_determinism_attempts': 0,
    }


def diagnostic_summary(rows):
    # F31 math/ledger is unchanged; R16/F47 explicitly replaces the load-path gate.
    summary = analyze(rows)
    summary['owner_decisions'] = 'R14 A/A1 pose and positional sleep/F42 APPROVED'
    summary['limitations'] = [
        'R14 axis-only pose applied; transient grip is NOT sustained sole-foot support',
        'free rotational hinges; angular limits/motors/self-response absent',
        'awake-only diagnostic; tested positional sleep composition deliberately disabled here',
    ]
    return summary


if __name__ == '__main__':
    rows = [json.loads(line) for line in Path(sys.argv[1]).read_text().splitlines()]
    summary = diagnostic_summary(rows)
    Path(sys.argv[2]).write_text(json.dumps(summary, indent=2) + '\n')
    _, profile = motion_profile(rows, close)
    Path(sys.argv[2]).with_name('slug-motion-profile.jsonl').write_text(
        ''.join(json.dumps(r, sort_keys=True) + '\n' for r in profile))
    from load_contact_report import save
    contacts = save(Path(sys.argv[2]).parent, rows)
    print('M1 Slug contact verification: ' + json.dumps({k: contacts[k] for k in
        ('sample_events', 'observer_on_off_equal_ticks', 'steady_ticks_with_any_active_sample',
         'steady_new_grounded_transition_count', 'steady_grounded_sets', 'sleep_breaking_interpretation')}))
    good = summary['force_window_within_owner_tolerance']
    print('M1 Slug force window (ALL grounded): ' + ('WITHIN TOLERANCE' if good else 'FINDING (outside fixed tolerance)'))
    for label, key in [('errors', 'max_absolute_errors_n'), ('ranges', 'steady_ranges_n'),
                       ('all-terrain reaction', 'all_terrain_reaction_range_n'),
                       ('momentum ledger maxima', 'ledger_maxima'),
                       ('momentum ledger verified', 'momentum_ledger_verified'),
                       ('momentum budget ranges', 'steady_momentum_budget_ranges'),
                       ('first', 'first'), ('last', 'last'), ('grip toggle ticks', 'grip_toggle_ticks')]:
        print('M1 Slug ' + label + ': ' + json.dumps(summary[key], sort_keys=True))
    motion = summary['motion']
    for body in motion['bodies']:
        print('M1 Slug motion part: ' + json.dumps(body, sort_keys=True))
    print('M1 Slug motion summary: ' + json.dumps({k: v for k, v in motion.items() if k != 'bodies'}, sort_keys=True))
    from load_convergence_report import drift_summary
    print('M1 Slug zero-input drift: ' + json.dumps(drift_summary(rows), sort_keys=True))
    print('M1 Slug engagement: ' + summary['grip_engagement'])
    print('M1 Slug sustained-support gate: ' + json.dumps(summary['sustained_support_gate'], sort_keys=True))
    print('M1 Slug peaks: applied=' + str(summary['peak_foot_applied_n']) +
          'N measured=' + str(summary['peak_foot_measured_n']) + 'N (all600), steady measured=' + str(summary['steady_peak_foot_measured_n']) +
          'N; N1 gate=17.36N')
    if not summary['foot_load_path_exercised']:
        print('M1 Slug F30 BLOCKED: authored R14 A/A1 applied, but sustained majority foot support not exercised (R16/F47)')
    raise SystemExit(0 if good and summary['momentum_ledger_verified'] and motion['position_ledger_and_speed_identities_verified'] and summary['foot_load_path_exercised'] else 1)
