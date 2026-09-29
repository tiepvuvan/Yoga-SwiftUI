# Benchmarks

Compare the native Swift core with pinned C++ Yoga and the SwiftUI integration with the exact v2 implementation. All reference code and metrics helpers belong to a separate development package; neither production library has a C or C++ dependency.

## Results

Read [every measured case and confidence interval](Results.md). Raw [core](results/latest.json) and [SwiftUI](results/swiftui.json) reports include all process trials. The [implementation review](../Documentation/PerformanceImplementation.md) maps measured outcomes to the performance targets. Pre-optimization reports are retained as [core baseline](results/before-optimization.json) and [SwiftUI baseline](results/swiftui-before-optimization.json); their older sampling method and compiler flags differ, so do not treat them as a paired comparison with the new run.

The [physical iPhone report](iPhoneResults.md) uses the same core workloads on an iPhone 16 Pro. The [device and Linux guide](../Documentation/DeviceValidation.md) explains development signing, hosted tests, Address Sanitizer, thermal controls, and the pinned Swift 6.4 Linux image.

## Run

Requirements: Swift 6.4, Python 3.12+, Git, and Clang with C++20 support. Complete hardware counters, allocator checks, and the SwiftUI comparison require macOS. These tools are required only for development.

```sh
# Verifies geometry and mutation traces before timing each case.
# The first run downloads the pinned reference into Benchmarks/.build/reference/yoga.
python3 Scripts/benchmark.py --cpp-lto --trials 10 --sizes 8,32,128

# Builds the same SwiftUI program against the exact v2 implementation.
python3 Scripts/benchmark-swiftui.py \
  --reference Benchmarks/.build/reference/yoga --iterations 1000 --trials 10

# Requires current source digests for the product measured by each report.
python3 Scripts/benchmark-report.py
```

Reuse an existing Yoga 3.2.1 checkout with `--reference /path/to/yoga`. Both scripts verify its commit and reject modified reference sources. The reference is commit `042f5013152eb81c1552dec945b88f7b95ca350f`. `--workload flat` selects one core workload; `--verify-only` checks conformance without timing; `--output /path/to/report.json` preserves a separate run. `--iterations` sets a minimum, then each core batch is calibrated upward to at least 100 ms for the faster engine. `--min-sample-ms` changes this threshold.

Run sequentially on an otherwise idle machine. Production Swift source is hashed before and after each run; changes invalidate that run. Swift uses SwiftPM release `-O` and whole-module optimization. Safe preconditions and normal exclusivity checks stay enabled. C++ uses `-O3 -DNDEBUG`, with full LTO when `--cpp-lto` is supplied, as in the recorded report. The Swift executable links only the native core and the development metrics helper. C++ is a separate executable.

Reports preserve the complete production snapshot and a separate `Sources/Yoga` digest. Core benchmark and Linux records must match the current core digest; SwiftUI benchmarks and full Mac/iPhone suites must match all production Swift source. This allows an unchanged core's measurements to remain valid after an adapter-only correction, while preserving their original complete-source snapshots. `Scripts/validate-release-evidence.py` checks both source scope and completeness.

## Frozen primary core matrix

Six workloads run at size parameters 8, 32, and 128, for 18 equally weighted cases:

| Workload | Tree |
| --- | --- |
| `flat` | Fixed-size shrinking children in a row |
| `wrap` | Mixed points, percentages, gaps, and min/max widths |
| `deep` | Branching three ways with alternating row/column; depths 2, 3, 5 produce 13, 40, 364 total nodes |
| `measured` | Leaves with the same deterministic wrapping measurement in both engines |
| `absolute` | A quarter of the children absolutely positioned with percentage sizing |
| `contents` | Groups whose children participate through `display: contents` |

Other workloads use the size parameter as their leaf count; each adds a root, and contents also adds grouping nodes. Both engines use web defaults, pixel scale one, height 640, and the same tree structure and style data. `YogaTree` starts at its ordinary default capacity; it receives no special reserve hint in the benchmark. C++ uses its normal public construction and setter APIs. Both retain the same last-child handle outside timed layout loops and consume the result.

Before timing, every node's positions, dimensions, four margins, four paddings, four borders, direction, and overflow must match at widths 320 and 321. Then 128 deterministic steps change width, margins, min-width, positioning, display, and gaps, with changing constraints and alternating LTR/RTL. The harness compares the complete output at every step. Decimal JSON values are normalized to their original IEEE Float32 values and compared exactly, without an epsilon. A mismatch saves the complete counterexample and stops the run.

A separate rounding differential checks 140,000 outputs from generated Double bit patterns, selected edge cases, seven positive pixel scales, and all four rounding-flag combinations. Outputs must match bit for bit, with NaNs compared by classification. Pixel scale zero is the layout configuration's rounding bypass and is not part of this primitive comparison.

## Timing and statistics

Every mode has 100 warm-up iterations. Each of ten paired trials launches fresh processes in randomized engine order, with the same calibrated iteration count for both engines:

- **Rebuild:** create a `YogaTree`, prepare value styles, attach children, calculate layout, consume output, and destroy the tree. C++ includes its corresponding construction, setters, layout, and destruction.
- **Relayout:** retain a tree and alternate width 320/321. Construction is excluded.
- **Mutation:** vary a child's width, margins, min-width, positioning, and display, plus the root gap, with alternating width; calculate and consume layout. The separate conformance trace also changes direction.
- **Cached:** repeat identical constraints on an unchanged tree. At least 100,000 iterations per trial, then calibration, limits measurement overhead.
- **Rebuild detached:** separately construct `YogaNode` objects, attach them, lay out, and destroy. This convenience API incurs storage transfers and extra allocations. Its C++ counterpart is ordinary rebuild; report it separately from `YogaTree`.
- **Memory:** retain 128 additional trees, measuring live allocator bytes before construction, after construction, and after layout. Run this separately from timing. Values are per tree and include storage, styles, closures, children, and caches.

The estimate is the geometric mean of the paired Swift/reference ratios. Confidence intervals resample whole paired process trials in log space, with 4,000 bootstrap samples. Inner iterations are not independent statistical samples. Suite summaries give each case equal weight and resample paired trials within each case. Intervals describe this fixed matrix under repeated measurement; they do not establish performance on unseen trees. An interval spanning one does not establish an improvement.

The final mutation sequence corrects an unreachable hidden-display condition in the earlier harness. Both engines now exercise `.none` during these traces and timings; older mutation reports use the previous sequence and are not a paired optimization baseline.

CPU nanoseconds come from `CLOCK_PROCESS_CPUTIME_ID`; wall time comes from `CLOCK_MONOTONIC`. On supported macOS hosts, `proc_pid_rusage` supplies hardware cycles and instructions. They are measured counters, not conversions from elapsed time. `hardware_counters_available` controls whether those fields may be interpreted. Live heap comes from `malloc_zone_statistics`. Unsupported counters remain unavailable. Heap is retained allocator memory, not peak allocations or process RSS.

The C++ configuration is shared across trees. Swift stores a small configuration value per node. The native engine has one layout entry and up to four lazy measurement entries; eviction can trade memory for callback work.

## Allocation checks

Allocation instrumentation runs separately from timings. On macOS, the development metrics helper discovers the deprecated `malloc_logger` diagnostic hook at runtime, rejects an existing logger, and verifies that a probe allocation is observed. It then counts allocation/reallocation events and requested bytes during 1,000 warmed alternating-width layouts. Deallocation events are not counted as allocations. The logger is removed immediately afterward. The hook's availability is not guaranteed; an unsupported or failed probe reports unavailable, never a false zero.

This instrumentation follows the event format in Apple's [allocator source](https://github.com/apple-oss-distributions/libmalloc/blob/main/src/malloc.c). It is confined to local benchmark executables. It is not linked by either production product. Results apply to these warmed, stable-topology trees and their deterministic callbacks. First-time layout, structural edits, newly needed measurement entries, and arbitrary application measurement code can allocate.

## Previous-version SwiftUI comparison

The script exports v2 commit `698e082bc50f33fec785675009cbdc41a75458bb` into an ignored build directory. It replaces only the manifest's remote Yoga reference with the verified local 3.2.1 checkout. The old library source is unchanged. Both versions compile the same [SwiftUI workload](Sources/SwiftUIBenchmarks/main.swift).

Each trial lays out an `NSHostingView` containing 128 shapes or text views, alternating width 320/321 at height 640. It performs 100 warm-ups and 1,000 measured layouts. Ten independent paired trials randomize version order. Each pair must render identical pixel digests at both widths before it is accepted. Report intervals use the same paired bootstrap method as the core.

Retained-memory measurements keep 32 additional laid-out hosting views alive after framework warm-up. These figures include SwiftUI and AppKit state, measurement boxes, and native/C++ layout state. They do not measure peak memory during a frame. A small change in complete hosting-view memory can accompany a larger reduction in engine memory.

## Limits and further work

Desktop results describe one M4 Pro, compiler, OS, and matrix. The Mac is not thermally locked, and power state and CPU placement are not captured. The separate iPhone run records thermal and Low Power Mode state, allows nominal or fair temperature, and uses fixed cooling pauses. Its batches target 20 ms with a minimum of 100 iterations, compared with the desktop's 100 ms and 1,000 minimum. Serious/critical state fails the run. It measures CPU and wall time; public iOS APIs do not provide the desktop hardware counters. Both device engines are linked into a development host, with construction and layout timed inside the app rather than across device transport.

Correctness tests pass on Linux aarch64 with Swift 6.4 and on the physical iPhone, including SwiftUI rendering and Address Sanitizer on the phone. Current coverage does not establish Linux performance, Linux x86_64 correctness, watch hardware performance, request p95/p99, peak memory, branch/cache counters, large adversarial trees, or realistic dynamic nested SwiftUI workloads. The iPhone core benchmark does not replace an end-to-end iPhone comparison against the v2 SwiftUI adapter.

The generated correctness corpus is separate from the benchmark matrix. Refresh it with:

```sh
python3 Scripts/import-yoga-fixtures.py Benchmarks/.build/reference/yoga
swift test -c release
```
