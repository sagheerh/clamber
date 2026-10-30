#!/usr/bin/env python3
"""Owner-attested, once-only ZIP entry point. Does not activate CI markers."""
import atexit
import json
import os
from pathlib import Path
import re
import subprocess
import sys
from source_provenance import verify

ROOT = Path(__file__).resolve().parents[1]
P = ROOT / 'tests/fixtures/m1_r29_execution'
ARMS = ['D1', 'D2', 'D3', 'D4', 'D5']
ERROR = re.compile(r'SCRIPT ERROR:|ERROR:|Parse Error:|Failed to load script')


def save(path, value):
    path.write_text(json.dumps(value, indent=2) + '\n')


def main():
    os.chdir(ROOT)
    if os.environ.get('CLAMBER_LOCAL') != '1':
        raise ValueError('CLAMBER_LOCAL=1 is required')
    if len(sys.argv) != 2 or sys.argv[1] not in ARMS:
        raise ValueError('Usage: bash tests/run_m1_r29.sh D1 (then D2 ... D5 once each)')
    manifest = verify()  # Before engine invocation or evidence writes.
    arm = sys.argv[1]
    P.mkdir(parents=True, exist_ok=True)
    # Exclusive creation prevents two terminals from launching the same arm.
    # A killed process leaves the lock for inspection, never automatic recovery.
    lock = P / '.local-run.lock'
    with lock.open('x') as stream:
        stream.write(str(os.getpid()) + '\n')
    atexit.register(lock.unlink)
    state_file = P / 'local-run.json'
    state = json.loads(state_file.read_text()) if state_file.exists() else dict(
        evidence_kind='owner-attested local evidence, NOT CI evidence',
        source_manifest=manifest, arms={}, stopped=False)
    if state['source_manifest'] != manifest:
        raise ValueError('Manifest changed during local run')
    if state['stopped'] or arm in state['arms']:
        raise ValueError('STOP: previous failure or attempted arm; do not retry/delete the ledger')
    if len(state['arms']) >= len(ARMS) or arm != ARMS[len(state['arms'])]:
        raise ValueError('Run D1 ... D5 exactly once, in order')
    godot = os.environ['GODOT']
    build = subprocess.check_output([godot, '--version'], text=True).strip()
    if build != '4.7.2.stable.official.ed1daf0bf':
        raise ValueError(f'Wrong engine build: {build}')
    (P / 'engine-build.txt').write_text(build + '\n')
    env = dict(os.environ, R29_SOURCE_SHA=manifest['source_commit'],
               R29_FOLDER=str(P.relative_to(ROOT)),
               R29_EVIDENCE=str((P / 'measurement-evidence.json').relative_to(ROOT)),
               R29_CAPTURES=str((P / 'captures').relative_to(ROOT)))
    env.pop('GITHUB_RUN_ID', None)  # Local evidence must never inherit a CI identity.
    if not (P / 'measurement-evidence.json').exists():
        historical = json.loads((ROOT / '.review/m1_r29_measurement_evidence.json').read_text())
        save(P / 'measurement-evidence.json', dict(
            evidence_kind=state['evidence_kind'], source_manifest=manifest,
            start_facts=historical['start_facts'],
            gates=[g for g in historical['gates'] if g['gate'].startswith('D0/')]))

    def run(args, log):
        with (P / log).open('w') as stream:
            code = subprocess.call(args, stdout=stream, stderr=subprocess.STDOUT, env=env)
        if code or ERROR.search((P / log).read_text()):
            raise RuntimeError(f'STOP: {log}, status {code}; retain all files, no retry')

    # Record attempted arm BEFORE import so a failure cannot silently be retried.
    state['arms'][arm] = dict(status='preflight', measurement_started=False)
    save(state_file, state)
    try:
        run([godot, '--headless', '--editor', '--import'], 'import.log')
        run([godot, '--headless', '--check-only', '--script', 'res://tests/sim/test_r29.gd'], 'compile.log')
        # Retain each import/compile barrier, not only the last arm's logs.
        for name in ('import.log', 'compile.log'):
            (P / f'{arm}-{name}').write_bytes((P / name).read_bytes())
        state['arms'][arm].update(status='starting', measurement_started=True)
        save(state_file, state)
        print(f'LOCAL OWNER-ATTESTED: starting {arm}; source core {manifest["source_commit"]}', flush=True)
        run([godot, '--headless', '--script', 'res://tests/sim/test_r29.gd', '--',
             f'--mode={arm}', f'--report-dir={P.relative_to(ROOT)}'], f'{arm}-engine.log')
        if (P / f'{arm}-failure.json').exists():
            raise RuntimeError(f'STOP: {arm}-failure.json; no retry')
        subprocess.run([sys.executable, 'tests/r29_remaining.py', arm], env=dict(env, R29_ENGINE_STATUS='0'), check=True)
        state['arms'][arm]['status'] = 'completed'
        if arm == 'D5':
            run(['bash', 'scripts/review_checks.sh'], 'D7-static.log')
            run(['bash', 'tests/run_tests.sh'], 'D7-m0.log')
            subprocess.run([sys.executable, 'scripts/check_m0_regression.py', str(P / 'D7-m0.log')], check=True, env=env)
            subprocess.run([sys.executable, 'tests/r29_remaining.py', 'final'], check=True, env=env)
    except Exception as exc:
        state['stopped'] = True
        state['arms'][arm].update(status='NOT RUN / stopped; inspect logs', blocker=str(exc))
        save(state_file, state)
        raise
    save(state_file, state)


if __name__ == '__main__':
    try:
        main()
    except Exception as exc:
        sys.exit(str(exc))
