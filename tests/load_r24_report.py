#!/usr/bin/env python3
"""R24: exactly3 slip cells + committed lurch; C reprocesses OLD traces, no rerun."""
from collections import deque
import csv
import json
import math
from pathlib import Path
import sys
import subprocess
from load_d09_report import validate_arm, center, f52_eligibility
from load_motor_report import resource, thrust_summary
from load_saturation_report import audit_drive, stats
from load_long_report import verify_all
from load_limit_report import limit_summary, relative_q, wrapped
from load_external_report import external_identity
from load_convergence_report import com_values
from load_trace_report import close

SLIPS=(.15,.015,.0015)


def conditional_allowance(slip,drift):
    # Owner hypothesis ONLY, not a measured target or adopted threshold.
    return None if drift==0 else slip*.3/abs(drift)


def book(rows):
    assert len(rows)==6000
    windows=[external_identity(rows[i:i+300]) for i in range(0,6000,300)]
    assert all(w['internal_rows_and_complete_ledger_verified'] for w in windows)
    identity=dict(windows[-1])
    identity['all6000_disjoint300_windows']=windows
    identity['all6000_max_abs_per_tick_full_residual']=max(w['axes'][a]['max_abs_per_tick_full_residual'] for w in windows for a in ('x','y'))
    identity['all6000_max_abs_window_residual']=max(abs(w['axes'][a]['sums']['full_residual_from_sides']) for w in windows for a in ('x','y'))
    return identity,{a:[identity['axes'][a]['sums'][k] for k in
        ('delta','normal','friction','damping','gravity','clamp','internal_drive','internal_velocity','full_residual_from_sides')] for a in ('x','y')}


def trace(path):return [json.loads(s) for s in path.read_text().splitlines()]


def q_samples(row):
    bodies={b['part']:b for b in row['feet']+row['other_bodies']}
    rest=row['angular_joints'][0]['rest_angle']
    def integrated(b):return [b['start_'+k]+d for k,d in zip(('ax','ay','bx','by'),b['position_delta_wu']['integration'])]
    q=row['drive_events'][0]['q']
    samples=[q,relative_q(integrated(bodies[0]),integrated(bodies[1]),rest)]
    samples.extend(e['q_rad'] for e in row['angular_position_events'])
    samples.extend(e['q_rad'] for e in row['angular_limit_events'])
    samples.append(row['angular_joints'][0]['q'])
    # Unwrap around same drive-time reference; no false2pi span at branch cut.
    return [q+wrapped(v-q) for v in samples]


def old_c(root,out):
    result={}
    for name in ('c10','c20','c40'):
        files=list(root.glob(f'**/{name}/both/trace.jsonl'));assert len(files)==1
        tail=deque(maxlen=300);count=0;engaged=0;projected=0;blocked=0
        with files[0].open() as stream:
            for line in stream:
                row=json.loads(line);assert row['tick']==count;count+=1;tail.append(row)
                engaged+=any(e['error_rad']!=0. for e in row['angular_position_events']) or any(e['engaged'] for e in row['angular_limit_events'])
                projected+=any(e['parent_before']!=e['parent_after'] or e['child_before']!=e['child_after'] for e in row['angular_position_events'])
                blocked+=any(e['impulse']!=0. for e in row['angular_limit_events'])
        assert count==6000
        rows=list(tail);qs=[r['drive_events'][0]['q'] for r in rows]
        vx=[com_values(r)[1] for r in rows]
        summary=json.loads(files[0].with_name('summary.json').read_text())
        assert all(close(a,b) for a,b in zip((min(vx),max(vx)),summary['convergence']['last300_vx_range_wu_s']))
        assert engaged==summary['limits']['all6000_limit_engaged_ticks']
        assert summary['working_pose_q_rad']['min']==min(qs) and summary['working_pose_q_rad']['max']==max(qs)
        spreads=[max(q_samples(r))-min(q_samples(r)) for r in rows]
        omega=[r['drive_events'][0]['omega'] for r in rows]
        item={'source':'OLD573a1fb/artifact12901654637, NO new k study',
            'last300_com_vx_range_wu_s':[min(vx),max(vx)],
            'last300_drive_q_range_rad':[min(qs),max(qs)],'between_ticks_drive_q_spread_rad':max(qs)-min(qs),
            'between_ticks_drive_q_max_abs_adjacent_change_rad':max(abs(b-a) for a,b in zip(qs,qs[1:])),
            'within_tick_sampled_q_spread_rad':stats(spreads),
            'drive_time_relative_omega_rad_s':stats(omega),
            'all6000_limit_engaged_ticks':engaged,'all6000_projection_moved_ticks':projected,'all6000_nonzero_limit_block_ticks':blocked,
            'sample_definition':'drive; after integration reconstructed from raw start+integration phase; pre-angular per-pass; velocity-limit samples; completed. Sampled range, NOT continuous extrema.',
            'interpretation':'Tiny between-tick drive-q range does NOT imply a frozen within-tick joint. No phase/contact cause isolated by this postprocessing.'}
        result[name]=item
        with (out/f'C-{name}-per-tick.csv').open('w') as f:
            w=csv.writer(f);w.writerow(['tick','com_vx_wu_s','drive_q_rad','q_after_integration_rad','within_tick_sampled_q_spread_rad','drive_omega_rad_s'])
            for r,v,spread in zip(rows,vx,spreads):w.writerow([r['tick'],v,r['drive_events'][0]['q'],q_samples(r)[1],spread,r['drive_events'][0]['omega']])
        print('M1 R24 C: '+json.dumps({'candidate':name,**item},separators=(',',':')))
    return result


def report(root,old):
    result={'A':{},'B':{},'C':{},'STOP':'Package decision required; no further experiment/adoption/brace',
        'source_head':subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),
        'old_source_head':'573a1fb7aa43059b4c51f995a4fe3d5998b0ace1','old_artifact_id':12901654637,
        'runtime_rows_passed':8,'runtime_rows_total':18,'adopted':False}
    for slip in SLIPS:
        folder=root/f'A-{slip}';rows=trace(folder/'trace.jsonl')
        p,weight,damping,delivery=validate_arm(rows,'c40','both',static_slip=slip)
        summary=thrust_summary(rows);identity,sums=book(rows)
        limits=limit_summary(rows)
        item={'candidate':'c40','candidate_parameters':p,'derived_motor_damping':damping,
            'all6000_observer_on_off_equal':True,'static_slip_wu_s':slip,'drift_px_s':summary['drift_px_s'],
            'mean_thrust_force_n':summary['mean_thrust_force_n'],'strength':delivery,
            'F56_complete_passed':identity['internal_rows_and_complete_ledger_verified'],'F56_axis_sums':sums,
            'F56_all6000_per_tick_and20windows_verified':True,
            'F56_all6000_max_abs_per_tick_full_residual':identity['all6000_max_abs_per_tick_full_residual'],
            'F56_all6000_max_abs_window_residual':identity['all6000_max_abs_window_residual'],
            'F56_literal_vector_passed':identity['F56_literal_vector_passed'],
            'implied_allowance_if_proportional_to_this_point':conditional_allowance(slip,summary['drift_px_s']),
            'implied_allowance_label':'UNMEASURED extrapolation under hypothesis drift proportional through origin; NOT adopted/tested target',
            'limits':limits,'F52_observer':f52_eligibility(rows)}
        (folder/'f56.json').write_text(json.dumps(identity,indent=2)+'\n')
        (folder/'summary.json').write_text(json.dumps(item,indent=2)+'\n')
        result['A'][str(slip)]=item
        print('M1 R24 A: '+json.dumps(item,separators=(',',':')))
    folder=root/'B';rows=trace(folder/'trace.jsonl')
    expected={'diagnostic_d09_candidate':'','diagnostic_d09_lurch':True,
        'diagnostic_motor_stiffness':resource('motors_joint_stiffness'),
        'diagnostic_motor_damping':resource('motors_joint_damping'),
        'diagnostic_motor_max_torque':resource('motors_max_torque'),
        'diagnostic_angular_impulse_limit_rad_s':resource('physics_max_constraint_angular_impulse_rad_s'),
        'diagnostic_static_slip_wu_s':resource('physics_static_slip_wu_s'),
        'diagnostic_motor_limit_max_deg':resource('motors_limit_max_deg'),
        'diagnostic_motor_limit_min_deg':resource('motors_limit_min_deg'),
        'diagnostic_linear_damping':resource('physics_linear_damping'),
        'diagnostic_passive_stiffness':resource('physics_passive_stiffness'),
        'motor_gain':resource('motors_gain_default'),'diagnostic_pose':'after','diagnostic_spawn_lift_wu':0.}
    if any(any(r.get(k)!=v for k,v in expected.items()) for r in rows):raise ValueError('B not committed defaults')
    verify_all(rows,d09_lurch=True)
    audits=[audit_drive(r,allow_input=True) for r in rows]
    identity,sums=book(rows)
    length=sum(math.hypot(b['start_bx']-b['start_ax'],b['start_by']-b['start_ay']) for b in rows[0]['feet']+rows[0]['other_bodies'])
    start=center(rows[5699]);end=center(rows[5759]);release=center(rows[-1]);dx=end[0]-start[0];dy=end[1]-start[1]
    b={'committed_settings':expected,'all6000_observer_on_off_equal':True,'protocol':'SAME proposed95s released /1sL /4srelease; NOT formal FA4',
       'body_length_definition':'sum initial actual capsule axes, all3parts; not AABB width',
       'body_chain_length_wu':length,'held_displacement_xy_wu':[dx,dy],
       'held_horizontal_displacement_body_lengths':dx/length,
       'held_com_displacement_norm_wu':math.hypot(dx,dy),
       'end_release_displacement_xy_wu':[release[i]-start[i] for i in (0,1)],
       'held_torque':stats([r['drive_events'][0]['torque'] for r in rows[5700:5760]]),
       'held_requested_over_bound':stats([a['requested_over_bound'] for a in audits[5700:5760]]),
       'held_saturated_ticks':sum(a['saturated'] for a in audits[5700:5760]),
       'F56_complete_passed':identity['internal_rows_and_complete_ledger_verified'],'F56_axis_sums':sums,
            'F56_all6000_per_tick_and20windows_verified':True,
            'F56_all6000_max_abs_per_tick_full_residual':identity['all6000_max_abs_per_tick_full_residual'],
            'F56_all6000_max_abs_window_residual':identity['all6000_max_abs_window_residual'],
            'F56_literal_vector_passed':identity['F56_literal_vector_passed'],
       'limits':limit_summary(rows)}
    result['B']=b;(folder/'f56.json').write_text(json.dumps(identity,indent=2)+'\n')
    print('M1 R24 B: '+json.dumps(b,separators=(',',':')))
    result['C']=old_c(old,root)
    (root/'r24-report.json').write_text(json.dumps(result,indent=2)+'\n')
    return result

if __name__=='__main__':report(Path(sys.argv[1]),Path(sys.argv[2]))
