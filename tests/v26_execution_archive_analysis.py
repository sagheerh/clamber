"""Read-only V26/V27 CLOSEDFAIL audits; no Godot invocation or new creature ticks.

Long traces do not retain every contact observation. Native7539/9972 force checks are
live assertions; offline checks below recheck provenance, fresh/parked accounting,
geometry, input wake and actual endpoint linear momentum, not full local torque.
"""
import base64
import gzip
import hashlib
import json
import re
from pathlib import Path

from coplanar_idle_analysis import audit_rows, audit_geometry_rows, require
from godot_capture_variant import decode

ROOT = Path(__file__).resolve().parents[1]
SOURCE = "5d6c4409a19ee310863e3342a5791467ff0c4903"
FOLDER = ROOT / "tests/fixtures/m1_articulated_execution" / SOURCE[:12]


V27_SOURCE = "617ef4b55efc8c720b102605abb76c422ddfa72e"
PINNED = {
    SOURCE: ('41221098908', 369, 432, 7539, 'v26'),
    V27_SOURCE: ('41221974706', 2802, 438, 9972, 'v27'),
}


def audit(requested=SOURCE):
    run, failed_tick, native_components, awake_total, version = PINNED[requested]
    folder = ROOT / "tests/fixtures/m1_articulated_execution" / requested[:12]
    source = json.loads((folder / 'source.json').read_text())
    require(source['source_commit'] == source['checkout_head'] == requested
            and source['checkout_dirty'] is False
            and source['source_ci_run'] == run, 'exact clean world source')
    require(source['engine_build'] == '4.7.2.stable.official.ed1daf0bf', 'exact engine')
    transport = json.loads((folder / 'transport-index.json').read_text())
    require(transport['source_commit'] == requested, 'transport source')
    summary = json.loads((folder / 'summary.json').read_text())
    require(summary['status'] == 'STOP; inspect first failure; NOT ADOPTED'
            and summary['not_run_arms'] == ['length-TwinRoller'], 'firstfailure STOP')
    require(not list(folder.glob('length-TwinRoller*')), 'no later arm fabricated')
    prerequisite = json.loads((ROOT / ('.review/physics_fix/'+version+'-world-prerequisite-native-annotations.json')).read_text())
    messages = [item['message'] for item in prerequisite]
    require('M1 articulated mobility units: 42 checks, 0 failures' in messages, 'actual prior native42 gate')
    provenance = [json.loads(text) for text in messages if text.startswith('{')]
    require(any(item.get('source_commit') == requested and item.get('checkout_dirty') is False
                for item in provenance), 'same-source prerequisite provenance')
    # V26:432 / V27:438 checks in execution job; additional prerequisite job42 is CI evidence,
    # not silently counted as a second copy of a local component log.
    components = 0
    for file in folder.glob('*.log'):
        if file.name != 'engine.log':
            components += sum(map(int, re.findall(r'(\d+) checks, 0 failures', file.read_text())))
    require(components == native_components, 'all execution-job native components complete')
    results = {}
    linear_peak = 0.0
    native_awake = 0
    for arm, target in [('idle-Slug', 600), ('length-Slug', 7200), ('length-Hopper', failed_tick)]:
        pin = transport['raw_traces'][arm + '.jsonl']
        packed = (folder / (arm + '.jsonl.gz')).read_bytes()
        raw = gzip.decompress(packed)
        for data, kind in [(packed, 'gzip'), (raw, 'raw')]:
            require(len(data) == pin[kind + '_bytes']
                    and hashlib.sha256(data).hexdigest() == pin[kind + '_sha256'], 'transport ' + kind)
        rows = [json.loads(line) for line in raw.splitlines()]
        report = summary['arms'][arm]
        require(len(rows) == report['ticks'] == target, 'complete committed prefix')
        spawn = json.loads((folder / (arm + '-spawn.json')).read_text())
        previous = spawn['rig']
        fresh = parked = 0
        for tick, row in enumerate(rows):
            state, trace = row['state'], row['awake_solver_trace']
            mask = 0 if arm == 'idle-Slug' else (tick // 60) % 4
            require(row['tick'] == tick and row['input_mask'] == mask, 'contiguous real input')
            require(state['physical']['ticks'] == tick + 1, 'actual clock')
            if trace['tick'] == tick:
                require(row['force_audit'] == 'PASS fresh awake' and trace['input_mask'] == mask,
                        'same actual input/fresh trace, not stale force credit')
                fresh += 1
                # Actual endpoints are PREVIOUS/PUBLISHED state, unlike reported
                # stage impulse sums. Skip entering-sleep parking transaction.
                if not state['sleep']['asleep']:
                    for axis in 'xy':
                        actual = sum(b['mass'] * (b['a']['velocity_'+axis] + b['b']['velocity_'+axis]
                            - old['a']['velocity_'+axis] - old['b']['velocity_'+axis]) / 2
                            for b, old in zip(state['physical']['bodies'], previous['physical']['bodies']))
                        reported = sum(trace['momentum_budget'][stage+'_impulse_'+axis+'_ns']
                            for stage in ['drive_internal', 'damping', 'gravity', 'internal',
                                          'contact_velocity', 'clamp'])
                        linear_peak = max(linear_peak, abs(actual-reported))
            else:
                require(trace['tick'] < tick and mask == 0 and previous['sleep']['asleep']
                        and state['sleep']['asleep']
                        and row['force_audit'] == 'NOTRUN asleep; no new force solve', 'honest parked tick')
                parked += 1
            previous = state
        require(fresh == report['awake_force_audits']
                and parked == report['asleep_no_fresh_force_ticks']
                and fresh + parked == target, 'all fresh/parked counters independently agree')
        native_awake += fresh
        results[arm] = dict(committed_ticks=target, live_native_awake_audits=fresh, parked_no_new_force=parked)
        if arm == 'idle-Slug':
            results[arm]['original600'] = audit_rows(rows, spawn, report)
        if arm == 'length-Slug':
            results[arm]['geometry_input_wake'] = audit_geometry_rows(rows)
    failure = json.loads((folder / 'length-Hopper-failure.json').read_text())
    full = decode(base64.b64decode(failure['full_state_variant_base64']))
    trace = full['awake_trace']
    require(failure['tick'] == failed_tick and failure['status'] == 30
            and trace['stage_order'] == ['forces', 'velocity_pass_0']
            and trace['constitutive_stage']['status'] == 3
            and 'NOTRUN' in trace['constitutive_stage']['scope'], 'actual failed first phase, final NOTRUN')
    require(full['before'] == full['after'], 'snapshot values atomically restored')
    require(native_awake == awake_total and linear_peak < 1e-12, 'actual successful prefixes only')
    return dict(source_commit=requested, ci_run=run, status='CLOSEDFAIL; not adopted',
                scope='READ ONLY ZERO ticks; native full-force assertions distinguished from offline subset',
                native_execution_job_checks=components, native_prior_job_checks=42,
                arms=results, native_successful_fresh_force_audits=native_awake,
                offline_actual_linear_peak_ns=linear_peak, hopper_failed_tick=failed_tick,
                failure_phase='velocity_pass_0', final_constitutive='NOTRUN',
                rollback_snapshot_values_equal=True, twin='NOTRUN',
                limitations=['Long captures omit raw contact observations; offline proof is not all local-torque checks.',
                             'Hopper prefix is NOT Hopper7200; Twin not run.',
                             'World rollback value equality is NOT typed factory continuation; runtime207 tests that separately.',
                             'No production adoption, FA3, replay/determinism, device or M1 signature.'])


if __name__ == '__main__':
    print(json.dumps(audit(), indent=2))
