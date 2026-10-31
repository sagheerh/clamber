"""Read-only proof of archived ORIGINAL idle predicates; never an M1/replay verdict.

Changed-source runs are NOT determinism attempts. Long-arm failures are retained.
No clock, repair, normalization, force invention or solver shadow is performed.
"""
import gzip
import hashlib
import json
import math
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SOURCES = {
    'f101721f17cf': 'f101721f17cfaa82db5446106f544cd51da3dc78',
    '8496abfa354a': '8496abfa354ac084a463d2c177b6d6a9318198cc',
    'bccae29d24ad': 'bccae29d24ad9e7aa13148ac2b864db5a323cc45',
    'c49fcc66ee9f': 'c49fcc66ee9f09a1ebb225a5de8dcc6a41cda734',
}


def require(condition, reason):
    if not condition:
        raise ValueError(reason)


def finite(value):
    if isinstance(value, float):
        return math.isfinite(value)
    if isinstance(value, dict):
        return all(finite(v) for v in value.values())
    if isinstance(value, list):
        return all(finite(v) for v in value)
    return True


def com(bodies):
    mass = sum(b['mass'] for b in bodies)
    return [sum(b['mass']*(b['a'][ax]+b['b'][ax])/2 for b in bodies)/mass
            for ax in ['x', 'y']]


def audit_rows(rows, spawn, report):
    require(len(rows) == 600 and finite(rows), 'full600 contiguous finite data')
    original = spawn['rig']['physical']['bodies']
    start_com = com(original)
    initial = [original[0]['b'][ax]-original[0]['a'][ax] for ax in ['x', 'y']]
    max_angle = 0.0
    airborne = 0
    first_sleep = -1
    for tick, row in enumerate(rows):
        require(row['tick'] == tick and row['input_mask'] == 0, 'original idle tick/input')
        state = row['state']
        bodies, sleep = state['physical']['bodies'], state['sleep']
        require(state['physical']['ticks'] == tick+1 and len(bodies) == 3, 'actual600 physical clock')
        for b, old in zip(bodies, original):
            require(all(b[k] == old[k] for k in ['mass', 'radius', 'length', 'kind']), 'unchanged real capsules')
        dx, dy = [bodies[0]['b'][ax]-bodies[0]['a'][ax] for ax in ['x', 'y']]
        angle = abs(math.degrees(math.atan2(initial[0]*dy-initial[1]*dx, initial[0]*dx+initial[1]*dy)))
        max_angle = max(max_angle, angle)
        airborne += not any(b['grounded'] for b in bodies)
        require(row['length_peak_wu'] <= .05 and row['penetration_peak_wu'] <= .02*(1+1e-9), 'original length/penetration limits')
        if sleep['asleep']:
            if first_sleep < 0:
                first_sleep = tick
            require(tick >= 29 and sleep['still_ticks'] >= 30, 'original dwell count')
            require(sleep['max_body_com_displacement_wu'] <= .001 and sleep['max_body_dwell_displacement_wu'] <= .001, 'original tick AND anchored dwell')
            anchors = sleep['dwell_start']
            require(len(anchors) == len(bodies), 'real anchored dwell body count')
            before = original if tick == 0 else rows[tick-1]['state']['physical']['bodies']
            for b, anchor, prior in zip(bodies, anchors, before):
                current_com, anchor_com, prior_com = com([b]), com([anchor]), com([prior])
                require(math.hypot(current_com[0]-anchor_com[0], current_com[1]-anchor_com[1]) <= .001, 'actual anchored .001WU')
                require(math.hypot(current_com[0]-prior_com[0], current_com[1]-prior_com[1]) <= .001, 'actual per-tick .001WU')
            require(all(b[e]['velocity_'+ax] == 0.0 for b in bodies for e in ['a', 'b'] for ax in ['x', 'y']), 'actual sleep zero velocities')
    end_com = com(rows[-1]['state']['physical']['bodies'])
    displacement = math.hypot(end_com[0]-start_com[0], end_com[1]-start_com[1])
    require(max_angle <= 15.0 and airborne == 0 and displacement <= .90, 'original posture/airborne/actual-spawn displacement')
    require(0 <= first_sleep <= 240, 'ORIGINAL4s, not eventual600 sleep')
    require(report['ticks'] == report['target_ticks'] == 600 and report['sleep_by_original_4s'], 'honest full-arm report')
    require(report['first_sleep_tick'] == first_sleep and report['max_attitude_deg'] == max_angle and report['net_com_wu'] == displacement and report['airborne_ticks'] == airborne, 'metrics independently agree with actual rows')
    return dict(ticks=600, max_attitude_deg=max_angle, airborne_ticks=airborne,
                net_com_wu=displacement, first_sleep_tick=first_sleep,
                original4s_pass=True, scope='ONE archived idle arm ONLY; not production/M1/replay')


def audit(folder):
    require(folder.name in SOURCES, 'explicit immutable source registration')
    source = json.loads((folder/'source.json').read_text())
    require(source['source_commit'] == source['checkout_head'] == SOURCES[folder.name] and not source['checkout_dirty'], 'exact clean source')
    require(source['engine_build'] == '4.7.2.stable.official.ed1daf0bf', 'exact engine')
    transport = json.loads((folder/'transport-index.json').read_text())
    require(transport['source_commit'] == source['source_commit'], 'transport source')
    pin = transport['raw_traces']['idle-Slug.jsonl']
    packed = (folder/'idle-Slug.jsonl.gz').read_bytes()
    raw = gzip.decompress(packed)
    for data, label in [(packed, 'gzip'), (raw, 'raw')]:
        require(len(data) == pin[label+'_bytes'] and hashlib.sha256(data).hexdigest() == pin[label+'_sha256'], 'full transport '+label)
    rows = [json.loads(line) for line in raw.splitlines()]
    spawn = json.loads((folder/'idle-Slug-spawn.json').read_text())
    report = json.loads((folder/'idle-Slug-summary.json').read_text())
    result = audit_rows(rows, spawn, report)
    summary = json.loads((folder/'summary.json').read_text())
    require(summary['status'] == 'STOP; inspect first failure; NOT ADOPTED', 'later failure cannot become adoption')
    slug = summary['arms']['length-Slug']
    if slug['termination'] == 'step/nonfinite failure':
        require(summary['not_run_arms'] == ['length-Hopper', 'length-TwinRoller'], 'later arms NOTRUN')
    else:
        require(slug['ticks'] == slug['target_ticks'] == 7200 and slug['termination'] == 'completed; candidate metrics satisfied', 'full Slug geometry arm')
        require(summary['arms']['length-Hopper']['termination'] == 'step/nonfinite failure' and summary['not_run_arms'] == ['length-TwinRoller'], 'Hopper failure remains STOP')
    result.update(source_commit=source['source_commit'], source_ci_run=source['source_ci_run'], raw_sha256=pin['raw_sha256'], subsequent_slug_failure=slug.get('failing_tick'), subsequent_hopper_failure=summary['arms'].get('length-Hopper', {}).get('failing_tick'))
    return result


def audit_slug_geometry(folder):
    """Complete real 7200 states/input/wake subset; NOT full force/feel/FA/replay."""
    audit(folder)
    transport = json.loads((folder/'transport-index.json').read_text())
    pin = transport['raw_traces']['length-Slug.jsonl']
    packed = (folder/'length-Slug.jsonl.gz').read_bytes()
    raw = gzip.decompress(packed)
    for data, label in [(packed, 'gzip'), (raw, 'raw')]:
        require(len(data) == pin[label+'_bytes'] and hashlib.sha256(data).hexdigest() == pin[label+'_sha256'], 'long transport '+label)
    rows = [json.loads(line) for line in raw.splitlines()]
    result = audit_geometry_rows(rows)
    result.update(source_commit=SOURCES[folder.name], raw_sha256=pin['raw_sha256'])
    return result


def audit_geometry_rows(rows):
    require(len(rows) == 7200 and finite(rows), 'actual full7200 finite geometry rows')
    wake_ticks = []
    for tick, row in enumerate(rows):
        mask = (tick//60) % 4
        require(row['tick'] == tick and row['input_mask'] == mask, 'actual held/released input stream')
        require(row['state']['physical']['ticks'] == tick+1, 'actual7200 physical clock')
        require(row['length_peak_wu'] <= .05 and row['penetration_peak_wu'] <= .02*(1+1e-9), 'original long geometry limits')
        sleep = row['state']['sleep']
        if mask:
            require(not sleep['asleep'] and sleep['still_ticks'] == 0, 'any real input rearms sleep')
        if sleep['last_wake_tick'] == tick:
            wake_ticks.append(tick)
    require(rows[59]['state']['sleep']['asleep'] and rows[60]['state']['sleep']['last_wake_tick'] == 60, 'nonvacuous first actual sleep-to-input wake')
    require(any(b[e]['velocity_'+ax] != 0.0 for b in rows[60]['state']['physical']['bodies'] for e in ['a', 'b'] for ax in ['x', 'y']), 'actual motion on held input, not metadata park')
    return dict(ticks=7200, first_actual_wake_tick=60, actual_wake_ticks=wake_ticks,
                scope='Slug long geometry + input-wake subset ONLY; not FA3/feel/force/adoption/replay')


if __name__ == '__main__':
    for name in SOURCES:
        print(json.dumps(audit(ROOT/'tests/fixtures/m1_articulated_execution'/name), sort_keys=True))
    for name in ['bccae29d24ad', 'c49fcc66ee9f']:
        print(json.dumps(audit_slug_geometry(ROOT/'tests/fixtures/m1_articulated_execution'/name), sort_keys=True))
