#!/usr/bin/env python3
"""Enforce the current M1 runtime-claim freeze, not runtime acceptance itself."""
import hashlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACK_SHA256 = 'e3bd06654e0f92aaca55d0cc85e79f6d589a45aa6d9ddab5f4f068db22edb9a1'
SUCCESS = re.compile(r'\b(?:met|pass|passed|verified)\b', re.I)
RUNTIME = re.compile(
    r'\bAC-20[124]\b|\bpresets?\b|\btick cost\b|\bA9\.[23457]\b|'
    r'§\s*10\.6\b|\bA12\b|\bA5\.6\b|\bA10\b|\bA8 replay\b', re.I)
REQUIRED = ('AC-201', 'AC-202', 'AC-204', 'presets', 'Tick cost', 'A9.2',
            'A9.3', 'A9.4', 'A9.5', 'A9.7', '§10.6', 'A12', 'A5.6')
CITATION = re.compile(
    r'\b(?:CI|run)\s*#?\s*\d{6,}\b|'
    r'\bcommit\s*[:#]?\s*[0-9a-f]{7,40}\b|'
    r'https://github\.com/[^\s]+/actions/runs/\d+', re.I)
# Only these two gates can claim success during the foundation-only increment.
PENDING_STATUSES = {'NOT RUN', 'NOT RUN for M1', 'STATIC CHECK ONLY'}
HEADER = ['Gate / source', 'Required acceptance evidence', 'Status', 'Evidence reference']
EXCEPTIONS = {'M0 regression': 'PASS (regression only)',
              'A8 test-count floor': 'PASS (count floor only)'}


def plain(cell):
    return re.sub(r'[*`_]', '', cell).strip()


def validate_matrix(text):
    errors, rows = [], []
    for number, line in enumerate(text.splitlines(), 1):
        if not line.strip().startswith('|'):
            continue
        if not line.strip().endswith('|'):
            errors.append(f'line {number}: unterminated matrix row')
            continue
        cells = [plain(cell) for cell in re.split(r'(?<!\\)\|', line.strip())[1:-1]]
        if cells == HEADER:
            continue
        if cells and all(re.fullmatch(r'[-:]+', cell) for cell in cells):
            continue
        if len(cells) != 4:
            errors.append(f'line {number}: expected four matrix cells')
            continue
        gate, requirement, status, evidence = cells
        rows.append(cells)
        success = SUCCESS.search(' '.join(cells))
        prefix = f'line {number} ({gate})'
        if status not in PENDING_STATUSES and status != EXCEPTIONS.get(gate):
            errors.append(f'{prefix}: status not allowlisted: {status!r}')
        if status in EXCEPTIONS.values() and (status != EXCEPTIONS.get(gate) or not CITATION.search(evidence)):
            errors.append(f'{prefix}: scoped status requires its exact gate and run/commit evidence')
        if success and (not evidence or re.match(r'^None\b', evidence, re.I)):
            errors.append(f'{prefix}: success token with empty/None evidence')
        if RUNTIME.search(gate) and success:
            errors.append(f'{prefix}: runtime acceptance success claim forbidden; keep NOT RUN')
        if success:
            expected = EXCEPTIONS.get(gate)
            if not expected or status != expected or not CITATION.search(evidence):
                errors.append(f'{prefix}: success requires a scoped regression/count-floor status and run/commit evidence')
    if not rows:
        errors.append('acceptance table missing or empty')
    gates = ' '.join(row[0] for row in rows).casefold()
    for required in REQUIRED:
        if required.casefold() not in gates:
            errors.append(f'required gate missing: {required}')
    not_run = sum(row[2] in {'NOT RUN', 'NOT RUN for M1'} for row in rows)
    if not_run < 12:
        errors.append(f'NOT RUN row floor: {not_run} < 12')
    return errors


def validate_pack(data):
    errors = []
    if hashlib.sha256(data).hexdigest() != PACK_SHA256:
        errors.append('owner review pack SHA-256 mismatch; must remain byte-identical/unmodified')
    if data.count(b'\n') != 379:
        errors.append('owner review pack must contain exactly 379 lines')
    return errors


def main():
    try:
        errors = validate_matrix((ROOT / '.review/m1_ac_matrix.md').read_text())
        errors += validate_pack((ROOT / 'docs/CLAMBER_REVIEW_AGENT.md').read_bytes())
    except OSError as error:
        errors = [str(error)]
    for error in errors:
        print('FAIL M1 matrix/pack: ' + error, file=sys.stderr)
    if errors:
        return 1
    print('PASS: M1 claim-freeze matrix guard; owner pack SHA-256 / 379 lines verified.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
