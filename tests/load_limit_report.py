#!/usr/bin/env python3
"""R21 two diagnostic arms. Phase ledger WU is not a joint rotation in radians."""
import json
import math
import struct
from pathlib import Path
import sys
from load_saturation_report import strength, compare, clamp, raw_frame, DEFAULT_GAIN, DEFAULT_BOUND
from load_motor_report import thrust_summary, resource, MOTOR_STIFFNESS, MOTOR_DAMPING
from load_long_report import verify_all
from load_spring_report import joint_summary
from load_external_report import external_identity
from load_trace_report import close, LINEAR_DAMPING

DEGREE_RADIANS=math.pi/180
DEFAULT_UPPER=resource('motors_limit_max_deg')
LOWER=resource('motors_limit_min_deg')*DEGREE_RADIANS
OLD_GAIN0_DRIFT=5.387448117922983


def wrapped(angle):
    while angle>math.pi:angle-=2*math.pi
    while angle < -math.pi:angle+=2*math.pi
    return angle


def relative_q(parent,child,rest):
    px=parent[2]-parent[0];py=parent[3]-parent[1]
    cx=child[2]-child[0];cy=child[3]-child[1]
    return wrapped(math.atan2(px*cy-py*cx,px*cx+py*cy)-rest)


def inverse_inertia(points,body):
    x=points[2]-points[0];y=points[3]-points[1]
    if x*x+y*y<=0:raise ValueError('Degenerate projected body')
    return (body['inverse_mass_a']+body['inverse_mass_b'])/(x*x+y*y)


def rotation(before,after):
    x=before[2]-before[0];y=before[3]-before[1]
    u=after[2]-after[0];v=after[3]-after[1]
    return math.atan2(x*v-y*u,x*u+y*v)


def turned(points,angle):
    cx=(points[0]+points[2])/2;cy=(points[1]+points[3])/2
    c=math.cos(angle);s=math.sin(angle)
    return [coord for x,y in ((points[0]-cx,points[1]-cy),(points[2]-cx,points[3]-cy))
            for coord in (cx+c*x-s*y,cy+s*x+c*y)]


def points_finite(points):
    return len(points)==4 and all(math.isfinite(v) for v in points)


def audit_limits(row):
    bodies={b['part']:b for b in row['feet']+row['other_bodies']}
    if len(row['angular_joints'])!=1:raise ValueError('R21 Slug single angular row required')
    joint=row['angular_joints'][0];rest=joint['rest_angle']
    lower=LOWER;upper=row['diagnostic_motor_limit_max_deg']*DEGREE_RADIANS
    if not close(joint['lower'],lower) or not close(joint['upper'],upper):raise ValueError('Joint band metadata forged')
    errors=[];requested_angles=[];observed_angles=[];path=[]
    totals={part:[[] for _ in range(4)] for part in bodies}
    events=row['angular_position_events']
    if len(events)!=row['diagnostic_position_iterations']:raise ValueError('Missing position iteration events')
    for index,e in enumerate(events):
        if (e['joint'],e['sequence'],e['parent_part'],e['child_part'])!=(0,index,0,1):raise ValueError('Bad position event sequence')
        if not close(e['lower_rad'],lower) or not close(e['upper_rad'],upper):raise ValueError('Wrong position limit')
        p=e['parent_before'];c=e['child_before'];pa=e['parent_after'];ca=e['child_after']
        if not all(points_finite(v) for v in (p,c,pa,ca)):raise ValueError('Invalid projection points')
        q=relative_q(p,c,rest);error=q-clamp(q,lower,upper)
        if not close(wrapped(e['q_rad']-q),0.) or not close(e['error_rad'],error):raise ValueError('Raw positional angle/error forged')
        ip=inverse_inertia(p,bodies[0]);ic=inverse_inertia(c,bodies[1]);weight=ip+ic
        parent_angle=e['error_rad']*ip/weight;child_angle=-e['error_rad']*ic/weight
        if e['error_rad']==0.:
            if p!=pa or c!=ca:raise ValueError('Zero-error projection moved a body')
        elif not all(close(a,b) for expected,actual in ((turned(p,parent_angle),pa),(turned(c,child_angle),ca)) for a,b in zip(expected,actual)):
            raise ValueError('Projection does not match raw inertia-weighted correction')
        for part,before,after in ((0,p,pa),(1,c,ca)):
            for i,(a,b) in enumerate(zip(before,after)):totals[part][i].append(b-a)
        errors.append(e['error_rad']);requested_angles.append(abs(parent_angle)+abs(child_angle))
        observed_angles.append(abs(rotation(p,pa))+abs(rotation(c,ca)))
        path.append(math.fsum(abs(b-a) for before,after in ((p,pa),(c,ca)) for a,b in zip(before,after)))
    for part,body in bodies.items():
        if not all(close(math.fsum(totals[part][i]),body['position_delta_wu']['angular'][i]) for i in range(4)):
            raise ValueError('Angular event deltas disagree with original WU phase ledger')
    velocity_engaged=False;block=[];velocity_errors=[];boundary_disagreements=0
    events=row['angular_limit_events']
    if len(events)!=int(resource('physics_velocity_passes')):raise ValueError('Missing velocity-limit event')
    for index,e in enumerate(events):
        if (e['joint'],e['sequence'],e['parent_part'],e['child_part'])!=(0,index,0,1):raise ValueError('Bad velocity event sequence')
        p=e['parent_positions'];c=e['child_positions'];pv=e['parent_velocities'];cv=e['child_velocities']
        if not all(points_finite(v) for v in (p,c,pv,cv)):raise ValueError('Invalid velocity-limit observation')
        q=relative_q(p,c,rest)
        def omega(points,vel):
            x=points[2]-points[0];y=points[3]-points[1]
            return (x*(vel[3]-vel[1])-y*(vel[2]-vel[0]))/(x*x+y*y)
        w=omega(c,cv)-omega(p,pv)
        if not (close(wrapped(e['q_rad']-q),0.) and close(e['omega_rad_s'],w)
                and close(e['lower_rad'],lower) and close(e['upper_rad'],upper)):
            raise ValueError('Raw velocity-limit predicate forged')
        # Exact IEEE754 words preserve decisions at q==upper / omega==0 without
        # inventing an epsilon or trusting a rounded decimal comparison.
        bits=bytes.fromhex(e['predicate_f64_le_hex'])
        if len(bits)!=32:raise ValueError('Missing four binary64 predicate words')
        q_exact,lo_exact,hi_exact,w_exact=struct.unpack('<4d',bits)
        if not all(math.isfinite(a) and close(a,b) for a,b in
                ((q_exact,e['q_rad']),(lo_exact,lower),(hi_exact,upper),(w_exact,w))):
            raise ValueError('Binary predicate disagrees with independently reconstructed values')
        engaged=(q_exact<=lo_exact and w_exact<0) or (q_exact>=hi_exact and w_exact>0)
        decimal_engaged=(e['q_rad']<=lower and e['omega_rad_s']<0) or (e['q_rad']>=upper and e['omega_rad_s']>0)
        boundary_disagreements+=decimal_engaged!=engaged
        if e['engaged']!=engaged or not close(e['impulse'],e['impulse_after']-e['impulse_before']):
            raise ValueError('Limit engagement/impulse forged: '+json.dumps(e,separators=(',',':')))
        if not engaged and e['impulse']!=0.:raise ValueError('Disengaged stop delivered impulse')
        velocity_engaged|=engaged;block.append(e['impulse'])
        velocity_errors.append(e['q_rad']-clamp(e['q_rad'],lower,upper))
    drive=row['drive_events'][0]
    parent=bodies[0];child=bodies[1]
    p=[parent['start_'+k] for k in ('ax','ay','bx','by')];c=[child['start_'+k] for k in ('ax','ay','bx','by')]
    if not close(wrapped(drive['q']-relative_q(p,c,rest)),0.):raise ValueError('Drive-time q forged')
    drive_error=drive['q']-clamp(drive['q'],lower,upper)
    return {'engaged':any(e!=0. for e in errors) or velocity_engaged,
        'position_engaged':any(e!=0. for e in errors),'velocity_engaged':velocity_engaged,
        'drive_q':drive['q'],'drive_error':drive_error,
        'max_position_error':max(map(abs,errors)),'max_any_error':max(map(abs,errors+velocity_errors+[drive_error])),
        'requested_abs_rotation_rad':math.fsum(requested_angles),'observed_abs_rotation_rad':math.fsum(observed_angles),
        'angular_phase_endpoint_magnitude_wu':math.fsum(math.hypot(*b['position_delta_wu']['angular'][i:i+2]) for b in bodies.values() for i in (0,2)),
        'angular_phase_net_l1_wu':math.fsum(abs(v) for b in bodies.values() for v in b['position_delta_wu']['angular']),
        'angular_projection_path_l1_wu':math.fsum(path),
        'max_abs_limit_block_impulse':max(map(abs,block)),
        'nonzero_block':any(v!=0. for v in block),
        'decimal_binary_predicate_disagreements':boundary_disagreements}


def limit_summary(rows):
    audits=[audit_limits(r) for r in rows];tail=audits[-300:]
    return {'limit_engaged_ticks':sum(a['engaged'] for a in tail),'window_ticks':300,
        'position_limit_engaged_ticks':sum(a['position_engaged'] for a in tail),
        'velocity_limit_engaged_ticks':sum(a['velocity_engaged'] for a in tail),
        'drive_outside_band_ticks':sum(a['drive_error']!=0. for a in tail),
        'drive_q_rad_range':[min(a['drive_q'] for a in tail),max(a['drive_q'] for a in tail)],
        'max_drive_time_violation_rad':max(abs(a['drive_error']) for a in tail),
        'max_position_stage_violation_rad':max(a['max_position_error'] for a in tail),
        'max_any_sample_violation_rad':max(a['max_any_error'] for a in tail),
        'requested_abs_projection_rad_sum':math.fsum(a['requested_abs_rotation_rad'] for a in tail),
        'requested_abs_projection_rad_per_tick':math.fsum(a['requested_abs_rotation_rad'] for a in tail)/300,
        'observed_abs_projection_rad_sum':math.fsum(a['observed_abs_rotation_rad'] for a in tail),
        'angular_phase_endpoint_magnitude_wu_sum':math.fsum(a['angular_phase_endpoint_magnitude_wu'] for a in tail),
        'angular_phase_net_l1_wu_sum':math.fsum(a['angular_phase_net_l1_wu'] for a in tail),
        'angular_projection_path_l1_wu_sum':math.fsum(a['angular_projection_path_l1_wu'] for a in tail),
        'max_abs_limit_block_impulse':max(a['max_abs_limit_block_impulse'] for a in tail),
        'limit_block_exact_zero_last300':all(not a['nonzero_block'] for a in tail),
        'limit_block_exact_zero_all6000':all(not a['nonzero_block'] for a in audits),
        'all6000_limit_engaged_ticks':sum(a['engaged'] for a in audits),
        'last300_decimal_binary_predicate_disagreements':sum(a['decimal_binary_predicate_disagreements'] for a in tail),
        'all6000_decimal_binary_predicate_disagreements':sum(a['decimal_binary_predicate_disagreements'] for a in audits),
        'definition':'engaged tick = any nonzero positional stop error OR exact binary64 velocity predicate; phase ledger WU, rotation rad separately verified'}


def predictions(arms):
    ref=arms['reference'];wide=arms['wide90'];weak=arms['bound1']
    removed=wide['limits']['limit_engaged_ticks']==0 and wide['limits']['requested_abs_projection_rad_sum']==0. and wide['limits']['limit_block_exact_zero_last300']
    expectation=.08<=wide['drift_px_s']<=.5
    collapsed=abs(wide['drift_px_s'])<=.5  # owner's upper expectation, not a physical epsilon
    return {'wide_limit_removed_last300':removed,'wide_owner_drift_expectation_px_s':[.08,.5],
        'wide_in_owner_drift_expectation':expectation,
        'wide_drift_collapsed':collapsed,
        'F64_necessary_stop_cause_falsified':removed and not collapsed,
        'wide_interpretation':('Stop removed but drift does not meet owner prediction; do NOT infer a necessary stop propulsor' if removed and not collapsed else
            'Stop removal and drift reduction support owner prediction, not a remedy choice' if removed else
            'Widening did NOT remove stop engagement; necessary-stop mechanism not isolated'),
        'reference_drift_px_s':ref['drift_px_s'],'bound1_drift_px_s':weak['drift_px_s'],
        'old_gain0_drift_px_s':OLD_GAIN0_DRIFT,
        'bound_brake_ordering':ref['drift_px_s']<weak['drift_px_s']<OLD_GAIN0_DRIFT,
        'bound_drift_fell_sign_prediction_inverted':weak['drift_px_s']<ref['drift_px_s'],
        'data_acceptance_not_runtime_acceptance':True}


def report(root):
    arms={};raw={}
    for name,upper,bound in [('reference',DEFAULT_UPPER,DEFAULT_BOUND),('wide90',90.,DEFAULT_BOUND),('bound1',DEFAULT_UPPER,1.)]:
        rows=[json.loads(s) for s in (root/name/'actuated-after-6000.jsonl').read_text().splitlines()]
        expected={'diagnostic_motor_stiffness':MOTOR_STIFFNESS,'motor_gain':DEFAULT_GAIN,
            'diagnostic_motor_limit_min_deg':resource('motors_limit_min_deg'),'diagnostic_motor_limit_max_deg':upper,
            'diagnostic_angular_impulse_limit_rad_s':bound,'diagnostic_linear_damping':LINEAR_DAMPING,
            'diagnostic_motor_damping':MOTOR_DAMPING,'diagnostic_passive_stiffness':resource('physics_passive_stiffness'),
            'diagnostic_static_slip_wu_s':resource('physics_static_slip_wu_s'),'diagnostic_pose':'after','diagnostic_spawn_lift_wu':0.}
        if any(any(r[k]!=v for k,v in expected.items()) for r in rows):raise ValueError('R21 arm changed unauthorized parameter')
        verify_all(rows)
        arm=thrust_summary(rows);arm.update({'strength':strength(rows),'joints':joint_summary(rows),'limits':limit_summary(rows)})
        identity=external_identity(rows);(root/name/'f56-identity.json').write_text(json.dumps(identity,indent=2)+'\n')
        arm['F56']=identity
        print('M1 R21 F56: '+json.dumps({'arm':name,**identity},separators=(',',':')))
        arm.update({'upper_deg':upper,'angular_impulse_limit_rad_s':bound})
        arms[name]=arm;raw[name]=rows
        print('M1 R21 arm: '+json.dumps({'arm':name,**{k:arm[k] for k in ('drift_px_s','rectified_friction_impulse_per_tick','mean_thrust_force_n','mean_completed_vx_wu_s','F56_complete_passed','full_window_residual_x_y','strength','limits','joints')}},separators=(',',':')))
    comparisons={name:compare(raw['reference'],rows) for name,rows in raw.items() if name!='reference'}
    for name,c in comparisons.items():(root/name/'reference-differences.json').write_text(json.dumps(c,indent=2)+'\n')
    ratios={'bound1_commanded_ratio':1/DEFAULT_BOUND,
        'bound1_observed_mean_abs_applied_ratio':arms['bound1']['strength']['applied']['mean_abs']/arms['reference']['strength']['applied']['mean_abs'],
        'wide90_observed_mean_abs_applied_ratio':arms['wide90']['strength']['applied']['mean_abs']/arms['reference']['strength']['applied']['mean_abs']}
    result={'arms':arms,'predictions':predictions(arms),'delivered_ratios':ratios,
        'comparisons':{k:{a:b for a,b in v.items() if a!='per_tick'} for k,v in comparisons.items()},
        'runtime_rows_passed':8,'runtime_rows_total':18,'A':'WITHDRAWN, residual check OBSOLETE / NOT RUN',
        'baseline':'UNCHANGED','Phase3':'NOT ENTERED',
        'D08':'Owner limit-band versus loaded pose/authoring mechanic decision, no choice adopted',
        'D06':'Tutorial FA-6 chunk pending owner','D07':'Reference-device tick cost pending owner'}
    (root/'limit-report.json').write_text(json.dumps(result,indent=2)+'\n')
    print('M1 R21 ratios: '+json.dumps(ratios,separators=(',',':')))
    print('M1 R21 predictions: '+json.dumps(result['predictions'],separators=(',',':')))
    print('M1 R21 teeth: '+json.dumps(result['comparisons'],separators=(',',':')))
    return result

if __name__=='__main__':
    r=report(Path(sys.argv[1]))
    if not (r['predictions']['wide_limit_removed_last300'] and r['predictions']['wide_drift_collapsed'] and r['predictions']['bound_brake_ordering']):raise SystemExit(1)
