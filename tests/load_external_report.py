#!/usr/bin/env python3
"""R18 F56: measure the literal contact-only identity; never hide other forces.

The requested predicate is a gate, NOT an approximation we are free to correct.
Publish complete Newton balance separately; only the literal predicate authorizes
continuation. Existing 1e-12 ledger precision, not a new physical threshold.
"""
import json
import math
from pathlib import Path
import sys
from load_trace_report import IDENTITY_EPS, LINEAR_DAMPING, close
from load_long_report import verify_all
from load_convergence_report import drift_summary
from load_spring_report import joint_summary


def momentum(row, axis, start=False):
    prefix='start_' if start else ''
    return math.fsum(b[prefix+end+'v'+axis]/b['inverse_mass_'+end]
                     for b in sorted(row['feet']+row['other_bodies'], key=lambda b:b['part'])
                     for end in ('a','b'))


def external_identity(rows):
    if len(rows)<300: raise ValueError('Need all last300 raw ticks')
    tail=rows[-300:]
    if [r['tick'] for r in tail]!=list(range(tail[0]['tick'],tail[0]['tick']+300)):
        raise ValueError('Missing/reordered last300')
    result={'window_ticks':[tail[0]['tick'],tail[-1]['tick']], 'impulse_unit':'mass*WU/s',
            'ledger_precision_existing':IDENTITY_EPS,
            'literal_definition':'sum(p_after-p_before) == sum(ground normal + friction), no damping/gravity subtraction',
            'complete_definition':'delta_p == contact + damping + gravity + clamp + internal_drive + internal_velocity',
            'axes':{}}
    for axis in ('x','y'):
        values={k:[] for k in ('delta','normal','friction','contact','damping','gravity','clamp','internal_drive','internal_velocity','full_residual','literal_residual','attributed_residual')}
        for i,r in enumerate(tail):
            before=momentum(r,axis,True);after=momentum(r,axis)
            if i and not close(before,momentum(tail[i-1],axis)):
                raise ValueError('Raw endpoint momentum not continuous')
            budget=r['momentum_budget']
            if not close(before,budget[f'momentum_before_{axis}_ns']) or not close(after,budget[f'momentum_after_{axis}_ns']):
                raise ValueError('Claimed COM momentum disagrees with raw endpoint masses/velocities')
            normal=math.fsum(e['n'+axis]*e['normal_impulse_ns'] for e in r['contact_samples'])
            friction=math.fsum((-e['ny'] if axis=='x' else e['nx'])*e['tangential_impulse_ns'] for e in r['contact_samples'])
            contact=normal+friction
            if not close(contact,budget[f'contact_velocity_impulse_{axis}_ns']):
                raise ValueError('Raw contact events disagree with actual velocity change')
            drive=budget[f'drive_internal_impulse_{axis}_ns']
            damping=budget[f'damping_impulse_{axis}_ns']
            gravity=budget[f'gravity_impulse_{axis}_ns']
            clamp=budget[f'clamp_impulse_{axis}_ns']
            internal=budget[f'internal_impulse_{axis}_ns']
            if not close(damping,-LINEAR_DAMPING*(before+drive)):
                raise ValueError('Damping book disagrees with resource-derived damping')
            if not close(drive,0.) or not close(internal,0.):
                raise ValueError('INTERNAL momentum leak; STOP')
            delta=after-before
            full=delta-math.fsum((contact,damping,gravity,clamp,drive,internal))
            if not close(full,0.): raise ValueError('Complete momentum ledger fails; STOP')
            parts={'delta':delta,'normal':normal,'friction':friction,'contact':contact,
                'damping':damping,'gravity':gravity,'clamp':clamp,'internal_drive':drive,'internal_velocity':internal,
                'full_residual':full,'literal_residual':delta-contact,
                'attributed_residual':(delta-math.fsum((damping,gravity,clamp)))-contact}
            for key,value in parts.items():
                if not math.isfinite(value):raise ValueError('Nonfinite raw momentum identity')
                values[key].append(value)
        sums={k:math.fsum(v) for k,v in values.items()}
        # Reconstruct both sides from their window sums too, not only per-tick sums.
        sums['literal_residual_from_sides']=sums['delta']-sums['contact']
        sums['full_residual_from_sides']=sums['delta']-math.fsum(sums[k] for k in ('contact','damping','gravity','clamp','internal_drive','internal_velocity'))
        if not close(sums['internal_drive'],0.) or not close(sums['internal_velocity'],0.):
            raise ValueError('Window INTERNAL momentum leak; STOP')
        if not close(sums['attributed_residual'],0.) or not close(sums['full_residual_from_sides'],0.):
            raise ValueError('Window complete external momentum ledger fails; STOP')
        result['axes'][axis]={'sums':sums,
            'contact_attributed_momentum_change':sums['delta']-math.fsum(sums[k] for k in ('damping','gravity','clamp')),
            'max_abs_per_tick_full_residual':max(map(abs,values['full_residual'])),
            'max_abs_per_tick_internal_drive':max(map(abs,values['internal_drive'])),
            'max_abs_per_tick_internal_velocity':max(map(abs,values['internal_velocity'])),
            'literal_contact_only_passed':close(sums['delta'],sums['contact']),
            'complete_external_balance_passed':close(sums['full_residual_from_sides'],0.)}
    result['F56_literal_lateral_passed']=result['axes']['x']['literal_contact_only_passed']
    result['F56_literal_vector_passed']=all(a['literal_contact_only_passed'] for a in result['axes'].values())
    result['internal_rows_and_complete_ledger_verified']=all(a['complete_external_balance_passed'] for a in result['axes'].values())
    result['remedy_authorized_by_requested_gate']=result['F56_literal_lateral_passed'] and result['F56_literal_vector_passed']
    result['outcome']='PASS literal requested identity' if result['remedy_authorized_by_requested_gate'] else 'STOP: literal contact-only identity fails; do NOT apply remedy or silently redefine momentum change'
    return result


def report(folder):
    rows=[json.loads(s) for s in (folder/'actuated-after-6000.jsonl').read_text().splitlines()]
    verify_all(rows)
    identity=external_identity(rows)
    mechanism={'scope':'F55 report ONLY; COM drift comparison with configured static-slip allowance, not a new acceptance band',
        'static_slip_wu_s':rows[0]['diagnostic_static_slip_wu_s'],
        'static_slip_px_s_at150':rows[0]['diagnostic_static_slip_wu_s']*150,
        'current_after_drift':drift_summary(rows),'joints':joint_summary(rows),
        'F57':'Injected seeded stream exists and survives replay; no physics path consumes RNG. Randomness is NOT exercised by physics.'}
    result={'identity':identity,'mechanism':mechanism,'runtime_rows_passed':8,'runtime_rows_total':18,
            'motor_stiffness_zero_sweep':'NOT RUN until F56 requested identity passes',
            'A_calibration':'NOT SELECTED/APPLIED until prerequisite passes',
            'AC201':'NOT RUN; no acceptance upgrade','baseline':'UNCHANGED; no physics remedy applied'}
    (folder/'external-report.json').write_text(json.dumps(result,indent=2)+'\n')
    print('M1 R18 F56: '+json.dumps(identity,separators=(',',':')))
    print('M1 R18 mechanism: '+json.dumps(mechanism,separators=(',',':')))
    return result


if __name__=='__main__':
    r=report(Path(sys.argv[1]))
    if not r['identity']['remedy_authorized_by_requested_gate']:raise SystemExit(1)
