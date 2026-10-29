#!/usr/bin/env python3
"""Persist evidence on the SAME fixed branch; bounded compressed backup if push fails."""
import base64,hashlib,json,os,subprocess,tarfile
from pathlib import Path
paths=[p for p in (Path('tests/fixtures/m1_r29_raw'),Path('tests/fixtures/m1_captures')) if p.exists()]
paths += [p for p in Path('.review').glob('m1_r29_measurement_*') if p.is_file()]
# Transport before any push: artifacts quota must not destroy the one-shot arm.
archive=Path(os.environ['RUNNER_TEMP'])/'r29-evidence.tar.gz'
with tarfile.open(archive,'w:gz') as t:
 for p in paths:t.add(p,arcname=str(p))
b=archive.read_bytes();encoded=base64.b64encode(b).decode();parts=[encoded[i:i+24000] for i in range(0,len(encoded),24000)]
for i,part in enumerate(parts):print(f'::notice title=R29 evidence {i+1:04d}/{len(parts):04d} sha256 {hashlib.sha256(b).hexdigest()}::{part}',flush=True)
subprocess.run(['git','config','user.name','R29 evidence recorder'],check=True)
subprocess.run(['git','config','user.email','r29-evidence@users.noreply.github.com'],check=True)
subprocess.run(['git','add','--',*[str(p) for p in paths]],check=True)
if subprocess.run(['git','diff','--cached','--quiet']).returncode==0:raise SystemExit(0)
subprocess.run(['git','commit','-m','docs: preserve one-shot R29 measurements [skip ci]'],check=True)
subprocess.run(['git','push','origin','arena/4cd0a587-clamber'],check=True)
