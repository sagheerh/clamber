#!/usr/bin/env python3
"""R20 F60–63. Ordered, observation-only; every arm keeps complete F56 guards."""
import json
import math
from pathlib import Path
import sys
from load_motor_report import thrust_summary, resource, MOTOR_STIFFNESS, MOTOR_DAMPING, BASELINE_DRIFT_PX_S
from load_long_report import verify_all
from load_spring_report import joint_summary
from load_trace_report import close, LINEAR_DAMPING, IDENTITY_EPS

DEFAULT_GAIN=resource('motors_gain_default')
DEFAULT_BOUND=resource('physics_max_constraint_angular_impulse_rad_s')
HZ=resource('physics_tick_hz')
LIMIT=resource('physics_max_angular_velocity_rad_s')
TORQUE=resource('motors_max_torque')


def clamp(value,minimum,maximum):return min(max(value,minimum),maximum)


def raw_frame(body):
    x=body['start_bx']-body['start_ax'];y=body['start_by']-body['start_ay']
    squared=x*x+y*y
    return {'inverse_inertia':(body['inverse_mass_a']+body['inverse_mass_b'])/squared,
        'omega':(x*(body['start_bvy']-body['start_avy'])-y*(body['start_bvx']-body['start_avx']))/squared}


def audit_drive(row):
    """Reconstruct BOTH clamps from actual pre-drive endpoint geometry/velocities.
    Nominal preset inertia is not substituted for the evolving body extent.
    """
    bodies={b['part']:b for b in row['feet']+row['other_bodies']}
    if len(row['drive_events'])!=1:raise ValueError('R20 Slug requires its single motor')
    e=row['drive_events'][0]
    if e['kind']!='motor' or e['parent_part']!=0 or e['child_part']!=1:
        raise ValueError('Wrong Slug drive mapping')
    parent=raw_frame(bodies[e['parent_part']]);child=raw_frame(bodies[e['child_part']])
    weight=parent['inverse_inertia']+child['inverse_inertia']
    bound=row['diagnostic_angular_impulse_limit_rad_s']/weight
    omega=child['omega']-parent['omega']
    stiffness=row['diagnostic_motor_stiffness'];gain=row['motor_gain']
    spring=stiffness*(e['target']-e['q']);damping=-MOTOR_DAMPING*omega
    torque=clamp(spring+damping,-TORQUE*gain,TORQUE*gain)
    requested=torque/HZ
    minimum=max((parent['omega']-LIMIT)/parent['inverse_inertia'],(-LIMIT-child['omega'])/child['inverse_inertia'])
    maximum=min((parent['omega']+LIMIT)/parent['inverse_inertia'],(LIMIT-child['omega'])/child['inverse_inertia'])
    before=e['impulse_before']
    if before!=0.:raise ValueError('Motor cumulative impulse must reset before each drive')
    first=clamp(requested,-bound-before,bound-before)
    speed_clamped=first
    applied=first
    if minimum<=maximum:
        speed_clamped=clamp(first,minimum,maximum)
        applied=clamp(speed_clamped,-bound-before,bound-before)
    expected={'parent_inverse_inertia':parent['inverse_inertia'],'child_inverse_inertia':child['inverse_inertia'],
        'parent_omega':parent['omega'],'child_omega':child['omega'],'omega':omega,
        'impulse_bound':bound,'speed_minimum_impulse':minimum,'speed_maximum_impulse':maximum,
        'spring_torque':spring,'damping_torque':damping,'torque':torque,
        'requested_impulse':requested,'impulse':applied,'impulse_after':before+applied,
        'relative_speed_change':applied*weight,'tick_net_relative_speed_change':(before+applied)*weight}
    if e['target']!=0.:raise ValueError('R20 zero-input diagnostics retain original target0')
    if not all(math.isfinite(e[k]) and close(e[k],v) for k,v in expected.items()):
        raise ValueError('F63 raw requested/bound/applied drive audit fails')
    return {'requested':requested,'bound':bound,'applied':e['impulse'],
        'requested_over_bound':abs(requested)/bound,
        'constraint_limited':first!=requested,'body_speed_limited':speed_clamped!=first,
        'saturated':applied!=requested,'at_constraint_bound':close(abs(before+applied),bound)}


def stats(values):
    return {'mean':math.fsum(values)/len(values),'mean_abs':math.fsum(map(abs,values))/len(values),
        'min':min(values),'max':max(values)}


def strength(rows):
    # Audit every tick before summarizing last300, not just the mean.
    all_ticks=[audit_drive(r) for r in rows];tail=all_ticks[-300:]
    return {'unit':'angular impulse mass*WU^2/s; bound*weight is relative rad/s increment',
        **{k:stats([a[k] for a in tail]) for k in ('requested','bound','applied','requested_over_bound')},
        'saturated_ticks':sum(a['saturated'] for a in tail),'window_ticks':300,
        'saturated_fraction':sum(a['saturated'] for a in tail)/300,
        'constraint_limited_ticks':sum(a['constraint_limited'] for a in tail),
        'body_speed_limited_ticks':sum(a['body_speed_limited'] for a in tail),
        'at_constraint_bound_ticks':sum(a['at_constraint_bound'] for a in tail),
        'definition':'saturated iff reconstructed final applied != requested; constraint/body-speed limits separately counted',
        'all6000_requested_exact_zero':all(a['requested']==0. for a in all_ticks),
        'all6000_applied_exact_zero':all(a['applied']==0. for a in all_ticks),
        'all6000_max_abs_applied':max(abs(a['applied']) for a in all_ticks)}


def compare(reference,arm):
    if [r['tick'] for r in reference]!=[r['tick'] for r in arm]:raise ValueError('Unaligned comparison')
    impulses=[];trajectories=[];velocities=[]
    for a,b in zip(reference,arm):
        impulses.append(b['drive_events'][0]['impulse']-a['drive_events'][0]['impulse'])
        left=sorted(a['feet']+a['other_bodies'],key=lambda p:p['part'])
        right=sorted(b['feet']+b['other_bodies'],key=lambda p:p['part'])
        trajectories.append(max(abs(x[k]-y[k]) for x,y in zip(left,right) for k in ('ax','ay','bx','by')))
        velocities.append(max(abs(x[k]-y[k]) for x,y in zip(left,right) for k in ('avx','avy','bvx','bvy')))
    return {'last300_applied_impulse_delta':stats(impulses[-300:]),
        'last300_applied_changed_above_existing_ledger_precision_ticks':sum(abs(v)>IDENTITY_EPS for v in impulses[-300:]),
        'last300_max_abs_endpoint_position_delta_wu':max(trajectories[-300:]),
        'last300_max_abs_endpoint_velocity_delta_wu_s':max(velocities[-300:]),
        'per_tick': [{'tick':r['tick'],'drive_applied_delta':j,'max_endpoint_position_delta_wu':p,
                      'max_endpoint_velocity_delta_wu_s':v} for r,j,p,v in zip(reference,impulses,trajectories,velocities)]}


def zero_gate(arm):
    s=arm['strength']
    zero=(s['all6000_requested_exact_zero'] and s['all6000_max_abs_applied']<=IDENTITY_EPS)
    collapsed=abs(arm['drift_px_s'])<=BASELINE_DRIFT_PX_S
    return {'zero_drive_verified_at_existing_ledger_precision':zero,
        'applied_exact_zero':s['all6000_applied_exact_zero'],
        'free_hinge_reference_px_s':BASELINE_DRIFT_PX_S,'drift_collapsed':collapsed,
        'continue_to_bound_sweep':zero and collapsed,
        'outcome':('PROCEED to bound diagnostic, not A' if zero and collapsed else
            'STOP: gain0 does not establish zero drive' if not zero else
            'STOP: zero drive does not collapse drift; do not run bound sweep or A')}


def report(root,stage):
    configs=[('reference',MOTOR_STIFFNESS,DEFAULT_GAIN,DEFAULT_BOUND),
             ('stiffness0_record',0.,DEFAULT_GAIN,DEFAULT_BOUND),
             ('gain0',MOTOR_STIFFNESS,0.,DEFAULT_BOUND)]
    if stage=='bound':configs.append(('bound1',MOTOR_STIFFNESS,DEFAULT_GAIN,1.))
    arms={};raw={}
    for name,stiffness,gain,bound in configs:
        rows=[json.loads(s) for s in (root/name/'actuated-after-6000.jsonl').read_text().splitlines()]
        for r in rows:
            expected={'diagnostic_motor_stiffness':stiffness,'motor_gain':gain,
                'diagnostic_angular_impulse_limit_rad_s':bound,'diagnostic_linear_damping':LINEAR_DAMPING,
                'diagnostic_motor_damping':MOTOR_DAMPING,'diagnostic_passive_stiffness':resource('physics_passive_stiffness'),
                'diagnostic_static_slip_wu_s':resource('physics_static_slip_wu_s'),'diagnostic_pose':'after',
                'diagnostic_spawn_lift_wu':0.}
            if any(r[k]!=v for k,v in expected.items()):raise ValueError('Unauthorized mixed intervention')
        verify_all(rows,zero_motor_stiffness=stiffness==0.,zero_motor_gain=gain==0.)
        arm=thrust_summary(rows);arm['strength']=strength(rows);arm['joints']=joint_summary(rows)
        arm.update({'motor_stiffness':stiffness,'motor_gain':gain,'angular_impulse_limit_rad_s':bound})
        arms[name]=arm;raw[name]=rows
        compact={k:arm[k] for k in ('drift_px_s','rectified_friction_impulse_per_tick','mean_thrust_force_n',
            'full_window_residual_x_y','F56_complete_passed','strength','joints')}
        print('M1 R20 arm: '+json.dumps({'arm':name,**compact},separators=(',',':')))
    comparisons={name:compare(raw['reference'],rows) for name,rows in raw.items() if name!='reference'}
    for name,c in comparisons.items():
        (root/name/'reference-differences.json').write_text(json.dumps(c,indent=2)+'\n')
    old=comparisons['stiffness0_record']
    void=old['last300_applied_changed_above_existing_ledger_precision_ticks']==0
    gate=zero_gate(arms['gain0'])
    result={'stage':stage,'arms':arms,'comparisons':{k:{a:b for a,b in v.items() if a!='per_tick'} for k,v in comparisons.items()},
        'F60_R19_intervention':'VOID, not falsifying' if void else 'Observed delivered-impulse differences; report, no automatic spring attribution',
        'R19_spring_source_conclusion':'WITHDRAWN by owner R20; historical numbers retained',
        'zero_drive_gate':gate,'bound_sweep':'NOT RUN: ordered after gain0 collapse' if stage=='zero-drive' else 'MEASURED',
        'A':'WITHDRAWN by owner F62; NOT RUN','residual_point5deg_arm':'NOT RUN unless two ordered diagnostics leave question open',
        'runtime_rows_passed':8,'runtime_rows_total':18,'baseline':'UNCHANGED; no regeneration','Phase3':'NOT ENTERED'}
    if stage=='bound':
        a=arms['reference'];b=arms['bound1']
        result['bound_observation']={'commanded_bound_ratio':1/DEFAULT_BOUND,
            'observed_abs_thrust_ratio':abs(b['rectified_friction_impulse_per_tick']/a['rectified_friction_impulse_per_tick']),
            'observed_mean_abs_applied_ratio':b['strength']['applied']['mean_abs']/a['strength']['applied']['mean_abs'],
            'interpretation':'Quantitative causal diagnostic, no invented approx4x tolerance or adopted tuning; A remains withdrawn'}
    (root/'saturation-report.json').write_text(json.dumps(result,indent=2)+'\n')
    print('M1 R20 status: '+json.dumps({k:v for k,v in result.items() if k not in ('arms','comparisons')},separators=(',',':')))
    print('M1 R20 teeth: '+json.dumps(result['comparisons'],separators=(',',':')))
    return result

if __name__=='__main__':
    r=report(Path(sys.argv[1]),sys.argv[2])
    if not r['zero_drive_gate']['continue_to_bound_sweep']:raise SystemExit(1)
