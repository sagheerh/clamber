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


def verify_all(rows):
    if len(rows) != 6000 or [r['tick'] for r in rows] != list(range(6000)):
        raise ValueError('Need complete ordered6000; partial is NOT convergence evidence')
    validate_spawn(rows)
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
    counts = verify_all(rows)
    windows = {}
    for end in (600,3000,6000):
        d = drift_summary(rows[:end])
        windows[str(end)] = d
    return {'scope':'awake ZERO INPUT, LIVE spring return; component observation NOT public Sim/FA/determinism',
            'rows':len(rows), 'spawn_root_y_wu':rows[0]['diagnostic_spawn_y_wu'],
            'full_raw_F31_position_counts_contact_impulses_verified':True,
            'windows_ending_at_ticks_exclusive':windows,
            'last300_counts':count_summary(counts[-300:]),
            'sustained_support_gate':sustained_support(rows),
            'settled_value':windows['6000']['convergence']['settled_mean_dx_wu_tick'],
            'F41':'OPEN; do not interpret nonsettled actuator drift as equilibrium'}


if __name__=='__main__':
    root = Path(sys.argv[1]); result = {}
    for name in ('actuated-before','actuated-after'):
        try:
            folder=root/name
            if (folder/'engine-status.txt').read_text().strip() != '0': raise ValueError('Engine incomplete')
            rows=[json.loads(s) for s in (folder/'slug-6000.jsonl').read_text().splitlines()]
            result[name]={'status':'OBSERVED', **summarize(rows)}
        except (OSError,ValueError,KeyError,TypeError) as e:
            result[name]={'status':'NOT COMPLETED','finding':str(e)}
        print('M1 convergence '+name+': '+json.dumps({k:v for k,v in result[name].items() if k != 'windows_ending_at_ticks_exclusive'},sort_keys=True))
        for window,d in result[name].get('windows_ending_at_ticks_exclusive',{}).items():
            print('M1 zero-input drift '+name+' through'+window+': '+json.dumps(d,sort_keys=True))
    (root/'convergence-report.json').write_text(json.dumps(result,indent=2)+'\n')
    raise SystemExit(0 if all(c['status']=='OBSERVED' for c in result.values()) else 1)
