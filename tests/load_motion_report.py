"""F35/F37 observation only. No sleep predicate, velocity epsilon, or acceptance band."""
import math

PHASES = ('integration', 'distance', 'hinge', 'contact')
COORDS = ('ax', 'ay', 'bx', 'by')


def motion_profile(rows, close):
    profile = []
    verified = True
    residual_max = 0.0
    for row in rows:
        dt = row['momentum_budget']['dt_s']
        bodies = sorted(row['feet'] + row['other_bodies'], key=lambda b: b['part'])
        parts = []
        for body in bodies:
            speeds = [math.hypot(body[e + 'vx'], body[e + 'vy']) for e in ('a', 'b')]
            com = math.hypot((body['avx'] + body['bvx']) / 2, (body['avy'] + body['bvy']) / 2)
            verified &= all(close(body[k], value) for k, value in
                            [('speed_a_wu_s', speeds[0]), ('speed_b_wu_s', speeds[1]),
                             ('com_speed_wu_s', com)])
            phases = body['position_delta_wu']
            if set(phases) != set(PHASES) or any(len(phases[p]) != 4 for p in PHASES):
                raise ValueError('Missing endpoint position phase')
            if not all(math.isfinite(v) for p in PHASES for v in phases[p]):
                raise ValueError('Nonfinite position phase')
            net = [body[c] - body['start_' + c] for c in COORDS]
            residual = [net[i] - math.fsum(phases[p][i] for p in PHASES) for i in range(4)]
            residual_max = max(residual_max, *(abs(v) for v in residual))
            verified &= all(close(v, 0.0) for v in residual)
            completed_v_dt = [body[e + v] * dt for e in ('a', 'b') for v in ('vx', 'vy')]
            # End-of-tick velocity is NOT the same-tick predictor velocity. Show
            # both, rather than pretending contact undoes dt*v_completed directly.
            phase_offset = [phases['integration'][i] - completed_v_dt[i] for i in range(4)]
            parts.append({
                'part': body['part'], 'kind': body.get('kind', 'foot'),
                'endpoint_speeds_wu_s': speeds, 'com_speed_wu_s': com,
                'max_endpoint_speed_wu_s': max(speeds),
                'net_delta_wu': net, 'position_delta_wu': phases,
                'completed_velocity_dt_wu': completed_v_dt,
                'predictor_minus_completed_velocity_dt_wu': phase_offset,
                'position_residual_wu': residual,
            })
        grounded_total = math.fsum(b['measured_reaction_n'] for b in bodies if b['grounded'])
        grounded_foot = math.fsum(b['measured_reaction_n'] for b in row['feet'] if b['grounded'])
        profile.append({
            'tick': row['tick'], 'momentum_start_y_ns': row['momentum_budget']['momentum_before_y_ns'], 'momentum_y_ns': row['momentum_budget']['momentum_after_y_ns'],
            'gripping': any(f['gripping'] for f in row['feet']),
            'foot_support_share': grounded_foot / grounded_total if grounded_total else None,
            'bodies': parts,
        })
    ps = [r['momentum_y_ns'] for r in profile]
    low, high = min(ps[300:]), max(ps[300:])
    outside = [i for i, value in enumerate(ps) if not low <= value <= high]
    first_envelope = max(outside, default=-1) + 1
    last_change = max((i for i in range(1, len(ps)) if ps[i] != ps[i-1]), default=0)
    exact_suffix = last_change if last_change < len(ps)-1 else None
    # All600 values + per-part phase vectors stay in the profile artifact.
    for row in profile:
        row['momentum_distance_from_final_ns'] = abs(row['momentum_y_ns'] - ps[-1])
    steady = profile[300:]
    parts_summary = []
    for index, body in enumerate(profile[-1]['bodies']):
        observed = [r['bodies'][index] for r in steady]
        parts_summary.append({
            'part': body['part'], 'kind': body['kind'],
            'steady_max_endpoint_speed_range_wu_s': [min(b['max_endpoint_speed_wu_s'] for b in observed),
                                                     max(b['max_endpoint_speed_wu_s'] for b in observed)],
            'steady_com_speed_range_wu_s': [min(b['com_speed_wu_s'] for b in observed), max(b['com_speed_wu_s'] for b in observed)],
            'last_endpoint_speeds_wu_s': body['endpoint_speeds_wu_s'],
            'last_net_delta_wu': body['net_delta_wu'],
            'last_position_delta_wu': body['position_delta_wu'],
            'last_completed_velocity_dt_wu': body['completed_velocity_dt_wu'],
            'last_predictor_minus_completed_velocity_dt_wu': body['predictor_minus_completed_velocity_dt_wu'],
            'steady_phase_y_ranges_wu': {
                phase: [[min(b['position_delta_wu'][phase][i] for b in observed),
                         max(b['position_delta_wu'][phase][i] for b in observed)] for i in (1, 3)]
                for phase in PHASES
            },
        })
    shares = [r['foot_support_share'] for r in steady if r['foot_support_share'] is not None]
    summary = {
        'scope': 'F35 observation, NOT rest/sleep acceptance; NO velocity epsilon',
        'position_ledger_and_speed_identities_verified': bool(verified),
        'max_position_ledger_residual_wu': residual_max,
        'momentum_final_observed_envelope_ns': [low, high],
        'first_tick_all_remaining_inside_final_observed_envelope': first_envelope,
        'first_tick_exact_constant_suffix_at_least_two_rows': exact_suffix,
        'envelope_definition': 'Observed ticks300..599 min/max, NOT an invented velocity/rest tolerance',
        'decay_samples': [{'tick': i, 'p_y_ns': ps[i], 'distance_from_final_ns': abs(ps[i]-ps[-1]),
                          'max_endpoint_speed_wu_s': max(b['max_endpoint_speed_wu_s'] for b in profile[i]['bodies'])}
                         for i in (0, 1, 2, 5, 10, 20, 30, 60, 120, 180, 240, 299, 300, 599)],
        'steady_grip_ticks': sum(r['gripping'] for r in steady),
        'steady_grip_fraction': sum(r['gripping'] for r in steady) / len(steady),
        'steady_foot_support_share_range': [min(shares), max(shares)] if shares else None,
        'steady_foot_support_share_mean': math.fsum(shares) / len(shares) if shares else None,
        'steady_undefined_support_share_ticks': len(steady)-len(shares),
        'path_exists_scope': 'At least one loaded gripping tick only; NOT sustained support or a new acceptance threshold',
        'bodies': parts_summary,
    }
    return summary, profile
