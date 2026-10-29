#!/usr/bin/env python3
"""R13 F41/F42: inspect real sample responses, adopt no friction/sleep interpretation."""
import json
import math
from pathlib import Path
import re
from load_trace_report import analyze, close

RESOURCE = (Path(__file__).resolve().parents[1] / 'core/tuning.tres').read_text()
PASSES = int(re.search(r'^physics_velocity_passes = (.+)$', RESOURCE, re.M)[1])


def tangent(event, suffix):
    u = event['u']
    vx = (1-u)*event['avx_' + suffix] + u*event['bvx_' + suffix]
    vy = (1-u)*event['avy_' + suffix] + u*event['bvy_' + suffix]
    return -vx*event['ny'] + vy*event['nx']


def com_vx(row):
    bodies = row['feet']+row['other_bodies']
    return math.fsum(b[e+'vx']/b['inverse_mass_'+e] for b in bodies for e in ('a','b'))/math.fsum(b['mass'] for b in bodies)


def com_dx(row, phase):
    bodies = row['feet']+row['other_bodies']
    if phase == 'net':
        return math.fsum((b[e+'x']-b['start_'+e+'x'])/b['inverse_mass_'+e] for b in bodies for e in ('a','b'))/math.fsum(b['mass'] for b in bodies)
    return math.fsum(b['position_delta_wu'][phase][index]/b['inverse_mass_'+e] for b in bodies for e,index in (('a',0),('b',2)))/math.fsum(b['mass'] for b in bodies)


def inspect(rows):
    # Accepted F31/F35 verification remains the first independent door.
    accepted = analyze(rows)
    previous = []
    profiles = []
    events_out = []
    max_tangent_error = max_impulse_error = 0.0
    stats = {p: {'candidate_counts': set(), 'active_counts': set(),
                 'zero_retained_with_surviving_endpoint_count': 0,
                 'earlier_static_sample_changed_by_later_samples_count': 0,
                 'max_tangent_at_body_end_after_static_response': 0.0,
                 'max_abs_tangent_before': 0.0, 'per_pass': {v: {'candidate_count_histogram': {}, 'active_count_histogram': {}, 'body_end_com_vx_min_wu_s': math.inf, 'body_end_com_vx_max_wu_s': -math.inf} for v in range(PASSES)}} for p in range(3)}
    last_samples = {p: [] for p in range(3)}
    for row in rows:
        bodies = {b['part']: b for b in row['feet'] + row['other_bodies']}
        if row['observer_on_off_physical_state_equal'] is not True:
            raise ValueError('Observer-on/off physical state comparison missing/failed')
        grounded = sorted(p for p, b in bodies.items() if b['grounded'])
        if row['grounded_parts'] != grounded or row['previous_grounded_parts'] != previous:
            raise ValueError('Grounded sets do not match actual completed states')
        new = sorted(set(grounded)-set(previous))
        lifted = sorted(set(previous)-set(grounded))
        if row['new_grounded_parts'] != new or row['lifted_parts'] != lifted:
            raise ValueError('New/lifted grounded transition mismatch')
        if any(b['grounded_previous'] != (p in previous) for p, b in bodies.items()):
            raise ValueError('Per-body prior flag mismatch')
        groups = {(v, p): [] for v in range(PASSES) for p in range(3)}
        for event in row['contact_samples']:
            if (event['velocity_pass'], event['part']) not in groups:
                raise ValueError('Unknown sample body/pass')
            groups[event['velocity_pass'], event['part']].append(event)
            events_out.append({'tick': row['tick'], **event})
        normal_sums = {p: 0.0 for p in range(3)}
        active_total = 0
        cleanup_sums = {p: 0.0 for p in range(3)}
        for (velocity_pass, part), events in groups.items():
            if not events or events[0]['intervals'] <= 0 or [e['sample_index'] for e in events] != list(range(events[0]['intervals']+1)):
                raise ValueError('Missing/reordered candidate sample coverage')
            body = bodies[part]
            tail = events[-1]
            active = 0
            last_state = None
            for event in events:
                numeric = ('u', 'nx', 'ny', 'tangent_before', 'tangent_after', 'normal_impulse_ns',
                           'tangential_impulse_ns', 'inverse_mass_a', 'inverse_mass_b', 'positional_cleanup_n', 'avx_before', 'avy_before', 'bvx_before', 'bvy_before',
                           'avx_after', 'avy_after', 'bvx_after', 'bvy_after')
                if not all(math.isfinite(event[k]) for k in numeric):
                    raise ValueError('Nonfinite sample telemetry')
                if event['intervals'] != events[0]['intervals'] or not close(event['u'], event['sample_index']/event['intervals']):
                    raise ValueError('Sample barycentric coordinate mismatch')
                if last_state is not None and not all(close(event[k+'_before'], last_state[k]) for k in last_state):
                    raise ValueError('Sample endpoint continuity mismatch')
                if not close(event['tangent_before'], tangent(event, 'before')) or not close(event['tangent_after'], tangent(event, 'after')):
                    raise ValueError('Claimed tangent does not match raw endpoints')
                if not isinstance(event['active'], bool) or not isinstance(event['static_branch'], bool):
                    raise ValueError('Missing actual contact/branch flags')
                if not all(close(event['inverse_mass_'+e],body['inverse_mass_'+e]) for e in ('a','b')):
                    raise ValueError('Sample inverse masses do not match actual endpoints')
                if event['positional_cleanup_n'] < 0:
                    raise ValueError('Negative positional cleanup')
                cleanup_sums[part] += event['positional_cleanup_n']
                if event['normal_impulse_ns'] < 0:
                    raise ValueError('Negative normal impulse')
                if event['active']:
                    active += 1
                    if not math.isfinite(event['retained']):
                        raise ValueError('Invalid retained tangent')
                    static = abs(event['tangent_before']) < row['diagnostic_static_slip_wu_s']
                    if event['static_branch'] != static or (static and event['retained'] != 0.0):
                        raise ValueError('Static-slip branch does not match resource/diagnostic value')
                    error = abs(event['tangent_after'] - event['retained'])
                    max_tangent_error = max(max_tangent_error, error)
                    if not close(event['tangent_after'], event['retained']):
                        raise ValueError('Sample tangent response does not equal retained target')
                    for end, weight in (('a', 1-event['u']), ('b', event['u'])):
                        jx = event['nx']*event['normal_impulse_ns']-event['ny']*event['tangential_impulse_ns']
                        jy = event['ny']*event['normal_impulse_ns']+event['nx']*event['tangential_impulse_ns']
                        for axis, impulse in (('x', jx), ('y', jy)):
                            actual = event[end+'v'+axis+'_after']-event[end+'v'+axis+'_before']
                            predicted = body['inverse_mass_'+end]*weight*impulse
                            max_impulse_error = max(max_impulse_error, abs(actual-predicted))
                            if not close(actual, predicted):
                                raise ValueError('Endpoint response does not match signed sample impulse')
                    normal_sums[part] += event['normal_impulse_ns']
                elif event['retained'] is not None or event['normal_impulse_ns'] != 0 or event['tangential_impulse_ns'] != 0 or any(event[k+'_after'] != event[k+'_before'] for k in ('avx','avy','bvx','bvy')):
                    raise ValueError('Inactive sample claims a response')
                last_state = {k: event[k+'_after'] for k in ('avx', 'avy', 'bvx', 'bvy')}
                if row['tick'] >= 300 and event['active']:
                    stats[part]['max_abs_tangent_before'] = max(stats[part]['max_abs_tangent_before'], abs(event['tangent_before']))
                    end_event = {**event, **{k+'_after': tail[k+'_after'] for k in ('avx','avy','bvx','bvy')}}
                    at_body_end = tangent(end_event, 'after')
                    if event['retained'] == 0.0:
                        if event['avx_after'] != 0 or event['bvx_after'] != 0:
                            stats[part]['zero_retained_with_surviving_endpoint_count'] += 1
                        if at_body_end != event['tangent_after']:
                            stats[part]['earlier_static_sample_changed_by_later_samples_count'] += 1
                        stats[part]['max_tangent_at_body_end_after_static_response'] = max(stats[part]['max_tangent_at_body_end_after_static_response'], abs(at_body_end))
                    if row['tick'] == 599 and velocity_pass == PASSES-1:
                        last_samples[part].append({k: event[k] for k in ('sample_index','u','tangent_before','tangent_after','retained','avx_before','bvx_before','avx_after','bvx_after','normal_impulse_ns','tangential_impulse_ns')} | {'tangent_at_body_end': at_body_end})
            active_total += active
            if velocity_pass == PASSES-1:
                if bool(active) != body['grounded'] or not all(close(tail[k+'_after'], body[k]) for k in ('avx','avy','bvx','bvy')):
                    raise ValueError('Final contact sample does not match completed body')
            if row['tick'] >= 300:
                per_pass = stats[part]['per_pass'][velocity_pass]
                for key, value in (('candidate_count_histogram',len(events)),('active_count_histogram',active)):
                    per_pass[key][value] = per_pass[key].get(value,0)+1
                body_com_vx = (tail['avx_after']/body['inverse_mass_a']+tail['bvx_after']/body['inverse_mass_b'])/body['mass']
                per_pass['body_end_com_vx_min_wu_s'] = min(per_pass['body_end_com_vx_min_wu_s'],body_com_vx)
                per_pass['body_end_com_vx_max_wu_s'] = max(per_pass['body_end_com_vx_max_wu_s'],body_com_vx)
                stats[part]['candidate_counts'].add(len(events))
                stats[part]['active_counts'].add(active)
        for part, value in normal_sums.items():
            if not close(cleanup_sums[part], bodies[part]['positional_cleanup_n']):
                raise ValueError('Positional cleanup sum differs from raw body; never qualifying load')
            if not close(value, bodies[part]['measured_reaction_n']*row['momentum_budget']['dt_s']):
                raise ValueError('Per-sample normal impulses do not match independent reported force')
        profiles.append({'tick': row['tick'], 'grounded_parts': grounded, 'new_grounded_parts': new,
                         'lifted_parts': lifted, 'normal_impulse_by_part_ns': normal_sums,
                         'active_sample_responses': active_total})
        previous = grounded
    for part in stats:
        stats[part]['candidate_counts'] = sorted(stats[part]['candidate_counts'])
        stats[part]['active_counts'] = sorted(stats[part]['active_counts'])
        stats[part]['last_final_pass_samples'] = last_samples[part]
    summary = {'rows': len(rows), 'sample_events': len(events_out), 'observer_on_off_equal_ticks': len(rows),
               'full_active_sample_count': sum(e['active'] for e in events_out),
               'full_static_branch_count': sum(e['active'] and e['static_branch'] for e in events_out),
               'steady_active_sample_count': sum(e['active'] for e in events_out if e['tick']>=300),
               'steady_static_branch_count': sum(e['active'] and e['static_branch'] for e in events_out if e['tick']>=300),
               'steady_mean_com_dx_wu_tick': math.fsum(com_dx(r,'net') for r in rows[300:])/300,
               'steady_mean_integration_com_dx_wu_tick': math.fsum(com_dx(r,'integration') for r in rows[300:])/300,
               'max_tangent_target_identity_error': max_tangent_error, 'max_endpoint_impulse_identity_error': max_impulse_error,
               'steady_completed_com_vx_range_wu_s': [min(com_vx(r) for r in rows[300:]), max(com_vx(r) for r in rows[300:])],
               'steady_ticks_with_any_active_sample': sum(r['active_sample_responses'] > 0 for r in profiles[300:]),
               'steady_new_grounded_transition_count': sum(len(r['new_grounded_parts']) for r in profiles[300:]),
               'steady_grounded_sets': sorted({tuple(r['grounded_parts']) for r in profiles[300:]}),
               'grounded_transitions_all600': [r for r in profiles if r['new_grounded_parts'] or r['lifted_parts']],
               'parts': stats, 'f31_momentum_verified': accepted['momentum_ledger_verified'],
               'sleep_breaking_interpretation': 'NOT ADOPTED; grounded/new transitions/impulses are raw evidence only'}
    return summary, profiles, events_out


def save(folder, rows):
    report, grounding, events = inspect(rows)
    root = Path(folder)
    (root/'contact-summary.json').write_text(json.dumps(report, indent=2)+'\n')
    (root/'grounding-events.jsonl').write_text(''.join(json.dumps(r)+'\n' for r in grounding))
    (root/'contact-events.jsonl').write_text(''.join(json.dumps(r)+'\n' for r in events))
    return report
