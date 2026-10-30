#!/usr/bin/env python3
"""Synthetic observer controls ONLY, never creature/physics acceptance evidence."""
import json
from pathlib import Path
import tempfile
import unittest
from test_load_trace import fixture
from load_contact_report import inspect


def contact_fixture():
    rows = fixture()
    for row in rows:
        tick = row['tick']
        row.update(diagnostic_spawn_y_wu=.33, diagnostic_static_slip_wu_s=.15,
                   observer_on_off_physical_state_equal=True, grounded_parts=[2],
                   previous_grounded_parts=[] if tick==0 else [2],
                   new_grounded_parts=[2] if tick==0 else [], lifted_parts=[], contact_samples=[])
        head = row['other_bodies'][0]
        for key in ('ay','by','start_ay','start_by'):
            head[key] = .33
        head['bottom_wu'] = head['bottom_start_wu'] = .33-head['radius_wu']
        bodies = {b['part']: b for b in row['feet']+row['other_bodies']}
        for p,b in bodies.items():
            b['grounded_previous'] = p==2 and tick>0
        for v in range(2):
            for p in range(3):
                for i in range(2):
                    impulse = 43.4/60 if (v,p,i)==(0,2,0) else 0.0
                    row['contact_samples'].append({
                        'part':p,'velocity_pass':v,'sample_index':i,'intervals':1,'u':float(i),
                        'inverse_mass_a':bodies[p]['inverse_mass_a'],'inverse_mass_b':bodies[p]['inverse_mass_b'],'positional_cleanup_n':0.0,
                        'distance_wu':bodies[p]['radius_wu']-.02 if p==2 else .2,
                        'nx':0.0,'ny':1.0,'active':p==2,'static_branch':p==2,
                        'avx_before':0.0,'avy_before':-impulse*bodies[p]['inverse_mass_a'],
                        'bvx_before':0.0,'bvy_before':0.0,
                        'avx_after':0.0,'avy_after':0.0,'bvx_after':0.0,'bvy_after':0.0,
                        'tangent_before':0.0,'tangent_after':0.0,'retained':0.0 if p==2 else None,
                        'normal_impulse_ns':impulse,'tangential_impulse_ns':0.0})
    return rows


class ContactObserverTests(unittest.TestCase):
    def test_complete_samples_impulses_and_grounding_are_independently_checked(self):
        report, profile, events = inspect(contact_fixture())
        self.assertEqual(report['sample_events'], 7200)
        self.assertEqual(len(profile),600)
        self.assertEqual(report['steady_ticks_with_any_active_sample'],300)
        self.assertEqual(report['steady_new_grounded_transition_count'],0)
        self.assertEqual(report['sleep_breaking_interpretation'].split(';')[0],'NOT ADOPTED')

    def test_missing_candidate_rejected(self):
        rows=contact_fixture();rows[350]['contact_samples'].pop()
        with self.assertRaises(ValueError):inspect(rows)

    def test_tangent_claim_recomputed_from_endpoints(self):
        rows=contact_fixture();rows[350]['contact_samples'][4]['tangent_after']=.1
        with self.assertRaises(ValueError):inspect(rows)

    def test_retained_zero_requires_real_endpoint_response(self):
        rows=contact_fixture();rows[350]['contact_samples'][4]['avx_after']=.1
        with self.assertRaises(ValueError):inspect(rows)

    def test_wrong_static_branch_rejected(self):
        rows=contact_fixture();rows[350]['contact_samples'][4]['static_branch']=False
        with self.assertRaises(ValueError):inspect(rows)

    def test_signed_impulse_not_just_claimed_force(self):
        rows=contact_fixture();rows[350]['contact_samples'][4]['normal_impulse_ns']+=.1
        with self.assertRaises(ValueError):inspect(rows)

    def test_grounded_transition_not_inferred_from_impulse(self):
        rows=contact_fixture();rows[350]['new_grounded_parts']=[2]
        with self.assertRaises(ValueError):inspect(rows)

    def test_observer_read_only_comparison_required(self):
        rows=contact_fixture();rows[350]['observer_on_off_physical_state_equal']=False
        with self.assertRaises(ValueError):inspect(rows)

    def test_later_overlapping_sample_can_reopen_a_previously_zeroed_sample(self):
        rows=contact_fixture()
        for row in rows:
            head=row['other_bodies'][0];head['grounded']=True
            head.update(avx=.01,speed_a_wu_s=.01,com_speed_wu_s=.005,
                        grounded_previous=row['tick']>0)
            row['grounded_parts']=[0,2]
            row['previous_grounded_parts']=[] if row['tick']==0 else [0,2]
            row['new_grounded_parts']=[0,2] if row['tick']==0 else []
            events=[]
            for v in range(2):
                a,b=.04,-.02
                for i,u in enumerate((0.0,.5,1.0)):
                    before_a,before_b=a,b
                    t=-((1-u)*a+u*b)
                    j=-t/(((1-u)**2+u*u)*head['inverse_mass_a'])
                    a-=head['inverse_mass_a']*(1-u)*j
                    b-=head['inverse_mass_b']*u*j
                    events.append({'part':0,'velocity_pass':v,'sample_index':i,'intervals':2,'u':u,
                                   'inverse_mass_a':head['inverse_mass_a'],'inverse_mass_b':head['inverse_mass_b'],'positional_cleanup_n':0.0,
                                   'distance_wu':head['radius_wu']-.02,
                                   'nx':0.0,'ny':1.0,'active':True,'static_branch':True,
                                   'avx_before':before_a,'bvx_before':before_b,'avy_before':0.0,'bvy_before':0.0,
                                   'avx_after':a,'bvx_after':b,'avy_after':0.0,'bvy_after':0.0,
                                   'tangent_before':t,'tangent_after':-((1-u)*a+u*b),'retained':0.0,
                                   'normal_impulse_ns':0.0,'tangential_impulse_ns':j})
            row['contact_samples']=[e for e in row['contact_samples'] if e['part']!=0]+events
        report,_,_=inspect(rows)
        self.assertEqual(report['parts'][0]['active_counts'],[3])
        self.assertGreater(report['parts'][0]['earlier_static_sample_changed_by_later_samples_count'],0)

    def test_sample_geometry_not_just_claimed_active_flag(self):
        rows=contact_fixture();rows[350]['contact_samples'][4]['distance_wu']=.2
        with self.assertRaises(ValueError):inspect(rows)

    def test_positional_cleanup_is_recomputed_and_never_an_impulse(self):
        rows=contact_fixture();rows[350]['contact_samples'][4]['positional_cleanup_n']=1.0
        with self.assertRaises(ValueError):inspect(rows)

    def test_slip_sweep_observes_both_without_adoption(self):
        from load_slip_report import summarize, VALUES
        with tempfile.TemporaryDirectory() as folder:
            for value in VALUES:
                root=Path(folder)/f'slip-{value}';root.mkdir()
                rows=contact_fixture()
                for row in rows:row['diagnostic_static_slip_wu_s']=float(value)
                (root/'engine-status.txt').write_text('0')
                (root/'slug-600.jsonl').write_text(''.join(json.dumps(r)+'\n' for r in rows))
            report=summarize(folder)
        self.assertTrue(all(c['status']=='OBSERVED' for c in report['cases']))
        self.assertEqual([c['configured_resource_value'] for c in report['cases']],[True,False])
        self.assertFalse(report['comparison']['adopted_new_threshold'])
        self.assertEqual(report['FA-3'],'NOT RUN')

    def test_missing_sweep_does_not_mean_zero_residual(self):
        from load_slip_report import summarize
        with tempfile.TemporaryDirectory() as folder:report=summarize(folder)
        self.assertEqual(report['comparison']['status'],'INCOMPLETE')
        self.assertTrue(all('contact_report' not in c for c in report['cases']))


if __name__=='__main__':
    unittest.main(verbosity=2)
