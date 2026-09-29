#!/usr/bin/env python3
"""Run the package's actual XCTest sources inside a signed physical-device host."""
import argparse
import datetime
import hashlib
import json
import subprocess
from pathlib import Path
from source_fingerprint import production_digest

ROOT=Path(__file__).resolve().parents[1]
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--device',required=True)
p.add_argument('--team',required=True)
p.add_argument('--reference',type=Path,default=ROOT/'.build/checkouts/yoga')
p.add_argument('--address-sanitizer',action='store_true')
a=p.parse_args()

def digest(module=None):
    return production_digest(ROOT, module)

def run(command,**kwargs):
    return subprocess.run([str(x) for x in command],check=True,text=True,**kwargs)

source=digest();kind='asan' if a.address_sanitizer else 'release'
folder=ROOT/'.build/device-tests'/source[:16]/kind
folder.mkdir(parents=True,exist_ok=True)
stamp=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
bundle=folder/f'{stamp}.xcresult'
run(['ruby',ROOT/'Scripts/make-device-project.rb',a.reference])
# Tests install their own host (possibly with sanitizers). It must not be reused
# as the optimized benchmark app, even when the production source is identical.
(ROOT/'Benchmarks/.build/device/installed-build.sha256').unlink(missing_ok=True)
(ROOT/'Benchmarks/.build/device/installed-source.sha256').unlink(missing_ok=True)
command=['xcodebuild','test','-project',ROOT/'Benchmarks/.build/device/YogaValidation.xcodeproj',
         '-scheme','YogaValidation','-configuration','Debug' if a.address_sanitizer else 'Release',
         '-destination',f'platform=iOS,id={a.device}','-derivedDataPath',folder/'build',
         '-resultBundlePath',bundle,'-allowProvisioningUpdates',f'DEVELOPMENT_TEAM={a.team}']
if a.address_sanitizer:command+=['-enableAddressSanitizer','YES']
with (folder/f'{stamp}.log').open('w') as log:
    run(command,stdout=log,stderr=subprocess.STDOUT)
summary=json.loads(run(['xcrun','xcresulttool','get','test-results','summary','--path',bundle,'--format','json'],capture_output=True).stdout)
assert summary['failedTests']==0 and summary['passedTests']==summary['totalTestCount'] and summary['passedTests']>0
assert source==digest(),'Production source changed during device verification'
path=ROOT/'Benchmarks/results/iphone-tests.json'
record=json.loads(path.read_text()) if path.exists() else {}
if record.get('source_sha256')!=source:record={}
result={'passed':True,'tests':summary['totalTestCount'],'passed_tests':summary['passedTests'],
        'configuration':'Debug' if a.address_sanitizer else 'Release',
        'date':datetime.datetime.now(datetime.timezone.utc).isoformat(),
        'result_bundle':str(bundle.relative_to(ROOT))}
if a.address_sanitizer:record['address_sanitizer']=result
else:record.update(result)
record['source_sha256']=source
record['core_source_sha256']=digest('Yoga')
info_path=folder/'device-info.json'
run(['xcrun','devicectl','device','info','details','--device',a.device,'--json-output',info_path],capture_output=True)
info=json.loads(info_path.read_text())['result']
record['device']=info['hardwareProperties']['marketingName']
record['os']=info['deviceProperties']['osVersionNumber']
record['upstream_fixtures_per_api']=531
record['upstream_geometry_assertions']=31712
path.parent.mkdir(parents=True,exist_ok=True)
path.write_text(json.dumps(record,indent=2)+'\n')
print(f"{summary['passedTests']} tests passed on device ({kind}); {path}")
