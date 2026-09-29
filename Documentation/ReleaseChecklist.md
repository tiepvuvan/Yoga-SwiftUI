# 3.0.0 release checklist

The native implementation is on `codex/native-yoga-3`. No release tag or hosted documentation publication is implied by a successful local build.

## Verified locally

- [x] Swift tools version 6.4 and Swift 6 language mode.
- [x] Standalone `Yoga` and Apple-platform `YogaSwiftUI` products.
- [x] Production graph contains only Swift targets, without remote dependencies or C++ interoperability settings.
- [x] All 531 enabled generated Yoga 3.2.1 fixtures pass through both core APIs (31,712 geometry assertions). The 17 upstream-disabled fixtures remain explicitly marked.
- [x] Release tests pass: 26 core tests, including both fixture interpreters, and 12 SwiftUI/API tests.
- [x] The same 38 tests pass under Address Sanitizer, without sanitizer errors.
- [x] All 38 tests pass on the connected iPhone 16 Pro running iOS 27.0, in release and Address Sanitizer builds, including rendered SwiftUI pixel checks.
- [x] All 26 core tests pass on Linux aarch64 in the pinned official Swift 6.4 Ubuntu 24.04 image.
- [x] Core regressions cover style values, tree lifetime, detached-node reuse, reparenting, dirty propagation, content invalidation, compatible measurements, percentage insets, rounding, display transitions, and baselines.
- [x] SwiftUI rendering tests include text updates, child placement, padding, gaps, absolute positioning, hidden children/containers, and hide/show transitions.
- [x] macOS tests and generic iOS, tvOS, watchOS, and visionOS Simulator builds succeed with the installed toolchain.
- [x] Both DocC catalogs compile with warnings treated as errors.
- [x] Both targets are listed in `.spi.yml`.
- [x] README, migration guide, changelog, attribution, and benchmark methodology are updated.
- [x] All 18 core cases match C++ full geometry at both tested widths and throughout 128-step mutation traces.
- [x] Pixel rounding matches C++ in 140,000 differential results, including signed zero and extreme values.
- [x] Ten independent paired benchmark trials, with C++ LTO and matching source hashes for each measured product across reports.
- [x] All 18 warmed resize allocation checks record zero native allocations.
- [x] SwiftUI rendered pixels match the pinned v2 implementation at both widths in every trial.

## Before publishing

- [ ] Review the native port and public core API as a major-version change.
- [ ] Review the complete [benchmark report](../Benchmarks/Results.md) and [implementation review](PerformanceImplementation.md). Resized core layout uses 45% fewer cycles, retained heap is 32% lower, and construction uses 19% fewer cycles overall. The strict 20% construction target remains unmet (upper ratio bound 0.811 versus 0.800). Resolve that gate or explicitly revise the release criterion; do not advertise a universal C++ speed advantage.
- [ ] Confirm acceptable performance on representative application layouts beyond the declared synthetic matrix and the two SwiftUI hosting-view workloads.
- [ ] Commit and push the reviewed changes.
- [ ] Confirm Swift Package Index has a Swift 6.4 builder and successfully hosts both documentation catalogs after publication.
- [ ] Tag the approved commit `v3.0.0` and publish release notes from the changelog, including the benchmark limitations.

## Reproduce the checks

```sh
swift test -c release
swift test -c debug --sanitize address --scratch-path .build/asan
xcodebuild docbuild -scheme Yoga-SwiftUI-Package \
  -destination 'generic/platform=macOS' \
  OTHER_DOCC_FLAGS=--warnings-as-errors CODE_SIGNING_ALLOWED=NO
xcodebuild build -scheme YogaSwiftUI \
  -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
python3 Scripts/benchmark.py --cpp-lto --trials 10 --sizes 8,32,128
python3 Scripts/benchmark-swiftui.py \
  --reference Benchmarks/.build/reference/yoga --iterations 1000 --trials 10
python3 Scripts/benchmark-report.py
python3 Scripts/verify-linux.py
python3 Scripts/verify-device.py --device DEVICE_ID --team TEAM_ID \
  --reference Benchmarks/.build/reference/yoga
python3 Scripts/verify-device.py --device DEVICE_ID --team TEAM_ID \
  --reference Benchmarks/.build/reference/yoga --address-sanitizer
python3 Scripts/benchmark-device.py --device DEVICE_ID --team TEAM_ID \
  --reference Benchmarks/.build/reference/yoga \
  --minimum-sample-ms 20 --minimum-iterations 100
python3 Scripts/benchmark-device-report.py
python3 Scripts/validate-release-evidence.py
```

The benchmark guide explains the separate development-only dependencies and how to preserve raw results. Run CPU benchmarks sequentially while the machine is otherwise idle.
