#!/usr/bin/env python3
"""Preserve fresh candidate evidence on this fixed branch; no artifact quota dependency."""
import gzip,hashlib,json,os,re,subprocess
from pathlib import Path

def run(*args):
 return subprocess.check_output(args,text=True).strip()

source=os.environ['SOURCE_SHA']
if run('git','rev-parse','HEAD')!=source:
 raise SystemExit('STOP: checkout changed; refuse evidence publication')
if os.environ['GITHUB_REF_NAME']!='arena/f43f36ab-clamber':
 raise SystemExit('STOP: wrong evidence branch')
folder=Path(os.environ['M1_ARTICULATED_EXECUTION_REPORT_DIR'])
if not folder.is_dir():
 raise SystemExit('STOP: no evidence folder; no measurement started')
files=[];index={}
for p in sorted(folder.iterdir()):
 if p.suffix=='.jsonl':
  raw=p.read_bytes(); target=p.with_suffix('.jsonl.gz')
  if target.exists():raise SystemExit('STOP: refusing to overwrite compressed evidence')
  target.write_bytes(gzip.compress(raw,mtime=0))
  index[p.name]={'raw_bytes':len(raw),'raw_sha256':hashlib.sha256(raw).hexdigest(),
                 'gzip_bytes':target.stat().st_size,'gzip_sha256':hashlib.sha256(target.read_bytes()).hexdigest()}
  files.append(target)
 elif p.suffix in {'.json','.txt','.log'}:files.append(p)
index_path=folder/'transport-index.json'
if index_path.exists():raise SystemExit('STOP: transport index exists')
index_path.write_text(json.dumps({'source_commit':source,'raw_traces':index},indent=2)+'\n');files.append(index_path)
if sum(p.stat().st_size for p in files)>32*1024*1024:
 raise SystemExit('STOP: candidate evidence exceeds bounded repository budget; preserved on runner')
# Announcements survive an upload-quota failure, independent of optional artifacts.
for p in files:
 if p.name in {'summary.json','exit-code.txt'}:
  message=p.read_text().replace('%','%25').replace('\r','%0D').replace('\n','%0A')
  print(f'::notice title=NEW articulated execution {p.name}::{message}',flush=True)
for p in files:
 if p.suffix=='.log':
  rows=[s for s in p.read_text().splitlines() if re.search(r'SCRIPT ERROR|ERROR:|Parse Error',s)]
  for row in rows[:8]:
   escaped=row.replace('%','%25').replace('\r','%0D')
   print(f'::error title=Candidate {p.name}::{escaped}',flush=True)
subprocess.run(['git','config','user.name','M1 candidate evidence recorder'],check=True)
subprocess.run(['git','config','user.email','candidate-evidence@users.noreply.github.com'],check=True)
subprocess.run(['git','add','--',*[str(p) for p in files]],check=True)
subprocess.run(['git','commit','-m','docs: preserve articulated execution evidence [skip ci]'],check=True)
subprocess.run(['git','push','origin','arena/f43f36ab-clamber'],check=True)
