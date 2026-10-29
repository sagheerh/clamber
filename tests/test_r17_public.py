#!/usr/bin/env python3
import contextlib
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import public_sim_report as public

class PublicRuntimeControls(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        self.root=Path(self.temp.name)
        self.report={'failures':0,'attempt_started':True,'determinism_attempt':1,
            'replay_streams_byte_equal':True,'falsification':{'baseline_digest':'a','changed_digest':'b','physical_bodies_differ_at_flip':True},
            'per_tick_digests':['a']*600,'replay_final_digests':['a']*3,'runtime_gates':{},'fixture':{'name':'control'},'tuning_sha256':'t'}
        for i in range(3):(self.root/f'replay-{i}.bin').write_bytes(b'independent raw control')
        for hz in (30,144):
            (self.root/f'delivery-{hz}.bin').write_bytes(b'frame control')
            (self.root/f'delivery-{hz}.json').write_text(json.dumps({'condition':hz,'failures':0,'tick_hashes':['a']*600,'tick_hz':60,'frame_seconds':[1/hz]}))
    def run_report(self):
        (self.root/'public-sim-report.json').write_text(json.dumps(self.report))
        with patch.object(public,'BASELINE',self.root/'missing-baseline.json'),contextlib.redirect_stdout(io.StringIO()):
            public.summarize(self.root)
    def test_missing_baseline_is_red_not_bootstrap_pass(self):
        with self.assertRaisesRegex(ValueError,'Baseline absent'):self.run_report()
        self.assertTrue((self.root/'baseline-candidate.json').exists())
    def test_equal_flip_hash_is_red(self):
        self.report['falsification']['changed_digest']='a'
        with self.assertRaisesRegex(ValueError,'Falsification'):self.run_report()
    def test_metadata_only_flip_is_red(self):
        self.report['falsification']['physical_bodies_differ_at_flip']=False
        with self.assertRaisesRegex(ValueError,'Falsification'):self.run_report()
    def test_full_bytes_disagree_even_when_booleans_claim_equal(self):
        (self.root/'replay-2.bin').write_bytes(b'changed')
        with self.assertRaisesRegex(ValueError,'streams DIFFER'):self.run_report()
    def test_frame_label_without_actual_delivery_rejected(self):
        p=self.root/'delivery-30.json';r=json.loads(p.read_text());r['frame_seconds']=[1/60];p.write_text(json.dumps(r))
        with self.assertRaisesRegex(ValueError,'fixed-fps'):self.run_report()
    def test_frame_stream_disagreement_rejected(self):
        (self.root/'delivery-144.bin').write_bytes(b'wrong frame stream')
        with self.assertRaisesRegex(ValueError,'frame-delivered'):self.run_report()
    def test_attempt_not_executed_is_not_evidence(self):
        self.report['attempt_started']=False
        with self.assertRaisesRegex(ValueError,'did not execute'):self.run_report()
    def test_short_hash_table_rejected(self):
        self.report['per_tick_digests'].pop()
        with self.assertRaisesRegex(ValueError,'Missing tick stream'):self.run_report()

if __name__=='__main__':unittest.main(verbosity=2)
