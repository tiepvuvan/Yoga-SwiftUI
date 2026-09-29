#!/usr/bin/env python3
"""Reject stale, partial, or incomplete release verification reports."""
import json
from pathlib import Path
from source_fingerprint import production_digest

ROOT = Path(__file__).resolve().parents[1]
RESULTS = ROOT / 'Benchmarks/results'
REFERENCE = '042f5013152eb81c1552dec945b88f7b95ca350f'
CASES = {(workload, size) for workload in ['flat', 'wrap', 'deep', 'measured', 'absolute', 'contents']
         for size in [8, 32, 128]}


def require(condition, message):
    if not condition:
        raise SystemExit(message)


source = production_digest(ROOT)
core_source = production_digest(ROOT, 'Yoga')
reports = {}
for name in ['latest', 'swiftui', 'iphone', 'iphone-tests', 'linux', 'macos-tests', 'platform-builds']:
    report = json.loads((RESULTS / f'{name}.json').read_text())
    if name in ['latest', 'iphone', 'linux']:
        require(report['core_source_sha256'] == core_source, f'{name}: stale core source digest')
    else:
        require(report['source_sha256'] == source, f'{name}: stale production source digest')
    reports[name] = report

for name in ['latest', 'iphone']:
    report = reports[name]
    require(report['reference_commit'] == REFERENCE, f'{name}: wrong C++ reference')
    require(report['method']['trials'] >= 10, f'{name}: fewer than ten independent trials')
    require(report['rounding_cases'] == 140000, f'{name}: incomplete rounding differential')
    cases = {(row['workload'], row['requested_children']) for row in report['verified']}
    require(cases == CASES and len(report['verified']) == len(CASES), f'{name}: incomplete case matrix')
    require(all(row['mutation_steps'] == 128 for row in report['verified']), f'{name}: incomplete mutation traces')
    modes = ['rebuild', 'relayout', 'mutation', 'cached', 'memory']
    if name == 'latest':
        modes.append('rebuild-detached')
    comparisons = {(row['workload'], row['requested_children'], row['mode']) for row in report['comparisons']}
    require(comparisons == {(w, s, m) for w, s in CASES for m in modes}
            and len(report['comparisons']) == len(comparisons), f'{name}: missing or duplicate timing mode')

core = reports['latest']
allocations = [row for row in core['allocations'] if row['engine'] == 'swift']
require(len(allocations) == 18 and all(row['available'] and row['allocations'] == 0
        and row['allocated_bytes'] == 0 for row in allocations), 'Native warmed allocation gate failed')
require(all(row['hardware_counters_available'] for row in core['results'] if row['mode'] != 'memory'),
        'Desktop hardware counters unavailable')

ui = reports['swiftui']
require(ui['baseline_commit'] == '698e082bc50f33fec785675009cbdc41a75458bb', 'Wrong v2 reference')
require(ui['method']['trials'] >= 10 and len(ui['comparisons']) == 2, 'Incomplete SwiftUI comparison')
for workload in ['shapes', 'text']:
    rows = {row['engine']: row for row in ui['results'] if row['workload'] == workload}
    require(set(rows) == {'v2', 'v3'}, 'Missing SwiftUI engine')
    require(all(len(row['trials']) == ui['method']['trials'] for row in rows.values()), 'Missing SwiftUI trial')
    for a, b in zip(rows['v2']['trials'], rows['v3']['trials']):
        require(a['pixel_sha256_by_width'] == b['pixel_sha256_by_width']
                and len(a['pixel_sha256_by_width']) == 2, 'SwiftUI pixel verification mismatch')
phone = reports['iphone']
require(phone['complete'], 'Device benchmark is a partial run')
require(len(phone['trials']) == 18 * 2 * phone['method']['trials'], 'Incomplete device trial count')
trial_keys = {(row['workload'], row['requested_children'], row['engine'], row['trial'])
              for row in phone['trials']}
require(trial_keys == {(w, s, e, t) for w, s in CASES for e in ['swift', 'cpp']
                       for t in range(phone['method']['trials'])}, 'Missing or duplicate device trial')
require(all(not row['low_power_mode'] and row['thermal_before'] < 2 and row['thermal_after'] < 2
            for row in phone['trials']), 'Invalid device thermal/power conditions')
require(all(row['cycles'] is None and row['instructions'] is None for row in phone['comparisons']),
        'Device hardware counters must remain unavailable')
phone_tests = reports['iphone-tests']
require(phone_tests['passed'] and phone_tests['tests'] == 38 and phone_tests['passed_tests'] == 38,
        'Device release correctness suite incomplete')
require(phone_tests['address_sanitizer']['passed'] and phone_tests['address_sanitizer']['tests'] == 38
        and phone_tests['address_sanitizer']['passed_tests'] == 38,
        'Device sanitizer suite incomplete')
require(reports['linux']['passed'], 'Linux verification failed')
require('Executed 26 tests, with 0 failures' in (RESULTS / 'linux.log').read_text(),
        'Linux core test count mismatch')
for mode in ['release', 'address_sanitizer']:
    record = reports['macos-tests'][mode]
    require(record['passed'] and record['tests'] == 38, 'macOS correctness suite incomplete')
    log = (RESULTS / record['log']).read_text()
    require('Executed 26 tests, with 0 failures' in log and 'Executed 12 tests, with 0 failures' in log,
            'macOS test log count mismatch')
builds = reports['platform-builds']
require(builds['documentation_warnings_as_errors'], 'DocC warnings gate disabled')
require(set(builds['checks']) == {'iOS', 'tvOS', 'watchOS', 'visionOS', 'DocC'}, 'Missing platform build')
for name, record in builds['checks'].items():
    success = '** BUILD DOCUMENTATION SUCCEEDED **' if name == 'DocC' else '** BUILD SUCCEEDED **'
    require(record['passed'] and success in (RESULTS / record['log']).read_text(),
            f'{name}: platform build did not succeed')
print(f'PASS: all release evidence matches production source {source}')
print('Performance target interpretation remains in Documentation/PerformanceImplementation.md.')
