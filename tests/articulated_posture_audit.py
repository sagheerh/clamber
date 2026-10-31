#!/usr/bin/env python3
"""Read immutable14-frame evidence; reconstruct integration vs aggregate correction.
No engine, Sim step, new world ticks, or invented intermediate iteration poses.
"""
import gzip,hashlib,json,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
FOLDER=ROOT/'tests/fixtures/m1_articulated_execution/f7b8fd24d6b8'
def vector(parts):
    head=parts[0]; feet=[b for b in parts if b['kind']=='foot']
    return [sum((b['a'][i]+b['b'][i])/2 for b in feet)/len(feet)-(head['a'][i]+head['b'][i])/2 for i in range(2)]
def attitude(initial,current):
    return abs(math.degrees(math.atan2(initial[0]*current[1]-initial[1]*current[0],initial[0]*current[0]+initial[1]*current[1])))
def audit():
    packed=(FOLDER/'idle-Slug.jsonl.gz').read_bytes();raw=gzip.decompress(packed)
    index=json.loads((FOLDER/'transport-index.json').read_text())['raw_traces']['idle-Slug.jsonl']
    if hashlib.sha256(raw).hexdigest()!=index['raw_sha256']:raise ValueError('immutable trace hash mismatch')
    rows=[json.loads(s) for s in raw.splitlines()]
    spawn=json.loads((FOLDER/'idle-Slug-spawn.json').read_text())['rig']['physical']['bodies']
    initial=vector([dict(kind=b['kind'],a=[b['a']['x'],b['a']['y']],b=[b['b']['x'],b['b']['y']]) for b in spawn])
    result=[]; max_reconstruction=0.0
    for row in rows:
        trace=row['awake_solver_trace'];parts=sorted(trace['feet']+trace['other_bodies'],key=lambda x:x['part'])
        start=[];predicted=[];end=[]
        for p in parts:
            kind='foot' if p['part']==2 else p['kind']
            s=dict(kind=kind,a=[p['start_ax'],p['start_ay']],b=[p['start_bx'],p['start_by']]);start.append(s)
            phases=p['position_delta_wu'];d=phases['integration']
            predicted.append(dict(kind=kind,a=[s['a'][i]+d[i] for i in range(2)],b=[s['b'][i]+d[2+i] for i in range(2)]))
            end.append(dict(kind=kind,a=p['a'],b=p['b']))
            for endpoint,offset in [('a',0),('b',2)]:
                for i in range(2):
                    value=s[endpoint][i]+sum(v[offset+i] for v in phases.values())
                    max_reconstruction=max(max_reconstruction,abs(value-p[endpoint][i]))
        angle=attitude(initial,vector(end))
        if abs(angle-row['attitude_deg'])>1e-12:raise ValueError('attitude reconstruction mismatch') # Offline arithmetic only.
        budget=trace['momentum_budget']
        x_res=budget['momentum_change_x_ns']-sum(budget[k] for k in ['drive_internal_impulse_x_ns','damping_impulse_x_ns','gravity_impulse_x_ns','internal_impulse_x_ns','contact_velocity_impulse_x_ns','clamp_impulse_x_ns'])
        y_res=budget['momentum_change_y_ns']-sum(budget[k] for k in ['drive_internal_impulse_y_ns','damping_impulse_y_ns','gravity_impulse_y_ns','internal_impulse_y_ns','contact_velocity_impulse_y_ns','clamp_impulse_y_ns'])
        result.append(dict(tick=row['tick'],before_deg=attitude(initial,vector(start)),after_integration_deg=attitude(initial,vector(predicted)),final_deg=angle,
            angular_position_changed=any(e['parent_before']!=e['parent_after'] or e['child_before']!=e['child_after'] for e in trace['angular_position_events']),
            angular_velocity_engaged=any(e['engaged'] for e in trace['angular_limit_events']),self_events=len(trace['self_contact_events']),
            momentum_residual_x=x_res,momentum_residual_y=y_res,foot_applied_n=parts[2]['applied_load_n'],gripping=parts[2]['gripping']))
    return dict(scope='OFFLINE saved trace audit; ZERO new world ticks; NOT M1 acceptance',rows=result,max_position_ledger_residual_wu=max_reconstruction,
        first_integration_violation=next(r['tick'] for r in result if r['after_integration_deg']>15),first_final_violation=next(r['tick'] for r in result if r['final_deg']>15),
        limitation='Integration is reconstructable; interleaved position-iteration stages are only aggregate ledgers, NOT chronological intermediate poses.')
if __name__=='__main__':print(json.dumps(audit(),indent=2))
