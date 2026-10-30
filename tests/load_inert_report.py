#!/usr/bin/env python3
"""R22: the single missing cell, gain0 + upper90. No further sweep authorized."""
import json
from pathlib import Path
import sys
from load_external_report import external_identity
from load_limit_report import limit_summary
from load_long_report import verify_all
from load_motor_report import resource, thrust_summary, BASELINE_DRIFT_PX_S
from load_saturation_report import strength


def validate_parameters(rows):
    expected={'motor_gain':0.,'diagnostic_motor_limit_max_deg':90.,
        'diagnostic_motor_limit_min_deg':resource('motors_limit_min_deg'),
        'diagnostic_angular_impulse_limit_rad_s':resource('physics_max_constraint_angular_impulse_rad_s'),
        'diagnostic_motor_stiffness':resource('motors_joint_stiffness'),
        'diagnostic_motor_damping':resource('motors_joint_damping'),
        'diagnostic_passive_stiffness':resource('physics_passive_stiffness'),
        'diagnostic_static_slip_wu_s':resource('physics_static_slip_wu_s'),
        'diagnostic_linear_damping':resource('physics_linear_damping'),
        'diagnostic_pose':'after','diagnostic_spawn_lift_wu':0.}
    if any(any(r.get(k)!=v for k,v in expected.items()) for r in rows):
        raise ValueError('R22 authorizes ONLY gain0+upper90, all other defaults fixed')
    if resource('motors_limit_max_deg')!=40. or resource('motors_gain_default')!=.7:
        raise ValueError('Committed defaults were changed; diagnostic duplicate only')


def inert_premise(delivery,limits):
    # Record the premise, do not infer it from parameter names or drift.
    return (delivery['all6000_requested_exact_zero'] and delivery['all6000_applied_exact_zero']
            and limits['all6000_limit_engaged_ticks']==0
            and limits['limit_block_exact_zero_all6000'])


def report(folder):
    rows=[json.loads(s) for s in (folder/'actuated-after-6000.jsonl').read_text().splitlines()]
    validate_parameters(rows)
    verify_all(rows,zero_motor_gain=True)
    summary=thrust_summary(rows)
    delivery=strength(rows)
    limits=limit_summary(rows)  # Existing independent per-pass/raw/binary64 audits, no epsilon.
    identity=external_identity(rows)
    result={'arm':'gain0-wide90','rows':len(rows),'window_ticks':[5700,5999],
        'drift_px_s':summary['drift_px_s'],
        'rectified_friction_impulse_per_tick':summary['rectified_friction_impulse_per_tick'],
        'mean_thrust_force_n':summary['mean_thrust_force_n'],
        'free_hinge_baseline_px_s':BASELINE_DRIFT_PX_S,
        'drift_minus_free_hinge_px_s':summary['drift_px_s']-BASELINE_DRIFT_PX_S,
        'F56':identity,'limits':limits,'strength':delivery,
        'inert_premise_all6000_verified':inert_premise(delivery,limits),
        'mean_clamped_total_torque':sum(r['drive_events'][0]['torque'] for r in rows[-300:])/300,
        'STOP':'MANDATORY regardless of outcome: no further arm, sweep, remedy or design change authorized',
        'A':'WITHDRAWN; residual OBSOLETE / NOT RUN','baseline':'UNCHANGED','Phase3':'NOT ENTERED',
        'runtime_rows_passed':8,'runtime_rows_total':18,'rows_moved':0}
    (folder/'inert-report.json').write_text(json.dumps(result,indent=2)+'\n')
    (folder/'f56-identity.json').write_text(json.dumps(identity,indent=2)+'\n')
    print('M1 R22 arm: '+json.dumps({k:v for k,v in result.items() if k!='F56'},separators=(',',':')))
    print('M1 R22 F56: '+json.dumps(identity,separators=(',',':')))
    return result

if __name__=='__main__':
    report(Path(sys.argv[1]))  # Integrity audits, not a new approximate-drift acceptance band.
