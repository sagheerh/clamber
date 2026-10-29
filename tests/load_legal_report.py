#!/usr/bin/env python3
"""R15 legal paired awake diagnostics; no sampling change or causal landing-depth claim."""
from collections import Counter
from copy import deepcopy
import json
import math
from pathlib import Path
import sys
from load_trace_report import analyze
from load_contact_report import inspect


def validate_counts(rows):
    """Required MAIN-trace fields, independently checked against every raw candidate."""
    regimes = []
    for row in rows:
        parts = sorted(b['part'] for b in row['feet'] + row['other_bodies'])
        expected = {(p, v) for p in parts for v in range(2)}
        counts = {}
        for c in row['contact_counts']:
            key = (c['part'], c['velocity_pass'])
            if key not in expected or key in counts:
                raise ValueError('Missing/duplicate/foreign per-body/pass counts')
            if any(type(c[k]) is not int for k in ('intervals', 'candidate_count', 'active_count')):
                raise ValueError('Count fields must be integers')
            if not (c['intervals'] >= 1 and c['candidate_count'] == c['intervals'] + 1 and 0 <= c['active_count'] <= c['candidate_count']):
                raise ValueError('Invalid interval/candidate/active counts')
            events = [e for e in row['contact_samples'] if (e['part'], e['velocity_pass']) == key]
            if (len(events) != c['candidate_count'] or sum(e['active'] for e in events) != c['active_count'] or
                any(e['intervals'] != c['intervals'] for e in events) or
                [e['sample_index'] for e in events] != list(range(c['candidate_count']))):
                raise ValueError('Main counts disagree with raw candidate observations')
            counts[key] = (c['intervals'], c['candidate_count'], c['active_count'])
        if set(counts) != expected:
            raise ValueError('Every body/pass is required, even airborne')
        regimes.append(counts)
    return regimes


def count_summary(regimes):
    if not regimes:
        raise ValueError('No count evidence')
    return {f'part{p}/pass{v}': {
        label: {','.join(map(str, k)): n for k, n in sorted(Counter(r[p, v] for r in selected).items())}
        for label, selected in [('all600', regimes), ('last300', regimes[-300:])]
    } for p, v in sorted(regimes[0])}


def accepted_view(rows):
    """Keep accepted analyzer/control source unchanged. Explicit lossless phase adapter:
    raw angular/self rows are FIRST verified independently then folded into its
    historical internal-position column. No physical value/count is altered.
    """
    adapted = deepcopy(rows)
    for row in adapted:
        for b in row['feet'] + row['other_bodies']:
            phases = b['position_delta_wu']
            if row['diagnostic_actuated']:
                if set(phases) != {'integration', 'distance', 'hinge', 'contact', 'angular', 'self_contact'}:
                    raise ValueError('Missing actuated position phase')
                for i, end in enumerate(('ax', 'ay', 'bx', 'by')):
                    net = b[end] - b['start_' + end]
                    if not all(math.isfinite(p[i]) for p in phases.values()) or abs(net - math.fsum(p[i] for p in phases.values())) > 1e-12:
                        raise ValueError('Raw actuated position ledger does not close')
                    phases['hinge'][i] = math.fsum(phases[k][i] for k in ('hinge', 'angular', 'self_contact'))
                del phases['angular'], phases['self_contact']
    return adapted


def compare(root):
    result = {'scope': 'R15 derived legal +.01WU; awake zero-input; NOT FA/public Sim/creature determinism',
              'count_tuple': ['intervals', 'candidate_count', 'active_count'], 'cases': {}}
    regimes = {}
    for mechanics in ('baseline', 'actuated'):
        for pose in ('before', 'after'):
            name = mechanics + '-' + pose
            folder = Path(root, name)
            try:
                if (folder/'engine-status.txt').read_text().strip() != '0':
                    raise ValueError('Engine incomplete')
                rows = [json.loads(s) for s in (folder/'slug-600.jsonl').read_text().splitlines()]
                if len(rows) != 600 or [r['tick'] for r in rows] != list(range(600)):
                    raise ValueError('Required main600 trace incomplete')
                for r in rows:
                    if (r['diagnostic_pose'] != pose or r['diagnostic_actuated'] != (mechanics == 'actuated') or
                        r['diagnostic_spawn_kind'] != 'derived legal +.01WU' or
                        abs(r['diagnostic_lowest_initial_surface_wu'] - .01) > 1e-15 or
                        abs(r['diagnostic_spawn_y_wu'] + r['diagnostic_authored_bottom_wu'] - .01) > 1e-15 or
                        r['diagnostic_position_iterations'] != 6 or r['diagnostic_static_slip_wu_s'] != .15 or r['sleep_implemented']):
                        raise ValueError('Legal pair metadata mismatch')
                regimes[name] = validate_counts(rows)
                adapted = accepted_view(rows)
                a, c = analyze(adapted), inspect(adapted)[0]
                if not a['momentum_ledger_verified'] or not a['motion']['position_ledger_and_speed_identities_verified']:
                    raise ValueError('Accepted independent physical verifiers failed')
                result['cases'][name] = {'status': 'OBSERVED', 'rows': 600,
                    'spawn_root_y_wu': rows[0]['diagnostic_spawn_y_wu'],
                    'lowest_initial_surface_wu': rows[0]['diagnostic_lowest_initial_surface_wu'],
                    'counts': count_summary(regimes[name]),
                    'last300_com_dx_wu_tick': c['steady_mean_com_dx_wu_tick'],
                    'last300_com_vx_range_wu_s': c['steady_completed_com_vx_range_wu_s'],
                    'grounded_sets': c['steady_grounded_sets'],
                    'grip_ticks': len(a['grip_engaged_ticks']), 'grip_toggle_ticks': a['grip_toggle_ticks'],
                    'first_grip_tick': next(iter(a['grip_engaged_ticks']), None),
                    'last300_grip_fraction': a['motion']['steady_grip_fraction'],
                    'last300_foot_support_share': a['motion']['steady_foot_support_share_mean'],
                    'momentum_and_position_verifiers': True,
                    'internal_position_phase_adapter': mechanics == 'actuated'}
            except (OSError, ValueError, KeyError, TypeError) as e:
                result['cases'][name] = {'status': 'NOT COMPLETED', 'finding': str(e)}
    result['F41'] = {}
    for mechanics in ('baseline', 'actuated'):
        names = [mechanics + '-' + p for p in ('before', 'after')]
        cases = [result['cases'][n] for n in names]
        if not all(c['status'] == 'OBSERVED' for c in cases):
            result['F41'][mechanics] = {'status': 'BLOCKED: incomplete legal/count evidence'}
            continue
        matching = regimes[names[0]][300:] == regimes[names[1]][300:]
        a, b = [c['last300_com_dx_wu_tick'] for c in cases]
        result['F41'][mechanics] = {'before_dx_wu_tick': a, 'after_dx_wu_tick': b, 'difference_wu_tick': b-a,
            'last300_count_regimes_identical': matching,
            'pose_causal_interpretation': 'NOT ESTABLISHED; geometry/count confounding' if not matching else 'NOT ESTABLISHED; observational pair, not causal proof',
            'absolute_drift_smaller_observed_only': abs(b) < abs(a),
            'landing_depth_causal_claim': False}
    return result


if __name__ == '__main__':
    r = compare(sys.argv[1])
    Path(sys.argv[1], 'legal-comparison.json').write_text(json.dumps(r, indent=2) + '\n')
    for name, c in r['cases'].items():
        print('M1 legal ' + name + ': ' + json.dumps(c, sort_keys=True))
    print('M1 legal F41: ' + json.dumps(r['F41'], sort_keys=True))
    raise SystemExit(0 if all(c['status'] == 'OBSERVED' for c in r['cases'].values()) else 1)
