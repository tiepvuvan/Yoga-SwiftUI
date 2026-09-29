#!/usr/bin/env python3
"""Summarize the complete physical-device run without dropping cases or trials."""
import hashlib
import json
import math
import random
import statistics
from pathlib import Path
from source_fingerprint import production_digest

ROOT=Path(__file__).resolve().parents[1]
r=json.loads((ROOT/'Benchmarks/results/iphone.json').read_text())
assert r['complete']
assert r['core_source_sha256']==production_digest(ROOT, 'Yoga'), 'Device report does not match the current core source'

def format_ratio(value):
    lo,hi=value['ci95'];return f"{value['ratio']:.3f} [{lo:.3f}, {hi:.3f}]"

def comparison(case,mode,metric):
    return next(x for x in r['comparisons'] if x['workload']==case['workload'] and x['requested_children']==case['requested_children'] and x['mode']==mode)[metric]

def summary(mode,metric):
    logs=[]
    for case in r['verified']:
        rows=[x for x in r['trials'] if x['workload']==case['workload'] and x['requested_children']==case['requested_children']]
        ratios=[]
        for trial in range(r['method']['trials']):
            values={}
            for engine in ['swift','cpp']:
                row=next(x for x in rows if x['trial']==trial and x['engine']==engine)
                data=next(x for x in row['result'] if x['mode']==mode)
                values[engine]=data[metric] if mode=='memory' else data['samples'][0][metric]
            ratios.append(math.log(values['swift']/values['cpp']))
        logs.append(ratios)
    rng=random.Random(321064)
    boot=sorted(math.exp(statistics.mean(statistics.mean(rng.choices(x,k=len(x))) for x in logs)) for _ in range(4000))
    return {'ratio':math.exp(statistics.mean(statistics.mean(x) for x in logs)), 'ci95':[boot[100],boot[3899]]}

lines=['# Physical iPhone performance','',
       f"Measured on **{r['device']['model']}**, iOS **{r['device']['os']}**, at {r['date']}.",'',
       f"Native core digest: `{r['core_source_sha256']}`. Full source snapshot when measured: `{r['source_sha256']}`. Reference: Yoga 3.2.1, `{r['reference_commit']}`.",'',
       'Ratios are Swift/C++; below 1 is better. Brackets are 95% paired bootstrap intervals. Every case has equal weight in the suite means. The raw [device report](results/iphone.json) preserves every trial and its thermal/power state.', '',
       f"Each engine/trial uses a fresh application process. Engine order is randomized within {r['method']['trials']} pairs. Timed modes run in fixed order inside that process, each with 100 warm-ups and equal iteration counts calibrated to at least {r['method']['minimum_sample_ms']:g} ms for the faster engine. Retained-heap measurement follows separately. C++ uses -O3, NDEBUG, and full LTO; Swift uses release -O and whole-module optimization.",'',
       '**Hardware CPU cycles and instruction counts are unavailable through the public iOS SDK. These tables report measured CPU time and wall time; neither is presented as a cycle count.** Live heap is an allocator delta for 128 retained trees, not peak memory or process RSS.', '',
       '## Suite summary','', '| Mode | CPU time ratio | Wall time ratio |','| --- | ---: | ---: |']
for mode in ['rebuild','relayout','mutation','cached']:
    lines.append(f"| {mode} | {format_ratio(summary(mode,'cpu_ns'))} | {format_ratio(summary(mode,'wall_ns'))} |")
lines+=['',f"Retained live heap ratio: **{format_ratio(summary('memory','laid_out_heap_bytes_per_tree'))}**.",'',
        '## Every case','', '| Workload / size | Nodes | Rebuild CPU | Resized CPU | Mutation CPU | Cached CPU | Heap |','| --- | ---: | ---: | ---: | ---: | ---: | ---: |']
for case in r['verified']:
    values=[format_ratio(comparison(case,m,'cpu_ns')) for m in ['rebuild','relayout','mutation','cached']]
    values.append(format_ratio(comparison(case,'memory','laid_out_heap_bytes_per_tree')))
    lines.append(f"| {case['workload']} / {case['requested_children']} | {case['nodes']} | "+' | '.join(values)+' |')
thermal=sorted({x[k] for x in r['trials'] for k in ['thermal_before','thermal_after']})
lines+=['','## Correctness and conditions','',
        f"- All {len(r['verified'])} cases match full C++ geometry at widths 320 and 321 and throughout 128 mutation steps each.",
        f"- {r['rounding_cases']:,} pixel-rounding results match C++ bit for bit; NaNs are compared by classification.",
        '- The complete core and SwiftUI XCTest suite runs in the same development host; see [device correctness](results/iphone-tests.json).',
        f"- Recorded thermal states: {thermal} (0 = nominal, 1 = fair). The runner fails the run if serious/critical state or Low Power Mode is observed.",
        f"- A fixed {r['method']['cooldown_seconds']:g}-second pause precedes each pair, followed by a wait for thermal state at or below {r['method']['maximum_start_thermal_state']} (0 = nominal, 1 = fair). These waits are excluded from timings and recorded in the raw report. Every measured trial is retained.",
        '- The phone is connected by USB. Display, OS background work, and CPU frequency are not controlled; confidence intervals describe the fixed suite on this device.',
        '- The development app links both engines so launch environment and framework overhead are shared. Construction, layout, and destruction are timed inside the app; app launch, JSON, and device transport are excluded.',
        '- This validates the native core on physical hardware. The pinned-v2 end-to-end SwiftUI performance comparison remains the macOS hosting-view experiment; iPhone SwiftUI correctness is checked separately.',
        '', f"Reproduce with `python3 Scripts/benchmark-device.py --device DEVICE_ID --team TEAM_ID --minimum-sample-ms {r['method']['minimum_sample_ms']:g} --minimum-iterations {r['method']['minimum_iterations']} --cooldown-seconds {r['method']['cooldown_seconds']:g} --maximum-start-thermal-state {r['method']['maximum_start_thermal_state']}`, then `python3 Scripts/benchmark-device-report.py`. See the [methodology](README.md) for installation, signing, and test commands.",'']
(ROOT/'Benchmarks/iPhoneResults.md').write_text('\n'.join(lines))
print('Wrote Benchmarks/iPhoneResults.md')
