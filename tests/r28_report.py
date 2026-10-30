#!/usr/bin/env python3
"""Pure R28 measurements. No simulation, epsilon, fitting window substitution or tuning."""
import json, math, sys
from pathlib import Path
from r27_report import bodies, com, attitude, angle_degrees, segment_errors, rows, load, completed, need


def measure(folder):
    engine=load(folder/'engine.json'); result={}; limb={}
    for name in ('Slug','Hopper','TwinRoller'):
        maximum={'penetration_wu':0.,'part':None,'tick':None}; foot=0.; maximum_length=None; count=0
        for r in rows(folder/f'{name}.jsonl'):
            need(r['tick']==count and r['input_mask']==(count//60)%4,'Wrong production arm')
            need(r['status']==0 and not r['nonfinite'],'Nonfinite/status failure; inspect full raw first failing row')
            p=bodies(r['state'])
            samples=r['penetration']['samples']; need(r['penetration']['status']==0 and samples,'Missing terrain samples')
            for s in samples:
                actual=max(0.,s['radius_wu']-s['distance_wu'])
                need(actual==s['penetration_wu'],'Forged penetration')
                # For the registered uniform y=0 plane this independently verifies
                # normal signed distance and the complete capsule's extremal surface.
                need(s['normal']==[0.,1.], 'Not registered analytical floor normal')
                if actual>maximum['penetration_wu']:maximum=dict(s,tick=count)
                if s['kind']=='foot':foot=max(foot,actual)
            # Endpoint samples include the exact extremum on this linear plane.
            exact=max(0.,max(b['radius']-min(b['a']['y'],b['b']['y']) for b in p))
            need(all(any(s['part']==i and s['u']==u for s in samples) for i in range(len(p)) for u in (0.,1.)), 'Missing extremal endpoint')
            for v in segment_errors(p):
                if v['kind'] in ('motor','passive','limb') and (maximum_length is None or v['error_wu']>maximum_length['error_wu']):maximum_length=dict(v,tick=count)
            if r['phases']:
                tail=r['phases']['after_diagnostic_final_distance']
                need(all(s['a']==[b['a']['x'],b['a']['y']] and s['b']==[b['b']['x'],b['b']['y']] for s,b in zip(tail,p,strict=True)),'Not completed post-reprojection pose')
            else:need(r['state']['sleep']['asleep'],'Missing awake phase recording')
            count+=1
        done=completed(engine[name],7200,count)
        result[name]=dict(max_penetration_wu=maximum['penetration_wu'],max_foot_penetration_wu=foot,limit=.02,
                          verdict='PASS' if done and maximum['penetration_wu']<.02 else 'FAIL',worst_sample=maximum,ticks=count,completed=done,termination=engine[name])
        need(maximum_length is not None,'Empty limb criterion')
        limb[name]=dict(completed_tick_limb_max_wu=maximum_length['error_wu'],worst=maximum_length,ticks=count,limit=.05,
                        verdict='PASS' if done and maximum_length['error_wu']<=.05 else 'FAIL')
    return dict(penetration=result,ac202_production=limb,penetration_gate_passed=all(x['verdict']=='PASS' for x in result.values()),
                stop_and_revert=any(x['verdict']!='PASS' for x in result.values()))


def idle(folder, target):
    engine=load(folder/'engine.json'); spawn=load(folder/'Slug-spawn.json')
    origin=com(bodies(spawn)); vector=attitude(bodies(spawn)); points=[origin]; angles=[0.]; airborne=0; sleep=0; first=None; last_raw=0.
    for count,r in enumerate(rows(folder/'Slug.jsonl')):
        need(r['tick']==count and r['input_mask']==0,'Wrong idle arm')
        need(r['status']==0 and not r['nonfinite'],'Nonfinite/status failure; inspect raw first failing row')
        p=bodies(r['state']); raw=angle_degrees(vector,attitude(p)); angles.append(angles[-1]+math.remainder(raw-last_raw,360.));last_raw=raw
        points.append(com(p));airborne+=int(all(not b['grounded'] for b in p))
        if r['state']['sleep']['asleep']:
            sleep+=1
            if first is None:first=count
    count=len(angles)-1;done=completed(engine['Slug'],target,count);need(done,'Incomplete required window')
    if target==600:
        displacement=math.dist(points[-1],origin); span=max(angles)-min(angles)
        # Exactly 300 displacements ending at completed ticks300..599: prior
        # completed tick299 supplies the boundary point, not spawn or tick300.
        speed=math.fsum(math.dist(points[t+1],points[t]) for t in range(300,600))/5.*150.
        return dict(ticks=count,completed=done,AC201a=dict(degrees=span,min_signed_degrees=min(angles),max_signed_degrees=max(angles),airborne_tick_count=airborne,threshold_degrees=15.,passed=span<=15. and airborne==0,delta_vs_R27_degrees=span-35.34385590667538),
                    AC201b=dict(wu=displacement,px=displacement*150.,body_lengths=displacement/.9,effective_px_s=displacement*150./10.,margin=.9/displacement if displacement else None,passed=displacement<=.9,delta_vs_R27_wu=displacement-.6460243614279206,delta_vs_R27_px=displacement*150.-96.9036542141881),
                    AC201s=dict(first_tick=first,sleeping_ticks=sleep,passed=first is not None and first<600,delta_sleeping_ticks=sleep),
                    drift=dict(mean_com_speed_px_s=speed,window='300 completed-tick COM displacement norms ending at ticks300..599, including boundary point at completed tick299; exactly5s',signed_lateral_net_px_s=math.fsum(points[t+1][0]-points[t][0] for t in range(300,600))/5.*150.,R26_reference_px_s=8.550150769956836,reference_definition='R26 signed lateral COM net displacement/5s, not2D path length',delta_lateral_px_s=math.fsum(points[t+1][0]-points[t][0] for t in range(300,600))/5.*150.-8.550150769956836,no_fix_claim=True))
    deltas=[b-a for a,b in zip(angles,angles[1:])];signs=[1 if d>0 else -1 for d in deltas if d!=0.];changes=sum(a!=b for a,b in zip(signs,signs[1:]))
    crossing=lambda limit:next((i/60. for i,v in enumerate(angles) if abs(v)>=limit),None)
    ninety=crossing(90.);one_eighty=crossing(180.)
    return dict(ticks=count,rate_deg_s=angles[-1]/60.,rate_definition='net unwrapped spawn-relative angle / full60s, no fitted/substituted window',time_to_90_s=ninety,time_to_180_s=one_eighty,sign_changes=changes,zero_delta_policy='exact zero deltas ignored, no epsilon/dead zone',max_abs_angle_last600_degrees=max(map(abs,angles[-600:])),min_signed_degrees=min(angles),max_signed_degrees=max(angles),reading='toppling' if ninety is not None else 'undetermined',reading_basis='90degree crossing' if ninety is not None else 'no90degree crossing within60s; finite window cannot establish an attractor; sign/envelope numbers above',new_gate=False)


def main(mode, folder):
    try:
        r=measure(folder) if mode=='adoption-measure' else idle(folder,600 if mode=='idle-family' else 3600)
        r['verification_passed']=True
    except (ValueError,KeyError,OSError,TypeError) as exc:r=dict(verification_passed=False,error=f'{type(exc).__name__}: {exc}')
    (folder/'report.json').write_text(json.dumps(r,indent=2)+'\n')
    print('M1 R28 report: '+json.dumps(r,separators=(',',':')))
    return 0 if r['verification_passed'] and not r.get('stop_and_revert',False) else 1


if __name__=='__main__':sys.exit(main(sys.argv[1],Path(sys.argv[2])))
