#!/usr/bin/env python3
"""R27 preregistered gate computations; no simulation, acceptance epsilon or drift sweep."""
import hashlib
import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PLAN = json.loads((ROOT/'tests/fixtures/r27_plan.json').read_text())


def need(value, message):
    if not value:
        raise ValueError(message)


def load(path):
    return json.loads(path.read_text(), parse_constant=lambda v: (_ for _ in ()).throw(ValueError('nonfinite JSON '+v)))


def rows(path):
    with path.open() as f:
        for line in f:
            yield json.loads(line, parse_constant=lambda v: (_ for _ in ()).throw(ValueError('nonfinite JSON '+v)))


def completed(end, target, count):
    need(end['target_ticks'] == target, 'Edited horizon')
    return count == end['ticks'] == target and end['status'] == 0 and end['failing_tick'] is None and end['termination_reason'] == 'completed'


def bodies(state):
    return state['physical']['bodies']


def center(part):
    return ((part['a']['x']+part['b']['x'])/2, (part['a']['y']+part['b']['y'])/2)


def com(parts):
    mass = math.fsum(p['mass'] for p in parts)
    return [math.fsum(p['mass']*center(p)[i] for p in parts)/mass for i in (0, 1)]


def attitude(parts):
    head = next(p for p in parts if p['kind'] == 'head')
    feet = [p for p in parts if p['kind'] == 'foot']
    need(feet, 'No authored feet')
    h = center(head)
    vector = [math.fsum(center(p)[i] for p in feet)/len(feet)-h[i] for i in (0, 1)]
    need(math.hypot(*vector) > 0, 'Undefined head-to-foot attitude')
    return vector


def angle_degrees(first, other):
    return math.degrees(math.atan2(first[0]*other[1]-first[1]*other[0], first[0]*other[0]+first[1]*other[1]))


def ac201(folder, engine):
    spec = PLAN['ac201']
    initial = load(folder/'Slug-spawn.json')
    parts = bodies(initial)
    origin = com(parts)
    vector = attitude(parts)
    airborne = []
    angles = [0.]
    count = sleeping = 0
    first_sleep = None
    final = None
    for row in rows(folder/'Slug.jsonl'):
        need(row['tick'] == count and row['input_mask'] == 0 and row['candidate_enabled'] is False, 'Wrong stability experiment')
        final = row['state']
        p = bodies(final)
        if all(not b['grounded'] for b in p):
            airborne.append(count)
        angles.append(angle_degrees(vector, attitude(p)))
        if final['sleep']['asleep']:
            sleeping += 1
            if first_sleep is None:
                first_sleep = count
        count += 1
    done = completed(engine['Slug'], spec['ticks'], count)
    need(final is not None, 'No measured ticks')
    delta = [a-b for a, b in zip(com(bodies(final)), origin)]
    displacement = math.hypot(*delta)
    bound = spec['body_length_wu']*spec['displacement_body_lengths_max']
    return dict(preset='Slug', ticks=count, completed=done, termination=engine['Slug'],
                AC201a=dict(passed=done and not airborne and max(map(abs, angles)) <= spec['attitude_degrees_max'],
                            all_parts_airborne_ticks=airborne, max_attitude_change_degrees=max(map(abs, angles)),
                            peak_to_peak_degrees=max(angles)-min(angles), initial_attitude_vector=vector,
                            criterion_degrees=spec['attitude_degrees_max']),
                AC201b=dict(passed=done and displacement <= bound, net_com_delta_wu=delta,
                            net_com_displacement_wu=displacement, net_com_displacement_px=displacement*150,
                            body_lengths=displacement/.90, owner_limit_wu=bound, margin=bound/displacement if displacement else None,
                            half_body_length_limit_would_fail=displacement > .45,
                            steady_creep_flip_boundary_px_s=13.5,
                            owner_steady_reference='85.5px/.570WU/.633BL/1.58x; not a substitute for measured from-spawn displacement'),
                AC201s=dict(passed=done and first_sleep is not None, first_sleep_tick=first_sleep,
                            sleeping_ticks=sleeping, status='FAILED' if first_sleep is None else 'PASS',
                            predicate='unmodified F52', carry_over='M1.1 contact-model work', original_GDD='settle AND sleep within4s preserved'))


def segment_errors(parts):
    out = []
    for i, p in enumerate(parts):
        error = abs(math.hypot(p['b']['x']-p['a']['x'], p['b']['y']-p['a']['y'])-p['length'])
        need(math.isfinite(error), 'Nonfinite segment')
        out.append(dict(error_wu=error, part=i, kind=p['kind']))
    return out


def ac202(folder, engine):
    result = {}
    for name in PLAN['ac202']['presets']:
        maxima = {}
        count = 0
        phases_max = {}
        for r in rows(folder/f'{name}.jsonl'):
            need(r['tick'] == count and r['input_mask'] == (count//60)%4 and r['candidate_enabled'] is True, 'Wrong correctness arm')
            parts = bodies(r['state'])
            values = segment_errors(parts)
            groups = {kind: [v for v in values if v['kind'] == kind] for kind in ('head','motor','passive','limb','foot')}
            groups['articulated_limb'] = [v for v in values if v['kind'] in ('motor','passive','limb')]
            groups['all'] = values
            for kind, candidates in groups.items():
                if candidates:
                    v = max(candidates, key=lambda v:v['error_wu'])
                    if kind not in maxima or v['error_wu'] > maxima[kind]['error_wu']:
                        maxima[kind] = dict(v, tick=count)
            if r['phases']:
                need('after_diagnostic_final_distance' in r['phases'], 'Missing post-contact pass')
                for phase, states in r['phases'].items():
                    error = max(abs(math.hypot(s['b'][0]-s['a'][0], s['b'][1]-s['a'][1])-s['rest_length']) for s in states)
                    phases_max[phase] = max(phases_max.get(phase, 0.), error)
                tail = r['phases']['after_diagnostic_final_distance']
                need(all(s['a'] == [p['a']['x'],p['a']['y']] and s['b'] == [p['b']['x'],p['b']['y']] for s, p in zip(tail, parts, strict=True)), 'Projection is not completed-tick position')
            else:
                need(r['state']['sleep']['asleep'], 'Missing awake phases')
            count += 1
        done = completed(engine[name], 7200, count)
        need(maxima.get('articulated_limb') is not None, 'Empty limb criterion cannot pass')
        result[name] = dict(ticks=count, completed=done, termination=engine[name], maxima=maxima,
                            phase_all_parts_maxima=phases_max,
                            passed=done and maxima['articulated_limb']['error_wu'] <= .05)
    return dict(presets=result, passed=all(p['passed'] for p in result.values()),
                scope='ONE post-contact candidate, same rows/code; all articulated segments, literal limb/head/foot separately; defaultfalse pending adoption',
                adoption='REPORT FOR ADOPTION' if all(p['passed'] for p in result.values()) else 'FAILING: M1.1 carry-over with measured maximum')


def fa3(folder, engine):
    presets = {}
    for name in PLAN['fa3']['presets']:
        previous = load(folder/f'{name}-spawn.json')
        count = sleep_ticks = 0
        wakes = []
        new_contacts = 0
        for r in rows(folder/f'{name}.jsonl'):
            need(r['tick'] == count and r['input_mask'] == 0 and r['candidate_enabled'] is False, 'Wrong static scene')
            observed = r['observation']
            current = r['state']
            new = [i for i, (b,a) in enumerate(zip(bodies(previous),bodies(current),strict=True)) if not b['grounded'] and a['grounded']]
            new_contacts += len(new)
            if observed['wake_reason'] == 'new_grounded':
                need(previous['sleep']['asleep'] and observed['sleep_breaking_new_grounded_parts'], 'Fake F42 wake')
                wakes.append(dict(tick=count, parts=observed['sleep_breaking_new_grounded_parts']))
            elif previous['sleep']['asleep']:
                need(not new and current['sleep']['asleep'], 'Missed sleep-breaking contact')
            if current['sleep']['asleep']:
                sleep_ticks += 1
            if 'awake_solver_trace_before_sleep_parking' in observed:
                need(observed['awake_solver_trace_before_sleep_parking']['contact_samples'], 'Missing real static contact trace')
            previous = current
            count += 1
        done = completed(engine[name], 600, count)
        presets[name] = dict(ticks=count, completed=done, termination=engine[name], sleep_breaking_contacts=len(wakes),
                             sleep_breaking_events=wakes, sleeping_ticks=sleep_ticks, ordinary_new_grounded_parts=new_contacts,
                             passed=done and not wakes)
    return dict(passed=all(p['passed'] for p in presets.values()), presets=presets,
                caveat='Zero actual sleep-breaking contacts is the authored policy criterion. Sleeping opportunities reported explicitly: awake creeping is NOT resting, and zero opportunities do not characterise sustained sleep or grip.')


def soak(folder, engine, batch):
    data = list(rows(folder/'runs.jsonl'))
    need(len(data) == 10 and [r['run_id'] for r in data] == list(range(batch*10,(batch+1)*10)), 'Missing/duplicate runs')
    for r in data:
        need(r['seed'] == PLAN['soak']['seed_base']+r['run_id'], 'Seed changed')
        need(r['preset'] == ['Slug','Hopper','TwinRoller'][r['run_id']%3], 'Wrong preset')
        need(r['candidate_enabled'] is False and r['target_ticks'] == 7200, 'Wrong soak configuration')
        done = completed(r, 7200, r['ticks']) and not r['nonfinite_events'] and r['finite_float_checks'] > 0
        need(r['completed'] == done, 'False completed verdict')
        need(len(r['state_stream_sha256']) == len(r['input_stream_sha256']) == 64, 'Missing run hashes')
    return dict(batch=batch, runs=[{k:v for k,v in r.items() if k not in ('final_state','offending_observation')} for r in data],
                passed=all(r['completed'] for r in data), numerical_soak=True, determinism_attempt=False)


def aggregate(root):
    found = list(root.glob('**/report.json'))
    reports = [load(f) for f in found]
    batches = [r for r in reports if 'batch' in r]
    need(len(batches) == 20 and sorted(r['batch'] for r in batches) == list(range(20)), 'Missing/duplicate 20 soak batches')
    runs = sorted([run for r in batches for run in r['runs']], key=lambda r:r['run_id'])
    need([r['run_id'] for r in runs] == list(range(200)), 'Missing/duplicate 200 runs')
    return dict(runs=runs, runs_required=200, runs_completed=sum(r['completed'] for r in runs),
                ticks_completed=sum(r['ticks'] for r in runs), target_ticks=200*7200,
                passed=all(r['completed'] for r in runs), failed_runs=[r for r in runs if not r['completed']],
                scope=PLAN['soak'], determinism_attempt=False)


def main(mode, folder, batch=-1):
    try:
        engine = load(folder/'engine.json') if mode != 'aggregate' else None
        r = aggregate(folder) if mode == 'aggregate' else soak(folder,engine,batch) if mode == 'soak' else {'ac201':ac201,'ac202':ac202,'fa3':fa3}[mode](folder,engine)
        r['verification_passed'] = True
    except (OSError, ValueError, KeyError, TypeError, StopIteration) as exc:
        r = dict(verification_passed=False, error=f'{type(exc).__name__}: {exc}')
    (folder/'aggregate.json' if mode == 'aggregate' else folder/'report.json').write_text(json.dumps(r,indent=2)+'\n')
    compact = {k:v for k,v in r.items() if k != 'runs'}
    if 'runs' in r:
        compact.update(runs_logged=len(r['runs']), runs_completed=sum(x['completed'] for x in r['runs']), ticks_completed=sum(x['ticks'] for x in r['runs']), failed_runs=[x for x in r['runs'] if not x['completed']])
    print('M1 R27 report: '+json.dumps(compact,separators=(',',':')))
    return 0 if r['verification_passed'] and r.get('passed',r.get('AC201a',{}).get('passed',False) and r.get('AC201b',{}).get('passed',False)) else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv[1],Path(sys.argv[2]),int(sys.argv[3]) if len(sys.argv)>3 else -1))
