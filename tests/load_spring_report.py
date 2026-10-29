#!/usr/bin/env python3
"""R17 diagnostic only: passive stiffness intervention, no adopted remedy."""
import json
import math
from pathlib import Path
import sys
from load_long_report import verify_all, summarize_baseline
from load_convergence_report import drift_summary
from load_phase_report import phase_magnitudes


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
        item['passive_stiffness']=rows[0]['diagnostic_passive_stiffness']
        item['motor_stiffness']=rows[0]['diagnostic_motor_stiffness']
        result['arms'][name]=item
        print('M1 R17 spring: '+json.dumps({'arm':name, **item},separators=(',',':')))
    result['interpretation']='Intervention changes ONLY passive stiffness. Slug has one MOTOR joint, zero passive joints. Spring-return-live remains true with passive stiffness zero; no motor stiffness intervention was authorized. Do not claim passive spring mechanism proven.'
    (root/'spring-report.json').write_text(json.dumps(result,indent=2)+'\n')
    print('M1 R17 spring interpretation: '+result['interpretation'])
    return result

if __name__=='__main__': report(Path(sys.argv[1]))
