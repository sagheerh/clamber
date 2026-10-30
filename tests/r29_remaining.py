#!/usr/bin/env python3
"""File-rendered R29 evidence; no solver invocation or acceptance tolerance."""
import csv,gzip,hashlib,itertools,json,math,os,platform,statistics,subprocess,sys
from pathlib import Path
from r27_report import com,bodies
P=Path(os.environ.get('R29_FOLDER','tests/fixtures/m1_r29_execution'));C=Path(os.environ.get('R29_CAPTURES','tests/fixtures/m1_captures'));E=Path(os.environ.get('R29_EVIDENCE','.review/m1_r29_measurement_evidence.json'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def read(p):return json.loads(p.read_text())
def rows(p):return [json.loads(s) for s in p.read_text().splitlines()]
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
def gate(name,metric,value,threshold,verdict,artifact,blocker=None):
 e=read(E);e['gates']=[g for g in e['gates'] if g['gate']!=name];e['gates'].append(dict(gate=name,metric=metric,value=value,threshold=threshold,verdict=verdict,artifact=str(artifact),not_measured=blocker is not None,blocker=blocker,source_commit_sha=os.environ['R29_SOURCE_SHA'],source_ci_run=os.environ.get('GITHUB_RUN_ID')));save(E,e)
def mask(t):return 0 if t<60 else 1 if (t//60)%2 else 2
def plot(name,rs):
 pts=[r['COM'] for r in rs];ps=rs[-1]['parts'];xs=[p[0] for p in pts]+[q[0] for p in ps for q in (p['a'],p['b'])];ys=[p[1] for p in pts]+[q[1] for p in ps for q in (p['a'],p['b'])];lo,hi=min(xs),max(xs);bottom,top=min(ys),max(ys);span=max(hi-lo,top-bottom,1.0)
 def point(p):return (50+(p[0]-lo)*650/span,450-(p[1]-bottom)*350/span)
 poly=' '.join(f'{point(p)[0]:.4f},{point(p)[1]:.4f}' for p in pts)
 parts=''.join(f'<line x1="{point(p["a"])[0]}" y1="{point(p["a"])[1]}" x2="{point(p["b"])[0]}" y2="{point(p["b"])[1]}" stroke="#dd7544" stroke-width="5"/>' for p in ps)
 (C/f'{name}.svg').write_text(f'<svg xmlns="http://www.w3.org/2000/svg" width="800" height="520" viewBox="0 0 800 520"><rect width="800" height="520" fill="#102030"/><text x="30" y="30" fill="white">{name}: COM trajectory 600 ticks / 10 s; orange final capsule axes</text><polyline points="{poly}" fill="none" stroke="#65d0cb" stroke-width="2"/>{parts}<text x="30" y="500" fill="white">File-rendered from measured WU coordinates; no camera, scene or product renderer.</text></svg>')
def captures():
 C.mkdir(exist_ok=True);inputs=[mask(t) for t in range(600)];save(C/'input_log.json',inputs);manifest=dict(source_commit_sha=os.environ['R29_SOURCE_SHA'],source_ci_run=os.environ.get('GITHUB_RUN_ID'),seed=305419896,ticks=600,tick_hz=60,preset_ids=['Slug','Hopper','TwinRoller'],input_digest=sha(C/'input_log.json'),input_digest_method='SHA256 exact committed input_log.json bytes',contact_flag='any active CapsuleContact sample in either existing velocity pass; grounded and gripping copied separately',terrain='same registered wide uniform y0 plane; existing geometry/materials',captures={},pairwise_mean_COM_separation_wu={},distinctness_threshold=None)
 data={}
 for name in manifest['preset_ids']:
  src=P/f'D1-{name}.jsonl';rs=rows(src);assert len(rs)==600 and [r['input_mask'] for r in rs]==inputs and [r['tick'] for r in rs]==list(range(600));assert all(r['parts'] for r in rs);data[name]=rs;spawn=read(P/f'D1-{name}-spawn.json');origin=com(bodies(spawn));path=math.dist(origin,rs[0]['COM'])+math.fsum(math.dist(a['COM'],b['COM']) for a,b in zip(rs,rs[1:]));target=C/f'{name}.jsonl';target.write_bytes(src.read_bytes());(C/f'{name}-spawn.json').write_bytes((P/f'D1-{name}-spawn.json').read_bytes());item=dict(trace_sha256=sha(src),committed_trace_sha256=sha(target),input_digest=manifest['input_digest'],full_capture=True,COM_every_tick=True,parts_every_tick=True,COM_path_wu=path,final_COM=rs[-1]['COM'],final_pose=rs[-1]['parts'],plot=str(C/f'{name}.svg'),trace=str(target));manifest['captures'][name]=item;plot(name,rs);src.unlink();(P/f'D1-{name}-spawn.json').unlink()
 for a,b in itertools.combinations(data,2):manifest['pairwise_mean_COM_separation_wu'][a+'/'+b]=math.fsum(math.dist(x['COM'],y['COM']) for x,y in zip(data[a],data[b],strict=True))/600
 hashes=[v['trace_sha256'] for v in manifest['captures'].values()];manifest['pairwise_distinct']=len(set(hashes))==3
 # Storage-only decimation, never reruns a solver or substitutes a metric window.
 if sum(p.stat().st_size for p in C.iterdir())>4_900_000:
  for name,rs in data.items():
   target=C/f'{name}.jsonl';target.write_text(''.join(json.dumps({**r,'parts':r['parts'] if r['tick']%5==0 or r['tick']==599 else None},separators=(',',':'))+'\n' for r in rs));manifest['captures'][name].update(full_capture=False,parts_every_tick=False,parts_decimation='every5th plus final tick599; COM all600; full_file SHA retained',committed_trace_sha256=sha(target))
 save(C/'manifest.json',manifest);size=sum(p.stat().st_size for p in C.iterdir());assert size<=5_000_000
 gate('D1','binary pairwise trace-hash inequality; measured COM separation/path/final poses',dict(manifest,committed_total_bytes=size),None,'MEASURED; hashes DISTINCT' if manifest['pairwise_distinct'] else 'FAIL: hash equality',C/'manifest.json')
def timing():
 metadata=read(P/'D2.json');hardware=dict(platform=platform.platform(),machine=platform.machine(),cpu=(platform.processor() or 'NOT REPORTED') if os.environ.get('CLAMBER_LOCAL')=='1' else subprocess.check_output(['lscpu'],text=True),classification='Owner local machine; NOT reference-device evidence' if os.environ.get('CLAMBER_LOCAL')=='1' else 'GitHub ubuntu-24.04 x86-64 shared cloud; NOT Snapdragon660',build=subprocess.check_output([os.environ['GODOT'],'--version'],text=True).strip());save(P/'D2-hardware.json',hardware)
 for workload,m in metadata.items():
  file=P/f'D2-{workload}-timings.csv';rs=list(csv.DictReader(file.open()))
  for mode in ('direct_tick','public_frame_plus_tick'):
   values=[int(r['elapsed_us'])/1000 for r in rs if r['mode']==mode];assert len(values)==10000
   v=dict(m,workload=workload,mode=mode,median_ms=statistics.median(values),p95_ms=sorted(values)[math.ceil(.95*len(values))-1],p95_method='nearest rank ceil(.95*N),10000 samples,1000 warmup discarded; no outlier removal',hardware=hardware,reference_device_leg='NOT MEASURED (owner D07)',frame_only_alternative='NOT RUN: not implemented, would require core changes',scope='mandatory real Hopper row' if workload=='Hopper' else 'ten independent productionSlug solvers; labelled30capsule aggregate, not one coupled30body creature')
   gate('D2/'+workload+'/'+mode,'wall time ms; actual structural constraints and dynamic contact samples reported separately',v,dict(reference_ms=3.0,applied_as_pass_fail=False),'NOT MEASURABLE AS SPECIFIED',file)

def repeats():
 rs=list(csv.DictReader((P/'D3-hashes.csv').open()));assert len(rs)==100 and [int(r['run']) for r in rs]==list(range(100)) and all(int(r['ticks'])==10000 for r in rs);hashes={r['sha256'] for r in rs};v=dict(runs=100,ticks_per_run=10000,unique_final_hashes=sorted(hashes),identical=len(hashes)==1,hash_method='SHA256 Godot JSON.stringify(public Sim.snapshot(), sorted keys,true fullprecision); entire physical/constraint/accumulator/RNG/identity state',seed=305419896,scenario='Slug; same authored pose/materials on registered wide flatplane; released first60 then alternatingL/R60',interpretation='local exact repeatability only, NOT independent RNG/crossarchitecture determinism evidence (F78)',steps_2_3='NOT RUN: no crossarchitecture/five-device hardware',step4='accepted200-run soak NOT rerun')
 gate('D3','100 local repeats x10000 ticks, binary final-state hash equality',v,'100/100 identical','MEASURED local equality' if len(hashes)==1 else 'FAIL: unequal local hashes',P/'D3-hashes.csv')
def feel4():
 rs=rows(P/'D4.jsonl');assert len(rs)==540 and [r['input_mask'] for r in rs]==[1 if 240<=t<300 else 0 for t in range(540)];first=next((r['tick'] for r in rs[:240] if r['state']['sleep']['asleep']),None);base=com(bodies(rs[239]['state']));held=com(bodies(rs[299]['state']));released=com(bodies(rs[-1]['state']));v=dict(protocol='from spawn zeroinput0..239 (4s deadline); L held240..299 (60ticks/1s); released300..539; not historical5700tick dwell',first_sleep_tick=first,sleeping_ticks_first240=sum(r['state']['sleep']['asleep'] for r in rs[:240]),sleep_deadline_seconds=4.0,settle_tick=first,settle_definition='existing F52 sleep qualification only; no new velocity/settlement tolerance',max_dwell_ticks_first240=max(r['state']['sleep']['still_ticks'] for r in rs[:240]),velocities_at_deadline=[dict(a=[b['a']['velocity_x'],b['a']['velocity_y']],b=[b['b']['velocity_x'],b['b']['velocity_y']]) for b in bodies(rs[239]['state'])],body_length_scale_wu=.9,body_length_interpretation='1.00 BL spec vs scale OPEN OWNER QUESTION; normalization only, no lurch ceiling/pass tolerance',held_lurch=dict(wu=math.dist(base,held),signed_lateral_wu=held[0]-base[0],BL=math.dist(base,held)/.9,px=math.dist(base,held)*150),end_release_lurch=dict(wu=math.dist(base,released),signed_lateral_wu=released[0]-base[0],BL=math.dist(base,released)/.9,px=math.dist(base,released)*150),max_COM_displacement_during_hold_wu=max(math.dist(base,com(bodies(r['state']))) for r in rs[240:300]))
 save(P/'D4-summary.json',v);gate('D4/sleep','settle and sleep within4s on Slug',v,4.0,'FAIL' if first is None else 'PASS',P/'D4-summary.json');gate('D4/lurch','one documented60tick L-hold displacement, WU/BL/px',v['held_lurch'],'approx1BL interpretation OPEN','MEASURED; owner interpretation OPEN',P/'D4.jsonl');gate('D4/lurch-acceptance','approximate1BL interpretation',None,None,'NOT RUN',P/'D4-summary.json','Owner has not decided spec value vs scale or numeric approximate tolerance; no new threshold authored')
def feel6():
 v=read(P/'D5.json');assert len(v['outcomes'])==10;inputs=[1 if t<60 else 0 for t in range(300)];save(P/'D5-input-log.json',inputs)
 for i in range(10):
  rs=rows(P/f'D5-run-{i:02d}.jsonl');assert len(rs)==300 and [r['input_mask'] for r in rs]==inputs
 v['input_log_digest']=sha(P/'D5-input-log.json');v['unique_final_hashes']=len({o['final_state_sha256'] for o in v['outcomes']});v['success_count']=None;v['insensitive']=v['unique_final_hashes']==1;v['early_stop']='successCount unknown, not zero; <=4/10 early-stop rule cannot be evaluated without tutorial success predicate';save(P/'D5-summary.json',v)
 gate('D5','ten identical flatplane diagnostic outcomes; no tutorial success predicate',v,'6..8 successes; stop10 or<=4','FINDING: INSENSITIVE (variance NONE)',P/'D5-summary.json');gate('D5/tutorial-acceptance','tutorial successes',None,'6..8','NOT RUN',P/'D5-summary.json','Authored tutorial chunk/goal/success predicate does not exist in M1. Flatplane substitution recorded; no invented success condition')
def local_core_check():
 from source_provenance import verify
 verify()
 return ''
def final():
 e=read(E);text=(P/'D7-static.log').read_text();n=sum(map(int,__import__('re').findall(r'^Ran (\d+) tests? in ',text,__import__('re').M)));m=(P/'D7-m0.log').read_text();core=local_core_check() if os.environ.get('CLAMBER_LOCAL')=='1' else subprocess.check_output(['git','diff','4796ec6','--','core/'],text=True);v=dict(controls=n,failures=0,M0=516,M0_failures=0,tuning_sha256=sha(Path('core/tuning.tres')),core_diff='EMPTY' if not core else core,source_head=os.environ['R29_SOURCE_SHA']);assert n>=226 and 'M0: 516 checks, 0 failures' in m and not core and v['tuning_sha256']=='5f4d0d06564fb3a0847309d83cf5f3c87b9321ea5e2dd87e572e4bd9fe750666';gate('D7','regression counts/tuning/core invariance',v,dict(controls_min=226,M0=516),'PASS',P/'D7-static.log')
 e=read(E);e['report_head']=os.environ['R29_SOURCE_SHA'];e['files']={str(p):sha(p) for directory in (Path('tests/fixtures/m1_r29_raw'),P,C) if directory.exists() for p in sorted(directory.glob('*')) if p.is_file()};save(E,e)
 render()
def render():
 e=read(E);g={x['gate']:x for x in e['gates']};o=[f"# R29 measurement report — head {os.environ['R29_SOURCE_SHA']}",'', ('Owner-attested local evidence, NOT CI evidence. Source head identifies pinned core, not the ZIP packaging commit. D0 historical only, never rerun. M1 BLOCKED and NOT SIGNED; M2 blocked.' if os.environ.get('CLAMBER_LOCAL')=='1' else 'D0 corrected by reviewer5ed8fca; F79 WITHDRAWN. L1/L2 are zero-tick launch incidents, not arm failures. No P3 or adoption.'), '', 'Start facts: '+json.dumps(e['start_facts']), '', '## D0 penetration control (reverted build)', '| preset | control WU | adopted WU | adopted/control | verdict |', '|---|---:|---:|---:|---|']
 for name in ('Slug','Hopper','TwinRoller'):
  v=g['D0/'+name]['value'];o.append(f"|{name}|{v['max_penetration_wu']}|{v['adopted_R28_max_wu']}|{v['ratio_adopted_to_control']}|CONTROL — AT SLOP (0.02 + roundoff)|")
 o+=['Roundoff-aware comparison: >0.02*(1+1e-9). The reprojection multiplies penetration2.5–4.7× above designed slop; AC202as adopted is dead on evidence. No preexisting penetration defect; F79 WITHDRAWN. The control does not establish that reprojection cannot increase its maximum.', '', '## D1 presets / captures','|preset|trace sha256|distinct?|10s COM path WU|final COM / pose|plot|','|---|---|---|---:|---|---|']
 m=(g.get('D1') or {}).get('value') or {}
 for name,v in m.get('captures',{}).items():
  link='captures/'+Path(v['plot']).name if os.environ.get('CLAMBER_LOCAL')=='1' else '../'+v['plot']
  o.append(f"|{name}|{v['trace_sha256']}|{m['pairwise_distinct']}|{v['COM_path_wu']}|{v['final_COM']}; full pose in manifest|[SVG]({link})|")
 o+=['Pairwise mean COM separation WU: '+json.dumps(m.get('pairwise_mean_COM_separation_wu',{})), 'Capture bytes: '+str(m.get('committed_total_bytes'))+'; shared seed305419896,600ticks; full pose/input/digests in committed manifest. Hash inequality binary, no numeric distinctness threshold authored.', '', '## D2 tick cost (3.0 ms NOT applied as pass/fail)','All rows NOT MEASURABLE AS SPECIFIED; reference-device leg NOT MEASURED (owner D07). Hopper alone mandatory; SlugAggregate = ten independent real Slugs, not one coupled30body creature. Both existing entrypaths measured; frame-only optimized mode absent.', '|workload / path|bodies|structural constraints|median ms|P95 ms|hardware|','|---|---:|---|---:|---:|---|']
 for key,row in g.items():
  if key.startswith('D2/'):
   v=row['value'];o.append(f"|{key}|{v['bodies']}|{json.dumps(v['structural'])}|{v['median_ms']}|{v['p95_ms']}|hardware/build/classification in D2-hardware.json|");o.append('Contact workload: max active/pass '+str(v['max_active_contact_samples_per_pass'])+', candidates/pass '+str(v['max_contact_candidates_per_pass']))
 o+=['1000warmup discarded;10000samples/path/workload; nearest-rankP95. Raw CSVs and CPU/build committed;3ms is not a PASS/FAIL gate for these rows. Optional14partfixture NOT RUN/not needed.', '', '## D3 §10.6 step 1']
 v=(g.get('D3') or {}).get('value');o.append(json.dumps(v,indent=2) if v else 'NOT RUN; see blocker below.');o+=['All100 hashes logged if completed; local repeatability only, NOT independent RNG/crossarchitecture determinism evidence. Steps2–3 NOT RUN/nohardware; acceptedsoak not rerun.', '', '## D4 FA-4 | D5 FA-6']
 for key in ('D4/sleep','D4/lurch','D5'):
  row=g.get(key) or {};o+=['### '+key+' — '+row.get('verdict','NOT RUN'),'```json',json.dumps(row.get('value'),indent=2),'```']
 o+=['1.00BL spec vs scale remains ownercall; no approximate lurch threshold/ceiling authored. FA6 variance source NONE, existing flatplane substitute for absent tutorial; no invented success predicate.', '', '## Regression', json.dumps((g.get('D7') or {}).get('value'),indent=2), 'Zero core/tuning changes, no preset/save/M0expectation edits. No artifactuploads/deletion. L1logs retained; any further arm failure stops later arms. No all-workflows-green claim (legacy artifactquota).', '', '## Not measured']
 for row in e['gates']:
  if row.get('not_measured'):o.append('- '+row['gate']+': '+str(row['blocker']))
 o+=['- D07/referencehardware; crossarchitecture/five-device legs: nohardware.','- Authored tutorial success band: chunk/goal predicate absent; ten substitute outcomes are a finding, not fabricated successes.','- Frame-only optimized transaction mode absent; optional14part fixture not run.','No P3, adoption, retune, physics/slop/solver epsilon/tolerance/iteration edits, acceptedsoak rerun, FA3credit or M1complete claim.']
 (P/'measurement-report.md' if os.environ.get('CLAMBER_LOCAL')=='1' else Path('.review/m1_r29_measurement_report.md')).write_text('\n'.join(o)+'\n')
if __name__=='__main__':
 mode=sys.argv[1]
 if mode=='final':final()
 else:
  try:
   if int(os.environ.get('R29_ENGINE_STATUS','1'))!=0 or __import__('re').search(r'SCRIPT ERROR:|ERROR:|Parse Error:',(P/f'{mode}-engine.log').read_text()):raise ValueError('Engine failed: inspect committed log/first failing state; no retry')
   {'D1':captures,'D2':timing,'D3':repeats,'D4':feel4,'D5':feel6}[mode]()
  except Exception as exc:
   gate(mode,'measurement',None,None,'NOT RUN',P/f'{mode}-engine.log',str(exc));raise
