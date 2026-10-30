#!/usr/bin/env python3
"""ZIP provenance: canonical SHA256 of sorted [path, SHA256(file bytes)] rows.

Every source file under core/ is included, including additions. Godot-generated
.gd.uid sidecars (untracked by the original Git guard) are excluded. Symlinks are
rejected. Permissions are deliberately excluded: ZIP extraction on Windows does
not preserve them; all pinned core files are non-executable regular blobs.
The manifest pins the measured core, not the self-referential packaging commit.
"""
import hashlib
import json
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / 'tests/fixtures/source_manifest.json'


def tree_sha256(root=ROOT):
    if (root / 'core').is_symlink():
        raise ValueError('Core root symlink not allowed')
    rows = []
    for p in sorted((root / 'core').rglob('*')):
        if p.is_symlink():
            raise ValueError(f'Core symlink not allowed: {p}')
        if p.is_file():
            # Editor import creates these. They are not committed source blobs,
            # and git diff 4796ec6 -- core/ also ignores them. A new .gd still
            # changes the hash, even if it has a generated sidecar.
            if p.name.endswith('.gd.uid') and p.with_suffix('').is_file():
                continue
            rows.append([p.relative_to(root).as_posix(), hashlib.sha256(p.read_bytes()).hexdigest()])
    return hashlib.sha256(json.dumps(rows, separators=(',', ':'), ensure_ascii=True).encode()).hexdigest()


def verify():
    m = json.loads(MANIFEST.read_text())
    if tree_sha256() != m['core_tree_sha256']:
        raise ValueError('Core tree differs from source_manifest.json')
    if hashlib.sha256((ROOT / 'core/tuning.tres').read_bytes()).hexdigest() != m['tuning_sha256']:
        raise ValueError('Tuning differs from source_manifest.json')
    return m


def source_head():
    if os.environ.get('CLAMBER_LOCAL') == '1':
        return verify()['source_commit']
    return subprocess.check_output(['git', 'rev-parse', 'HEAD'], text=True).strip()


def historical_blob(spec, text=False):
    if (ROOT / '.git').exists():
        return subprocess.check_output(['git', 'show', spec], text=text)
    # Exact archived blobs, not a substitute with current production bytes.
    index = json.loads((ROOT / 'tests/fixtures/source_baselines/index.json').read_text())
    entry = index[spec]
    data = (ROOT / 'tests/fixtures/source_baselines' / entry['file']).read_bytes()
    if hashlib.sha256(data).hexdigest() != entry['sha256']:
        raise ValueError(f'Historical blob differs: {spec}')
    return data.decode() if text else data


if __name__ == '__main__':
    print(json.dumps(verify(), sort_keys=True))
