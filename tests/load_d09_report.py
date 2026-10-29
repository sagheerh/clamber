#!/usr/bin/env python3
"""NON-ADOPTED proportional-muscle proposals. No feel/runtime gate upgrade."""
import json
import math
import re
from pathlib import Path
import sys
from load_motor_report import resource, thrust_summary
from load_long_report import verify_all
from load_saturation_report import audit_drive, raw_frame, stats, compare
from load_limit_report import limit_summary
from load_external_report import external_identity
from load_spring_report import joint_summary
from load_trace_report import close

CANDIDATES=('c10','c20','c40')
CELLS=('both','stop_only','drive_only','inert')
ROOT=Path(__file__).resolve().parents[1]


def proposal(name):
    if name not in CANDIDATES:raise ValueError('Unknown non-adopted proposal')
    text=(ROOT/f'tests/fixtures/d09/{name}/tuning.tres').read_text()
    return {k:float(re.search(r'^'+k+r' = (.+)$',text,re.M)[1]) for k in
        ('motors_joint_stiffness','motors_max_torque','physics_max_constraint_angular_impulse_rad_s')}


def damping_from_weight(k,weight):
    if k<=0 or weight<=0 or not math.isfinite(k+weight):raise ValueError('Invalid critical damping inputs')
    return 2*math.sqrt(k/weight)


def f52_eligibility(rows):
    """Exact original body-COM per-tick AND dwell-net predicate, observation only.
    Does NOT park bodies, alter trace, claim actual sleep or formal AC201.
    """
    threshold=resource('sleep_still_displacement_wu');dwell=int(resource('sleep_dwell_ticks'))
    count=0;origin=None;first=None
    for r in rows:
        bodies=sorted(r['feet']+r['other_bodies'],key=lambda b:b['part'])
        before=[((b['start_ax']+b['start_bx'])/2,(b['start_ay']+b['start_by'])/2) for b in bodies]
        after=[((b['ax']+b['bx'])/2,(b['ay']+b['by'])/2) for b in bodies]
        anchor=origin if count else before
        step=max(math.hypot(b[0]-a[0],b[1]-a[1]) for a,b in zip(before,after))
        net=max(math.hypot(b[0]-a[0],b[1]-a[1]) for a,b in zip(anchor,after))
        if r['input_mask']!=0 or step>=threshold or net>=threshold:
            count=0;origin=None
        else:
            if count==0:origin=before
            count+=1
        if count==dwell and first is None:first=r['tick']
    return {'first_eligible_tick':first,'eligible_within4s':first is not None and first<int(4*resource('physics_tick_hz')),
        'scope':'counterfactual F52 eligibility on AWAKE trace, NO parking; NOT AC201',
        'derived_drift_line_px_s':threshold/dwell*resource('physics_tick_hz')*resource('feel_readability_px_per_wu')}


def validate_arm(rows,name,cell):
    p=proposal(name);zero=cell in ('stop_only','inert');wide=cell in ('drive_only','inert')
    base=rows[0];bodies={b['part']:b for b in base['feet']+base['other_bodies']}
    weight=sum(raw_frame(bodies[i])['inverse_inertia'] for i in (0,1))
    damping=damping_from_weight(p['motors_joint_stiffness'],weight)
    expected={'diagnostic_d09_candidate':name,'diagnostic_d09_lurch':cell=='lurch',
        'diagnostic_motor_stiffness':p['motors_joint_stiffness'],
        'diagnostic_motor_max_torque':p['motors_max_torque'],
        'diagnostic_angular_impulse_limit_rad_s':p['physics_max_constraint_angular_impulse_rad_s'],
        'motor_gain':0. if zero else resource('motors_gain_default'),
        'diagnostic_motor_limit_min_deg':resource('motors_limit_min_deg'),
        'diagnostic_motor_limit_max_deg':90. if wide else resource('motors_limit_max_deg'),
        'diagnostic_linear_damping':resource('physics_linear_damping'),
        'diagnostic_static_slip_wu_s':resource('physics_static_slip_wu_s'),
        'diagnostic_passive_stiffness':resource('physics_passive_stiffness'),
        'diagnostic_pose':'after','diagnostic_spawn_lift_wu':0.}
    if any(any(r.get(k)!=v for k,v in expected.items()) or
           not close(r['diagnostic_motor_damping'],damping) or
           not close(r['diagnostic_d09_authored_weight'],weight) for r in rows):
        raise ValueError('D09 proposal changed unauthorized setting or damping formula')
    verify_all(rows,zero_motor_gain=zero,d09_lurch=cell=='lurch')
    audits=[audit_drive(r,motor_damping=damping,max_torque=p['motors_max_torque'],allow_input=cell=='lurch') for r in rows]
    tail=audits[-300:];events=[r['drive_events'][0] for r in rows[-300:]]
    ratios=[x['requested_over_bound'] for x in tail]
    clipping=sum(abs(e['spring_torque']+e['damping_torque'])>p['motors_max_torque']*rows[-1]['motor_gain'] for e in events)
    delivery={**{k:stats([a[k] for a in tail]) for k in ('requested','bound','applied','requested_over_bound')},
        'saturated_ticks':sum(a['saturated'] for a in tail),'window_ticks':300,
        'body_speed_limited_ticks':sum(a['body_speed_limited'] for a in tail),
        'upstream_torque_clipped_ticks':clipping,
        'holding_headroom_observed_all300':max(ratios)<=.5 and clipping==0,
        'all6000_requested_exact_zero':all(a['requested']==0. for a in audits),
        'all6000_applied_exact_zero':all(a['applied']==0. for a in audits)}
    return p,weight,damping,delivery


def center(row):
    bodies=row['feet']+row['other_bodies'];mass=sum(b['mass'] for b in bodies)
    return [math.fsum((b[a+axis]+b['b'+axis])/2*b['mass'] for b in bodies)/mass for a,axis in [('a','x'),('a','y')]]


def summarize_arm(folder,name,cell):
    rows=[json.loads(s) for s in (folder/'trace.jsonl').read_text().splitlines()]
    p,weight,damping,delivery=validate_arm(rows,name,cell)
    identity=external_identity(rows);(folder/'f56.json').write_text(json.dumps(identity,indent=2)+'\n')
    limits=limit_summary(rows);events=[r['drive_events'][0] for r in rows[-300:]]
    # Never call a floating-point near-cycle a settled pose or a calibrated target.
    qs=[e['q'] for e in events];exact_constant=len(set(qs))==1
    item={'candidate':name,'cell':cell,'proposal_not_adopted':True,
        'candidate_triple':p,'damping_formula':'c_crit=2*sqrt(k*I_eff); I_eff=1/(inverseI_parent+inverseI_child)',
        'linearization':'AUTHORED actual endpoint geometry at setup; fixed coefficient, not adaptive damping',
        'authored_inverse_inertia_sum':weight,'derived_motor_damping':damping,
        'observed_effective_damping_ratio':stats([damping*math.sqrt(sum(raw_frame(b)['inverse_inertia'] for b in r['other_bodies'] if b['part'] in (0,1)))/(2*math.sqrt(p['motors_joint_stiffness'])) for r in rows[-300:]]),
        'strength':delivery,'limits':limits,'F56_complete_passed':identity['internal_rows_and_complete_ledger_verified'],
        'F56_residual_x_y':[identity['axes'][a]['sums']['full_residual_from_sides'] for a in ('x','y')],
        'joints':joint_summary(rows),'F52_observation':f52_eligibility(rows),
        'holding_residual_q_minus_target_rad':stats([e['q']-e['target'] for e in events]),
        'settled_pose':None,'working_pose_q_rad':stats(qs),'q_exact_constant_last300':exact_constant}
    if cell=='lurch':
        start=center(rows[5699]);held=center(rows[5759]);released=center(rows[5999])
        item['lurch']={'PROPOSED_protocol':'released0..5699; L held5700..5759 (1s); released5760..5999 (4s); NOT FA4',
            'com_displacement_held_wu':[b-a for a,b in zip(start,held)],
            'com_displacement_end_of_release_wu':[b-a for a,b in zip(start,released)],
            'max_abs_q_during_hold_rad':max(abs(r['drive_events'][0]['q']) for r in rows[5700:5760]),
            'max_abs_drive_impulse_during_hold':max(abs(r['drive_events'][0]['impulse']) for r in rows[5700:5760])}
    else:
        summary=thrust_summary(rows);item.update(summary)
        if exact_constant and summary['convergence']['settled']:
            item['settled_pose']={'q_rad':qs[0],'scope':'exact constant late q and exact COM recurrence, not proof of global equilibrium'}
        item['holding_criterion_qualified']=item['settled_pose'] is not None and delivery['holding_headroom_observed_all300']
        item['D08_drift_margin_px_s']=item['F52_observation']['derived_drift_line_px_s']-abs(summary['drift_px_s'])
    (folder/'summary.json').write_text(json.dumps(item,indent=2)+'\n')
    compact={k:item[k] for k in ('candidate','cell','derived_motor_damping','settled_pose','working_pose_q_rad','holding_residual_q_minus_target_rad','strength','F56_residual_x_y')}
    compact.update({k:item[k] for k in ('drift_px_s','mean_thrust_force_n','D08_drift_margin_px_s','lurch') if k in item})
    compact['limit_columns']={k:limits[k] for k in ('limit_engaged_ticks','max_drive_time_violation_rad','requested_abs_projection_rad_sum','angular_phase_endpoint_magnitude_wu_sum')}
    compact['F56_axis_sums']={a:[identity['axes'][a]['sums'][k] for k in ('delta','normal','friction','damping','gravity','clamp','internal_drive','internal_velocity','full_residual_from_sides')] for a in ('x','y')}
    compact['F52']=item['F52_observation']
    print('M1 D09 arm: '+json.dumps(compact,separators=(',',':')))
    return item,rows


def report(root):
    result={'PROPOSALS_ONLY':True,'adopted':False,'baseline_regenerated':False,'STOP':'Mandatory review before adoption; no bound increase or hold',
        'runtime_rows_passed':8,'runtime_rows_total':18,'candidates':{}}
    for name in CANDIDATES:
        arms={};ref=None
        for cell in (*CELLS,'lurch'):
            item,rows=summarize_arm(root/name/cell,name,cell);arms[cell]=item
            if cell=='both':ref=rows
            elif cell!='lurch':
                delta=compare(ref,rows);(root/name/cell/'reference-differences.json').write_text(json.dumps(delta,indent=2)+'\n')
            del rows
        result['candidates'][name]=arms
    (root/'d09-study.json').write_text(json.dumps(result,indent=2)+'\n')
    return result

if __name__=='__main__':report(Path(sys.argv[1]))
