#!/usr/bin/env python3
"""Read-only closure of NEW V11 full600 failure, never a new physical attempt."""
import gzip,hashlib,json,math
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
SOURCE='30a220585b67a41f751ed786f698760b1d7b717b'
FOLDER=ROOT/'tests/fixtures/m1_articulated_execution'/SOURCE[:12]
RAW_SHA256='14c57e6a8ed4b5bc1b7d5289c595a0d07ed83b1a2921a4a00a891cd12c306e5e'
GZIP_SHA256='8c47764b30ad92d5e8b29d5cee76e5ec5b41c3352e59f39098f6f15b7f8babbc'
def audit():
 packed=(FOLDER/'idle-Slug.jsonl.gz').read_bytes();raw=gzip.decompress(packed)
 if hashlib.sha256(raw).hexdigest()!=RAW_SHA256 or hashlib.sha256(packed).hexdigest()!=GZIP_SHA256:raise ValueError('immutable capture mismatch')
 source=json.loads((FOLDER/'source.json').read_text())
 if source['source_commit']!=SOURCE or source['checkout_dirty'] is not False:raise ValueError('wrong/dirty source')
 rows=[json.loads(s)for s in raw.splitlines()];expected=['angular_damping','linear_damping','drive','gravity','velocity_pass_0','integration']+['position_sweep_'+str(i)for i in range(6)]+['velocity_pass_1']
 residual=0.0;finite=True
 def scan(v):
  nonlocal finite
  if isinstance(v,float):finite=finite and math.isfinite(v)
  elif isinstance(v,dict):
   for x in v.values():scan(x)
  elif isinstance(v,list):
   for x in v:scan(x)
 for row in rows:
  scan(row);b=row['awake_solver_trace']['momentum_budget']
  for axis in ['x','y']:
   residual=max(residual,abs(b['momentum_change_'+axis+'_ns']-sum(b[stage+'_impulse_'+axis+'_ns']for stage in ['drive_internal','damping','gravity','internal','contact_velocity','clamp'])))
 return dict(scope='OFFLINE immutable600 closure; ZERO new world ticks; NOT acceptance',source=SOURCE,raw_sha256=RAW_SHA256,gzip_sha256=GZIP_SHA256,
  ticks=len(rows),tick_sequence=[rows[0]['tick'],rows[-1]['tick']],every_status_ok=all(r['awake_solver_trace']['status']==0 for r in rows),every_row_finite=finite,
  exact_actual_stage_order_all600=all(r['awake_solver_trace']['stage_order']==expected for r in rows),one_original_controller_event_per_tick=all(len(r['awake_solver_trace']['drive_events'])==1 for r in rows),
  first_posture_violation=next(r['tick']for r in rows if r['attitude_deg']>15),max_attitude_deg=max(r['attitude_deg']for r in rows),final_attitude_deg=rows[-1]['attitude_deg'],
  airborne_ticks=[r['tick']for r in rows if not any(b['grounded']for b in r['state']['physical']['bodies'])],any_sleep=any(r['state']['sleep']['asleep']for r in rows),max_still_ticks=max(r['state']['sleep']['still_ticks']for r in rows),
  penetration_violations=sum(r['penetration_peak_wu']>.02*(1+1e-9)for r in rows),max_length_wu=max(r['length_peak_wu']for r in rows),max_momentum_ledger_residual_ns=residual,
  summary=json.loads((FOLDER/'summary.json').read_text()),
  limitations=['Constitutive identity and full fresh motor controls pass, but original posture/no-airborne/rest still FAIL. No adoption.',
   'No native/runtime/device/performance/determinism gate can be credited from this offline audit.',
   'Do not retry this source or sweep force/damping order. Need a new independently justified physical correction, not threshold/tuning/sleep relaxation.',
   'This is not an impossibility proof or evidence that contact/damping/rest coupling has been fully diagnosed.'])
if __name__=='__main__':print(json.dumps(audit(),indent=2))
