# Recorded performance

Generated from the checked-in raw samples by `python3 Scripts/benchmark-report.py`. Ratios are native Swift divided by the reference; **below 1 is better**. Brackets show 95% paired bootstrap confidence intervals.

## Environment

- CPU: Apple M4 Pro
- OS: macOS-27.2-arm64-arm-64bit-Mach-O
- Core run: 2026-09-29T08:41:25.271053+00:00
- SwiftUI run: 2026-09-29T09:51:45.550656+00:00
- Native core source digest: `0698f0133a28c84591a0d16fe6eb0f1596c8e01b0cff04591513a445a11e808e`
- Full source snapshot at core measurement: `526e4ad346a7b18a12a7fb2c7a8a32c0ef0738dbe6be88d931d3be1c4aed9d56`
- Full source snapshot at SwiftUI measurement: `fdc9f00884bddb991c797da615d43b15ad9489cdbfe71eed33273beea4139f22`
- Core reference: Yoga 3.2.1, `042f5013152eb81c1552dec945b88f7b95ca350f`
- Swift: SwiftPM release (-O, whole module)
- C++: `-std=c++20 -O3 -DNDEBUG -flto=full`
- Core timing: 10 independent paired trials, randomized engine order, at least 100 ms calibrated batches, 100 warm-up iterations
- SwiftUI timing: 10 independent paired trials, 1000 iterations per trial, randomized engine order, 100 warm-up iterations

```text
Apple Swift version 6.4 (swiftlang-6.4.0.34.1 clang-2100.3.34.1)
Target: arm64-apple-macosx27.2.0
```

Compiler metadata, every sample, process order, and executable sizes are retained in [core JSON](results/latest.json) and [SwiftUI JSON](results/swiftui.json). Benchmarks run sequentially; temperature, power state, and scheduler placement are not controlled or recorded. These results describe this machine and fixed suite.

## Core suite summary

Each of the 18 cases has equal weight in these geometric means. Intervals resample paired trials within each case; they do not predict performance for unseen workloads. Cached calls are kept separate from real layout work.

| Mode | CPU cycles | CPU time | Wall time | Instructions |
| --- | ---: | ---: | ---: | ---: |
| rebuild | 0.808 [0.806, 0.811] | 0.809 [0.804, 0.815] | 0.811 [0.802, 0.820] | 0.648 [0.648, 0.648] |
| relayout | 0.552 [0.549, 0.554] | 0.549 [0.544, 0.553] | 0.548 [0.541, 0.554] | 0.455 [0.455, 0.455] |
| mutation | 0.789 [0.787, 0.792] | 0.790 [0.784, 0.796] | 0.791 [0.783, 0.799] | 0.710 [0.710, 0.710] |
| cached | 0.928 [0.924, 0.933] | 0.929 [0.920, 0.938] | 0.931 [0.918, 0.944] | 0.845 [0.845, 0.845] |

Retained live heap ratio: **0.683 [0.683, 0.683]**. This excludes peak allocations and is not process RSS.

## Every core case

The size parameter requests 8, 32, or 128 children. Deep trees use 13, 40, or 364 total nodes; contents adds grouping nodes. All geometry fields match C++ at both widths and throughout each 128-step mutation trace.

| Workload / size | Nodes | Rebuild cycles | Resized cycles | Mutation cycles | Cached cycles | Heap ratio |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| flat / 8 | 9 | 0.856 [0.852, 0.859] | 0.587 [0.567, 0.601] | 0.868 [0.864, 0.872] | 0.936 [0.932, 0.941] | 0.659 [0.659, 0.659] |
| flat / 32 | 33 | 0.725 [0.722, 0.729] | 0.532 [0.528, 0.537] | 0.877 [0.870, 0.883] | 0.924 [0.916, 0.931] | 0.597 [0.597, 0.597] |
| flat / 128 | 129 | 0.746 [0.731, 0.764] | 0.520 [0.519, 0.521] | 0.781 [0.746, 0.802] | 0.934 [0.926, 0.943] | 0.605 [0.605, 0.605] |
| wrap / 8 | 9 | 0.815 [0.805, 0.826] | 0.579 [0.576, 0.582] | 0.873 [0.869, 0.877] | 0.924 [0.916, 0.932] | 0.668 [0.668, 0.668] |
| wrap / 32 | 33 | 0.701 [0.697, 0.705] | 0.533 [0.531, 0.535] | 0.791 [0.772, 0.827] | 0.923 [0.917, 0.929] | 0.600 [0.600, 0.600] |
| wrap / 128 | 129 | 0.648 [0.644, 0.652] | 0.474 [0.472, 0.477] | 0.679 [0.675, 0.682] | 0.918 [0.898, 0.933] | 0.606 [0.606, 0.606] |
| deep / 8 | 13 | 0.935 [0.929, 0.943] | 0.645 [0.642, 0.649] | 0.719 [0.715, 0.723] | 0.940 [0.919, 0.973] | 0.780 [0.780, 0.780] |
| deep / 32 | 40 | 0.844 [0.809, 0.863] | 0.651 [0.647, 0.654] | 0.690 [0.686, 0.693] | 0.926 [0.920, 0.933] | 0.818 [0.818, 0.818] |
| deep / 128 | 364 | 0.781 [0.770, 0.788] | 0.654 [0.631, 0.671] | 0.688 [0.676, 0.697] | 0.934 [0.890, 0.978] | 0.831 [0.831, 0.831] |
| measured / 8 | 9 | 1.009 [1.002, 1.015] | 0.616 [0.596, 0.628] | 0.897 [0.890, 0.904] | 0.927 [0.911, 0.945] | 0.791 [0.791, 0.791] |
| measured / 32 | 33 | 0.914 [0.908, 0.921] | 0.598 [0.585, 0.610] | 0.839 [0.835, 0.844] | 0.930 [0.925, 0.935] | 0.741 [0.741, 0.741] |
| measured / 128 | 129 | 0.827 [0.821, 0.832] | 0.512 [0.510, 0.515] | 0.713 [0.709, 0.718] | 0.938 [0.908, 0.977] | 0.752 [0.752, 0.752] |
| absolute / 8 | 9 | 1.026 [1.015, 1.037] | 0.667 [0.662, 0.672] | 0.870 [0.865, 0.875] | 0.925 [0.918, 0.933] | 0.692 [0.692, 0.692] |
| absolute / 32 | 33 | 0.869 [0.863, 0.875] | 0.579 [0.561, 0.590] | 0.883 [0.879, 0.888] | 0.926 [0.918, 0.935] | 0.630 [0.630, 0.630] |
| absolute / 128 | 129 | 0.848 [0.841, 0.854] | 0.581 [0.576, 0.587] | 0.817 [0.805, 0.834] | 0.932 [0.929, 0.934] | 0.639 [0.639, 0.639] |
| contents / 8 | 11 | 0.801 [0.785, 0.829] | 0.469 [0.466, 0.471] | 0.842 [0.840, 0.844] | 0.940 [0.932, 0.946] | 0.640 [0.640, 0.640] |
| contents / 32 | 41 | 0.687 [0.683, 0.690] | 0.436 [0.423, 0.444] | 0.765 [0.763, 0.767] | 0.924 [0.913, 0.935] | 0.654 [0.654, 0.654] |
| contents / 128 | 161 | 0.648 [0.644, 0.652] | 0.396 [0.393, 0.398] | 0.686 [0.684, 0.689] | 0.908 [0.863, 0.936] | 0.662 [0.662, 0.662] |

## Reference-based node construction

`rebuild` above uses `YogaTree`. The following rows create separate `YogaNode` objects, attach them, calculate layout, and destroy them. Each detached object begins with its own storage, so attaching it adds transfers and allocations. This convenience path is slower and must not inherit claims made for `YogaTree`. Its C++ reference uses the same ordinary C++ construction as `rebuild`.

| Workload / size | Detached YogaNode/C++ cycles |
| --- | ---: |
| flat / 8 | 2.724 [2.709, 2.741] |
| flat / 32 | 2.359 [2.323, 2.400] |
| flat / 128 | 2.348 [2.334, 2.361] |
| wrap / 8 | 2.379 [2.346, 2.419] |
| wrap / 32 | 2.176 [2.153, 2.207] |
| wrap / 128 | 2.037 [2.005, 2.077] |
| deep / 8 | 2.070 [2.063, 2.078] |
| deep / 32 | 1.598 [1.588, 1.609] |
| deep / 128 | 1.181 [1.175, 1.187] |
| measured / 8 | 2.526 [2.504, 2.547] |
| measured / 32 | 2.313 [2.298, 2.331] |
| measured / 128 | 2.099 [2.077, 2.132] |
| absolute / 8 | 2.946 [2.895, 3.015] |
| absolute / 32 | 2.553 [2.533, 2.572] |
| absolute / 128 | 2.476 [2.445, 2.499] |
| contents / 8 | 2.456 [2.436, 2.475] |
| contents / 32 | 2.253 [2.182, 2.306] |
| contents / 128 | 2.131 [2.121, 2.142] |

## Warmed allocation checks

Each row measures 1,000 alternating-width layouts after warm-up. Construction and timing instrumentation are excluded. The macOS allocation hook verifies its own operation before counting; unsupported hosts report unavailable. Zero here applies to these warmed workloads, including their deterministic callbacks, rather than all layouts or content callbacks.

| Workload / size | Swift allocations / bytes | C++ allocations / bytes |
| --- | ---: | ---: |
| flat / 8 | 0 / 0 | 1,000 / 64,000 |
| flat / 32 | 0 / 0 | 1,000 / 256,000 |
| flat / 128 | 0 / 0 | 1,000 / 1,024,000 |
| wrap / 8 | 0 / 0 | 2,000 / 128,000 |
| wrap / 32 | 0 / 0 | 6,000 / 1,536,000 |
| wrap / 128 | 0 / 0 | 22,000 / 22,528,000 |
| deep / 8 | 0 / 0 | 4,000 / 96,000 |
| deep / 32 | 0 / 0 | 13,000 / 312,000 |
| deep / 128 | 0 / 0 | 121,000 / 2,904,000 |
| measured / 8 | 0 / 0 | 3,000 / 192,000 |
| measured / 32 | 0 / 0 | 11,000 / 2,816,000 |
| measured / 128 | 0 / 0 | 43,000 / 44,032,000 |
| absolute / 8 | 0 / 0 | 1,000 / 64,000 |
| absolute / 32 | 0 / 0 | 1,000 / 256,000 |
| absolute / 128 | 0 / 0 | 1,000 / 1,024,000 |
| contents / 8 | 0 / 0 | 20,000 / 624,000 |
| contents / 32 | 0 / 0 | 71,000 / 2,168,000 |
| contents / 128 | 0 / 0 | 377,000 / 17,048,000 |

## SwiftUI v3 versus v2

Baseline commit: `698e082bc50f33fec785675009cbdc41a75458bb`. Both versions render identical pixels at widths 320 and 321 in every trial. Measurements include SwiftUI and AppKit overhead, 128 children per host, and 32 retained hosts for live heap.

| Workload | v2 CPU μs | v3 CPU μs | v3/v2 cycles | v3/v2 CPU time | v3/v2 heap |
| --- | ---: | ---: | ---: | ---: | ---: |
| shapes | 1156.8 | 1110.5 | 0.959 [0.951, 0.966] | 0.959 [0.951, 0.965] | 0.978 [0.978, 0.979] |
| text | 1177.2 | 1100.9 | 0.942 [0.934, 0.950] | 0.941 [0.931, 0.950] | 0.992 [0.992, 0.992] |

## Release interpretation

Retained layout and fresh construction have different costs. A fast resized-layout mean cannot establish a construction win, and a confidence interval spanning 1 does not establish an improvement. Keep individual regressions visible when assessing the [performance targets](../Documentation/PerformancePlan.md).

The desktop suite does not establish request p95/p99, peak memory, hardware cache/branch behavior, Linux performance, or watch performance. See the separate [physical iPhone report](iPhoneResults.md) and [device/Linux validation](../Documentation/DeviceValidation.md). The [implementation review](../Documentation/PerformanceImplementation.md) records achieved targets and remaining work. See the [methodology](README.md) before repeating or extending the results.
