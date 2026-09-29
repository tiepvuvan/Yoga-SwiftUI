# Conformance and Performance

Understand the reference version, test coverage, and benchmark boundaries.

## Reference version

The port follows [React Yoga 3.2.1](https://github.com/react/yoga/tree/v3.2.1), commit `042f5013152eb81c1552dec945b88f7b95ca350f`. This is also the C++ version used by Yoga-SwiftUI 2.0. The generated conformance corpus includes all 548 upstream fixtures: 531 enabled cases and 17 cases disabled by upstream. Both `YogaTree` and `YogaNode` run every enabled fixture, making 31,712 geometry assertions, including left-to-right and right-to-left layouts.

The import script preserves disabled cases and fails on unrecognized statements rather than silently omitting them. Additional tests cover style value semantics, ownership, stale identifiers, storage growth and reuse, dirty propagation, content changes, baseline callbacks, rounded cache hits, display transitions, and reused-versus-fresh layouts after mutations. Release and Address Sanitizer test runs validate both public APIs.

The 38-test core and SwiftUI suite passes on macOS and a physical iPhone 16 Pro, including rendered-pixel checks and Address Sanitizer. The 26 core tests also pass on Linux aarch64 with Swift 6.4. The repository's [device validation guide](https://github.com/tiepvuvan/Yoga-SwiftUI/blob/main/Documentation/DeviceValidation.md) records the environment and reproduction commands.

This covers the generated layout corpus, rather than every upstream test or API. The native API implements modern flexbox behavior. Legacy errata switches, experimental feature switches, C ABI entry points, clone callbacks, logging, and upstream event hooks are not exposed. SwiftUI retains its own documented layout boundary around measured children.

## Reproducible benchmarks

The repository's [benchmark guide](https://github.com/tiepvuvan/Yoga-SwiftUI/blob/main/Benchmarks/README.md) contains commands, raw results, workload definitions, and limitations. Benchmarks live in a separate development package. Its C helper collects operating-system metrics; the C++ executable is only a reference process. Neither is a dependency of the libraries.

Before timing, the harness compares every node's positions, dimensions, resolved edges, direction, and overflow against C++. It also checks 128 deterministic mutation steps per case, including direction, display, positioning, and percentage changes. Numeric output must match after conversion to the original Float32 representation, with no epsilon tolerance.

A separate differential checks 140,000 pixel-rounding results against C++, including signed zero and extreme values. Results match bit for bit; NaNs are compared by classification.

Ten independent paired process trials use randomized engine order and calibrated batches. Reports separate construction plus layout, resized layout, style mutation, cached layout, and retained live heap. CPU time, hardware cycles, instructions, and wall time are recorded separately when available. The recorded C++ reference enables link-time optimization. Allocation checks run separately so instrumentation does not distort timing.

The SwiftUI comparison builds the same hosting-view workload against the pinned v2 commit and the native working tree, then checks rendered pixels. Its measurements include framework overhead.

The same core workload matrix also runs on a physical iPhone. That runner records thermal and power state, pauses between pairs, and accepts nominal or fair temperature while rejecting serious heat. Its [device report](https://github.com/tiepvuvan/Yoga-SwiftUI/blob/main/Benchmarks/iPhoneResults.md) uses CPU and wall time because hardware cycle counters are unavailable through the public iOS SDK. The end-to-end SwiftUI comparison remains a macOS experiment.

## Interpret the results

Prefer `YogaTree` and reuse its storage between updates. The contiguous store, borrowed style access, prepared child lists, and bounded caches reduce repeated work. Fresh construction and the reference-based `YogaNode` API have different costs, which the report keeps visible.

Performance depends on workload, cache reuse, callbacks, compiler, hardware, and allocator. Zero allocations in a warmed resize benchmark do not imply that construction, structural changes, first-time measurement, or application callbacks allocate nothing. Live retained heap is also different from peak memory or process RSS. Consult the [recorded results](https://github.com/tiepvuvan/Yoga-SwiftUI/blob/main/Benchmarks/Results.md) and remaining release targets before making a performance claim.
