#!/usr/bin/env python3
"""A8: keep M0's separate engine floor and combined 488-check floor."""
import re
import sys
from pathlib import Path

ENGINE_BASELINE = 475
COMBINED_BASELINE = 488


def validate(text):
    if re.search(r'SCRIPT ERROR:|Parse Error:|Failed to load script|^FAILED\b', text, re.M):
        raise ValueError('M0 regression log contains errors')
    matches = re.findall(r'^M0: (\d+) checks, (\d+) failures$', text, re.M)
    if len(matches) != 1 or int(matches[0][1]) != 0:
        raise ValueError('Expected exactly one completed successful M0 engine run')
    engine = int(matches[0][0])
    python = sum(map(int, re.findall(r'^Ran (\d+) tests? in ', text, re.M)))
    # No automatic waiver: changing these floors needs a reviewed DECISIONS entry.
    if engine < ENGINE_BASELINE or python < 13 or engine + python < COMBINED_BASELINE:
        raise ValueError(f'Count regression: engine={engine}, Python={python}, combined={engine + python}; baseline=475+13=488')
    return engine, python


if __name__ == '__main__':
    try:
        engine, python = validate(Path(sys.argv[1]).read_text())
        print(f'PASS: M0 regression engine={engine} (>=475), Python={python} (>=13), total={engine + python} (>=488).')
    except (ValueError, OSError) as error:
        print('::error title=A8 M0 regression::' + str(error))
        raise SystemExit(1) from error
