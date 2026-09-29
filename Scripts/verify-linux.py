#!/usr/bin/env python3
"""Run native Swift tests in the official Linux image, without writing into the checkout."""
import datetime
import hashlib
import json
import subprocess
from pathlib import Path
from source_fingerprint import production_digest

ROOT=Path(__file__).resolve().parents[1]
IMAGE='swift:6.4.0-noble@sha256:64bab762bc73a3fda6d9ebc559258bd6d7660c10a705bb25ecacad2f99d066f9'

def digest(module=None):
    return production_digest(ROOT, module)

source=digest()
command=['docker','run','--rm','--network','none','--mount',f'type=bind,source={ROOT},target=/package,readonly',
         '--tmpfs','/work:exec,size=4g','--workdir','/package',IMAGE,
         'sh','-c','swift --version && uname -m && swift test -c release --scratch-path /work/build']
result=subprocess.run(command,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
folder=ROOT/'Benchmarks/results'
folder.mkdir(exist_ok=True)
(folder/'linux.log').write_text(result.stdout)
print(result.stdout)
if result.returncode:raise SystemExit(result.returncode)
if digest()!=source:raise RuntimeError('Production source changed during Linux tests')
report={'date':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source_sha256':source,'core_source_sha256':digest('Yoga'),'source_scope':'Yoga',
        'image':IMAGE,'passed':True,'log':'linux.log',
        'isolation':'Network disabled; repository mounted read-only; build artifacts in temporary container memory'}
(folder/'linux.json').write_text(json.dumps(report,indent=2)+'\n')
