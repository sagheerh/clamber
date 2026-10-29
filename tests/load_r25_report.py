#!/usr/bin/env python3
"""R25 measured arms only. No outcome-dependent tolerances, thresholds or tuning."""
import csv,json,math,subprocess,sys
from pathlib import Path
from load_external_report import momentum
from load_trace_report import close, LINEAR_DAMPING
from load_limit_report import relative_q,wrapped,inverse_inertia,turned,audit_limits
from load_saturation_report import audit_drive
from load_motor_report import resource
from load_convergence_report import drift_summary

ARMS=('idle-on','idle-off','lurch-off','lurch-on','gain1-short','gain07-long','gain1-long')
OLD_DRIFT=8.550150769956836


def center(states):
    mass=math.fsum(b['mass'] for b in states)
    return [math.fsum(b['mass']*(b['a'][axis]+b['b'][axis])/2 for b in states)/mass for axis in ('x','y')]


def state_center(r):return center(r['state']['physical']['bodies'])


def verify_brace(r):
    bodies={b['part']:b for b in r['feet']+r['other_bodies']}
    for e in r['brace_events']:
        p=e['parent_positions'];c=e['child_positions'];pv=e['parent_before'];cv=e['child_before']
        ip=inverse_inertia(p,bodies[e['parent_part']]);ic=inverse_inertia(c,bodies[e['child_part']])
        def omega(a,v):
            x=a[2]-a[0];y=a[3]-a[1]
            return (x*(v[3]-v[1])-y*(v[2]-v[0]))/(x*x+y*y)
        w=omega(c,cv)-omega(p,pv);j=-w/(ip+ic)
        assert close(e['omega'],w) and close(e['weight'],ip+ic) and close(e['impulse'],j)
        for points,before,after,dw in ((p,pv,e['parent_after'],-j*ip),(c,cv,e['child_after'],j*ic)):
            x=(points[2]-points[0])*dw/2;y=(points[3]-points[1])*dw/2
            expected=[before[0]+y,before[1]-x,before[2]-y,before[3]+x]
            assert all(close(a,b) for a,b in zip(expected,after))
            # Equal/opposite couple has zero body COM impulse, not just creature cancellation.
            assert close((after[0]+after[2])-(before[0]+before[2]),0.)
            assert close((after[1]+after[3])-(before[1]+before[3]),0.)
        assert close(e['internal_x_ns'],0.) and close(e['internal_y_ns'],0.)
    if r['angular_joints'][0]['brace_active']:
        assert not r['drive_events'] and not r['angular_limit_events']
        assert len(r['brace_events'])==1+int(resource('physics_velocity_passes'))
        for e in r['angular_position_events']:
            p=e['parent_before'];c=e['child_before'];target=r['angular_joints'][0]['brace_q']
            q=relative_q(p,c,r['angular_joints'][0]['rest_angle']);error=wrapped(q-target)
            assert close(e['error_rad'],error)
            ip=inverse_inertia(p,bodies[0]);ic=inverse_inertia(c,bodies[1])
            for original,actual,angle in ((p,e['parent_after'],error*ip/(ip+ic)),(c,e['child_after'],-error*ic/(ip+ic))):
                expected=original if error==0. else turned(original,angle)
                assert all(close(a,b) for a,b in zip(expected,actual))
    else:
        assert not r['brace_events']
        audit_limits(r)
        audit_drive(r,motor_damping=resource('motors_joint_damping'),max_torque=resource('motors_max_torque'),allow_input=True)


def f56_tick(r):
    """Independent raw both-axis balance on EVERY awake tick; parking separate."""
    verify_brace(r);book={}
    budget=r['momentum_budget']
    for axis in ('x','y'):
        before=momentum(r,axis,True);after=momentum(r,axis)
        assert close(before,budget[f'momentum_before_{axis}_ns']) and close(after,budget[f'momentum_after_{axis}_ns'])
        normal=math.fsum(e['n'+axis]*e['normal_impulse_ns'] for e in r['contact_samples'])
        friction=math.fsum((-e['ny'] if axis=='x' else e['nx'])*e['tangential_impulse_ns'] for e in r['contact_samples'])
        drive=budget[f'drive_internal_impulse_{axis}_ns'];internal=budget[f'internal_impulse_{axis}_ns']
        brace=budget[f'brace_internal_impulse_{axis}_ns']
        damping=budget[f'damping_impulse_{axis}_ns'];gravity=budget[f'gravity_impulse_{axis}_ns'];clamp=budget[f'clamp_impulse_{axis}_ns']
        mass=math.fsum(b['mass'] for b in r['feet']+r['other_bodies'])
        assert close(normal+friction,budget[f'contact_velocity_impulse_{axis}_ns'])
        assert close(damping,-LINEAR_DAMPING*(before+drive))
        assert close(gravity,mass*resource('physics_gravity_wu_s2')/60 if axis=='y' else 0.)
        assert close(drive,0.) and close(internal,0.) and close(brace,0.)
        residual=after-before-math.fsum((normal,friction,damping,gravity,clamp,drive,internal))
        assert close(residual,0.)
        book[axis]=[after-before,normal,friction,damping,gravity,clamp,drive,internal,residual,brace]
    return book


def summarise(root):
    result={'source_head':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),'arms':{},'gate_failures':[]}
    for name in ARMS:
        rows=[json.loads(l) for l in (root/f'{name}.jsonl').open()]
        assert len(rows)==rows[0]['requested_ticks'] and [r['tick'] for r in rows]==list(range(len(rows)))
        assert all(r['status']==0 and r['observer_on_off_physical_state_equal'] for r in rows)
        hold=rows[0]['hold_ticks'];raw=[];books=[];parking=[]
        for r in rows:
            assert r['input_mask']==(1 if hold and 5700<=r['tick']<5700+hold else 0)
            if 'awake_solver_trace_before_sleep_parking' in r:
                rr=r['awake_solver_trace_before_sleep_parking'];raw.append(rr);books.append(f56_tick(rr))
                if r['sleep_state']=='asleep':parking.append(r['tick'])
            else:
                assert r['sleep_state']=='asleep'
        first=next((r['tick'] for r in rows if r['sleep_state']=='asleep'),None)
        item={'ticks':len(rows),'brace_enabled':rows[0]['brace_enabled'],'gain':rows[0]['gain'],'hold_ticks':hold,
            'first_actual_sleep_tick':first,'actual_sleep_within4s':first is not None and first<240,
            'awake_ticks_with_F56_raw_verified':len(books),'parked_rows_NO_fresh_force_budget':len(rows)-len(books),
            'parking_events_EXCLUDED_from_awake_force_budget':parking,
            'F56_complete_passed':True,'observer_equal_all_ticks':True,
            'max_abs_per_tick_F56_residual':max(abs(b[a][8]) for b in books for a in ('x','y')),
            'max_abs_per_tick_brace_internal':max(abs(b[a][9]) for b in books for a in ('x','y'))}
        # Whole-run sums are published honestly; numerical net-zero means existing
        # binary64 ledger precision, never manufacture literal zero in a budget.
        item['F56_axis_sums_including_brace_SUBSET_last_column']={a:[math.fsum(b[a][i] for b in books) for i in range(10)] for a in ('x','y')}
        windows=[]
        for start in range(0,len(books),300):
            window=books[start:start+300]
            sums={a:[math.fsum(b[a][i] for b in window) for i in range(10)] for a in ('x','y')}
            for a,v in sums.items():
                assert close(v[6],0.) and close(v[7],0.) and close(v[9],0.)
                assert close(v[0]-math.fsum(v[1:8]),0.)
            windows.append({'awake_row_start':start,'count':len(window),'sums':sums})
        (root/f'{name}-f56.json').write_text(json.dumps({'scope':'EVERY actual awake solver tick before parking, no fictitious forces on parked rows; brace column is subset NOT added twice','windows':windows},indent=2)+'\n')
        if not hold:
            if name=='idle-off':
                assert len(raw)==6000
                item['drift_px_s']=drift_summary(raw)['net_drift_px_s_at_150px_wu']
            else:
                # Actual completed physical position increments, including parked ticks.
                item['drift_px_s']=(state_center(rows[-1])[0]-state_center(rows[-301])[0])*30
        else:
            start=state_center(rows[5699]);held=state_center(rows[5699+hold]);end=state_center(rows[-1])
            bodies=rows[0]['state']['physical']['bodies']
            length=math.fsum(b['length'] for b in bodies)
            item['chain_length_wu']=length
            item['held_xy_wu']=[b-a for a,b in zip(start,held)]
            item['end_release_xy_wu']=[b-a for a,b in zip(start,end)]
            item['held_horizontal_body_lengths']=(held[0]-start[0])/length
            item['end_release_horizontal_body_lengths']=(end[0]-start[0])/length
            item['peak_horizontal_during_hold_body_lengths']=max(state_center(r)[0]-start[0] for r in rows[5700:5700+hold])/length
        result['arms'][name]=item
        print('M1 R25 arm: '+json.dumps({'arm':name,**item},separators=(',',':')))
    public=[json.loads(l) for l in (root/'public-f52.jsonl').open()]
    assert len(public)==600 and all(r['status']==0 for r in public)
    first=next((r['tick'] for r in public if r['state']['accumulator']['solver']['rig']['sleep']['asleep']),None)
    result['public_actual_F52_first_sleep_tick']=first
    result['public_actual_F52_within4s']=first is not None and first<240
    a=result['arms']
    if not result['public_actual_F52_within4s'] or not a['idle-on']['actual_sleep_within4s']:result['gate_failures'].append('STOP: unmodified actual F52 did not fire within4s')
    if abs(a['idle-on']['drift_px_s'])>.3:result['gate_failures'].append('STOP: brace drift above.3px/s')
    if a['idle-off']['drift_px_s']!=OLD_DRIFT:result['gate_failures'].append('STOP: brace-off not EXACT c10 drift')
    if a['lurch-on']['held_xy_wu'][0]<a['lurch-off']['held_xy_wu'][0]:result['gate_failures'].append('Brace weakens held lurch vs same-adopted brace-off arm')
    result['F74_sampled_max_end_release_body_lengths']=max(a[n]['end_release_horizontal_body_lengths'] for n in ARMS if a[n]['hold_ticks'])
    result['F74_scope']='Published .7/1.0 x 1s/5s durations only, NOT a global maximum over unrestricted holdtime; idle translation must not be relabelled input effect'
    if result['F74_sampled_max_end_release_body_lengths']<1:result['gate_failures'].append('STOP F74: sampled ceiling short of1bodylength; no gain/contraction widening')
    (root/'r25-report.json').write_text(json.dumps(result,indent=2)+'\n')
    print('M1 R25 verdict: '+json.dumps({k:v for k,v in result.items() if k!='arms'},separators=(',',':')))
    return result

if __name__=='__main__':
    r=summarise(Path(sys.argv[1]));sys.exit(bool(r['gate_failures']))
