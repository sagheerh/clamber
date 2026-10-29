#!/usr/bin/env python3
"""Synthetic falsification of main-trace count validation; NOT physical evidence."""
from copy import deepcopy
import unittest
from test_contact_trace import contact_fixture
from load_legal_report import validate_counts, accepted_view, compare


def fixture():
    rows = contact_fixture()[:1]
    for r in rows:
        r['diagnostic_actuated'] = False
        r['contact_counts'] = []
        for v in range(2):
            for p in range(3):
                es = [e for e in r['contact_samples'] if e['part'] == p and e['velocity_pass'] == v]
                r['contact_counts'].append(dict(part=p, velocity_pass=v, intervals=es[0]['intervals'],
                    candidate_count=len(es), active_count=sum(e['active'] for e in es)))
    return rows


class R15Counts(unittest.TestCase):
    def test_counts_match_all_raw_candidates(self):
        self.assertEqual(len(validate_counts(fixture())[0]), 6)

    def test_missing_inactive_body_pass_rejected(self):
        r = fixture(); r[0]['contact_counts'].pop(0)
        with self.assertRaises(ValueError): validate_counts(r)

    def test_forged_interval_candidate_active_rejected_independently(self):
        for k in ('intervals', 'candidate_count', 'active_count'):
            with self.subTest(k=k):
                r = fixture(); r[0]['contact_counts'][0][k] += 1
                with self.assertRaises(ValueError): validate_counts(r)

    def test_duplicate_count_row_rejected(self):
        r = fixture(); r[0]['contact_counts'].append(deepcopy(r[0]['contact_counts'][0]))
        with self.assertRaises(ValueError): validate_counts(r)

    def test_missing_raw_event_not_accepted_as_smaller_regime(self):
        r = fixture(); r[0]['contact_samples'].pop()
        with self.assertRaises(ValueError): validate_counts(r)

    def test_count_types_required(self):
        r = fixture(); r[0]['contact_counts'][0]['active_count'] = False
        with self.assertRaises(ValueError): validate_counts(r)

    def test_lossless_phase_adapter_keeps_source_raw(self):
        r = fixture()
        for b in r[0]['feet'] + r[0]['other_bodies']:
            b['position_delta_wu']['angular'] = [0., 0., 0., 0.]
            b['position_delta_wu']['self_contact'] = [0., 0., 0., 0.]
        r[0]['diagnostic_actuated'] = True
        before = deepcopy(r)
        adapted = accepted_view(r)
        self.assertEqual(r, before)
        self.assertEqual(set(adapted[0]['feet'][0]['position_delta_wu']), {'integration', 'distance', 'hinge', 'contact'})
        r[0]['feet'][0]['position_delta_wu']['angular'][0] = .01
        with self.assertRaises(ValueError): accepted_view(r)

    def test_missing_legal_evidence_not_a_measured_comparison(self):
        import tempfile
        with tempfile.TemporaryDirectory() as root:
            result = compare(root)
        self.assertTrue(all(c['status'] == 'NOT COMPLETED' for c in result['cases'].values()))
        self.assertTrue(all('BLOCKED' in c['status'] for c in result['F41'].values()))


if __name__ == '__main__': unittest.main(verbosity=2)
