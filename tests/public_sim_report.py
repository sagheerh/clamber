#!/usr/bin/env python3
"""Independent byte-stream/baseline checks; missing/mismatching baseline is RED."""
import hashlib
import json
from pathlib import Path
import sys

ROOT=Path(__file__).resolve().parents[1]
BASELINE=ROOT/'tests/fixtures/public_sim_baseline.json'


def summarize(folder):
    report=json.loads((folder/'public-sim-report.json').read_text())
    if report['failures'] or not report['attempt_started'] or report['determinism_attempt']!=1:
        raise ValueError('Complete-creature attempt did not execute successfully; inspect raw report')
    streams=[(folder/f'replay-{i}.bin').read_bytes() for i in range(3)]
    if not streams[0] or not all(s==streams[0] for s in streams) or not report['replay_streams_byte_equal']:
        raise ValueError('Full complete-creature tick streams DIFFER')
    if report['falsification']['baseline_digest']==report['falsification']['changed_digest'] or not report['falsification']['physical_bodies_differ_at_flip']:
        raise ValueError('Falsification equal hash or metadata-only input change')
    if len(report['per_tick_digests'])!=600 or len(set(report['replay_final_digests']))!=1:
        raise ValueError('Missing tick stream/hash evidence')
    # Generate and expose provenance immediately after independently verified replay,
    # even when the SEPARATE delivery protocol/baseline gate is still RED.
    expected={'fixture':report['fixture'],'tuning_sha256':report['tuning_sha256'],
              'final_digest':report['replay_final_digests'][0],
              'full_stream_sha256':hashlib.sha256(streams[0]).hexdigest(),
              'per_tick_digest_table_sha256':hashlib.sha256(json.dumps(report['per_tick_digests'],separators=(',',':')).encode()).hexdigest()}
    (folder/'baseline-candidate.json').write_text(json.dumps(expected,indent=2)+'\n')
    print('M1 public baseline candidate: '+json.dumps(expected,separators=(',',':')))
    delivery=[json.loads((folder/f'delivery-{hz}.json').read_text()) for hz in (30,144)]
    dstreams=[(folder/f'delivery-{hz}-compared.bin').read_bytes() for hz in (30,144)]
    if not dstreams[0] or dstreams[0]!=dstreams[1]:
        raise ValueError('Actual30/144 frame-delivered tick streams differ')
    from collections import Counter
    for r in delivery:
        print('M1 public frame-duration support: '+json.dumps({'condition':r['condition'],'histogram':dict(Counter(r['frame_seconds']))},separators=(',',':')))
        if r['failures'] or len(r['compared_tick_hashes'])!=600 or r['compared_ticks']!=600 or len(r['tick_hashes'])!=r['actual_ticks'] or r['actual_ticks']<600 or r['tick_hz']!=60:
            raise ValueError('Frame-condition harness incomplete')
        # Actual engine callbacks must match requested fixed-fps, not a label only.
        if len(r['frame_seconds'])<2 or any(not t>0 for t in r['frame_seconds']) or round(1/Counter(r['frame_seconds']).most_common(1)[0][0]) != r['condition']:
            raise ValueError('Engine did not support requested fixed-fps delivery exactly')
    result={k:v for k,v in report.items() if k!='per_tick_digests'}
    result['full_stream_sha256']=hashlib.sha256(streams[0]).hexdigest()
    result['per_tick_digest_table_sha256']=hashlib.sha256(json.dumps(report['per_tick_digests'],separators=(',',':')).encode()).hexdigest()
    result['delivery']=[{k:v for k,v in r.items() if k not in ('tick_hashes','compared_tick_hashes','frame_seconds')}|{'min_frame_seconds':min(r['frame_seconds']),'max_frame_seconds':max(r['frame_seconds']),'startup_frame_seconds':r['frame_seconds'][0],'modal_frame_seconds':Counter(r['frame_seconds']).most_common(1)[0][0]} for r in delivery]
    result['delivery_stream_sha256']=hashlib.sha256(dstreams[0]).hexdigest()
    result['runtime_gates']['11']='MEASURED real --fixed-fps30/144 callbacks;600 same ticks, streams byte-identical, physics60'
    expected={'fixture':report['fixture'],'tuning_sha256':report['tuning_sha256'],
              'final_digest':report['replay_final_digests'][0],
              'full_stream_sha256':result['full_stream_sha256'],
              'per_tick_digest_table_sha256':result['per_tick_digest_table_sha256']}
    (folder/'baseline-candidate.json').write_text(json.dumps(expected,indent=2)+'\n')
    error=None
    if not BASELINE.exists():
        error='Baseline absent: row13 NOT RUN; candidate generated from actual engine, must commit and rerun'
    else:
        baseline=json.loads(BASELINE.read_text())
        if any(baseline.get(k)!=v for k,v in expected.items()):
            error='Committed baseline mismatch: FAIL, no tolerance/automatic update'
        decision=baseline.get('decision_id','')
        decisions=(ROOT/'DECISIONS.md').read_text()
        if not decision or f'## {decision}' not in decisions or expected['full_stream_sha256'] not in decisions or expected['final_digest'] not in decisions:
            error='Baseline must link a DECISIONS entry containing its exact generated hashes'
        if not error:
            result['runtime_gates']['13']='MEASURED committed real baseline matched, linked DECISIONS provenance'
    result['baseline_status']=error or 'MATCHED committed generated baseline'
    (folder/'public-sim-summary.json').write_text(json.dumps(result,indent=2)+'\n')
    print('M1 public summary: '+json.dumps(result,separators=(',',':')))
    if error: raise ValueError(error)
    return result

if __name__=='__main__':summarize(Path(sys.argv[1]))
