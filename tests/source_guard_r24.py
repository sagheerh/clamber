"""Exact historical R24 resource guard for ZIP; does not authorise execution."""
import hashlib
import json
from pathlib import Path
from source_provenance import verify
verify()
rows = json.loads(Path('tests/fixtures/r24_source_guard.json').read_text())
expected_paths = {path for path, _ in rows}
actual_paths = {'core/tuning.tres'} | {p.as_posix() for p in Path('data/creatures').rglob('*') if p.is_file()}
if expected_paths != actual_paths:
    raise ValueError('Historical R24 path set differs; STOP')
for path, expected in rows:
    if hashlib.sha256(Path(path).read_bytes()).hexdigest() != expected:
        raise ValueError(f'Historical R24 guard differs from 7d48ba0: {path}; STOP')
