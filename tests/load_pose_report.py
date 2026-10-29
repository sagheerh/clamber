#!/usr/bin/env python3
"""R14 owner A/A1: exact pre/post600, no sleep or force/sampling/tuning change."""
import json
from pathlib import Path
import sys
from load_trace_report import analyze
from load_contact_report import save


def compare(root):
    result = {'scope': 'R14 A/A1 pose ONLY; no sleep/motors/limits/self-contact', 'cases': {}}
    for pose in ('before','after'):
        folder = Path(root)/pose
        try:
            if (folder/'engine-status.txt').read_text().strip()!='0':
                raise ValueError('Engine incomplete; not an observed600')
            rows=[json.loads(s) for s in (folder/'slug-600.jsonl').read_text().splitlines()]
            if any(r['diagnostic_pose']!=pose or r['diagnostic_spawn_y_wu']!=.33 or r['diagnostic_position_iterations']!=6 or r['diagnostic_static_slip_wu_s']!=.15 or r['sleep_implemented'] for r in rows):
                raise ValueError('Paired unchanged diagnostic metadata mismatch')
            a=analyze(rows)
            c=save(folder,rows)
            result['cases'][pose]={'status':'OBSERVED','rows':len(rows),
                'grip_ticks':len(a['grip_engaged_ticks']),'first_grip_tick':next(iter(a['grip_engaged_ticks']),None),
                'loaded_grip_ticks':len(a['loaded_grip_ticks']),
                'last300_grip_fraction':a['motion']['steady_grip_fraction'],
                'last300_foot_support_share':a['motion']['steady_foot_support_share_mean'],
                'last300_all_terrain_reaction_n':a['all_terrain_reaction_range_n'],
                'last300_foot_ranges_n':a['steady_ranges_n'],
                'all_grounded_force_window':a['force_window_within_owner_tolerance'],
                'f31_verified':a['momentum_ledger_verified'], 'contacts':c}
            # Everytick support channel remains raw, not merely a summary.
            (folder/'supports-600.jsonl').write_text(''.join(json.dumps({
                'tick':r['tick'],'previous_grounded_feet':r['previous_grounded_feet'],
                'feet':r['feet'],'other_bodies':r['other_bodies']})+'\n' for r in rows))
        except (OSError,ValueError,KeyError,TypeError) as e:
            result['cases'][pose]={'status':'NOT COMPLETED','finding':str(e)}
    if all(c['status']=='OBSERVED' for c in result['cases'].values()):
        a,b=[result['cases'][p]['contacts'] for p in ('before','after')]
        dx0,dx1=[c['steady_mean_com_dx_wu_tick'] for c in (a,b)]
        result['F41']={'before_dx_wu_tick':dx0,'after_dx_wu_tick':dx1,
                       'absolute_drift_smaller':abs(dx1)<abs(dx0),
                       'difference_wu_tick':dx1-dx0,
                       'grounded_sets_changed':a['steady_grounded_sets']!=b['steady_grounded_sets'],
                       'suspicious_identical_drift_different_support':a['steady_grounded_sets']!=b['steady_grounded_sets'] and abs(dx1-dx0)<=1e-16}
    return result


if __name__=='__main__':
    report=compare(sys.argv[1])
    Path(sys.argv[1],'pose-comparison.json').write_text(json.dumps(report,indent=2)+'\n')
    for pose,case in report['cases'].items():
        brief={k:v for k,v in case.items() if k!='contacts'}
        if 'contacts' in case:
            c=case['contacts'];brief['grounded_sets']=c['steady_grounded_sets']
            brief['active_per_part_pass']={p:{v:s['active_count_histogram'] for v,s in stat['per_pass'].items()} for p,stat in c['parts'].items()}
            brief['com_vx_range']=c['steady_completed_com_vx_range_wu_s']
        print('M1 pose '+pose+': '+json.dumps(brief,sort_keys=True))
    print('M1 pose F41: '+json.dumps(report.get('F41',{'status':'INCOMPLETE'}),sort_keys=True))
    raise SystemExit(0 if 'F41' in report and not report['F41']['suspicious_identical_drift_different_support'] else 1)
