#!/usr/bin/env python3
"""R13 threshold diagnostic ONLY. No resource edit, sample-count change or sleep choice."""
import json
from pathlib import Path
import re
import sys
from load_contact_report import save, RESOURCE, com_vx
from load_trace_report import analyze

VALUES = ('0.15', '1.5')


def summarize(folder):
    configured = float(re.search(r'^physics_static_slip_wu_s = (.+)$', RESOURCE, re.M)[1])
    cases = []
    observed_rows = []
    for text in VALUES:
        root = Path(folder)/f'slip-{text}'
        case = {'static_slip_wu_s': float(text), 'configured_resource_value': float(text) == configured}
        try:
            if int((root/'engine-status.txt').read_text()) != 0:
                raise ValueError('engine/script incomplete; preserve partial evidence')
            rows = [json.loads(s) for s in (root/'slug-600.jsonl').read_text().splitlines()]
            accepted = analyze(rows)
            if any(r['diagnostic_static_slip_wu_s'] != float(text) or r['diagnostic_position_iterations'] != 6 or r['diagnostic_spawn_y_wu'] != .33 for r in rows):
                raise ValueError('R13 experiment metadata differs from fixed6/.33/requested threshold')
            first = rows[0]['feet']+rows[0]['other_bodies']
            if next(b for b in first if b['part']==0)['start_ay'] != .33 or any(b['start_'+e+v] != 0 for b in first for e in ('a','b') for v in ('vx','vy')):
                raise ValueError('R13 initial conditions changed')
            report = save(root, rows)
            observed_rows.append(rows)
            case.update(status='OBSERVED', rows=len(rows), contact_report=report,
                        all_grounded_force_window=accepted['force_window_within_owner_tolerance'])
        except (ValueError, KeyError, OSError, TypeError, StopIteration) as error:
            case.update(status='NOT COMPLETED', finding=str(error))
        cases.append(case)
    comparison = {'status': 'INCOMPLETE', 'adopted_new_threshold': False}
    if all(c['status']=='OBSERVED' for c in cases):
        ranges = [c['contact_report']['steady_completed_com_vx_range_wu_s'] for c in cases]
        comparison.update(status='OBSERVED', steady_com_vx_ranges=ranges,
                          max_abs_com_vx_difference_all600=max(abs(com_vx(a)-com_vx(b)) for a,b in zip(*observed_rows)),
                          max_abs_com_vx_difference_last300=max(abs(com_vx(a)-com_vx(b)) for a,b in zip(*(r[300:] for r in observed_rows))),
                          full_branch_counts=[{k:c['contact_report'][k] for k in ('full_active_sample_count','full_static_branch_count','steady_active_sample_count','steady_static_branch_count')} for c in cases],
                          steady_com_vx_envelopes_overlap=max(r[0] for r in ranges)<=min(r[1] for r in ranges),
                          maximum_endpoint_impulse_identity_error=max(c['contact_report']['max_endpoint_impulse_identity_error'] for c in cases))
    return {'scope':'R13 observer ONLY; no friction/sampling/sleep/pose fix',
            'configured_static_slip_wu_s':configured,'cases':cases,'comparison':comparison,
            'FA-3':'NOT RUN','FA-4':'NOT RUN','FA-5':'NOT RUN','FA-6':'NOT RUN',
            'complete_creature_determinism_attempts':0}


if __name__=='__main__':
    report=summarize(sys.argv[1])
    Path(sys.argv[1],'slip-comparison.json').write_text(json.dumps(report,indent=2)+'\n')
    for case in report['cases']:
        brief={k:v for k,v in case.items() if k!='contact_report'}
        if 'contact_report' in case:
            r=case['contact_report']
            brief.update({k:r[k] for k in ('sample_events','observer_on_off_equal_ticks','steady_completed_com_vx_range_wu_s','steady_ticks_with_any_active_sample','steady_new_grounded_transition_count','steady_grounded_sets','max_tangent_target_identity_error','full_active_sample_count','full_static_branch_count','steady_active_sample_count','steady_static_branch_count','steady_mean_com_dx_wu_tick','steady_mean_integration_com_dx_wu_tick')})
        if 'contact_report' in case:
            brief['grounded_transition_ticks'] = [{k:r[k] for k in ('tick','new_grounded_parts','lifted_parts')} for r in case['contact_report']['grounded_transitions_all600']]
        print('M1 slip case: '+json.dumps(brief,sort_keys=True))
    if report['cases'][0]['status']=='OBSERVED':
        for part,stats in report['cases'][0]['contact_report']['parts'].items():
            print('M1 slip baseline part: '+json.dumps({'part':part,**stats},sort_keys=True))
    if report['cases'][0]['status']=='OBSERVED':
        print('M1 slip final impulses: '+json.dumps(report['cases'][0]['contact_report']['last_tick_sample_impulses'],sort_keys=True))
    print('M1 slip comparison: '+json.dumps(report['comparison'],sort_keys=True))
    print('M1 slip scope: resource0.15 unchanged; diagnostic1.5 NOT adopted; no sampling/sleep/pose fix')
    raise SystemExit(0 if report['comparison']['status']=='OBSERVED' else 1)
