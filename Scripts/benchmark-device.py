#!/usr/bin/env python3
"""Build, install, verify, and benchmark both engines on a connected iPhone."""
import argparse
import datetime
import hashlib
import json
import math
import random
import statistics
import struct
import subprocess
import time
from pathlib import Path
from source_fingerprint import production_digest

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--device', required=True, help='Connected device identifier from devicectl')
parser.add_argument('--team', required=True, help='Development signing team')
parser.add_argument('--reference', type=Path, default=ROOT / '.build/checkouts/yoga')
parser.add_argument('--trials', type=int, default=10)
parser.add_argument('--sizes', default='8,32,128')
parser.add_argument('--workload', choices=['flat','wrap','deep','measured','absolute','contents'])
parser.add_argument('--minimum-sample-ms', type=float, default=100)
parser.add_argument('--minimum-iterations', type=int, default=1000)
parser.add_argument('--cooldown-seconds', type=float, default=5,
                    help='Fixed pause before every paired trial, outside measured work')
parser.add_argument('--maximum-start-thermal-state', type=int, choices=[0, 1], default=1,
                    help='0 requires nominal temperature; 1 also allows the recorded fair state')
parser.add_argument('--skip-build', action='store_true', help='Use only when the installed application matches current source')
parser.add_argument('--verify-only', action='store_true')
parser.add_argument('--output', type=Path, default=ROOT / 'Benchmarks/results/iphone.json')
args = parser.parse_args()
assert args.trials > 0 and args.minimum_sample_ms > 0
assert args.minimum_iterations > 0
assert args.cooldown_seconds >= 0
sizes = [int(x) for x in args.sizes.split(',')]
assert sizes and min(sizes) > 0
workloads = [args.workload] if args.workload else ['flat','wrap','deep','measured','absolute','contents']
folder = ROOT / 'Benchmarks/.build/device'
folder.mkdir(parents=True, exist_ok=True)

def run(command, **kwargs):
    return subprocess.run([str(x) for x in command], text=True, check=True, **kwargs)

def digest(module=None):
    return production_digest(ROOT, module)

source_hash = digest()
core_hash = digest("Yoga")
build_digest = hashlib.sha256(source_hash.encode())
host_inputs = [ROOT/'Package.swift', ROOT/'Scripts/make-device-project.rb', ROOT/'Benchmarks/ReferenceMain.cpp',
               ROOT/'Benchmarks/Sources/YogaBenchmarks/main.swift']
host_inputs += [p for directory in ['Benchmarks/DeviceValidation', 'Benchmarks/Sources/BenchmarkMetrics']
                for p in (ROOT/directory).rglob('*') if p.is_file()]
for path in sorted(host_inputs):
    build_digest.update(str(path.relative_to(ROOT)).encode());build_digest.update(path.read_bytes())
compiler_version = run(['swift','--version'],capture_output=True).stdout.strip()
build_digest.update(compiler_version.encode())
build_hash = build_digest.hexdigest()
installed_marker = folder/'installed-build.sha256'
derived = ROOT / ".build/device-benchmark" / build_hash[:16]
reference_commit = run(['git','-C',args.reference,'rev-parse','HEAD'],capture_output=True).stdout.strip()
assert reference_commit == '042f5013152eb81c1552dec945b88f7b95ca350f'
assert not run(['git','-C',args.reference,'status','--porcelain','--','yoga','Package.swift'],capture_output=True).stdout.strip()
if not args.skip_build:
    installed_marker.unlink(missing_ok=True)
    run(['ruby',ROOT/'Scripts/make-device-project.rb',args.reference])
    with (folder/'build.log').open('w') as log:
        run(['xcodebuild','build','-project',folder/'YogaValidation.xcodeproj','-scheme','YogaValidation',
             '-configuration','Release','-destination',f'platform=iOS,id={args.device}',
             '-derivedDataPath',derived,'-allowProvisioningUpdates',f'DEVELOPMENT_TEAM={args.team}'],stdout=log,stderr=subprocess.STDOUT)
    run(['xcrun','devicectl','device','install','app','--device',args.device,
         derived/'Build/Products/Release-iphoneos/YogaValidation.app'],capture_output=True)
    installed_marker.write_text(build_hash)
else:
    assert installed_marker.exists() and installed_marker.read_text() == build_hash, \
        'Installed production source, host, or compiler is not verified; repeat without --skip-build'

# Record only relevant public hardware/software metadata, not device identifiers.
info_path=folder/'device-info.json'
run(['xcrun','devicectl','device','info','details','--device',args.device,'--json-output',info_path],capture_output=True)
info=json.loads(info_path.read_text())['result']
hardware=info.get('hardwareProperties',{})
software=info.get('deviceProperties',{})
device={'model':hardware.get('marketingName'), 'product_type':hardware.get('productType'), 'os':software.get('osVersionNumber')}

def invoke(engine, workload, mode, count, size, retry_check=False):
    argument=json.dumps(count,separators=(',',':')) if isinstance(count,dict) else str(count)
    command=['xcrun','devicectl','device','process','launch','--device',args.device,
                '--terminate-existing','--console','--timeout','120',
                'com.tiepvuvan.yogaswiftui.yogavalidation','--','--benchmark',engine,workload,mode,argument,size]
    for attempt in range(3 if retry_check else 1):
        try:
            output=run(command,capture_output=True).stdout
            break
        except subprocess.CalledProcessError as error:
            (folder/'launch-failure.log').write_text((error.stdout or '')+'\n'+(error.stderr or ''))
            if not retry_check or attempt == 2:
                raise RuntimeError('Device launch failed; see the ignored device/launch-failure.log') from error
            # Only an untimed, side-effect-free check may be retried. Measured
            # trials fail the whole run instead of selecting another sample.
            time.sleep(2)
    matches=[line.split('YOGA_RESULT=',1)[1].strip() for line in output.splitlines() if 'YOGA_RESULT=' in line]
    if len(matches)!=1:
        (folder/'launch-failure.log').write_text(output)
        raise RuntimeError('Device runner did not return exactly one result; see launch-failure.log')
    return json.loads(matches[0])

def binary32(value):
    return [binary32(x) for x in value] if isinstance(value,list) else struct.unpack('f',struct.pack('f',value))[0]

cooling_checks=[]
def await_temperature():
    # Set a starting condition before taking samples; never delete a hot measured trial.
    started=time.monotonic()
    while True:
        state=invoke('swift','flat','dump',320,1,retry_check=True)
        if state['low_power_mode']:
            raise RuntimeError('Turn off Low Power Mode before running the device benchmark')
        if state['thermal_after'] <= args.maximum_start_thermal_state:
            cooling_checks.append(round(time.monotonic()-started,3))
            return
        if time.monotonic()-started > 600:
            raise RuntimeError('Device did not reach the requested thermal state within ten minutes')
        print(f"  cooling: thermal state {state['thermal_after']}",flush=True)
        time.sleep(15)

def equal(a,b,context):
    if binary32(a)!=binary32(b):
        (folder/'parity-failure.json').write_text(json.dumps({'context':context,'swift':a,'cpp':b}))
        raise RuntimeError(f'Device geometry mismatch: {context}')

def interval(values):
    logs=[math.log(x) for x in values]
    rng=random.Random(321064)
    boot=sorted(math.exp(statistics.mean(rng.choices(logs,k=len(logs)))) for _ in range(4000))
    return {'ratio':math.exp(statistics.mean(logs)), 'ci95':[boot[100],boot[3899]],'trials':len(logs)}

rounding=[invoke(e,'flat','rounding',5000,8)['result'] for e in ['swift','cpp']]
assert rounding[0] == rounding[1], 'Device pixel rounding mismatch'
print(f'Device pixel rounding: {len(rounding[0])} exact results match',flush=True)
verified=[]; comparisons=[]; trials=[]
rng=random.Random(321064)
for workload in workloads:
    for size in sizes:
        for width in [320,321]:
            layouts=[invoke(e,workload,'dump',width,size)['result'] for e in ['swift','cpp']]
            equal(*layouts,f'{workload}/{size}/width={width}')
        traces=[invoke(e,workload,'trace',128,size)['result'] for e in ['swift','cpp']]
        equal(*traces,f'{workload}/{size}/mutation trace')
        verified.append({'workload':workload,'requested_children':size,'nodes':len(layouts[0]),'mutation_steps':128})
        print(f'{workload}/{size}: device geometry and mutation trace match',flush=True)
        if args.verify_only:continue
        await_temperature()
        initial={'rebuild':args.minimum_iterations,'relayout':args.minimum_iterations,
                 'mutation':args.minimum_iterations,'cached':max(100000,args.minimum_iterations),'memory':128}
        probes={e:invoke(e,workload,'suite',initial,size)['result'] for e in ['swift','cpp']}
        counts={}
        for mode in initial:
            if mode=='memory':counts[mode]=128;continue
            fastest=min(next(r for r in probes[e] if r['mode']==mode)['samples'][0]['wall_ns'] for e in ['swift','cpp'])
            counts[mode]=max(initial[mode],math.ceil(args.minimum_sample_ms*1e6/fastest))
            assert counts[mode] < 2**31
        pairs=[]
        for trial in range(args.trials):
            time.sleep(args.cooldown_seconds)
            await_temperature()
            order=['swift','cpp'];rng.shuffle(order)
            pair={e:invoke(e,workload,'suite',counts,size) for e in order}
            for e in order:
                pair[e].update(engine=e,workload=workload,requested_children=size,trial=trial,process_order=order)
                if pair[e]['thermal_before'] >= 2 or pair[e]['thermal_after'] >= 2 or pair[e]['low_power_mode']:
                    (folder/'thermal-failure.json').write_text(json.dumps(pair))
                    raise RuntimeError('Device entered serious thermal state or Low Power Mode; cool the device and repeat the complete run')
                trials.append(pair[e])
            pairs.append(pair)
            print(f'  paired trial {trial+1}/{args.trials}',flush=True)
        for mode in initial:
            metrics=['laid_out_heap_bytes_per_tree'] if mode=='memory' else ['cpu_ns','wall_ns']
            c={'workload':workload,'requested_children':size,'mode':mode,'cycles':None,'instructions':None}
            for metric in metrics:
                ratios=[]
                for pair in pairs:
                    rows={e:next(r for r in pair[e]['result'] if r['mode']==mode) for e in ['swift','cpp']}
                    values={e:rows[e][metric] if mode=='memory' else rows[e]['samples'][0][metric] for e in rows}
                    assert min(values.values())>0
                    ratios.append(values['swift']/values['cpp'])
                c[metric]=interval(ratios)
            comparisons.append(c)
        # Save completed cases as a checkpoint; never mistake one for a complete matrix.
        checkpoint={'complete':False,'source_sha256':source_hash,'core_source_sha256':core_hash,'verified':verified,'comparisons':comparisons,'trials':trials}
        args.output.parent.mkdir(parents=True,exist_ok=True)
        args.output.with_suffix('.partial.json').write_text(json.dumps(checkpoint,indent=2)+'\n')
if digest()!=source_hash:raise RuntimeError('Production source changed during device measurement; discard this run')
report={'schema_version':1,'complete':True,'source_sha256':source_hash,'core_source_sha256':core_hash,
        'build_sha256':build_hash,
        'date':datetime.datetime.now(datetime.timezone.utc).isoformat(),'device':device,
        'reference_commit':reference_commit,'swift':compiler_version,
        'method':{'trials':args.trials,'minimum_sample_ms':args.minimum_sample_ms,
                  'minimum_iterations':args.minimum_iterations,
                  'cooldown_seconds':args.cooldown_seconds,
                  'maximum_start_thermal_state':args.maximum_start_thermal_state,
                  'thermal_policy':'Wait for the selected thermal state before calibration and each pair; fail on serious/critical state or Low Power Mode; retain every measured trial',
                  'process_isolation':'Fresh application process per engine and paired trial; all modes in fixed order within each process',
                  'optimization':'Swift release -O whole module; C++ -O3 -DNDEBUG full LTO',
                  'hardware_counters':'Unavailable through public iOS SDK; report CPU and wall time only',
                  'confidence_interval':'Paired process-trial log-ratio bootstrap, 4000 resamples'},
        'cooling_wait_seconds':cooling_checks,
        'rounding_cases':len(rounding[0]),'verified':verified,'comparisons':comparisons,'trials':trials}
args.output.parent.mkdir(parents=True,exist_ok=True)
args.output.write_text(json.dumps(report,indent=2)+'\n')
args.output.with_suffix('.partial.json').unlink(missing_ok=True)
print(f'Saved {args.output}',flush=True)
