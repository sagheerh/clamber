#!/usr/bin/env python3
"""Generate, never invent, an adoption-source baseline from independently checked raw streams."""
import datetime, hashlib, json, os, subprocess, sys
from pathlib import Path


def generate(folder, out):
    r=json.loads((folder/'public-sim-summary.json').read_text())
    assert r['baseline_status']=='Committed baseline mismatch: FAIL, no tolerance/automatic update'
    assert r['failures']==0 and r['replay_streams_byte_equal'] and all(d['failures']==0 for d in r['delivery'])
    raw=json.loads((folder/'public-sim-report.json').read_text())
    inputs=raw['actual_input_log'];assert len(inputs)==600
    streams=[(folder/f'replay-{i}.bin').read_bytes() for i in range(3)]
    assert streams[0] and streams[0]==streams[1]==streams[2]
    b=json.loads((folder/'baseline-candidate.json').read_text())
    assert b['full_stream_sha256']==hashlib.sha256(streams[0]).hexdigest()
    assert b['final_digest']==r['replay_final_digests'][0]
    source=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip()
    assert source==os.environ['R28_SOURCE_SHA']
    assert b['tuning_sha256']==hashlib.sha256(Path('core/tuning.tres').read_bytes()).hexdigest()
    assert b['full_stream_sha256']!=json.loads(Path('tests/fixtures/public_sim_baseline.json').read_text())['full_stream_sha256']
    b.update(decision_id='M1-R28-BASELINE',engine_version=r['engine'],source_commit_sha=source,
             seed=r['fixture']['seed'],tick_hz=60,ticks=r['fixture']['ticks'],
             input_log_digest=hashlib.sha256(bytes(inputs)).hexdigest(),final_state_hash=b['final_digest'],
             collected_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),source_ci_run=int(os.environ['GITHUB_RUN_ID']),
             method='Actual 600-tick public Sim x3 raw byte-equal streams; independent30/144 delivery protocol checked. Generated candidate, explicit source overlay, then separate public-sim-runtime replay on same commit. No manual hashes.')
    out.mkdir(parents=True,exist_ok=True)
    (out/'public_sim_baseline.json').write_text(json.dumps(b,indent=2)+'\n')
    (out/'provenance.md').write_text(f"\n\n## M1-R28-BASELINE — generated adoption replay provenance\n\nSource {source}, CI{os.environ['GITHUB_RUN_ID']}, engine {r['engine']}.\nFinal {b['final_digest']}; full stream {b['full_stream_sha256']}.\nInput log SHA256 {b['input_log_digest']}; tuning {b['tuning_sha256']}.\nGenerated from actual raw triple streams and delivery checks, no manual values.\nSame-source public-sim-runtime receives only this baseline/provenance overlay;\nsubsequently committed verbatim with no solver change.\n")
    print('M1 R28 baseline: '+json.dumps(b,separators=(',',':')))


if __name__=='__main__':generate(Path(sys.argv[1]),Path(sys.argv[2]))
