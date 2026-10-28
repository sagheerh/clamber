#!/usr/bin/env python3
"""Validate raw Slug rows independently; force findings fail, never waive or smooth."""
import json
import math
from pathlib import Path
import sys

WEIGHT_N = 43.4
CEILING_N = 0.723  # Owner literal, NOT rounded upward to W/60.


def analyze(rows):
    if len(rows) != 600:
        raise ValueError(f'Expected all 600 raw rows, got {len(rows)}')
    previous = 0
    toggles = []
    last_grip = None
    for tick, row in enumerate(rows):
        if row['tick'] != tick or row['status'] != 0:
            raise ValueError('Missing/reordered/failed tick')
        if row['previous_grounded_feet'] != previous:
            raise ValueError('N is not the previous completed tick count')
        if not math.isfinite(row['weight_n']) or abs(row['weight_n'] - WEIGHT_N) > 1e-12:
            raise ValueError('Not the unchanged Slug weight')
        if row['sleep_state'] not in ('awake', 'asleep') or not isinstance(row['sleep_implemented'], bool):
            raise ValueError('Missing explicit sleep state/scope')
        for key in ('applied_load_n', 'measured_reaction_n', 'positional_cleanup_n'):
            values = [foot[key] for foot in row['feet']]
            if not values or not all(math.isfinite(v) and v >= 0 for v in values):
                raise ValueError('Non-finite/negative force channel')
            if row['sum_' + key] != math.fsum(values):
                raise ValueError('Trace sum does not match raw foot channels')
        for foot in row['feet']:
            if not isinstance(foot['grounded'], bool) or not isinstance(foot['gripping'], bool):
                raise ValueError('Missing actual post-resolve flags')
            if not math.isfinite(foot['penetration_wu']):
                raise ValueError('Missing raw penetration')
            if previous == 0 and foot['gripping']:
                raise ValueError('N0 illegally gripped')
        grip = tuple(foot['gripping'] for foot in row['feet'])
        if last_grip is not None and last_grip != grip:
            toggles.append(tick)
        last_grip = grip
        previous = sum(foot['grounded'] for foot in row['feet'])
    window = rows[300:]
    maxima = {
        'applied_vs_weight_n': max(abs(r['sum_applied_load_n'] - WEIGHT_N) for r in window),
        'reaction_vs_weight_n': max(abs(r['sum_measured_reaction_n'] - WEIGHT_N) for r in window),
        'applied_vs_reaction_n': max(abs(r['sum_applied_load_n'] - r['sum_measured_reaction_n']) for r in window),
    }
    return {
        'scope': 'hinged engineering load probe, NOT FA acceptance or determinism',
        'rows': len(rows), 'steady_window_ticks': [300, 599], 'ceiling_n': CEILING_N,
        'max_absolute_errors_n': maxima,
        'force_window_within_owner_tolerance': all(v <= CEILING_N for v in maxima.values()),
        'grip_toggle_ticks': toggles,
        'first': rows[0], 'last': rows[-1],
        'limitations': ['free rotational hinges; angular limits/motors/self-response absent',
                        'sleep is not implemented; all rows remain awake'],
        'FA-3': 'NOT RUN', 'FA-4': 'NOT RUN', 'FA-5': 'NOT RUN', 'FA-6': 'NOT RUN',
        'complete_creature_determinism_attempts': 0,
    }


if __name__ == '__main__':
    rows = [json.loads(line) for line in Path(sys.argv[1]).read_text().splitlines()]
    summary = analyze(rows)
    Path(sys.argv[2]).write_text(json.dumps(summary, indent=2) + '\n')
    good = summary['force_window_within_owner_tolerance']
    print('M1 Slug force window: ' + ('WITHIN TOLERANCE' if good else 'FINDING (outside fixed tolerance)'))
    print('M1 Slug errors: ' + json.dumps(summary['max_absolute_errors_n'], sort_keys=True))
    print('M1 Slug grip toggle ticks: ' + json.dumps(summary['grip_toggle_ticks']))
    raise SystemExit(0 if good else 1)
