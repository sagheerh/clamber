#!/usr/bin/env python3
"""Static/forgery controls, NEVER physical measurement or acceptance credit."""
import copy
import hashlib
import json
import unittest
from pathlib import Path
from r26_report import Events, complete, completed_flags, length_errors, retention, terrain_sample


class R26Controls(unittest.TestCase):
    def test_brace_removed_from_runtime(self):
        for p in Path('core').rglob('*.gd'):
            self.assertNotIn('brace', p.read_text().lower(), p)
        self.assertFalse(Path('tests/sim/test_r25_brace.gd').exists())
        self.assertNotIn('r25-brace:', Path('.github/workflows/m1.yml').read_text())

    def test_pb_resource_bytes_unchanged(self):
        self.assertEqual(hashlib.sha256(Path('core/tuning.tres').read_bytes()).hexdigest(),
                         '5f4d0d06564fb3a0847309d83cf5f3c87b9321ea5e2dd87e572e4bd9fe750666')

    def test_diagnostic_and_observation_default_off(self):
        s = Path('core/sim/coupled_load_probe.gd').read_text()
        self.assertIn('collect_length_phases: bool = false', s)
        self.assertIn('diagnostic_final_distance_pass: bool = false', s)
        added = s.split('if diagnostic_final_distance_pass:', 1)[1].split('return OK', 1)[0]
        self.assertIn('for link in _links:', added)
        self.assertIn('link.project(_tuning)', added)
        self.assertNotIn('reset_multiplier', added)
        self.assertNotIn('velocity', added)
        self.assertNotIn('repetition', added)

    def test_phase_error_forgery_and_missing_row_rejected(self):
        parts = [dict(part=i, kind='limb' if i in (3, 6) else 'motor',
                      a=[0., 0.], b=[1., 0.], rest_length=1., error_wu=0.) for i in range(8)]
        length_errors(parts)
        bad = copy.deepcopy(parts); bad[3]['error_wu'] = .1
        with self.assertRaises(ValueError): length_errors(bad)
        with self.assertRaises(ValueError): length_errors(parts[:-1])

    def test_events_collapse_samples_and_passes_not_episodes(self):
        e = Events()
        e.add_tick(0, {('at_or_above', '5'), ('at_or_above', '7')})
        e.add_tick(1, {('at_or_above', '5'), ('at_or_above', '7')})
        e.add_tick(2, set())
        e.add_tick(3, {('at_or_above', '5')})
        r = e.report()['at_or_above']
        self.assertEqual(r['independent_events'], 3)
        self.assertEqual(r['event_durations_ticks'], [2, 2, 1])
        self.assertEqual(e.report()['below']['independent_true_grip_events'], 0)

    def test_flat_and_ledge_sdf_independent(self):
        self.assertEqual(terrain_sample(-1., 1., False), (1., 0., 1.))
        self.assertEqual(terrain_sample(1., 1., True), (1., 0., 1.))
        self.assertEqual(terrain_sample(-2., -2., True), (.5, 0., 1.))
        with self.assertRaises(ValueError): terrain_sample(-12.1, 0., False)

    def test_actual_operator_clamp_and_forgery(self):
        for mu in (.3, .9, 1.8, 3.6):
            e = dict(material_friction=mu, sample_friction=mu, may_grip=False,
                     active=True, tangent_before=1., tangent_after=1-min(1., mu),
                     retained=1-min(1., mu), static_branch=False)
            retention(e, mu, may_grip=False)
            bad = dict(e, retained=e['retained']+.01)
            with self.assertRaises(ValueError): retention(bad, mu)
            with self.assertRaises(ValueError): retention(e, mu, may_grip=True)
            e.update(tangent_before=.01, tangent_after=0., retained=0., static_branch=True)
            self.assertEqual(retention(e, mu), 'static_override')

    def test_completion_cannot_mask_step_failure(self):
        good = dict(target_ticks=12, ticks=12, termination_reason='completed',
                    failing_tick=None, status=0, observer_status=0)
        self.assertTrue(complete(good, 12))
        for key, value in [('status', 1), ('observer_status', 1), ('ticks', 11),
                           ('termination_reason', 'step_failure'), ('failing_tick', 11)]:
            self.assertFalse(complete(dict(good, **{key: value}), 12))

    def test_airborne_cases_explicit_before_outcomes(self):
        p = json.loads(Path('tests/fixtures/r26_fa5.json').read_text())
        self.assertEqual([s['id'] for s in p['cases']],
                         ['stance', 'drop_onto_feet', 'ledge_departure', 'midair_sample'])
        self.assertEqual([s['lift'] for s in p['cases']], [0., 2., 0., 4.])
        self.assertTrue(p['no_outcome_retuning'])

    def test_nonfoot_schema_not_misread_as_missing_foot_flag(self):
        completed_flags({'grounded': True}, True, False, False)
        completed_flags({'grounded': False}, False, False, False)
        with self.assertRaises(ValueError):
            completed_flags({'grounded': True, 'gripping': False}, True, True, True)
        with self.assertRaises(ValueError):
            completed_flags({'grounded': False}, True, False, False)

    def test_jobs_independent_and_push_once_only(self):
        s = Path('.github/workflows/m1.yml').read_text().split('  r26-diagnostics:', 1)[1].split('  r26-baseline:', 1)[0]
        self.assertNotIn('needs:', s)
        self.assertIn('mode: [d1, d2, fa5]', s)
        self.assertIn('fail-fast: false', s)
        self.assertIn("github.event_name == 'push'", s)
        self.assertIn('[R26-once]', s)


if __name__ == '__main__': unittest.main(verbosity=2)
