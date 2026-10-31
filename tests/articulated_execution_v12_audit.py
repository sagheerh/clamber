"""Read-only closure of V12's short failed capture. Never a full-arm PASS."""
import base64
import gzip
import hashlib
import json
import math
from pathlib import Path
import re
from godot_capture_variant import decode

ROOT = Path(__file__).resolve().parents[1]
SOURCE = 'a45a2b50eb67bd0f6ca0ee4940553965bdfddafb'
FIXTURE = ROOT / 'tests/fixtures/m1_articulated_execution' / SOURCE[:12]


def require(condition, message):
    if not condition:
        raise ValueError(message)


def finite(value):
    if isinstance(value, float):
        return math.isfinite(value)
    if isinstance(value, dict):
        return all(finite(v) for v in value.values())
    if isinstance(value, list):
        return all(finite(v) for v in value)
    return True


def audit_rows(rows):
    require(len(rows) == 37, 'only37 committed ticks, never600')
    for tick, row in enumerate(rows):
        require(row['tick'] == tick and finite(row), 'contiguous finite actual ticks')
        require(row['input_mask'] == 0, 'idle input')
        trace = row['awake_solver_trace']
        require(trace['status'] == 0, 'committed solver status')
        require(trace['stage_order'] == ['forces', 'velocity_pass_0', 'integration'] +
                ['position_sweep_' + str(i) for i in range(6)] + ['velocity_pass_1'], 'original phases')
        require(row['state']['physical']['ticks'] == tick + 1, 'actual physical clock')
        require(len(row['state']['physical']['bodies']) == 3, 'all bodies')
    return {
        'committed_ticks': len(rows),
        'max_attitude_deg': max(r['attitude_deg'] for r in rows),
        'airborne_ticks': sum(not any(b['grounded'] for b in r['state']['physical']['bodies']) for r in rows),
        'sleep_ticks': sum(r['state']['sleep']['asleep'] for r in rows),
        'max_still_ticks': max(r['state']['sleep']['still_ticks'] for r in rows),
        'max_length_wu': max(r['length_peak_wu'] for r in rows),
        'max_penetration_wu': max(r['penetration_peak_wu'] for r in rows),
        'full600_pass': False,
    }


def audit(folder=FIXTURE):
    source = json.loads((folder / 'source.json').read_text())
    require(source['source_commit'] == source['checkout_head'] == SOURCE and not source['checkout_dirty'], 'exact source')
    require(source['engine_build'] == '4.7.2.stable.official.ed1daf0bf', 'exact engine')
    transport = json.loads((folder / 'transport-index.json').read_text())
    require(transport['source_commit'] == SOURCE, 'transport source')
    record = transport['raw_traces']['idle-Slug.jsonl']
    packed = (folder / 'idle-Slug.jsonl.gz').read_bytes()
    raw = gzip.decompress(packed)
    for data, prefix in [(packed, 'gzip'), (raw, 'raw')]:
        require(len(data) == record[prefix + '_bytes'] and hashlib.sha256(data).hexdigest() == record[prefix + '_sha256'], 'transport ' + prefix)
    rows = [json.loads(line) for line in raw.splitlines()]
    result = audit_rows(rows)
    total = 0
    for p in folder.glob('*.log'):
        total += sum(int(n) for n in re.findall(r': (\d+) checks, 0 failures', p.read_text()))
    require(total == 172, 'native172 in execution job before world')
    annotations = json.loads((ROOT / '.review/physics_fix/articulated_execution_v12_primitives_annotations.json').read_text())
    messages = [a['message'] for a in annotations]
    require('M1 articulated mobility units: 42 checks, 0 failures' in messages, 'upstream native42')
    pins = [json.loads(m) for m in messages if m.startswith('{')]
    require(any(p.get('source_commit') == SOURCE and p.get('checkout_head') == SOURCE and not p.get('checkout_dirty', True) for p in pins), 'upstream exact source')
    total += 42
    failure = json.loads((folder / 'idle-Slug-failure.json').read_text())
    require(failure['tick'] == 37 and failure['status'] == 30 and failure['nonfinite'] == [], 'finite first failure')
    full = decode(base64.b64decode(failure['full_state_variant_base64']))
    require(full['candidate']['bodies'] == rows[-1]['state']['physical']['bodies'], 'atomic rollback to committed bodies')
    summary = json.loads((folder / 'summary.json').read_text())
    arm = summary['arms']['idle-Slug']
    require(arm['ticks'] == 37 and arm['failing_tick'] == 37 and arm['solver_status'] == 30, 'failed arm not full600')
    require(summary['not_run_arms'] == ['length-Slug', 'length-Hopper', 'length-TwinRoller'], 'all7200 blocked')
    result.update(source_commit=SOURCE, source_ci_run=source['source_ci_run'], native_checks=total,
                  failing_tick=37, solver_status=30, scope='CLOSED FAILED PREFIX; NOT ACCEPTANCE; NO WORLD REPLAY',
                  raw_sha256=record['raw_sha256'], gzip_sha256=record['gzip_sha256'])
    return result


if __name__ == '__main__':
    print(json.dumps(audit(), indent=2, sort_keys=True))
