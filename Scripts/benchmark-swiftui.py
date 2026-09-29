#!/usr/bin/env python3
"""Compare identical SwiftUI workloads against the v2 commit and the native v3 working tree (macOS)."""
import argparse
import datetime
import json
import hashlib
import math
import platform
import random
import shutil
import statistics
import subprocess
import tarfile
from pathlib import Path
from source_fingerprint import production_digest

ROOT = Path(__file__).resolve().parents[1]
BASELINE = "698e082bc50f33fec785675009cbdc41a75458bb"
YOGA_COMMIT = "042f5013152eb81c1552dec945b88f7b95ca350f"
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--reference", type=Path, required=True, help="Verified Yoga 3.2.1 Git checkout (created by benchmark.py)")
parser.add_argument("--iterations", type=int, default=1000)
parser.add_argument("--trials", type=int, default=10)
parser.add_argument("--seed", type=int, default=321064)
parser.add_argument("--output", type=Path, default=ROOT / "Benchmarks/results/swiftui.json")
args = parser.parse_args()
assert platform.system() == "Darwin" and args.iterations > 0 and args.trials > 0

def run(command, **kwargs):
    return subprocess.run([str(x) for x in command], check=True, text=True, **kwargs)

def digest(module=None):
    return production_digest(ROOT, module)

source_hash = digest()
core_hash = digest("Yoga")

def interval(ratios):
    logs = [math.log(value) for value in ratios]
    center = math.exp(statistics.mean(logs))
    if len(logs) < 2:
        return {"ratio": center, "ci95": None, "trials": len(logs)}
    bootstrap = random.Random(args.seed)
    means = sorted(math.exp(statistics.mean(bootstrap.choices(logs, k=len(logs)))) for _ in range(4000))
    return {"ratio": center, "ci95": [means[100], means[3899]], "trials": len(logs)}

reference = args.reference.resolve()
assert run(["git", "-C", reference, "rev-parse", "HEAD"], capture_output=True).stdout.strip() == YOGA_COMMIT
if run(["git", "-C", reference, "status", "--porcelain", "--untracked-files=normal", "--", "yoga", "Package.swift"], capture_output=True).stdout.strip():
    raise RuntimeError("Reference source has local changes; use a clean checkout for a reproducible comparison")

build = ROOT / "Benchmarks/.build/v2"
build.mkdir(parents=True, exist_ok=True)
archive = build / "source.tar"
run(["git", "-C", ROOT, "archive", "--format=tar", f"--output={archive}", BASELINE])
source = build / "source"
with tarfile.open(archive) as contents:
    contents.extractall(source, filter="data")
manifest = source / "Package.swift"
text = manifest.read_text()
text = text.replace('.package(url: "https://github.com/react/yoga.git", exact: "3.2.1")',
                    f'.package(path: {json.dumps(str(reference))})')
assert "https://github.com/react/yoga" not in text, "The baseline dependency must resolve to the verified local reference"
manifest.write_text(text)
bench = build / "benchmark"
(bench / "Sources").mkdir(parents=True, exist_ok=True)
for target in ["BenchmarkMetrics", "SwiftUIBenchmarks"]:
    shutil.copytree(ROOT / "Benchmarks/Sources" / target, bench / "Sources" / target, dirs_exist_ok=True)
(bench / "Package.swift").write_text(f'''// swift-tools-version: 6.4
import PackageDescription
let package = Package(name: "BaselineBenchmark", platforms: [.macOS(.v13)],
    products: [.executable(name: "swiftui-bench", targets: ["SwiftUIBenchmarks"])],
    dependencies: [.package(name: "Yoga-SwiftUI", path: {json.dumps(str(source))})],
    targets: [.target(name: "BenchmarkMetrics"),
        .executableTarget(name: "SwiftUIBenchmarks", dependencies: [
            .product(name: "YogaSwiftUI", package: "Yoga-SwiftUI"), "BenchmarkMetrics"
        ], swiftSettings: [.interoperabilityMode(.Cxx)])])
''')
binaries = {}
for engine, package in [("v2", bench), ("v3", ROOT / "Benchmarks")]:
    run(["swift", "build", "-c", "release", "--package-path", package, "--product", "swiftui-bench"])
    path = run(["swift", "build", "-c", "release", "--package-path", package, "--show-bin-path"], capture_output=True).stdout.strip()
    binaries[engine] = Path(path) / "swiftui-bench"
results, comparisons = [], []
randomizer = random.Random(args.seed)
for workload in ["shapes", "text"]:
    paired = []
    for trial in range(args.trials):
        order = ["v2", "v3"]
        randomizer.shuffle(order)
        pair = {}
        for engine in order:
            row = json.loads(run([binaries[engine], workload, args.iterations, 1], capture_output=True).stdout)
            row.update(engine=engine, trial=trial, process_order=order)
            pair[engine] = row
        assert pair['v2']['pixel_sha256_by_width'] == pair['v3']['pixel_sha256_by_width'], f"Rendered pixel mismatch: {workload}"
        paired.append(pair)
    comparison = {"workload": workload}
    for metric in ['cpu_ns', 'wall_ns', 'cycles', 'instructions', 'live_heap_bytes_per_host']:
        if metric in ['cycles', 'instructions'] and not all(p[e]['hardware_counters_available'] for p in paired for e in ['v2', 'v3']):
            comparison[metric] = None
            continue
        ratios = []
        for pair in paired:
            values = {e: pair[e][metric] if metric == 'live_heap_bytes_per_host' else pair[e]['samples'][0][metric] for e in ['v2', 'v3']}
            if min(values.values()) <= 0:
                raise RuntimeError(f'Invalid metric: {metric} {values}')
            ratios.append(values['v3'] / values['v2'])
        comparison[metric] = interval(ratios)
    comparisons.append(comparison)
    for engine in ['v2', 'v3']:
        rows = [p[engine] for p in paired]
        aggregate = {k: v for k, v in rows[0].items() if k not in ['trial', 'process_order', 'samples']}
        aggregate['samples'] = [dict(sample, trial=row['trial']) for row in rows for sample in row['samples']]
        aggregate['trials'] = rows
        aggregate['live_heap_bytes_per_host'] = statistics.median(row['live_heap_bytes_per_host'] for row in rows)
        results.append(aggregate)
    print(f"{workload}: pixels match at both widths; v3/v2 CPU time {comparison['cpu_ns']}", flush=True)
if digest() != source_hash:
    raise RuntimeError('Production source changed during the benchmark; discard this run')
report = {"schema_version": 2, "source_sha256": source_hash, "core_source_sha256": core_hash,
          "cpu": run(["sysctl", "-n", "machdep.cpu.brand_string"], capture_output=True).stdout.strip(),
          "memory_method": "Live malloc heap delta for 32 additional laid-out hosting views after framework warm-up; not RSS or peak allocation",
          "date": datetime.datetime.now(datetime.timezone.utc).isoformat(), "baseline_commit": BASELINE,
          "reference_commit": YOGA_COMMIT, "os": platform.platform(), "machine": platform.machine(),
          "swift": run(["swift", "--version"], capture_output=True).stdout.strip(),
          "method": {"trials": args.trials, "iterations": args.iterations, "seed": args.seed,
                     "description": "Release NSHostingView layout; alternating 320/321-point width, 128 children; randomized independent paired process trials, 100 warm-ups each",
                     "confidence_interval": "paired process-trial log-ratio bootstrap, 4000 resamples"},
          "comparisons": comparisons, "results": results}
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps(report, indent=2) + "\n")
print(f"Saved measurements to {args.output}")
