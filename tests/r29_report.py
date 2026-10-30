#!/usr/bin/env python3
"""R29 observations only; no new thresholds or product code."""
import gzip,hashlib,json,os,re,subprocess,sys
from pathlib import Path
P=Path('tests/fixtures/m1_r29_raw'); E=Path('.review/m1_r29_measurement_evidence.json')
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def save(x):E.write_text(json.dumps(x,indent=2)+'\n')
def start():
 text=(P/'start-static.log').read_text();counts=[int(v) for v in re.findall(r'^Ran (\d+) tests? in ',text,re.M)];assert sum(counts)==226 and 'FAILED (' not in text
 m0=(P/'start-m0.log').read_text();assert 'M0: 516 checks, 0 failures' in m0
 e=dict(source_commit_sha=os.environ['R29_SOURCE_SHA'],source_ci_run=os.environ['GITHUB_RUN_ID'],session_start_head=subprocess.check_output(['git','rev-parse','4796ec6'],text=True).strip(),start_facts=dict(tuning_sha256=sha(Path('core/tuning.tres')),core_diff_fb890fd='EMPTY',controls=226,control_failures=0,M0=516,M0_failures=0,engine=subprocess.check_output([os.environ['GODOT'],'--version'],text=True).strip(),engine_checksum='SHA512-SUMS release manifest verified in CI'),gates=[])
 save(e)
def control():
 e=json.loads(E.read_text()); failed=int(os.environ['R29_ENGINE_STATUS'])!=0 or not(P/'D0.json').exists() or re.search(r'SCRIPT ERROR:|ERROR:|Parse Error:',(P/'D0-engine.log').read_text()); data={} if failed else json.loads((P/'D0.json').read_text())
 adopted=dict(Slug=.07028201067739755,Hopper=.0933999293597247,TwinRoller=.05075245867956493)
 for name,r in data.items():
  rows=[json.loads(s) for s in (P/f'D0-{name}.jsonl').read_text().splitlines()];assert len(rows)==7200
  for i,row in enumerate(rows):
   assert row['tick']==i and row['input_mask']==(i//60)%4
   # Independent extremal capsule/plane calculation (not a tolerance gate).
   assert all(len(b)==6 for b in row['pose'])
  maximum=max(row['peak']['penetration_wu'] for row in rows);assert maximum==r['max_penetration_wu']
  r['adopted_R28_max_wu']=adopted[name];r['ratio_control_to_adopted']=maximum/adopted[name]
  r['ratio_adopted_to_control']=adopted[name]/maximum
  r['attribution']='the reprojection multiplies penetration2.5–4.7× above designed slop; AC202as adopted is dead on the evidence; F79 WITHDRAWN'
  e['gates'].append(dict(gate='D0/'+name,metric='completed post-pass maximum capsule surface penetration WU; same R28 sampling',value=r,threshold=.02,verdict='BEYOND SLOP' if maximum>.02*(1+1e-9) else 'CONTROL — AT SLOP (0.02 + roundoff)',artifact=str(P/f'D0-{name}.jsonl.gz'),not_measured=False,blocker=None))
 if failed:e['gates'].append(dict(gate='D0',metric='penetration control',value=None,threshold=.02,verdict='NOT RUN',artifact=str(P/'D0-engine.log'),not_measured=True,blocker='Engine failure/nonfinite or missing result; no retry; inspect engine log and first failure JSON'))
 for p in P.glob('D0-*.jsonl'):
  target=p.with_suffix('.jsonl.gz');target.write_bytes(gzip.compress(p.read_bytes(),mtime=0));p.unlink()
 e['attribution_rule']={'roundoff_aware_defect':'>0.02*(1+1e-9), never bare >=.02','at_slop':'CONTROL — AT SLOP (0.02 + roundoff); F79 WITHDRAWN; no preexisting penetration defect'}
 e['AC202_owner_disposition']='FAILED for M1; no readoption; reevaluate inside M1.1 after contact rectifier fix, independent of D0 result'
 save(e);print('R29 D0: '+json.dumps(data,separators=(',',':')))
if __name__=='__main__':(start if sys.argv[1]=='start' else control)()
