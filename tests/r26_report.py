#!/usr/bin/env python3
"""R26 last bounded diagnostics. Raw-data validation, not automatic adoption.
No fabricated qualifying loads, physical tolerances, or causal fit thresholds.
"""
import json
import math
import sys
from collections import Counter, defaultdict
from pathlib import Path
from load_trace_report import close
from load_long_report import verify_all
from load_motor_report import resource, thrust_summary
from load_spring_report import joint_summary
from load_saturation_report import strength

ROOT = Path(__file__).resolve().parents[1]
PHASES = ('after_integration', 'after_iteration_distance', 'after_final_hinge',
          'after_final_angular', 'after_final_self_contact',
          'after_contact_pass_0', 'after_contact_pass_1')
BRANCHES = ('below', 'at_or_above', 'two_foot_grip', 'airborne', 'N0_no_grip')


def require(condition, message):
    if not condition:
        raise ValueError(message)


def rows(path):
    with path.open() as f:
        for line in f:
            yield json.loads(line)


def complete(end, count):
    return (end['termination_reason'] == 'completed' and end['failing_tick'] is None
            and end['status'] == 0 and end['observer_status'] == 0
            and end['ticks'] == count == end['target_ticks'])


def retention(event, expected_mu, *, may_grip=None):
    """Independent clamp/static-override audit, including effective intervention."""
    require(event['material_friction'] == expected_mu == event['sample_friction'],
            'Intervention did not change BOTH material and terrain friction')
    if may_grip is not None:
        require(event['may_grip'] == may_grip, 'Actual grip predicate differs from raw N/load/geometry')
    if not event['active']:
        require(event['retained'] is None, 'Inactive candidate claims tangent response')
        return 'inactive'
    static = abs(event['tangent_before']) < resource('physics_static_slip_wu_s')
    factor = min(event['material_friction'], event['sample_friction'])
    if event['may_grip']:
        factor *= resource('physics_foot_grip_bias')
    retained = 0. if static else event['tangent_before'] * (1 - min(1., factor))
    require(event['static_branch'] == static and close(event['retained'], retained),
            'Raw friction response does not match resource-owned operator')
    require(close(event['tangent_after'], retained), 'Actual tangent did not reach retained target')
    return 'static_override' if static else ('dynamic_clamped' if factor >= 1 else 'dynamic_unsaturated')


def d1(root, engine):
    arms = {}
    for mu in (.9, .3, 1.8, 3.6):
        name = f'mu_{mu}'
        raw = list(rows(root / f'{name}.jsonl'))
        require(complete(engine[name], len(raw)), f'{name}: incomplete diagnostic')
        require(all(r['diagnostic_friction'] == mu for r in raw), 'Friction identity changed')
        verify_all(raw)  # unchanged counts/raw endpoints/full six-phase F31 verifier
        for r in raw:
            for e in r['contact_samples']:
                retention(e, mu)
        # Check every tick's complete F56 in nonoverlapping 300-tick windows,
        # not merely an average over the last300; literal predicate remains false.
        from load_external_report import external_identity
        identities = [external_identity(raw[offset:offset+300]) for offset in range(0, 6000, 300)]
        tail = raw[-300:]
        branches = Counter(retention(e, mu) for r in tail for e in r['contact_samples'])
        a = thrust_summary(raw)
        a.update(friction=mu, termination=engine[name], joints=joint_summary(raw),
                 F56_literal_lateral_passed=identities[-1]['F56_literal_lateral_passed'],
                 F56_literal_vector_passed=identities[-1]['F56_literal_vector_passed'],
                 F56_max_abs_per_tick_complete_residual=max(i['axes'][a]['max_abs_per_tick_full_residual'] for i in identities for a in ('x','y')),
                 F56_max_abs_window_complete_residual=max(abs(i['axes'][a]['sums']['full_residual_from_sides']) for i in identities for a in ('x','y')),
                 drive=strength(raw), effective_operator_counts_last300=dict(branches),
                 ungripped_dynamic_retention=1-min(1., mu),
                 gripping_dynamic_retention=1-min(1., mu*resource('physics_foot_grip_bias')),
                 note='ZERO INPUT internal-load rectification; thrust is signed net friction impulse, not commanded locomotion')
        arms[name] = a
    reference = arms['mu_0.9']
    require(reference['drift_px_s'] == 8.550150769956836,
            'P-B no-brace reference differs from archived exact drift; no new arms authorised')
    for a in arms.values():
        a['drift_over_reference'] = a['drift_px_s']/reference['drift_px_s']
        a['thrust_over_reference'] = a['mean_thrust_force_n']/reference['mean_thrust_force_n']
        a['coefficient_over_reference'] = a['friction']/.9
    return {'diagnostic_only': True, 'arms': arms,
            'operator_caveat': 'Static override always retains zero. 1.8 and 3.6 both clamp dynamic retention to zero, and gripping 0.9 already clamps. Flat response of clamped arms alone CANNOT identify an upstream cause. No new intervention is permitted.',
            'causal_decision': 'Evaluate reported drift/thrust together with effective-operator counts; do not equate coefficient with unsaturated Coulomb friction.',
            'measurement_complete': True, 'adopted': False}


def length_errors(parts):
    require([p['part'] for p in parts] == list(range(8)), 'Missing/duplicate Hopper distance row')
    out = []
    for p in parts:
        dx = p['b'][0]-p['a'][0]
        dy = p['b'][1]-p['a'][1]
        e = abs(math.sqrt(dx*dx+dy*dy)-p['rest_length'])
        require(math.isfinite(e) and close(e, p['error_wu']), 'Forged phase error')
        out.append((e, p['part'], p['kind']))
    return out


def worst(values):
    return {'all': max(values), 'limb': max(v for v in values if v[2] == 'limb')}


def d2(root, engine):
    arms = {}
    for arm in ('baseline', 'final_distance'):
        maxima = {}
        count = awake = 0
        output = (root/f'{arm}-phase-maxima.jsonl').open('w')
        for r in rows(root/f'{arm}.jsonl'):
            require(r['tick'] == count and r['input_mask'] == (count//60)%4, 'Wrong ordering script')
            require(r['diagnostic_final_distance_pass'] == (arm == 'final_distance'), 'Wrong diagnostic arm')
            if arm == 'baseline':
                require(r['observer_equal'] is True, 'Phase observer altered baseline physics')
            physical = []
            for i, b in enumerate(r['bodies']):
                e = abs(math.hypot(b['b']['x']-b['a']['x'], b['b']['y']-b['a']['y'])-b['length'])
                require(math.isfinite(e), 'Nonfinite final length')
                physical.append((e, i, b['kind']))
            phases = {}
            if r['phases']:
                expected = set(PHASES) | ({'after_diagnostic_final_distance'} if arm == 'final_distance' else set())
                require(set(r['phases']) == expected, 'Missing/mislabeled ordering phase')
                for name, parts in r['phases'].items():
                    for p, b in zip(parts, r['bodies'], strict=True):
                        require(p['rest_length'] == b['length'] and p['kind'] == b['kind'], 'Distance row identity changed')
                    phases[name] = worst(length_errors(parts))
                require(all(close(a, b) for p, b in zip(r['phases']['after_contact_pass_1'], r['bodies'])
                            for a, b in zip(p['a']+p['b'], [b['a']['x'], b['a']['y'], b['b']['x'], b['b']['y']])),
                        'Later hidden positional edit after observed contact pass')
                awake += 1
            else:
                require(r['sleep']['asleep'], 'Missing awake phase observations')
            phases['completed'] = worst(physical)
            for phase, kinds in phases.items():
                for kind, value in kinds.items():
                    key = f'{phase}/{kind}'
                    if key not in maxima or value[0] > maxima[key]['error_wu']:
                        maxima[key] = dict(error_wu=value[0], tick=count, part=value[1], kind=value[2])
            output.write(json.dumps({'tick': count, 'phases': phases}, separators=(',', ':'))+'\n')
            count += 1
        output.close()
        require(complete(engine[arm], count), f'{arm}: incomplete7200')
        arms[arm] = dict(ticks=count, awake_ticks=awake, parked_ticks=count-awake,
                         maxima=maxima, termination=engine[arm],
                         true_limb_passed=maxima['completed/limb']['error_wu'] <= .05,
                         all_parts_passed=maxima['completed/all']['error_wu'] <= .05)
    return {'diagnostic_only': True, 'preset': 'Hopper', 'arms': arms,
            'phase_semantics': 'after_iteration_distance is the last existing distance block BEFORE hinge/angular/self-contact. after_diagnostic_final_distance is ONE added traversal AFTER all position iterations, BEFORE velocity/contact cleanup. Completed-tick true limbs determine the unchanged .05 criterion. No pass is moved after contact cleanup.',
            'ordering_candidate_meets_limb_criterion': arms['final_distance']['true_limb_passed'],
            'measurement_complete': True, 'adopted': False}


def terrain_sample(x, y, ledge):
    cell = resource('physics_sdf_cell_wu')
    gx, gy = (x+12)/cell, (y+4)/cell
    require(0 <= gx <= 96 and 0 <= gy <= 48, 'SDF read outside authored bounds')
    ix, iy = min(math.floor(gx), 95), min(math.floor(gy), 47)
    tx, ty = gx-ix, gy-iy
    def value(i, j):
        xx, yy = -12+i*cell, -4+j*cell
        if not ledge:
            return yy
        qx, qy = -xx, yy
        corner = math.hypot(max(qx, 0.), max(qy, 0.))+min(max(qx, qy), 0.)
        return min(corner, yy+2.5)
    aa, ab, ba, bb = value(ix, iy), value(ix+1, iy), value(ix, iy+1), value(ix+1, iy+1)
    lo, hi = aa*(1-tx)+ab*tx, ba*(1-tx)+bb*tx
    dx, dy = ((ab-aa)*(1-ty)+(bb-ba)*ty)/cell, (hi-lo)/cell
    norm = math.hypot(dx, dy)
    require(norm > 0., 'Undefined fixture normal')
    return lo*(1-ty)+hi*ty, dx/norm, dy/norm


class Events:
    """Consecutive ticks, not contact candidates or repeated solver passes."""
    def __init__(self):
        self.last = {}
        self.episodes = defaultdict(list)
    def add_tick(self, tick, keys):
        for branch, part in keys:
            key = (branch, part)
            if self.last.get(key) != tick-1:
                self.episodes[branch].append({'part': part, 'start_tick': tick, 'end_tick': tick})
            else:
                # There may be simultaneous episodes for different feet.
                episode = next(e for e in reversed(self.episodes[branch]) if e['part'] == part)
                episode['end_tick'] = tick
            self.last[key] = tick
    def report(self):
        return {branch: {'independent_events': len(self.episodes[branch]),
                         'independent_true_grip_events': len(self.episodes[branch]) if branch in ('at_or_above', 'two_foot_grip') else 0,
                         'event_durations_ticks': [e['end_tick']-e['start_tick']+1 for e in self.episodes[branch]],
                         'events': self.episodes[branch]}
                for branch in BRANCHES}


def validate_fa5_row(r, previous, spec):
    """No synthetic observations: recompute N, raw SDF normals, load and predicate."""
    require(r['status'] == 0 and r['observer_on_off_physical_state_equal'], 'Incomplete/observer-altered row')
    bodies = {b['part']: b for b in r['feet']+r['other_bodies']}
    feet = {b['part'] for b in r['feet']}
    require(set(bodies) == set(range(8)) and feet == {5, 7}, 'Wrong authored Hopper')
    require(r['previous_grounded_parts'] == previous, 'Prior completed grounded flags changed')
    n = sum(i in feet for i in previous)
    require(n == r['previous_grounded_feet'], 'Frozen N mismatch')
    weight = math.fsum(b['mass'] for b in bodies.values())*abs(resource('physics_gravity_wu_s2'))
    require(close(weight, r['weight_n']), 'Mass/weight mismatch')
    threshold = max(resource('physics_grip_normal_force_floor'), resource('physics_grip_normal_force_ratio')*weight/n) if n else None
    distribution = []
    keys = set()
    candidate_counts = Counter()
    active_counts = Counter()
    require([b['velocity_pass'] for b in r['contact_batches']] == [0, 1], 'Missing independent passes')
    for batch in r['contact_batches']:
        parts = batch['parts']
        require([p['part'] for p in parts] == list(range(8)), 'Missing batch geometry')
        bottom = min(p['bottom_wu'] for p in parts)
        for axis in ('x', 'y'):
            require(close(math.fsum(p[f'hinge_{axis}_ns'] for p in parts), 0.), 'Internal hinge leak')
            require(close(math.fsum(p['extra'][axis] for p in parts), 0.), 'Internal self-contact leak')
        gripping = []
        for part in parts:
            i = part['part']
            b = bodies[i]
            require(close(part['bottom_wu'], min(part['a'][1], part['b'][1])-b['radius_wu']), 'Forged pre-contact bottom')
            lowest = part['bottom_wu'] <= bottom+resource('physics_contact_slop_wu')
            require(part['lowest'] == lowest, 'Wrong global lowest mask')
            distance, nx, ny = terrain_sample(*part['a'], spec['terrain'] == 'ledge')
            require(all(close(part['normal'][k], v) for k, v in zip(('distance', 'nx', 'ny'), (distance, nx, ny))), 'Raw normal differs from independently reconstructed fixture SDF')
            load = max(0., -(part['hinge_x_ns']+part['extra']['x'])*nx*60
                       -(b['mass']*resource('physics_gravity_wu_s2')/60+part['hinge_y_ns']+part['extra']['y'])*ny*60)
            require(close(load, part['applied_load_n']), 'Load not derived from gravity/real hinge/self-contact impulse')
            events = [e for e in r['contact_samples'] if e['part'] == i and e['velocity_pass'] == batch['velocity_pass']]
            require(events and [e['sample_index'] for e in events] == list(range(len(events))), 'Missing/duplicate real contact samples')
            may_grip = i in feet and n > 0 and lowest and load >= threshold
            active_prefix = False
            for e in events:
                require(e['active'] == (e['distance_wu'] <= b['radius_wu']+resource('physics_contact_slop_wu')), 'Active predicate mismatch')
                retention(e, .9, may_grip=may_grip)
                active_prefix |= e['active']
                require(e['gripping_after'] == (may_grip and active_prefix), 'Actual pass-level grip state differs from predicate')
            active = active_prefix
            expected_grip = active and may_grip
            if batch['velocity_pass'] == 1:
                require(b['grounded'] == active and b['gripping'] == expected_grip, 'Completed body flags differ from reconstructed law')
            if i not in feet:
                continue
            branch = ('airborne' if not active else 'N0_no_grip' if not n else
                      ('at_or_above' if load >= threshold else 'below') if lowest else 'ineligible_not_lowest')
            keys.add((branch, str(i)))
            candidate_counts[branch] += len(events)
            active_counts[branch] += sum(e['active'] for e in events)
            distribution.append(dict(branch=branch, N=n, threshold_n=threshold, load_n=load,
                                     tick=r['tick'], velocity_pass=batch['velocity_pass'], part=i,
                                     lowest=lowest, gripping=expected_grip))
            if expected_grip:
                gripping.append(i)
        if len(gripping) == 2:
            keys.add(('two_foot_grip', '5+7'))
            distribution.append(dict(branch='two_foot_grip', N=n, threshold_n=threshold,
                                     load_n=None, tick=r['tick'], velocity_pass=batch['velocity_pass'], part='5+7'))
    grounded = sorted(b['part'] for b in bodies.values() if b['grounded'])
    require(grounded == r['grounded_parts'], 'Completed grounded set mismatch')
    return grounded, keys, distribution, candidate_counts, active_counts


def fa5(root, engine):
    plan = json.loads((ROOT/'tests/fixtures/r26_fa5.json').read_text())
    cases = {}
    totals = Counter()
    for spec in plan['cases']:
        name = spec['id']
        count = 0
        previous = []
        episodes = Events()
        counts, candidates, active = Counter(), Counter(), Counter()
        distribution = defaultdict(list)
        ledger = []
        ledge_departure_at = None
        had_foot_support = False
        for r in rows(root/f'{name}.jsonl'):
            require(r['tick'] == count and r['fixture'] == name, 'Unordered/foreign fixture row')
            require(r['input_mask'] == ((count//60)%4 if spec['input'] == 'blocks60' else 0), 'Wrong authored input')
            previous, keys, values, cc, ac = validate_fa5_row(r, previous, spec)
            if count == 0 and spec['lift'] > 0:
                require(all(not f['grounded'] and not f['gripping'] for f in r['feet']), 'Airborne fixture premise failed')
            if name == 'ledge_departure':
                feet = r['feet']
                if (had_foot_support and ledge_departure_at is None
                        and all(not f['grounded'] for f in feet)
                        and all((f['ax']+f['bx'])/2 < 0 for f in feet)
                        and min(f['bottom_wu'] for f in feet) > -2.5+resource('physics_contact_slop_wu')):
                    ledge_departure_at = count
                had_foot_support |= any(f['grounded'] for f in feet)
            episodes.add_tick(count, keys)
            for value in values:
                counts[value['branch']] += 1
                distribution[(value['branch'], value['N'], value['threshold_n'])].append(value['load_n'])
            candidates.update(cc)
            active.update(ac)
            ledger.append(r)
            count += 1
        # Preserve raw provenance. Branch coverage alone never establishes F56.
        # Flat fixtures have the unchanged independent contact/F31 verifier;
        # all fixtures above independently reproduce N/load/normal and pass flags.
        from load_external_report import external_identity
        for start in range(0, count-299, 300):
            external_identity(ledger[start:start+300])
        totals.update(counts)
        cases[name] = dict(ticks=count, termination=engine[name],
                           completed=complete(engine[name], count),
                           ledge_departure_tick=ledge_departure_at,
                           foot_or_pair_pass_counts=dict(counts),
                           capsule_candidate_counts=dict(candidates), capsule_active_counts=dict(active),
                           events=episodes.report(),
                           N_threshold_distribution=[dict(branch=k[0], N=k[1], threshold_n=k[2],
                               foot_or_pair_passes=len(v), load_n_min=min((x for x in v if x is not None), default=None),
                               load_n_max=max((x for x in v if x is not None), default=None))
                               for k, v in sorted(distribution.items(), key=lambda item: str(item[0]))])
    missing = [b for b in BRANCHES if totals[b] == 0]
    return dict(gate='FA5', cases=cases, totals=dict(totals), missing_coverage=missing,
                passed=all(c['completed'] for c in cases.values()) and not missing and cases['ledge_departure']['ledge_departure_tick'] is not None,
                event_definition=plan['events'],
                scope='Natural authored Hopper, no pose/velocity/qualifying-load injection. Coverage is not a claim of long-lived robust grip; independent episode counts/durations expose transient-only coverage. No matrix upgrade automatically.')


def main(mode, root):
    try:
        engine = json.loads((root/'engine.json').read_text())
        result = {'d1': d1, 'd2': d2, 'fa5': fa5}[mode](root, engine)
        result['verification_passed'] = True
    except (ValueError, KeyError, AssertionError, OSError, TypeError) as exc:
        result = dict(verification_passed=False, error=f'{type(exc).__name__}: {exc}')
    (root/'report.json').write_text(json.dumps(result, indent=2)+'\n')
    console = result
    if mode == 'fa5' and result['verification_passed']:
        console = {k: v for k, v in result.items() if k != 'cases'}
        console['cases'] = {name: {
            **{k: v for k, v in case.items() if k not in ('termination', 'events')},
            'termination': {k: v for k, v in case['termination'].items() if k not in ('initial_bodies', 'failed_pre_step_bodies')},
            'events': {branch: {k: v for k, v in event.items() if k != 'events'}
                       for branch, event in case['events'].items()}}
            for name, case in result['cases'].items()}
    print('M1 R26 report: '+json.dumps(console, separators=(',', ':')))
    return 0 if result['verification_passed'] and result.get('passed', True) else 1


if __name__ == '__main__':
    sys.exit(main(sys.argv[1], Path(sys.argv[2])))
