#!/usr/bin/env python3
"""Independent AC202 / natural-load HopperFA5 evidence. Missing coverage cannot pass."""
import json,math,sys
from pathlib import Path
from load_motor_report import resource
from load_trace_report import close


def ac202(root):
    result={}
    for name in ('Slug','Hopper','TwinRoller'):
        maximum=0.;at=None;count=0
        for line in (root/f'{name}.jsonl').open():
            r=json.loads(line);assert r['tick']==count;count+=1
            assert r['input_mask']==(r['tick']//60)%4
            for i,b in enumerate(r['bodies']):
                error=abs(math.hypot(b['b']['x']-b['a']['x'],b['b']['y']-b['a']['y'])-b['length'])
                assert math.isfinite(error) and close(error,r['errors_wu'][i])
                if error>maximum:maximum=error;at=[r['tick'],i,b['kind']]
        result[name]={'ticks':count,'maximum_length_error_wu':maximum,'at':at,'passed':count==7200 and maximum<=.05}
    passed=all(v['passed'] for v in result.values())
    return {'gate':'AC202','passed':passed,'presets':result,'scope':'publicSim, allparts strongerthanlimbs,7200ticks each, threshold UNCHANGED.05WU'}


def fa5(root):
    counts={k:0 for k in ('below','at_or_above','two_foot_grip','airborne','N0_no_grip')};examples={};previous=[];count=0;maxN=0
    for line in (root/'Hopper.jsonl').open():
        r=json.loads(line);assert r['tick']==count and r['observer_on_off_physical_state_equal'];count+=1
        bodies={b['part']:b for b in r['feet']+r['other_bodies']};feet={b['part'] for b in r['feet']}
        assert len(feet)==2 and r['previous_grounded_parts']==previous
        N=sum(i in feet for i in previous);assert N==r['previous_grounded_feet'];maxN=max(maxN,N)
        threshold=max(resource('physics_grip_normal_force_floor'),resource('physics_grip_normal_force_ratio')*r['weight_n']/N) if N else None
        for batch in r['contact_batches']:
            parts=batch['parts'];bottom=min(b['bottom_wu'] for b in parts);passedfeet=[]
            for part in parts:
                i=part['part'];b=bodies[i]
                lowest=part['bottom_wu']<=bottom+resource('physics_contact_slop_wu')
                assert part['lowest']==lowest
                expected_load=max(0.,-(b['mass']*resource('physics_gravity_wu_s2')*(1/60)+part['hinge_y_ns']+part['extra']['y'])/(1/60))
                assert close(part['applied_load_n'],expected_load)
                if i not in feet:continue
                events=[e for e in r['contact_samples'] if e['part']==i and e['velocity_pass']==batch['velocity_pass']]
                assert len(events)>=1
                active=any(e['active'] for e in events)
                expected_grip=active and N>0 and lowest and part['applied_load_n']>=threshold
                if batch['velocity_pass']==int(resource('physics_velocity_passes'))-1:
                    assert b['grounded']==active and b['gripping']==expected_grip
                branches=[]
                if not active:branches.append('airborne')
                if active and N==0:branches.append('N0_no_grip')
                if active and N>0 and lowest:branches.append('at_or_above' if part['applied_load_n']>=threshold else 'below')
                if expected_grip:passedfeet.append(i)
                for branch in branches:
                    counts[branch]+=1;examples.setdefault(branch,{'tick':r['tick'],'pass':batch['velocity_pass'],'part':i,'N':N,'threshold':threshold,'actual_load':part['applied_load_n'],'lowest':lowest,'grounded':active,'expected_grip':expected_grip})
            if len(passedfeet)==2:
                counts['two_foot_grip']+=1;examples.setdefault('two_foot_grip',{'tick':r['tick'],'pass':batch['velocity_pass'],'parts':passedfeet,'N':N})
        previous=r['grounded_parts']
    missing=[k for k,v in counts.items() if not v]
    return {'gate':'FA5','ticks':count,'max_previous_grounded_feet':maxN,'branch_counts':counts,'examples':examples,'missing_coverage':missing,
        'passed':count==7200 and not missing,'scope':'actual authoredHopper/braceoff/natural hinge+gravity+selfcontact loads; no synthetic qualifying loads or pose edits; missingbranches are NOTPASS'}

if __name__=='__main__':
    mode=sys.argv[1];root=Path(sys.argv[2]);r=ac202(root) if mode=='ac202' else fa5(root)
    (root/f'{mode}-report.json').write_text(json.dumps(r,indent=2)+'\n')
    print('M1 R25 independent: '+json.dumps(r,separators=(',',':')))
    sys.exit(not r['passed'])
