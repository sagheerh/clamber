#!/usr/bin/env python3
"""R12 F38: three spawn heights, unchanged model. Observations, NEVER sleep choices."""
import json
import math
from pathlib import Path
import re
import sys
from load_trace_report import analyze, close, LINEAR_DAMPING
from load_motion_report import motion_profile

HEIGHTS = ('0.33', '0.53', '0.73')


def x_reconciliation(row):
    """Existing phase telemetry: do not infer COM injection from a single endpoint."""
    bodies = row['feet'] + row['other_bodies']
    mass = math.fsum(1 / b['inverse_mass_' + e] for b in bodies for e in ('a', 'b'))
    dt = row['momentum_budget']['dt_s']
    def weighted(values):
        return math.fsum(values(b, e, i) / b['inverse_mass_' + e]
                         for b in bodies for e, i in (('a', 0), ('b', 2))) / mass
    return {
        'mass_kg': mass,
        'net_com_x_wu': weighted(lambda b, e, i: b[e + 'x'] - b['start_' + e + 'x']),
        'phase_com_x_wu': {p: weighted(lambda b, e, i: b['position_delta_wu'][p][i])
                          for p in ('integration', 'distance', 'hinge', 'contact')},
        'predictor_from_raw_start_vx_wu': weighted(lambda b, e, i: b['start_' + e + 'vx'] * (1 - LINEAR_DAMPING) * dt),
        'completed_vx_dt_com_wu': weighted(lambda b, e, i: b[e + 'vx'] * dt),
    }


def comparison(cases):
    observed = [c for c in cases if c['status'] == 'OBSERVED']
    if len(observed) != 3:
        return {'status': 'INCOMPLETE', 'rest_or_sleep_definition_adopted': False}
    return {
        'status': 'OBSERVED',
        'last300_momentum_envelopes_overlap': max(c['steady_p_y_range_ns'][0] for c in observed) <=
                                            min(c['steady_p_y_range_ns'][1] for c in observed),
        'last_tick_momentum_spread_ns': max(c['last_p_y_ns'] for c in observed) - min(c['last_p_y_ns'] for c in observed),
        'scope': 'Finite600-tick spawn sensitivity only, NOT proof of a global rest attractor or sleep acceptance',
        'rest_or_sleep_definition_adopted': False,
    }


def summarize(folder):
    resource = (Path(__file__).resolve().parents[1] / 'core/tuning.tres').read_text()
    configured = int(re.search(r'^physics_position_iterations = (\d+)$', resource, re.M)[1])
    cases = []
    for height in HEIGHTS:
        root = Path(folder) / f'spawn-{height}'
        case = {'spawn_y_wu': float(height), 'position_iterations': configured}
        try:
            if int((root / 'engine-status.txt').read_text()) != 0:
                raise ValueError('engine/script did not complete; inspect partial trace/log')
            rows = [json.loads(line) for line in (root / 'slug-600.jsonl').read_text().splitlines()]
            report = analyze(rows)
            if configured != 6 or report['diagnostic_position_iterations'] != configured:
                raise ValueError('R12 requires unchanged configured6 position iterations')
            if any(r['diagnostic_spawn_y_wu'] != float(height) for r in rows):
                raise ValueError('missing/mixed/wrong spawn metadata')
            first = rows[0]['feet'] + rows[0]['other_bodies']
            head = next(b for b in first if b['part'] == 0)
            if head['start_ax'] != 0.0 or head['start_ay'] != float(height):
                raise ValueError('raw initial root does not match requested spawn')
            if any(b['start_' + e + v] != 0.0 for b in first for e in ('a', 'b') for v in ('vx', 'vy')):
                raise ValueError('spawn experiment must start from zero motion')
            motion, profile = motion_profile(rows, close)
            (root / 'slug-summary.json').write_text(json.dumps(report, indent=2) + '\n')
            (root / 'slug-motion-profile.jsonl').write_text(''.join(json.dumps(r) + '\n' for r in profile))
            ps = [r['momentum_budget']['momentum_after_y_ns'] for r in rows[300:]]
            mass = math.fsum(b['mass'] for b in rows[-1]['feet'] + rows[-1]['other_bodies'])
            verified = report['momentum_ledger_verified'] and motion['position_ledger_and_speed_identities_verified']
            case.update({
                'status': 'OBSERVED' if verified else 'BOOKKEEPING FINDING',
                'rows': len(rows), 'ledger_verified': bool(verified),
                'steady_p_y_range_ns': [min(ps), max(ps)],
                'steady_p_y_mean_ns': math.fsum(ps) / len(ps),
                'last_p_y_ns': rows[-1]['momentum_budget']['momentum_after_y_ns'],
                'last_com_vy_wu_s': rows[-1]['momentum_budget']['momentum_after_y_ns'] / mass,
                'first_tick_inside_final_observed_p_envelope': motion['first_tick_all_remaining_inside_final_observed_envelope'],
                'steady_max_endpoint_speed_range_wu_s': [
                    min(max(b['max_endpoint_speed_wu_s'] for b in r['bodies']) for r in profile[300:]),
                    max(max(b['max_endpoint_speed_wu_s'] for b in r['bodies']) for r in profile[300:])],
                'steady_grip_fraction': motion['steady_grip_fraction'],
                'steady_foot_support_share_mean': motion['steady_foot_support_share_mean'],
                'all_grounded_force_window_within_literal_tolerance': report['force_window_within_owner_tolerance'],
                'last_x_reconciliation': x_reconciliation(rows[-1]),
            })
        except (ValueError, KeyError, OSError, TypeError, StopIteration) as error:
            case.update(status='NOT COMPLETED', finding=str(error))
        cases.append(case)
    return {'scope': 'R12 three-spawn observation ONLY, no behavior/pose/asleep/iteration change',
            'configured_position_iterations': configured, 'cases': cases, 'comparison': comparison(cases),
            'FA-3': 'NOT RUN', 'FA-4': 'NOT RUN', 'FA-5': 'NOT RUN', 'FA-6': 'NOT RUN',
            'complete_creature_determinism_attempts': 0}


if __name__ == '__main__':
    report = summarize(sys.argv[1])
    Path(sys.argv[1], 'spawn-comparison.json').write_text(json.dumps(report, indent=2) + '\n')
    for case in report['cases']:
        print('M1 spawn row: ' + json.dumps(case, sort_keys=True))
    print('M1 spawn comparison: ' + json.dumps(report['comparison'], sort_keys=True))
    print('M1 spawn scope: unchanged6 iterations; no rest definition/model/pose adopted; no velocity epsilon')
    raise SystemExit(0 if all(c['status'] == 'OBSERVED' for c in report['cases']) else 1)
