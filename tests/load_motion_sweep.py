#!/usr/bin/env python3
"""Diagnostic-only iteration sensitivity. Never select/adopt a value or change gates."""
import json
from pathlib import Path
import re
import sys
from load_trace_report import analyze, close
from load_motion_report import motion_profile

ITERATIONS = (1, 2, 4, 6, 12, 24)  # Experimental sample points, NOT adopted tunables.


def summarize(folder):
    configured = int(re.search(r'^physics_position_iterations = (\d+)$',
        (Path(__file__).resolve().parents[1] / 'core/tuning.tres').read_text(), re.M)[1])
    cases = []
    for iterations in ITERATIONS:
        root = Path(folder) / f'iterations-{iterations}'
        case = {'iterations': iterations, 'configured_resource_value': iterations == configured}
        try:
            if int((root / 'engine-status.txt').read_text()) != 0:
                raise ValueError('engine/script did not complete; inspect preserved log/partial trace')
            rows = [json.loads(line) for line in (root / 'slug-600.jsonl').read_text().splitlines()]
            report = analyze(rows)
            if report['diagnostic_position_iterations'] != iterations:
                raise ValueError('trace does not match requested diagnostic iteration count')
            motion, profile = motion_profile(rows, close)
            (root / 'slug-summary.json').write_text(json.dumps(report, indent=2) + '\n')
            (root / 'slug-motion-profile.jsonl').write_text(''.join(json.dumps(r) + '\n' for r in profile))
            validated = report['momentum_ledger_verified'] and motion['position_ledger_and_speed_identities_verified']
            case.update({
                'status': 'OBSERVED' if validated else 'BOOKKEEPING FINDING',
                'rows': len(rows), 'ledger_verified': bool(validated),
                'steady_max_endpoint_speed_range_wu_s': [
                    min(max(b['max_endpoint_speed_wu_s'] for b in r['bodies']) for r in profile[300:]),
                    max(max(b['max_endpoint_speed_wu_s'] for b in r['bodies']) for r in profile[300:])],
                'per_part_steady_max_endpoint_speed_ranges_wu_s': [
                    {'part': b['part'], 'range': b['steady_max_endpoint_speed_range_wu_s']} for b in motion['bodies']],
                'steady_momentum_range_ns': motion['momentum_final_observed_envelope_ns'],
                'last_per_part_net_delta_wu': [{'part': b['part'], 'delta': b['last_net_delta_wu']} for b in motion['bodies']],
                'steady_grip_fraction': motion['steady_grip_fraction'],
                'steady_foot_support_share_range': motion['steady_foot_support_share_range'],
                'all_grounded_force_window_within_literal_tolerance': report['force_window_within_owner_tolerance'],
                'first_tick_inside_final_observed_momentum_envelope': motion['first_tick_all_remaining_inside_final_observed_envelope'],
            })
        except (ValueError, KeyError, OSError, TypeError) as error:
            case.update(status='NOT COMPLETED', finding=str(error))
        cases.append(case)
    return {'scope': 'R11 F35 diagnostic sweep ONLY; not feel/FA/sleep/determinism acceptance',
            'configured_position_iterations': configured, 'adopted_new_value': False,
            'cases': cases, 'complete_creature_determinism_attempts': 0,
            'FA-3': 'NOT RUN', 'FA-4': 'NOT RUN', 'FA-5': 'NOT RUN', 'FA-6': 'NOT RUN'}


if __name__ == '__main__':
    report = summarize(sys.argv[1])
    Path(sys.argv[1], 'iteration-sweep.json').write_text(json.dumps(report, indent=2) + '\n')
    for case in report['cases']:
        print('M1 sweep row: ' + json.dumps(case, sort_keys=True))
    print('M1 sweep scope: diagnostic ONLY; resource unchanged; NO new value adopted; NOT rest/sleep acceptance')
    raise SystemExit(0 if all(c['status'] == 'OBSERVED' for c in report['cases']) else 1)
