#!/usr/bin/env python3
"""POSTPROCESS ONLY accepted source artifacts. Never imports or runs Godot/solver."""
import hashlib,json,math,sys
from collections import deque
from pathlib import Path


def unique(root,suffix):
    paths=list(root.glob('**/'+suffix));assert len(paths)==1,(suffix,paths)
    return paths[0]


def audit(root,out):
    result={'source_head':'8d73597f0ce4c118ad0602816b51770d8292611f','source_run':40895082337,'new_physics_runs':0,'AC202':{}}
    for name in ('Slug','Hopper','TwinRoller'):
        path=unique(root,f'r25-ac202/{name}.jsonl')
        groups={};count=0
        for line in path.open():
            r=json.loads(line);assert r['tick']==count;count+=1
            for i,b in enumerate(r['bodies']):
                error=abs(math.hypot(b['b']['x']-b['a']['x'],b['b']['y']-b['a']['y'])-b['length'])
                assert math.isfinite(error)
                group=groups.setdefault(b['kind'],{'max_error_wu':0.,'at':None})
                if error>group['max_error_wu']:group.update(max_error_wu=error,at=[r['tick'],i])
        limbmax=max((v['max_error_wu'] for k,v in groups.items() if k in ('limb','motor','passive')),default=0.)
        result['AC202'][name]={'ticks':count,'by_kind':groups,'limb_motor_passive_max_wu':limbmax,
            'limb_motor_passive_criterion_met':count==7200 and limbmax<=.05,
            'all_segment_criterion_met':count==7200 and all(g['max_error_wu']<=.05 for g in groups.values())}
    p=unique(root,'r25-fa5/Hopper.jsonl');tail=deque(maxlen=1);count=0
    for line in p.open():count+=1;tail.append(json.loads(line))
    r=tail[0];bs=r['feet']+r['other_bodies']
    result['FA5']={'rows':count,'last_tick':r['tick'],
        'last_endpoint_x_range':[min(b[e+'x'] for b in bs for e in ('a','b')),max(b[e+'x'] for b in bs for e in ('a','b'))],
        'last_endpoint_y_range':[min(b[e+'y'] for b in bs for e in ('a','b')),max(b[e+'y'] for b in bs for e in ('a','b'))],
        'fixture_bounds':{'x':[-12.,12.],'y':[-4.,8.]},
        'termination_reason':'NOT LOGGED: harness breaks on bad status or observer mismatch. Last completed row only; no new step/replay to infer cause.',
        'report':json.loads(unique(root,'r25-fa5/fa5-report.json').read_text())}
    raw=unique(root,'r25-brace/idle-on.jsonl');public=unique(root,'r25-brace/public-f52.jsonl')
    a=raw.open();b=public.open();equal=True;count=0
    for line in b:
        rr=json.loads(next(a));pp=json.loads(line)
        equal=equal and rr['state']['physical']==pp['state']['accumulator']['solver']['rig']['physical']
        count+=1
    result['public_idle_equals_force_trace_physical_first600']={'ticks':count,'equal':equal}
    a.close();b.close();assert count==600 and equal
    # Full brace report/books already verified on source. Read original raw, no rerun.
    result['brace_report']=json.loads(unique(root,'r25-brace/r25-report.json').read_text())
    baseline=unique(root,'r25-baseline/public_sim_baseline.json').read_bytes()
    result['committed_baseline_byte_equal_generated']=baseline==Path('tests/fixtures/public_sim_baseline.json').read_bytes()
    result['generated_baseline_file_sha256']=hashlib.sha256(baseline).hexdigest()
    assert result['committed_baseline_byte_equal_generated']
    (out/'r25-archive-audit.json').write_text(json.dumps(result,indent=2)+'\n')
    for k,v in result.items():
        if k=='brace_report':continue
        print('M1 R25 archive: '+json.dumps({'field':k,'value':v},separators=(',',':')))
    return result

if __name__=='__main__':audit(Path(sys.argv[1]),Path(sys.argv[2]))
