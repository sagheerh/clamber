#!/usr/bin/env python3
"""R16 F48 6000-tick zero-input observation; NO equilibrium/FA/determinism upgrade."""
import json
import math
from pathlib import Path
import sys
from load_trace_report import analyze, close, body_momentum, sustained_support, WEIGHT_N, LINEAR_DAMPING
from load_legal_report import validate_counts, validate_spawn, accepted_view, count_summary
from load_contact_report import inspect
from load_convergence_report import drift_summary
from load_phase_report import phase_magnitudes


def verify_all(rows):
    if len(rows) != 6000 or [r['tick'] for r in rows] != list(range(6000)):
        raise ValueError('Need complete ordered6000; partial is NOT convergence evidence')
    lift = rows[0].get('diagnostic_spawn_lift_wu', 0.)
    if lift not in (0., .2): raise ValueError('Unauthorized diagnostic lift')
    validate_spawn(rows, clearance=.01+lift)
    counts = validate_counts(rows)
    # Preserve accepted first600 verifier. Long continuation independently checks
    # raw endpoints, ALL phase columns, real contact impulses and full F31 identities.
    prefix = accepted_view(rows[:600])
    a = analyze(prefix)
    inspect(prefix)
    if not a['momentum_ledger_verified'] or not a['motion']['position_ledger_and_speed_identities_verified']:
        raise ValueError('Accepted prefix verifier failed')
    previous = []
    for r in rows:
        if r['status'] != 0 or not r['observer_on_off_physical_state_equal'] or r['input_mask'] != 0 or not r['diagnostic_spring_return_live']:
            raise ValueError('Incomplete/altered/ nonzero-input long observation')
        bodies = r['feet'] + r['other_bodies']
        grounded = sorted(b['part'] for b in bodies if b['grounded'])
        if r['previous_grounded_parts'] != previous or r['grounded_parts'] != grounded or r['previous_grounded_feet'] != sum(b['part'] in previous for b in r['feet']):
            raise ValueError('Long continuation prior grounded-state mismatch')
        previous = grounded
        for b in bodies:
            phases = b['position_delta_wu']
            if set(phases) != {'integration','distance','hinge','contact','angular','self_contact'}:
                raise ValueError('Long raw phase missing')
            for i,k in enumerate(('ax','ay','bx','by')):
                if not all(math.isfinite(p[i]) for p in phases.values()) or not close(b[k]-b['start_'+k], math.fsum(p[i] for p in phases.values())):
                    raise ValueError('Long raw position ledger fails')
            for end in ('a','b'):
                if not close(b['speed_'+end+'_wu_s'], math.hypot(b[end+'vx'], b[end+'vy'])):
                    raise ValueError('Long endpoint speed claim mismatch')
            if not close(b['com_speed_wu_s'], math.hypot((b['avx']+b['bvx'])/2,(b['avy']+b['bvy'])/2)):
                raise ValueError('Long COM speed claim mismatch')
        budget = r['momentum_budget']
        before, after = body_momentum(bodies, True), body_momentum(bodies)
        contact = math.fsum(b['measured_reaction_n'] for b in bodies)/60
        if not all(math.isfinite(v) for v in budget.values()) or budget['dt_s'] != 1/60:
            raise ValueError('Long nonfinite/nonfixed budget')
        expected = {'momentum_before_y_ns': before, 'momentum_after_y_ns': after,
            'momentum_change_y_ns': after-before, 'gravity_impulse_y_ns': -WEIGHT_N/60,
            'damping_impulse_y_ns': -LINEAR_DAMPING*before, 'contact_reported_impulse_y_ns':contact,
            'contact_velocity_impulse_y_ns':contact}
        if not all(close(budget[k],v) for k,v in expected.items()) or not close(budget['internal_impulse_y_ns'],0):
            raise ValueError('Long independently reconstructed F31 budget fails')
        if not close(after-before, -WEIGHT_N/60 - LINEAR_DAMPING*before + budget['clamp_impulse_y_ns'] + budget['internal_impulse_y_ns'] + contact):
            raise ValueError('Long momentum conservation fails')
        for b in bodies:
            events = [e for e in r['contact_samples'] if e['part'] == b['part']]
            if not close(math.fsum(e['normal_impulse_ns']*e['ny'] for e in events), b['measured_reaction_n']/60):
                raise ValueError('Long raw normal impulses disagree with reaction')
            for e in events:
                for end, weight in [('a',1-e['u']),('b',e['u'])]:
                    for axis, j in [('x',e['nx']*e['normal_impulse_ns']-e['ny']*e['tangential_impulse_ns']),('y',e['ny']*e['normal_impulse_ns']+e['nx']*e['tangential_impulse_ns'])]:
                        if not close(e[end+'v'+axis+'_after']-e[end+'v'+axis+'_before'], e['inverse_mass_'+end]*weight*j):
                            raise ValueError('Long raw contact impulse response fails')
    return counts


def summarize(rows):
    phases = phase_magnitudes(rows)
    counts = verify_all(rows)
    windows = {}
    for end in (600,3000,6000):
        d = drift_summary(rows[:end])
        windows[str(end)] = d
    return {'scope':'awake ZERO INPUT, LIVE spring return; component observation NOT public Sim/FA/determinism',
            'rows':len(rows), 'raw_phase_magnitudes':phases, 'spawn_root_y_wu':rows[0]['diagnostic_spawn_y_wu'],
            'full_raw_F31_position_counts_contact_impulses_verified':True,
            'windows_ending_at_ticks_exclusive':windows,
            'last300_counts':count_summary(counts[-300:]),
            'sustained_support_gate':sustained_support(rows),
            'settled_value':windows['6000']['convergence']['settled_mean_dx_wu_tick'],
            'F41':'OPEN; do not interpret nonsettled actuator drift as equilibrium'}


def summarize_baseline(rows):
    if len(rows)!=600: raise ValueError('Need complete baseline600')
    lift=rows[0].get('diagnostic_spawn_lift_wu',0.)
    if lift not in (0.,.2): raise ValueError('Unauthorized baseline lift')
    validate_spawn(rows,clearance=.01+lift)
    counts=validate_counts(rows)
    a=analyze(rows);inspect(rows)
    if not a['momentum_ledger_verified'] or not a['motion']['position_ledger_and_speed_identities_verified']:
        raise ValueError('Baseline raw identities fail')
    return {'scope':'F50 post-pose free-hinge baseline, ZERO INPUT', 'rows':600,
        'spawn_root_y_wu':rows[0]['diagnostic_spawn_y_wu'],
        'zero_input_drift':drift_summary(rows),'sustained_support_gate':a['sustained_support_gate'],
        'last300_counts':count_summary(counts[-300:])}


def spawn_comparison(cases, counts, mechanics):
    names=[mechanics+'-after',mechanics+'-after-raised']
    if not all(cases[n]['status']=='OBSERVED' for n in names):
        return {'status':'NOT COMPLETED'}
    a,b=[cases[n].get('zero_input_drift',cases[n].get('windows_ending_at_ticks_exclusive',{}).get('6000')) for n in names]
    settled=all(d['convergence']['settled'] for d in (a,b))
    return {'scope':'SAME post-pose; derived+.01 vs +.21 legal clearance; no closure',
        'roots_wu':[cases[n]['spawn_root_y_wu'] for n in names],
        'observed_window_mean_dx_wu_tick':[d['mean_com_dx_wu_tick'] for d in (a,b)],
        'observed_vx_ranges_wu_s':[d['convergence']['last300_vx_range_wu_s'] for d in (a,b)],
        'bit_identical_window_means':a['mean_com_dx_wu_tick']==b['mean_com_dx_wu_tick'],
        'vx_observed_envelopes_overlap':max(d['convergence']['last300_vx_range_wu_s'][0] for d in (a,b)) <= min(d['convergence']['last300_vx_range_wu_s'][1] for d in (a,b)),
        'last300_per_tick_count_regimes_identical':counts[names[0]]==counts[names[1]],
        'both_windows_settled':settled,
        'settled_difference_wu_tick':b['convergence']['settled_mean_dx_wu_tick']-a['convergence']['settled_mean_dx_wu_tick'] if settled else None,
        'interpretation':'REPORT ONLY; F41 OPEN' if settled else 'DEFERRED: nonsettled; these are transient means, not equilibria',
        'F41_closed':False}


if __name__=='__main__':
    root = Path(sys.argv[1]); result = {}; counts={}
    for name in ('actuated-before','actuated-after','actuated-after-raised','baseline-after','baseline-after-raised'):
        try:
            folder=root/name
            if (folder/'engine-status.txt').read_text().strip() != '0': raise ValueError('Engine incomplete')
            duration=6000 if name.startswith('actuated') else 600
            rows=[json.loads(s) for s in (folder/f'slug-{duration}.jsonl').read_text().splitlines()]
            expected_lift=.2 if name.endswith('raised') else 0.
            if any(r.get('diagnostic_spawn_lift_wu')!=expected_lift or r['diagnostic_pose']!=('before' if name=='actuated-before' else 'after') or r['diagnostic_actuated']!=(duration==6000) for r in rows):
                raise ValueError('Wrong pose/mechanics/spawn arm')
            result[name]={'status':'OBSERVED', **(summarize(rows) if duration==6000 else summarize_baseline(rows))}
            counts[name]=[r['contact_counts'] for r in rows[-300:]]
        except (OSError,ValueError,KeyError,TypeError) as e:
            result[name]={'status':'NOT COMPLETED','finding':str(e)}
        brief={k:v for k,v in result[name].items() if k not in ('windows_ending_at_ticks_exclusive','last300_counts','zero_input_drift','sustained_support_gate')}
        if 'sustained_support_gate' in result[name]:
            g=result[name]['sustained_support_gate']
            brief.update(support_gate_passed=g['passed'],last300_grip_fraction=g['grip_fraction'],max_single_foot_share=g['max_single_foot_grounded_support_share'])
        print('M1 convergence '+name+': '+json.dumps(brief,sort_keys=True))
        for window,d in result[name].get('windows_ending_at_ticks_exclusive',{}).items():
            print('M1 zero-input drift '+name+' through'+window+': '+json.dumps(d,sort_keys=True))
        if 'zero_input_drift' in result[name]:
            print('M1 zero-input drift '+name+': '+json.dumps(result[name]['zero_input_drift'],sort_keys=True))
    spawn={m:spawn_comparison(result,counts,m) for m in ('baseline','actuated')}
    print('M1 F50 spawn comparison: '+json.dumps(spawn,sort_keys=True))
    (root/'convergence-report.json').write_text(json.dumps({'cases':result,'F50':spawn},indent=2)+'\n')
    raise SystemExit(0 if all(c['status']=='OBSERVED' for c in result.values()) else 1)
