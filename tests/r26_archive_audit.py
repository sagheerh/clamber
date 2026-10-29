#!/usr/bin/env python3
"""R26 archived interpretation ONLY. NEVER imports/runs Godot or advances a solver."""
import hashlib
import json
import sys
from pathlib import Path
from r26_report import d2, fa5

HEAD = '114265e0116101a897d8429a2998f4987549f86f'
RUN = 40901902007


def unique(root, suffix):
    found = list(root.glob('**/'+suffix))
    assert len(found) == 1, (suffix, found)
    return found[0]


def sha(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        while b := f.read(1 << 20):
            h.update(b)
    return h.hexdigest()


def compact_fa5(report):
    out = {k: v for k, v in report.items() if k != 'cases'}
    out['cases'] = {name: {
        **{k: v for k, v in case.items() if k not in ('termination', 'events')},
        'termination': {k: v for k, v in case['termination'].items() if k not in ('initial_bodies', 'failed_pre_step_bodies')},
        'events': {branch: {k: v for k, v in event.items() if k != 'events'} for branch, event in case['events'].items()}}
        for name, case in report['cases'].items()}
    return out


def audit(root, out):
    out.mkdir(parents=True, exist_ok=True)
    result = dict(source_head=HEAD, source_run=RUN, new_physics_runs=0, raw_provenance={})
    for mode in ('d1', 'd2', 'fa5'):
        folder = unique(root, f'r26-{mode}/engine.json').parent
        source = json.loads((folder/'source.json').read_text())
        assert source['source_head'] == HEAD and int(source['source_ci_run']) == RUN
        assert source['tuning_sha256'] == sha(Path('core/tuning.tres'))
        for filename, expected in source['raw_traces_sha256'].items():
            assert sha(folder/filename) == expected, (mode, filename)
        result['raw_provenance'][mode] = source
        if mode == 'd1':
            result['D1'] = json.loads((folder/'report.json').read_text())
            assert result['D1']['verification_passed'] and result['D1']['measurement_complete']
        else:
            engine = json.loads((folder/'engine.json').read_text())
            result[mode.upper() if mode == 'd2' else 'FA5'] = (d2 if mode == 'd2' else fa5)(folder, engine)
    actual = unique(root, 'r26-baseline/public_sim_baseline.json')
    result['generated_baseline_byte_equal_committed'] = actual.read_bytes() == Path('tests/fixtures/public_sim_baseline.json').read_bytes()
    assert result['generated_baseline_byte_equal_committed']
    result['generated_baseline_file_sha256'] = sha(actual)
    result['generated_baseline'] = json.loads(actual.read_text())
    result['original_generated_provenance'] = unique(root, 'r26-baseline/provenance.md').read_text()
    result['decision'] = 'Option2: D1 did not locate a correctness-shaped carrier. No further measurement; OWNER authors AC201 number, AC202 .05 unchanged and honestly reported.'
    (out/'audit.json').write_text(json.dumps(result, indent=2)+'\n')
    for field in result:
        value = compact_fa5(result[field]) if field == 'FA5' else result[field]
        text = 'M1 R26 archive: '+json.dumps(dict(field=field, value=value), separators=(',', ':'))+'\n'
        (out/f'console-{field}.log').write_text(text)
        print(field, len(text), flush=True)
    return result


if __name__ == '__main__': audit(Path(sys.argv[1]), Path(sys.argv[2]))
