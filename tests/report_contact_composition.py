#!/usr/bin/env python3
"""Independent audit of SEALED candidate evidence; zero engine ticks, no acceptance credit."""
import gzip
import hashlib
import json
import math
import subprocess
from pathlib import Path
import r27_report as original
import source_provenance as provenance

ROOT = Path(__file__).resolve().parents[1]
FOLDER = ROOT / 'tests/fixtures/m1_contact_composition/36313adee194'
SOURCE = '36313adee19458995618a860843b078a356975ed'
RAW_SHA = '61effb30f761f90c8dc7627a2034fd6aa055975bf4e961ec88dd7efc1727ed49'
GZIP_SHA = '779376a07699a8f11eaebe286c487534a15ca4f3a8e25ec6c7234a96c6c61171'


def need(value, message):
    if not value:
        raise ValueError(message)


def finite(value):
    if isinstance(value, float):
        need(math.isfinite(value), 'Nonfinite scalar')
    elif isinstance(value, dict):
        for child in value.values():
            finite(child)
    elif isinstance(value, list):
        for child in value:
            finite(child)


def sha(data):
    return hashlib.sha256(data).hexdigest()


def verify_source(source):
    need(source['source_commit'] == SOURCE, 'Wrong source commit')
    need(source['source_ci_run'] == '41005575775', 'Wrong CI provenance')
    need(source['engine_build'] == '4.7.2.stable.official.ed1daf0bf', 'Wrong engine')
    manifest = source['core_manifest']
    expected_manifest = {
        'source_commit': '0c1d3f875af8a9ddee1b3f6d10d0784060db4f1d',
        'core_tree_sha256': '557524202efe109074f692a56240ca6b50fcd422db4ed38888aed1b4476704df',
        'tuning_sha256': '5f4d0d06564fb3a0847309d83cf5f3c87b9321ea5e2dd87e572e4bd9fe750666'}
    need(manifest == expected_manifest, 'Archived core/tuning identity differs')
    if provenance.tree_sha256() != manifest['core_tree_sha256']:
        # Auditing old evidence must not require production to stay broken forever.
        # An advanced checkout needs EXACT historical bytes, never a fallback to
        # the new implementation under the old measurement's source label.
        need((ROOT / '.git').exists(), 'Historical core unavailable; fail closed')
        names = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', SOURCE, '--', 'core/'], cwd=ROOT, text=True).splitlines()
        entries = [[n, sha(subprocess.check_output(['git', 'show', SOURCE + ':' + n], cwd=ROOT))] for n in sorted(names)]
        need(sha(json.dumps(entries, separators=(',', ':'), ensure_ascii=True).encode()) == manifest['core_tree_sha256'], 'Historical core hash differs')
    else:
        need(sha((ROOT / 'core/tuning.tres').read_bytes()) == manifest['tuning_sha256'], 'Tuning hash differs')
    expected_files = {'tests/physics_fix/' + n + '.gd' for n in (
        'actuated_contact_composition', 'capsule_contact_composition',
        'rigid_contact_candidate', 'test_contact_composition', 'test_rigid_contact_candidate')}
    expected_files |= {'tests/run_m1_contact_composition.sh', 'scripts/publish_m1_contact_composition.py'}
    need(set(source['candidate_sha256']) == expected_files, 'Incomplete/foreign source inventory')
    for name, digest in source['candidate_sha256'].items():
        path = ROOT / name
        need(path.resolve().is_relative_to(ROOT), 'Candidate path escapes checkout')
        data = path.read_bytes()
        if sha(data) != digest:
            # Current source may later advance; historical bytes must match exactly.
            need((ROOT / '.git').exists(), 'Historical candidate unavailable; fail closed')
            data = subprocess.check_output(['git', 'show', SOURCE + ':' + name], cwd=ROOT)
        need(sha(data) == digest, 'Candidate hash mismatch: ' + name)
    need(len(source['candidate_sha256']) == 7, 'Incomplete source inventory')


def load_evidence(folder=FOLDER):
    need(sha((folder / 'source.json').read_bytes()) == '1b66308feb3474ebf910dc8cef57c57b22b1750f2a2a31d85a5a12e2c48f11dd', 'Source metadata seal differs')
    verify_source(original.load(folder / 'source.json'))
    packed = (folder / 'idle-Slug.jsonl.gz').read_bytes()
    need(sha(packed) == GZIP_SHA, 'Compressed evidence differs')
    raw = gzip.decompress(packed)
    need(sha(raw) == RAW_SHA, 'Raw evidence differs')
    index = original.load(folder / 'transport-index.json')
    need(index['source_commit'] == SOURCE, 'Wrong transport source')
    info = index['raw_traces']['idle-Slug.jsonl']
    need(info == dict(raw_bytes=len(raw), raw_sha256=RAW_SHA, gzip_bytes=len(packed), gzip_sha256=GZIP_SHA), 'Transport index differs')
    need((folder / 'exit-code.txt').read_text().strip() == '1', 'Failed candidate exit lost')
    spawn = original.load(folder / 'idle-Slug-spawn.json')['rig']
    rows = [json.loads(line, parse_constant=lambda v: (_ for _ in ()).throw(ValueError(v))) for line in raw.splitlines()]
    summary = original.load(folder / 'summary.json')
    return spawn, rows, summary


def audit(spawn, rows, summary):
    finite(spawn)
    need(len(rows) == 600, 'Incomplete600 horizon')
    origin = original.com(spawn['physical']['bodies'])
    vector = original.attitude(spawn['physical']['bodies'])
    angle = length = penetration = hinge_gap = hinge_velocity_gap = 0.0
    airborne = slept = max_still = 0
    first_angle = first_sleep = first_head_contact = None
    previous_parts = spawn['physical']['bodies']
    foot_counts = set()
    max_dwell = 0.0
    late_window_failures = 0
    for tick, row in enumerate(rows):
        need(row['tick'] == tick and row['input_mask'] == 0, 'Tick/input gap')
        finite(row)
        state = row['state']
        parts = state['physical']['bodies']
        need(len(parts) == 3 and [p['kind'] for p in parts] == ['head', 'motor', 'foot'], 'Missing/reordered body')
        need(state['physical']['ticks'] == tick + 1, 'Wrong committed tick count')
        current_angle = abs(original.angle_degrees(vector, original.attitude(parts)))
        angle = max(angle, current_angle)
        if current_angle > 15 and first_angle is None:
            first_angle = tick
        if parts[0]['grounded'] and first_head_contact is None:
            first_head_contact = tick
        airborne += not any(p['grounded'] for p in parts)
        if state['sleep']['asleep']:
            slept += 1
            if first_sleep is None:
                first_sleep = tick
            need(all(p[e]['velocity_' + axis] == 0 for p in parts for e in ['a', 'b'] for axis in ['x', 'y']), 'Fake parked velocity')
        max_still = max(max_still, state['sleep']['still_ticks'])
        max_dwell = max(max_dwell, state['sleep']['max_body_dwell_displacement_wu'])
        if tick >= 500 and state['sleep']['max_body_dwell_displacement_wu'] > .001:
            late_window_failures += 1
        for part in parts:
            extent = math.hypot(part['b']['x'] - part['a']['x'], part['b']['y'] - part['a']['y'])
            length = max(length, abs(extent - part['length']))
            penetration = max(penetration, part['radius'] - min(part['a']['y'], part['b']['y']))
        for child in (1, 2):
            parent_end, child_end = parts[child-1]['b'], parts[child]['a']
            hinge_gap = max(hinge_gap, math.hypot(*(child_end[a] - parent_end[a] for a in ['x', 'y'])))
            hinge_velocity_gap = max(hinge_velocity_gap, math.hypot(*(child_end['velocity_'+a] - parent_end['velocity_'+a] for a in ['x', 'y'])))
        for count in row['constraints']['contact_counts']:
            if count['part'] == 2:
                foot_counts.add(count['candidate_count'])
        previous_parts = parts
    end = original.com(previous_parts)
    net = math.dist(origin, end)
    need(set(summary['arms']) == {'idle-Slug'}, 'Unexecuted arms credited')
    need(summary['not_run_arms'] == ['length-Slug', 'length-Hopper', 'length-TwinRoller'], 'STOP arm ledger differs')
    need(summary['status'] == 'STOP; inspect first failure; NOT ADOPTED', 'Failed candidate laundered')
    arm = summary['arms']['idle-Slug']
    need(arm['ticks'] == arm['target_ticks'] == 600, 'Wrong recorded horizon')
    need(arm['first_sleep_tick'] == -1 and first_sleep is None and not arm['sleep_by_original_4s'], 'Sleep claim differs')
    need(arm['max_attitude_deg'] == angle and arm['net_com_wu'] == net, 'Reported metrics differ')
    need(arm['airborne_ticks'] == airborne == 0, 'Airborne count differs')
    need(arm['max_length_wu'] == max(r['length_peak_wu'] for r in rows), 'Reported length differs from raw rows')
    need(arm['max_penetration_wu'] == max(r['penetration_peak_wu'] for r in rows), 'Reported penetration differs from raw rows')
    # Floor interpolation roundoff is NOT removed: report native and geometric values.
    # The unchanged penetration reporting band is applied independently to both.
    need(arm['max_penetration_wu'] <= .02 * (1 + 1e-9) and penetration <= .02 * (1 + 1e-9), 'Penetration reporting violation')
    need(length <= .05 and arm['max_length_wu'] <= .05, 'Length violation in IDLE ONLY')
    need(first_angle == arm['first_metric_violation_tick'] == 8, 'First failure changed')
    final_vel_gaps = [math.hypot(*(previous_parts[i]['a']['velocity_'+a] - previous_parts[i-1]['b']['velocity_'+a] for a in ['x', 'y'])) for i in [1, 2]]
    return dict(scope='independent audit of600 FAILED candidate ticks; zero new simulation',
                source_commit=SOURCE, max_attitude_deg=angle, first_angle_violation_tick=first_angle,
                first_head_grounded_tick=first_head_contact, net_com_wu=net, sleeping_ticks=slept,
                first_sleep_tick=first_sleep, max_still_ticks=max_still, max_dwell_displacement_wu=max_dwell,
                late500_599_window_violations=late_window_failures,
                max_bone_error_wu=length, native_max_bone_error_wu=arm['max_length_wu'],
                geometric_max_penetration_wu=penetration, native_max_penetration_wu=arm['max_penetration_wu'],
                max_hinge_position_gap_wu=hinge_gap, max_hinge_velocity_gap_wu_s=hinge_velocity_gap,
                final_hinge_velocity_gaps_wu_s=final_vel_gaps, foot_sample_counts=sorted(foot_counts),
                AC202_7200='NOT RUN for ALL THREE; never inferred from600',
                verdict='candidate REJECTED / NOT ADOPTED; M1 BLOCKED / NOT SIGNED')


if __name__ == '__main__':
    print(json.dumps(audit(*load_evidence()), indent=2, allow_nan=False))
