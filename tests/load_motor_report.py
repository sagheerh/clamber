#!/usr/bin/env python3
"""R19 motor intervention ONLY. Signed net friction, never sum(abs(impulses))."""
import json
import math
from pathlib import Path
import re
import sys
from load_external_report import external_identity, r19_complete_prerequisite
from load_long_report import verify_all
from load_convergence_report import drift_summary
from load_spring_report import joint_summary
from load_trace_report import LINEAR_DAMPING, close, WEIGHT_N

RESOURCE=(Path(__file__).resolve().parents[1]/'core/tuning.tres').read_text()
def resource(name):
    return float(re.search(r'^'+name+r' = (.+)$',RESOURCE,re.M)[1])

MOTOR_STIFFNESS=resource('motors_joint_stiffness')
MOTOR_DAMPING=resource('motors_joint_damping')
# Explicit owner R19 comparison, not a solver epsilon / newly tuned parameter.
OWNER_THRUST_LIMIT=1.74e-05
BASELINE_DRIFT_PX_S=.08403595917823123


def thrust_summary(rows):
    identity=external_identity(rows)
    r19_complete_prerequisite(identity)
    tail=rows[-300:]
    masses=[]
    for r in tail:
        bodies=r['feet']+r['other_bodies']
        mass=math.fsum(1/b['inverse_mass_'+e] for b in bodies for e in ('a','b'))
        if not all(close(b['mass'],1/b['inverse_mass_a']+1/b['inverse_mass_b']) for b in bodies):
            raise ValueError('Mass claim differs from raw inverse endpoint masses')
        masses.append(mass)
    if len(set(masses))!=1:raise ValueError('Mass changed during window')
    x=identity['axes']['x']['sums'];y=identity['axes']['y']['sums']
    if x['normal']!=0.:raise ValueError('R19 flat-floor thrust must not hide horizontal normal impulse')
    thrust=x['friction']/300
    drift=drift_summary(rows)
    predicted=thrust/(LINEAR_DAMPING*masses[0])
    return {'window_ticks':identity['window_ticks'],'mass':masses[0],
        'drift_px_s':drift['net_drift_px_s_at_150px_wu'],
        'mean_completed_vx_wu_s':drift['mean_completed_com_vx_wu_s'],
        'mean_completed_vx_px_s':drift['mean_completed_com_vx_wu_s']*150,
        'rectified_friction_impulse_per_tick':thrust,
        'mean_thrust_force_n':thrust*60,
        'mean_thrust_percent_weight':thrust*60/WEIGHT_N*100,
        'terminal_velocity_prediction_wu_s':predicted,
        'prediction_minus_completed_vx_wu_s':predicted-drift['mean_completed_com_vx_wu_s'],
        'mean_normal_support_n':y['normal']/300*60,
        'support_minus_weight_n':y['normal']/300*60-WEIGHT_N,
        'linear_damping':LINEAR_DAMPING,'motor_damping':MOTOR_DAMPING,
        'convergence':drift['convergence'],'recurrence':drift['raw_recurrence_diagnostics'],
        'F56_complete_passed':identity['internal_rows_and_complete_ledger_verified'],
        'full_window_residual_x_y':[identity['axes'][a]['sums']['full_residual_from_sides'] for a in ('x','y')]}


def sweep_gate(live,zero):
    # The only quantitative collapse reference supplied by owner is 1.74e-05.
    # Use that supplied thrust reference, not an invented reduction factor.
    collapsed=abs(zero['rectified_friction_impulse_per_tick'])<=OWNER_THRUST_LIMIT
    return {'owner_thrust_reference':OWNER_THRUST_LIMIT,
        'free_hinge_drift_reference_px_s':BASELINE_DRIFT_PX_S,
        'zero_over_live_abs_thrust':abs(zero['rectified_friction_impulse_per_tick'])/abs(live['rectified_friction_impulse_per_tick']) if live['rectified_friction_impulse_per_tick'] else None,
        'zero_thrust_collapsed_to_owner_reference':abs(zero['rectified_friction_impulse_per_tick'])<=OWNER_THRUST_LIMIT,
        'zero_drift_no_worse_than_baseline':abs(zero['drift_px_s'])<=BASELINE_DRIFT_PX_S,
        'continuation_authorized':collapsed,
        'outcome':'Motor-source falsification supports proceeding to A' if collapsed else 'STOP: motor0 did not collapse thrust/drift to owner references; do NOT apply A'}


def report(root):
    arms={}
    for name,stiffness in [('motor2400',MOTOR_STIFFNESS),('motor0',0.)]:
        folder=root/name
        rows=[json.loads(s) for s in (folder/'actuated-after-6000.jsonl').read_text().splitlines()]
        for r in rows:
            if (r['diagnostic_motor_stiffness']!=stiffness
                or r['diagnostic_linear_damping']!=LINEAR_DAMPING
                or r['diagnostic_motor_damping']!=MOTOR_DAMPING
                or r['diagnostic_passive_stiffness']!=resource('physics_passive_stiffness')
                or r['diagnostic_pose']!='after' or r['diagnostic_spawn_lift_wu']!=0.):
                raise ValueError('Intervention changed something besides motor stiffness')
        verify_all(rows,zero_motor_stiffness=stiffness==0.)
        arm=thrust_summary(rows)
        arm['motor_stiffness']=stiffness
        arm['joints']=joint_summary(rows)
        arms[name]=arm
        print('M1 R19 motor arm: '+json.dumps({'arm':name,**arm},separators=(',',':')))
    gate=sweep_gate(arms['motor2400'],arms['motor0'])
    result={'scope':'R19 ordered diagnostic, NOT runtime acceptance/remedy',
        'arms':arms,'gate':gate,'runtime_rows_passed':8,'runtime_rows_total':18,
        'A':'NOT RUN until motor-source falsification supports it',
        'F55':'.15WU/s =22.5px/s; COM drift alone is not a leak',
        'F58':'Signed rectified friction thrust balanced by unchanged2percent linear damping; compare thrust, not just speed',
        'F59':'Owner interpretation: rocking walking limit cycle, not stationary equilibrium. AC-201 requires zero-input zero-net-motion AND original sleep within4s; no relaxation.',
        'F57':'RNG injection/snapshot/restore/hash preserved; NOT consumed by physics'}
    (root/'motor-report.json').write_text(json.dumps(result,indent=2)+'\n')
    print('M1 R19 motor gate: '+json.dumps(gate,separators=(',',':')))
    return result

if __name__=='__main__':
    r=report(Path(sys.argv[1]))
    if not r['gate']['continuation_authorized']:raise SystemExit(1)
