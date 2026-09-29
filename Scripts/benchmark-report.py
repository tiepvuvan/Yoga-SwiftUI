#!/usr/bin/env python3
"""Render every recorded case, including regressions and independent-trial intervals."""
import json
import math
import random
import statistics
from pathlib import Path
from source_fingerprint import production_digest

ROOT = Path(__file__).resolve().parents[1]
core = json.loads((ROOT / 'Benchmarks/results/latest.json').read_text())
ui = json.loads((ROOT / 'Benchmarks/results/swiftui.json').read_text())
if core['core_source_sha256'] != production_digest(ROOT, 'Yoga') or ui['source_sha256'] != production_digest(ROOT):
    raise RuntimeError('Reports do not match the current source of the products they measure')
if core['schema_version'] != 2 or ui['schema_version'] != 2:
    raise RuntimeError('Rerun both benchmarks with independent paired trials')

def estimate(value):
    if value is None:
        return 'unavailable'
    ci = value['ci95']
    return f"{value['ratio']:.3f} [{ci[0]:.3f}, {ci[1]:.3f}]" if ci else f"{value['ratio']:.3f}"

def comparison(case, mode):
    return next(x for x in core['comparisons'] if x['workload'] == case['workload'] and x['requested_children'] == case['requested_children'] and x['mode'] == mode)

def row(report, workload, engine, mode=None, size=None):
    return next(x for x in report['results'] if x['workload'] == workload and x['engine'] == engine
                and (mode is None or x['mode'] == mode) and (size is None or x['requested_children'] == size))

def summary(mode, metric):
    # Each case has equal weight. Resample paired process trials within each case;
    # the interval describes repeated measurements of this fixed suite, not unseen trees.
    logs = []
    for case in core['verified']:
        native = row(core, case['workload'], 'swift', mode, case['requested_children'])
        reference = row(core, case['workload'], 'cpp', mode, case['requested_children'])
        if metric in ['cycles', 'instructions'] and not (native['hardware_counters_available'] and reference['hardware_counters_available']):
            return None
        def value(trial):
            return trial[metric] if mode == 'memory' else trial['samples'][0][metric]
        logs.append([math.log(value(a) / value(b)) for a, b in zip(native['trials'], reference['trials'])])
    center = math.exp(statistics.mean(statistics.mean(case) for case in logs))
    rng = random.Random(core['method']['seed'])
    boot = sorted(math.exp(statistics.mean(statistics.mean(rng.choices(case, k=len(case))) for case in logs)) for _ in range(4000))
    return {'ratio': center, 'ci95': [boot[100], boot[3899]]}

lines = ['# Recorded performance', '',
         'Generated from the checked-in raw samples by `python3 Scripts/benchmark-report.py`. Ratios are native Swift divided by the reference; **below 1 is better**. Brackets show 95% paired bootstrap confidence intervals.', '',
         '## Environment', '', f"- CPU: {core['cpu']}", f"- OS: {core['os']}",
         f"- Core run: {core['date']}", f"- SwiftUI run: {ui['date']}",
         f"- Native core source digest: `{core['core_source_sha256']}`",
         f"- Full source snapshot at core measurement: `{core['source_sha256']}`",
         f"- Full source snapshot at SwiftUI measurement: `{ui['source_sha256']}`",
         f"- Core reference: Yoga 3.2.1, `{core['reference_commit']}`",
         f"- Swift: {core['optimization']['swift']}", f"- C++: `{core['optimization']['cpp']}`",
         f"- Core timing: {core['method']['trials']} independent paired trials, randomized engine order, at least {core['method']['minimum_sample_ms']:g} ms calibrated batches, 100 warm-up iterations",
         f"- SwiftUI timing: {ui['method']['trials']} independent paired trials, {ui['method']['iterations']} iterations per trial, randomized engine order, 100 warm-up iterations", '',
         '```text', core['swift'], '```', '',
         'Compiler metadata, every sample, process order, and executable sizes are retained in [core JSON](results/latest.json) and [SwiftUI JSON](results/swiftui.json). Benchmarks run sequentially; temperature, power state, and scheduler placement are not controlled or recorded. These results describe this machine and fixed suite.', '',
         '## Core suite summary', '',
         f"Each of the {len(core['verified'])} cases has equal weight in these geometric means. Intervals resample paired trials within each case; they do not predict performance for unseen workloads. Cached calls are kept separate from real layout work.", '',
         '| Mode | CPU cycles | CPU time | Wall time | Instructions |', '| --- | ---: | ---: | ---: | ---: |']
for mode in ['rebuild', 'relayout', 'mutation', 'cached']:
    lines.append(f"| {mode} | " + ' | '.join(estimate(summary(mode, metric)) for metric in ['cycles', 'cpu_ns', 'wall_ns', 'instructions']) + ' |')
if any(x['mode'] == 'memory' for x in core['comparisons']):
    lines += ['', f"Retained live heap ratio: **{estimate(summary('memory', 'laid_out_heap_bytes_per_tree'))}**. This excludes peak allocations and is not process RSS."]
lines += ['', '## Every core case', '',
          'The size parameter requests 8, 32, or 128 children. Deep trees use 13, 40, or 364 total nodes; contents adds grouping nodes. All geometry fields match C++ at both widths and throughout each 128-step mutation trace.', '',
          '| Workload / size | Nodes | Rebuild cycles | Resized cycles | Mutation cycles | Cached cycles | Heap ratio |',
          '| --- | ---: | ---: | ---: | ---: | ---: | ---: |']
for case in core['verified']:
    values = [estimate(comparison(case, mode)['cycles']) for mode in ['rebuild', 'relayout', 'mutation', 'cached']]
    memory = [x for x in core['comparisons'] if x['mode'] == 'memory' and x['workload'] == case['workload'] and x['requested_children'] == case['requested_children']]
    values.append(estimate(memory[0]['laid_out_heap_bytes_per_tree']) if memory else 'unavailable')
    lines.append(f"| {case['workload']} / {case['requested_children']} | {case['nodes']} | " + ' | '.join(values) + ' |')
lines += ['', '## Reference-based node construction', '',
          '`rebuild` above uses `YogaTree`. The following rows create separate `YogaNode` objects, attach them, calculate layout, and destroy them. Each detached object begins with its own storage, so attaching it adds transfers and allocations. This convenience path is slower and must not inherit claims made for `YogaTree`. Its C++ reference uses the same ordinary C++ construction as `rebuild`.', '',
          '| Workload / size | Detached YogaNode/C++ cycles |', '| --- | ---: |']
for case in core['verified']:
    lines.append(f"| {case['workload']} / {case['requested_children']} | {estimate(comparison(case, 'rebuild-detached')['cycles'])} |")
lines += ['', '## Warmed allocation checks', '',
          'Each row measures 1,000 alternating-width layouts after warm-up. Construction and timing instrumentation are excluded. The macOS allocation hook verifies its own operation before counting; unsupported hosts report unavailable. Zero here applies to these warmed workloads, including their deterministic callbacks, rather than all layouts or content callbacks.', '',
          '| Workload / size | Swift allocations / bytes | C++ allocations / bytes |', '| --- | ---: | ---: |']
for case in core['verified']:
    values=[]
    for engine in ['swift', 'cpp']:
        item=next(x for x in core['allocations'] if x['workload'] == case['workload'] and x['requested_children'] == case['requested_children'] and x['engine'] == engine)
        values.append(f"{item['allocations']:,} / {item['allocated_bytes']:,}" if item['available'] else 'unavailable')
    lines.append(f"| {case['workload']} / {case['requested_children']} | " + ' | '.join(values) + ' |')
lines += ['', '## SwiftUI v3 versus v2', '',
          f"Baseline commit: `{ui['baseline_commit']}`. Both versions render identical pixels at widths 320 and 321 in every trial. Measurements include SwiftUI and AppKit overhead, 128 children per host, and 32 retained hosts for live heap.", '',
          '| Workload | v2 CPU μs | v3 CPU μs | v3/v2 cycles | v3/v2 CPU time | v3/v2 heap |', '| --- | ---: | ---: | ---: | ---: | ---: |']
for c in ui['comparisons']:
    a, b = [row(ui, c['workload'], e) for e in ['v3', 'v2']]
    lines.append(f"| {c['workload']} | {statistics.median(x['cpu_ns'] for x in b['samples']) / 1000:.1f} | {statistics.median(x['cpu_ns'] for x in a['samples']) / 1000:.1f} | {estimate(c['cycles'])} | {estimate(c['cpu_ns'])} | {estimate(c['live_heap_bytes_per_host'])} |")
lines += ['', '## Release interpretation', '',
          'Retained layout and fresh construction have different costs. A fast resized-layout mean cannot establish a construction win, and a confidence interval spanning 1 does not establish an improvement. Keep individual regressions visible when assessing the [performance targets](../Documentation/PerformancePlan.md).', '',
          'The desktop suite does not establish request p95/p99, peak memory, hardware cache/branch behavior, Linux performance, or watch performance. See the separate [physical iPhone report](iPhoneResults.md) and [device/Linux validation](../Documentation/DeviceValidation.md). The [implementation review](../Documentation/PerformanceImplementation.md) records achieved targets and remaining work. See the [methodology](README.md) before repeating or extending the results.', '']
(ROOT / 'Benchmarks/Results.md').write_text('\n'.join(lines))
print('Wrote Benchmarks/Results.md')
