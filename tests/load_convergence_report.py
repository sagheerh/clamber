#!/usr/bin/env python3
"""R16 F48 observation only. No solver epsilon, settlement band or acceptance claim."""
import math


def com_values(row):
    bodies = row['feet'] + row['other_bodies']
    mass = math.fsum(b['mass'] for b in bodies)
    vx = math.fsum(b[e+'vx']/b['inverse_mass_'+e] for b in bodies for e in ('a','b')) / mass
    dx = math.fsum((b[e+'x']-b['start_'+e+'x'])/b['inverse_mass_'+e] for b in bodies for e in ('a','b')) / mass
    return dx, vx


def classify(values):
    """Exact repeated last300 drift/speed pattern only; not an invented velocity band.
    Nonsettled cases are explicitly monotone or oscillating. Means stay transient.
    """
    if len(values) < 300 or not all(all(math.isfinite(v) for v in pair) for pair in values):
        raise ValueError('Convergence requires >=300 finite raw COM observations')
    tail = values[-300:]
    period = next((p for p in range(1, 151) if all(tail[i] == tail[i-p] for i in range(p, 300))), None)
    speeds = [v[1] for v in tail]
    changes = [b-a for a, b in zip(speeds, speeds[1:])]
    monotone = all(d >= 0 for d in changes) or all(d <= 0 for d in changes)
    classification = ('settled constant' if period == 1 else 'settled exact periodic') if period else ('monotone transient' if monotone else 'oscillating transient')
    return {'classification': classification, 'settled': period is not None, 'exact_period_ticks': period,
            'settlement_criterion': 'last300 COM(dx,vx) exactly constant/repeating >=2 cycles; NO velocity epsilon; absence is not proof of divergence',
            'vx_increases': sum(d > 0 for d in changes), 'vx_decreases': sum(d < 0 for d in changes),
            'vx_unchanged': sum(d == 0 for d in changes),
            'dvx_direction_reversals': sum(a*b < 0 for a, b in zip([d for d in changes if d != 0], [d for d in changes if d != 0][1:])),
            'last300_vx_range_wu_s': [min(speeds), max(speeds)],
            'last300_dx_range_wu_tick': [min(v[0] for v in tail), max(v[0] for v in tail)],
            'settled_mean_dx_wu_tick': math.fsum(v[0] for v in tail) / 300 if period else None,
            'settled_mean_vx_wu_s': math.fsum(speeds) / 300 if period else None}


def drift_summary(rows):
    if any(r.get('input_mask', 0) != 0 for r in rows):
        raise ValueError('Nonzero input cannot be labeled zero-input drift')
    values = [com_values(r) for r in rows]
    c = classify(values)
    tail = values[-300:]
    dx = math.fsum(v[0] for v in tail) / 300
    vx = math.fsum(v[1] for v in tail) / 300
    active = rows[0].get('diagnostic_spring_return_live', rows[0].get('diagnostic_actuated', False))
    recurrence = {'count_pattern_period_ticks': None, 'repeat_lag_dx_max_difference_wu_tick': None,
                  'repeat_lag_vx_max_difference_wu_s': None,
                  'meaning': 'observed recurrence differences ONLY; no settlement tolerance/pass criterion'}
    if all('contact_counts' in r for r in rows[-300:]):
        signatures = [r['contact_counts'] for r in rows[-300:]]
        period = next((p for p in range(1,151) if all(signatures[i] == signatures[i-p] for i in range(p,300))), None)
        recurrence['count_pattern_period_ticks'] = period
        if period:
            recurrence['repeat_lag_dx_max_difference_wu_tick'] = max(abs(tail[i][0]-tail[i-period][0]) for i in range(period,300))
            recurrence['repeat_lag_vx_max_difference_wu_s'] = max(abs(tail[i][1]-tail[i-period][1]) for i in range(period,300))
    return {'input_mask': 0, 'spring_return_live': active,
            'power_description': 'ZERO INPUT IS NOT UNPOWERED: always-on spring return active' if active else 'free-hinge baseline; no motor spring return',
            'observation_ticks': [rows[-300]['tick'], rows[-1]['tick']],
            'mean_label': 'settled exact observed pattern' if c['settled'] else 'TRANSIENT WINDOW MEAN, NOT EQUILIBRIUM',
            'mean_com_dx_wu_tick': dx, 'net_drift_wu_s': dx * 60,
            'net_drift_px_s_at_150px_wu': dx * 60 * 150,
            'observed_window_lateral_travel_wu': math.fsum(v[0] for v in tail),
            'mean_completed_com_vx_wu_s': vx,
            'convergence': c, 'raw_recurrence_diagnostics': recurrence}
