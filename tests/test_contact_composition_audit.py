#!/usr/bin/env python3
"""Archived evidence/audit regressions: no engine execution or new physics ticks."""
import copy
import json
import math
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
import report_contact_composition as report


class CompositionAudit(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.spawn, cls.rows, cls.summary = report.load_evidence()

    def test_real_sealed_failure_is_not_adoption(self):
        result = report.audit(self.spawn, self.rows, self.summary)
        self.assertEqual(result['sleeping_ticks'], 0)
        self.assertEqual(result['first_angle_violation_tick'], 8)
        self.assertGreater(result['max_attitude_deg'], 15)
        self.assertIn('REJECTED', result['verdict'])
        self.assertIn('NOT RUN', result['AC202_7200'])

    def test_truncated_horizon_is_not_complete(self):
        with self.assertRaisesRegex(ValueError, 'Incomplete600'):
            report.audit(self.spawn, self.rows[:-1], self.summary)

    def test_wrong_tick_input_rejected(self):
        rows = copy.deepcopy(self.rows)
        rows[599]['input_mask'] = 1
        with self.assertRaisesRegex(ValueError, 'Tick/input gap'):
            report.audit(self.spawn, rows, self.summary)

    def test_nonfinite_in_head_not_just_foot_rejected(self):
        rows = copy.deepcopy(self.rows)
        rows[599]['state']['physical']['bodies'][0]['b']['velocity_x'] = math.nan
        with self.assertRaisesRegex(ValueError, 'Nonfinite'):
            report.audit(self.spawn, rows, self.summary)

    def test_claimed_pass_rejected(self):
        summary = copy.deepcopy(self.summary)
        summary['status'] = 'CANDIDATE METRICS SATISFIED; NOT ADOPTED'
        with self.assertRaisesRegex(ValueError, 'laundered'):
            report.audit(self.spawn, self.rows, summary)

    def test_unexecuted_7200_arm_cannot_be_credited(self):
        summary = copy.deepcopy(self.summary)
        summary['arms']['length-Slug'] = {'ticks': 7200}
        with self.assertRaisesRegex(ValueError, 'Unexecuted arms'):
            report.audit(self.spawn, self.rows, summary)

    def test_fabricated_sleep_in_summary_rejected(self):
        summary = copy.deepcopy(self.summary)
        summary['arms']['idle-Slug']['first_sleep_tick'] = 0
        with self.assertRaisesRegex(ValueError, 'Sleep claim'):
            report.audit(self.spawn, self.rows, summary)

    def test_fabricated_native_length_rejected(self):
        summary = copy.deepcopy(self.summary)
        summary['arms']['idle-Slug']['max_length_wu'] = 0
        with self.assertRaisesRegex(ValueError, 'Reported length differs'):
            report.audit(self.spawn, self.rows, summary)

    def test_fabricated_native_penetration_rejected(self):
        summary = copy.deepcopy(self.summary)
        summary['arms']['idle-Slug']['max_penetration_wu'] = 0
        with self.assertRaisesRegex(ValueError, 'Reported penetration differs'):
            report.audit(self.spawn, self.rows, summary)

    def test_edited_engine_provenance_rejected(self):
        source = json.loads((report.FOLDER / 'source.json').read_text())
        source['engine_build'] = 'other'
        with self.assertRaisesRegex(ValueError, 'Wrong engine'):
            report.verify_source(source)

    def test_edited_compressed_evidence_rejected_before_decode(self):
        with tempfile.TemporaryDirectory() as d:
            folder = Path(d)
            (folder / 'source.json').write_bytes((report.FOLDER / 'source.json').read_bytes())
            (folder / 'idle-Slug.jsonl.gz').write_bytes(b'edited')
            with self.assertRaisesRegex(ValueError, 'Compressed evidence differs'):
                report.load_evidence(folder)

    def test_historical_code_mismatch_fails_closed_without_git(self):
        source = json.loads((report.FOLDER / 'source.json').read_text())
        name = 'tests/physics_fix/rigid_contact_candidate.gd'
        source['candidate_sha256'][name] = '0' * 64
        # Simulate a ZIP with an unavailable historical source, not real code edits.
        original = Path.exists
        with patch.object(Path, 'exists', lambda p: False if p == report.ROOT / '.git' else original(p)):
            with self.assertRaisesRegex(ValueError, 'Historical candidate unavailable'):
                report.verify_source(source)


if __name__ == '__main__':
    unittest.main(verbosity=2)
