#!/usr/bin/env python3
"""Verify full geometry and mutation traces, then run paired native/C++ benchmarks."""
import argparse
import datetime
import hashlib
import json
import math
import platform
import random
import statistics
import struct
import subprocess
from pathlib import Path
from source_fingerprint import production_digest

ROOT = Path(__file__).resolve().parents[1]
REFERENCE_COMMIT = "042f5013152eb81c1552dec945b88f7b95ca350f"
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--reference", type=Path)
parser.add_argument("--iterations", type=int, default=1000, help="Minimum iterations; batches are calibrated upward")
parser.add_argument("--trials", type=int, default=10, help="Independent paired process trials")
parser.add_argument("--min-sample-ms", type=float, default=100)
parser.add_argument("--seed", type=int, default=321064)
parser.add_argument("--sizes", default="8,32,128")
parser.add_argument("--cpp-lto", action="store_true", help="Also enable full link-time optimization for C++")
parser.add_argument("--verify-only", action="store_true")
parser.add_argument("--trace-steps", type=int, default=128)
parser.add_argument("--output", type=Path, default=ROOT / "Benchmarks/results/latest.json")
parser.add_argument("--workload", choices=["flat", "wrap", "deep", "measured", "absolute", "contents"])
args = parser.parse_args()
assert args.iterations > 0 and args.trials > 0 and args.min_sample_ms >= 0 and args.trace_steps > 0
sizes = [int(x) for x in args.sizes.split(",")]
assert sizes and min(sizes) > 0
build = ROOT / "Benchmarks/.build/reference"
build.mkdir(parents=True, exist_ok=True)

def run(command, **kwargs):
    return subprocess.run([str(x) for x in command], check=True, text=True, **kwargs)

def digest(module=None):
    return production_digest(ROOT, module)

source_hash = digest()
core_hash = digest("Yoga")
reference = args.reference.resolve() if args.reference else build / "yoga"
if not reference.exists():
    run(["git", "clone", "--branch", "v3.2.1", "--depth", "1", "https://github.com/react/yoga.git", reference])
if not (reference / ".git").exists():
    raise RuntimeError("Reference must be a Git checkout for provenance verification")
revision = run(["git", "-C", reference, "rev-parse", "HEAD"], capture_output=True).stdout.strip()
if revision != REFERENCE_COMMIT:
    raise RuntimeError(f"Expected {REFERENCE_COMMIT}, got {revision}")
if run(["git", "-C", reference, "status", "--porcelain", "--untracked-files=normal", "--", "yoga", "Package.swift"], capture_output=True).stdout.strip():
    raise RuntimeError("Reference source has local changes")
run(["swift", "build", "-c", "release", "--package-path", ROOT / "Benchmarks", "--product", "yoga-bench"])
swift_path = run(["swift", "build", "-c", "release", "--package-path", ROOT / "Benchmarks", "--show-bin-path"], capture_output=True).stdout.strip()
native = Path(swift_path) / "yoga-bench"
metrics = ROOT / "Benchmarks/Sources/BenchmarkMetrics"
run(["clang", "-O3", "-I", metrics / "include", "-c", metrics / "BenchmarkMetrics.c", "-o", build / "metrics.o"])
cpp = build / ("yoga-cpp-lto-bench" if args.cpp_lto else "yoga-cpp-bench")
cpp_flags = ["-std=c++20", "-O3", "-DNDEBUG"] + (["-flto=full"] if args.cpp_lto else [])
run(["clang++", *cpp_flags, "-I", reference, "-I", ROOT / "Benchmarks", ROOT / "Benchmarks/ReferenceMain.cpp",
     *sorted((reference / "yoga").rglob("*.cpp")), build / "metrics.o", "-o", cpp])
binaries = {"swift": native, "cpp": cpp}
workloads = [args.workload] if args.workload else ["flat", "wrap", "deep", "measured", "absolute", "contents"]
randomizer = random.Random(args.seed)

# Paired bootstrap operates on independent process summaries, not inner iterations.
def interval(ratios):
    logs = [math.log(value) for value in ratios]
    center = math.exp(statistics.mean(logs))
    if len(logs) < 2:
        return {"ratio": center, "ci95": None, "trials": len(logs)}
    bootstrap = random.Random(args.seed)
    means = sorted(math.exp(statistics.mean(bootstrap.choices(logs, k=len(logs)))) for _ in range(4000))
    return {"ratio": center, "ci95": [means[100], means[3899]], "trials": len(logs)}

def invoke(engine, workload, mode, count, size):
    return json.loads(run([binaries[engine], workload, mode, count, size, 1], capture_output=True).stdout)

def require_equal(left, right, context):
    # Swift and iostreams choose different decimal spellings for Float. Compare
    # the represented IEEE-754 binary32 values exactly, without an epsilon.
    def binary32(value):
        if isinstance(value, list):
            return [binary32(item) for item in value]
        return struct.unpack("f", struct.pack("f", value))[0]
    left, right = binary32(left), binary32(right)
    if left == right:
        return
    # Persist the complete counterexample; never truncate away a length mismatch.
    failure = build / "parity-failure.json"
    failure.write_text(json.dumps({"context": context, "swift": left, "cpp": right}, indent=2) + "\n")
    raise RuntimeError(f"Geometry mismatch: {context}. Saved {failure}")

rounding = [invoke(engine, "flat", "rounding", 5000, 8) for engine in ["swift", "cpp"]]
if rounding[0] != rounding[1]:
    failure = build / "rounding-failure.json"
    failure.write_text(json.dumps({"swift": rounding[0], "cpp": rounding[1]}))
    raise RuntimeError(f"Pixel rounding bit-pattern mismatch: {failure}")
print(f"Pixel rounding: {len(rounding[0])} results match C++ bit for bit (NaNs compared by classification)", flush=True)
results, comparisons, verified, allocations = [], [], [], []
for workload in workloads:
    for size in sizes:
        for width in [320, 321]:
            layouts = [invoke(engine, workload, "dump", width, size) for engine in ["swift", "cpp"]]
            require_equal(*layouts, f"{workload}/{size}, width {width}")
        traces = [invoke(engine, workload, "trace", args.trace_steps, size) for engine in ["swift", "cpp"]]
        require_equal(*traces, f"{workload}/{size}, {args.trace_steps} mutation steps")
        node_count = len(layouts[0])
        verified.append({"workload": workload, "requested_children": size, "nodes": node_count, "mutation_steps": args.trace_steps})
        print(f"{workload}/{size}: {node_count} nodes, full geometry and {args.trace_steps} mutations match", flush=True)
        if args.verify_only:
            continue
        for engine in ["swift", "cpp"]:
            allocation = invoke(engine, workload, "allocations", 1000, size)
            allocation["requested_children"] = size
            allocations.append(allocation)
        modes = ["rebuild", "rebuild-detached", "relayout", "mutation", "cached"]
        if platform.system() == "Darwin":
            modes.append("memory")
        for mode in modes:
            count = 128 if mode == "memory" else max(args.iterations, 100_000 if mode == "cached" else 1)
            if mode != "memory" and args.min_sample_ms:
                calibration = [invoke(engine, workload, mode, count, size)["samples"][0]["wall_ns"] for engine in ["swift", "cpp"]]
                count = max(count, math.ceil(args.min_sample_ms * 1_000_000 / min(calibration)))
            paired = []
            for trial in range(args.trials):
                order = ["swift", "cpp"]
                randomizer.shuffle(order)
                pair = {engine: invoke(engine, workload, mode, count, size) for engine in order}
                for row in pair.values():
                    row["trial"] = trial
                    row["requested_children"] = size
                    row["process_order"] = order
                paired.append(pair)
            metrics_to_compare = ["laid_out_heap_bytes_per_tree"] if mode == "memory" else ["cpu_ns", "wall_ns", "cycles", "instructions"]
            comparison = {"workload": workload, "requested_children": size, "nodes": node_count, "mode": mode}
            for metric in metrics_to_compare:
                if metric in ["cycles", "instructions"] and not all(p[e]["hardware_counters_available"] for p in paired for e in ["swift", "cpp"]):
                    comparison[metric] = None
                    continue
                ratios = []
                for pair in paired:
                    values = {e: pair[e][metric] if mode == "memory" else statistics.median(s[metric] for s in pair[e]["samples"]) for e in ["swift", "cpp"]}
                    if min(values.values()) <= 0:
                        raise RuntimeError(f"Invalid nonpositive metric: {mode} {metric} {values}")
                    ratios.append(values["swift"] / values["cpp"])
                comparison[metric] = interval(ratios)
            comparisons.append(comparison)
            for engine in ["swift", "cpp"]:
                rows = [p[engine] for p in paired]
                aggregate = {k: v for k, v in rows[0].items() if k not in ["trial", "process_order", "samples"]}
                aggregate["trials"] = rows
                if mode == "memory":
                    for metric in ["constructed_heap_bytes_per_tree", "laid_out_heap_bytes_per_tree"]:
                        aggregate[metric] = statistics.median(r[metric] for r in rows)
                else:
                    aggregate["samples"] = [dict(sample, trial=row["trial"]) for row in rows for sample in row["samples"]]
                results.append(aggregate)
            metric = "laid_out_heap_bytes_per_tree" if mode == "memory" else "cpu_ns"
            result = comparison[metric]
            print(f"  {mode}: Swift/C++ {metric} {result['ratio']:.3f}; 95% CI {result['ci95']}", flush=True)
if digest() != source_hash:
    raise RuntimeError("Production source changed during the benchmark; discard this run")
report = {"schema_version": 2, "source_sha256": source_hash, "core_source_sha256": core_hash,
          "cpu": run(["sysctl", "-n", "machdep.cpu.brand_string"], capture_output=True).stdout.strip() if platform.system() == "Darwin" else platform.processor(),
          "date": datetime.datetime.now(datetime.timezone.utc).isoformat(), "reference_commit": REFERENCE_COMMIT,
          "machine": platform.machine(), "os": platform.platform(),
          "swift": run(["swift", "--version"], capture_output=True).stdout.strip(),
          "clang": run(["clang++", "--version"], capture_output=True).stdout.strip(),
          "optimization": {"swift": "SwiftPM release (-O, whole module)", "cpp": " ".join(cpp_flags)},
          "binary_bytes": {e: binary.stat().st_size for e, binary in binaries.items()},
          "method": {"trials": args.trials, "minimum_sample_ms": args.min_sample_ms, "seed": args.seed,
                     "confidence_interval": "paired process-trial log-ratio bootstrap, 4000 resamples", "warmup_iterations": 100},
          "rounding_cases": len(rounding[0]), "verified": verified, "allocations": allocations, "comparisons": comparisons, "results": results}
args.output.parent.mkdir(parents=True, exist_ok=True)
args.output.write_text(json.dumps(report, indent=2) + "\n")
print(f"Saved raw measurements to {args.output}")
