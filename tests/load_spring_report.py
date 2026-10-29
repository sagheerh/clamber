#!/usr/bin/env python3
"""R17 diagnostic only: passive stiffness intervention, no adopted remedy."""
import json
import math
from pathlib import Path
import sys
from load_long_report import verify_all, summarize_baseline
from load_convergence_report import drift_summary
from load_phase_report import phase_magnitudes
from load_legal_report import validate_counts
from load_convergence_report import com_values
from collections import defaultdict


def joint_summary(rows):
    tail = rows[-300:]
    result = []
    for index in range(len(tail[0]['drive_events'])):
        events = [r['drive_events'][index] for r in tail]
        for e in events:
            stiffness = tail[0]['diagnostic_motor_stiffness'] if e['kind'] == 'motor' else tail[0]['diagnostic_passive_stiffness']
            if e['spring_torque'] != stiffness * (e['target']-e['q']):
                raise ValueError('Spring decomposition not derived from raw pre-drive q')
            if not all(math.isfinite(e[k]) for k in ('q','spring_torque','damping_torque','torque')):
                raise ValueError('Nonfinite torque evidence')
        result.append({'joint':index, 'kind':events[0]['kind'], 'channel':events[0]['channel'],
            'mean_abs_q_rad':math.fsum(abs(e['q']) for e in events)/300,
            'mean_spring_torque':math.fsum(e['spring_torque'] for e in events)/300,
            'mean_damping_torque':math.fsum(e['damping_torque'] for e in events)/300,
            'mean_clamped_total_torque':math.fsum(e['torque'] for e in events)/300})
    return result



def count_buckets(rows):
    """Per-body AND whole-creature count signatures; no epsilon/causal upgrade."""
    regimes=validate_counts(rows)
    whole=defaultdict(list)
    per_body=defaultdict(list)
    for row,regime in zip(rows[-300:],regimes[-300:],strict=True):
        dx,_=com_values(row)
        signature=tuple((p,v,*regime[p,v]) for p,v in sorted(regime))
        whole[signature].append(dx)
        for part in sorted({p for p,v in regime}):
            body_sig=tuple((v,*regime[p,v]) for p,v in sorted(regime) if p==part)
            per_body[(part,body_sig)].append(dx)
    def stats(values):
        return {'ticks':len(values),'mean_com_dx_wu_tick':math.fsum(values)/len(values),
            'mean_drift_px_s':math.fsum(values)/len(values)*9000,
            'min_com_dx_wu_tick':min(values),'max_com_dx_wu_tick':max(values),
            'exactly_constant_within_bucket':min(values)==max(values)}
    return {'key_fields':['part','velocity_pass','intervals','candidate_count','active_count'],
        'whole_creature':[{'key':[list(t) for t in key],**stats(values)} for key,values in sorted(whole.items())],
        'per_body':[{'part':part,'key':[list(t) for t in key],**stats(values)} for (part,key),values in sorted(per_body.items())],
        'interpretation':'Observed association only. No sampling change, no epsilon, no pose-causal claim or automatic F41 closure.'}


def report(root):
    result={'scope':'F48 diagnostic, pre-drive signed torque contributions before total clamp; NOT equilibrium/acceptance', 'arms':{}}
    for name in ('baseline-after','current-before','current-after','zero-before','zero-after'):
        folder=root/name
        if (folder/'engine-status.txt').read_text().strip() != '0': raise ValueError(f'{name} incomplete')
        ticks=600 if name.startswith('baseline') else 6000
        rows=[json.loads(s) for s in (folder/f'slug-{ticks}.jsonl').read_text().splitlines()]
        if name.startswith('baseline'):
            item=summarize_baseline(rows)
            item={'drift':item['zero_input_drift'], 'joints':[]}
        else:
            verify_all(rows)
            item={'drift':drift_summary(rows), 'joints':joint_summary(rows), 'raw_phases':phase_magnitudes(rows)}
        if not name.startswith('zero'):
            item['F41_count_buckets']=count_buckets(rows)
            print('M1 R17 F41 buckets: '+json.dumps({'arm':name,'whole_creature':item['F41_count_buckets']['whole_creature']},separators=(',',':')))
        item['passive_stiffness']=rows[0]['diagnostic_passive_stiffness']
        item['motor_stiffness']=rows[0]['diagnostic_motor_stiffness']
        result['arms'][name]=item
        print('M1 R17 spring: '+json.dumps({'arm':name, **{k:v for k,v in item.items() if k!='F41_count_buckets'}},separators=(',',':')))
    result['interpretation']='Intervention changes ONLY passive stiffness. Slug has one MOTOR joint, zero passive joints. Spring-return-live remains true with passive stiffness zero; no motor stiffness intervention was authorized. Do not claim passive spring mechanism proven.'
    (root/'spring-report.json').write_text(json.dumps(result,indent=2)+'\n')
    print('M1 R17 spring interpretation: '+result['interpretation'])
    return result

if __name__=='__main__': report(Path(sys.argv[1]))
