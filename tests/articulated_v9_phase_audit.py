#!/usr/bin/env python3
"""Read-only V9 phase audit. No engine/step or new world ticks."""
import gzip, hashlib, json
from pathlib import Path
from articulated_posture_audit import vector, attitude
ROOT=Path(__file__).resolve().parents[1]
FOLDER=ROOT/'tests/fixtures/m1_articulated_execution/fb9ff2c58b44'
RAW_SHA256='05334bbd0fa61309297cb3bd92eff9a4f56ca62e922c9ae161f47d55b4837f2a'
SOURCE='fb9ff2c58b44ed30e1f916c87b0764a25d4fdc4b'
def audit():
    raw=gzip.decompress((FOLDER/'idle-Slug.jsonl.gz').read_bytes())
    if hashlib.sha256(raw).hexdigest()!=RAW_SHA256: raise ValueError('immutable source hash mismatch')
    rows=[json.loads(s) for s in raw.splitlines()]
    source=json.loads((FOLDER/'source.json').read_text())
    if source['source_commit']!=SOURCE: raise ValueError('source mismatch')
    spawn=json.loads((FOLDER/'idle-Slug-spawn.json').read_text())['rig']['physical']['bodies']
    initial=vector([dict(kind=b['kind'],a=[b['a']['x'],b['a']['y']],b=[b['b']['x'],b['b']['y']]) for b in spawn])
    measurements=[]; residual=drag_error=0.0; energy_errors=0
    for row in rows:
        trace=row['awake_solver_trace']; parts=sorted(trace['feet']+trace['other_bodies'],key=lambda p:p['part'])
        start=[]; predicted=[]; end=[]
        for p,b in zip(parts,spawn):
            z=dict(kind=b['kind'],a=[p['start_ax'],p['start_ay']],b=[p['start_bx'],p['start_by']]); start.append(z)
            d=p['position_delta_wu']['integration']
            predicted.append(dict(kind=b['kind'],a=[z['a'][k]+d[k] for k in range(2)],b=[z['b'][k]+d[k+2]for k in range(2)]))
            end.append(dict(kind=b['kind'],a=p['a'],b=p['b']))
            for endpoint,off in [('a',0),('b',2)]:
                for k in range(2):
                    residual=max(residual,abs(z[endpoint][k]+sum(d[off+k] for d in p['position_delta_wu'].values())-p[endpoint][k]))
        events=trace['authored_angular_damping']
        drag_error=max(drag_error,max(abs(e['omega_after']-0.2*e['omega_projected']) for e in events))
        energy_errors += sum(e['energy_after'] for e in events)>sum(e['energy_before'] for e in events)
        measurements.append(dict(tick=row['tick'],start_deg=attitude(initial,vector(start)),integration_deg=attitude(initial,vector(predicted)),final_deg=attitude(initial,vector(end))))
    first=next(r for r in measurements if r['final_deg']>15)
    return dict(scope='OFFLINE immutable V9 audit; ZERO new world ticks; NOT acceptance',source=SOURCE,raw_sha256=RAW_SHA256,
        ticks=len(rows),first_posture_failure=first,max_position_reconstruction_residual_wu=residual,
        max_drag_rate_arithmetic_residual=drag_error,drag_total_energy_increases=energy_errors,
        max_still_ticks=max(r['state']['sleep']['still_ticks'] for r in rows),
        sample_rows=[r for r in measurements if r['tick'] in [0,1,9,19,25,26,39,99,239,599]],
        limitations=['Integration and final poses are reconstructable; interleaved correction phases are aggregate, not chronological.',
                    'Authored angular loss holds at its phase; it does not prove the later contact solve retains it.',
                    'Both real integrated motion and later corrections contribute. No proof an upright pose is impossible.',
                    'Next isolated hypothesis is force/contact timing: constrain velocity before integrating supported points, not new damping/tuning.'])
if __name__=='__main__':print(json.dumps(audit(),indent=2))
