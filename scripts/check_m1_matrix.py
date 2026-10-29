#!/usr/bin/env python3
"""Enforce scoped measured-runtime claims; the guard itself is not evidence."""
import hashlib
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PACK_SHA256 = 'e3bd06654e0f92aaca55d0cc85e79f6d589a45aa6d9ddab5f4f068db22edb9a1'
SUCCESS = re.compile(r'\b(?:met|pass|passed|verified)\b', re.I)
RUNTIME = re.compile(
    r'\bAC-20[124](?:[abs])?\b|\bpresets?\b|\btick cost\b|\bA9\.[23457]\b|'
    r'§\s*10\.6\b|\bA12\b|\bA5\.6\b|\bA10\b|\bA8 replay\b|\bFA-[3456]\b', re.I)
REQUIRED = ('AC-201', 'AC-202', 'AC-204', 'presets', 'Tick cost', 'A9.2',
            'A9.3', 'A9.4', 'A9.5', 'A9.7', '§10.6', 'A12', 'A5.6',
            'FA-1', 'FA-2', 'FA-3', 'FA-4', 'FA-5', 'FA-6', 'FA-7', 'AC-201a', 'AC-201b', 'AC-201s')
CITATION = re.compile(
    r'\b(?:CI|run)\s*#?\s*\d{6,}\b|'
    r'\bcommit\s*[:#]?\s*[0-9a-f]{7,40}\b|'
    r'https://github\.com/[^\s]+/actions/runs/\d+', re.I)
ANALYTIC_GATES = {'FA-1', 'FA-2', 'FA-7'}
ANALYTIC_STATUS = 'PASS (analytic only)'
ANALYTIC_CITATION = re.compile(
    r'\b(?:CI|run)\s*#?\s*\d{6,}\b|https://github\.com/[^\s]+/actions/runs/\d+|'
    r'(?:^|[\s(])[^\s|]*(?:m1-owner-geometry|owner-geometry)\.json\b', re.I)
# Success scopes are exact gate/status/citation triples, never vocabulary guesses.
PENDING_STATUSES = {'NOT RUN', 'NOT RUN for M1', 'STATIC CHECK ONLY'}
HEADER = ['Gate / source', 'Required acceptance evidence', 'Status', 'Evidence reference']
# R17 owner authorizes measured runtime upgrades ONLY for these exact gate/status/citation triples.
RUNTIME_MEASURED_STATUS = "PASS (measured runtime)"
RUNTIME_MEASURED = {'Engine / architecture': 'CI40818428101 .review/m1_r17_phase2_evidence.json#row1',
 'A9.2 accumulator': 'CI40818428101 .review/m1_r17_phase2_evidence.json#row2',
 'A9.3 injected RNG': 'CI40818428101 .review/m1_r17_phase2_evidence.json#row3',
 'A9.4 replay ×3': 'CI40818428101 .review/m1_r17_phase2_evidence.json#row9',
 'A9.4 two-second stall': 'CI40818428101 .review/m1_r17_phase2_evidence.json#row10',
 'A9.5 two frame conditions': 'CI40818428101 .review/m1_r17_phase2_evidence.json#row11',
 'A9.7 mandatory falsification': 'CI40818428101 .review/m1_r17_phase2_evidence.json#row12',
 'A9.7 baseline / CI regression': 'CI40818428101 .review/m1_r17_phase2_evidence.json#row13',
 'A8 replay baseline': 'CI40818428101 .review/m1_r17_phase2_evidence.json#row13'}
# R27 owner-authorised measured scopes: exact gate/status/citation triples only.
R27_VERDICTS = {'AC-201': ('FAILED (a stability; s carried)', 'CI40960697692 .review/m1_r27_evidence.json#AC201'),
 'AC-201a': ('FAILED (35.344deg exceeds15deg)', 'CI40960697692 .review/m1_r27_evidence.json#AC201'),
 'AC-201b': ('PASS (measured10s COM)', 'CI40960697692 .review/m1_r27_evidence.json#AC201'),
 'AC-201s': ('FAILED (M1.1 carry-over)', 'CI40960697692 .review/m1_r27_evidence.json#AC201'),
 'AC-202': ('PASS (candidate only; unadopted)', 'CI40960697692 .review/m1_r27_evidence.json#AC202'),
 'FA-3': ('PASS (static wake-policy only)', 'CI40960697692 .review/m1_r27_evidence.json#FA3'),
 'FA-5': ('PASS (measured policy coverage)',
          'CI40904855466 .review/m1_r26_archive_evidence.json#FA5; owner R27 57ed098'),
 'AC-204': ('PASS (200-run numerical soak)',
            'CI40960697692 .review/m1_r27_evidence.json#AC204_aggregate')}

EXCEPTIONS = {'M0 regression': 'PASS (regression only)',
              'A8 test-count floor': 'PASS (count floor only)'}


def plain(cell):
    return re.sub(r'[*`_]', '', cell).strip()


def validate_matrix(text):
    errors, rows = [], []
    for number, line in enumerate(text.splitlines(), 1):
        if not line.strip().startswith('|'):
            # FA claims must live in the guarded table, not prose/checkbox escape hatches.
            if re.search(r'\bFA-[1-7]\b', line, re.I) and (
                SUCCESS.search(line) or re.search(r'FA-[1-7]\s*:', line, re.I)
            ):
                errors.append(f'line {number}: FA claim outside guarded gate table')
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
        analytic = gate in ANALYTIC_GATES and status == ANALYTIC_STATUS
        measured = (gate in RUNTIME_MEASURED and status == RUNTIME_MEASURED_STATUS
                    and evidence == plain(RUNTIME_MEASURED[gate]))
        reviewed = (gate in R27_VERDICTS and status == R27_VERDICTS[gate][0]
                    and evidence == plain(R27_VERDICTS[gate][1]))
        if status not in PENDING_STATUSES and status != EXCEPTIONS.get(gate) and not analytic and not measured and not reviewed:
            errors.append(f'{prefix}: status not allowlisted: {status!r}')
        if status in EXCEPTIONS.values() and (status != EXCEPTIONS.get(gate) or not CITATION.search(evidence)):
            errors.append(f'{prefix}: scoped status requires its exact gate and run/commit evidence')
        if re.fullmatch(r'FA-[3456]', gate) and status != 'NOT RUN' and not reviewed:
            errors.append(f'{prefix}: runtime FA status must remain NOT RUN')
        if analytic and not ANALYTIC_CITATION.search(evidence):
            errors.append(f'{prefix}: analytic-only status needs CI run or geometry report path')
        if success and (not evidence or re.match(r'^None\b', evidence, re.I)):
            errors.append(f'{prefix}: success token with empty/None evidence')
        if RUNTIME.search(gate) and success and not measured and not reviewed:
            errors.append(f'{prefix}: runtime acceptance success claim forbidden; keep NOT RUN')
        if success:
            expected = EXCEPTIONS.get(gate)
            if not ((expected and status == expected and CITATION.search(evidence)) or
                    (analytic and ANALYTIC_CITATION.search(evidence)) or measured or reviewed):
                errors.append(f'{prefix}: success requires a scoped regression/count-floor status and run/commit evidence')
    if not rows:
        errors.append('acceptance table missing or empty')
    gates = ' '.join(row[0] for row in rows).casefold()
    for required in REQUIRED:
        present = (any(row[0] == required for row in rows) if required.startswith(('FA-', 'AC-'))
                   else required.casefold() in gates)
        if not present:
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
    print('PASS: M1 scoped-evidence matrix guard; owner pack SHA-256 / 379 lines verified.')
    return 0


if __name__ == '__main__':
    sys.exit(main())
