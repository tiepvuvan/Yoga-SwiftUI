# Physical-device and Linux validation

Version 3 includes reproducible correctness and performance runners outside the production package. The core and SwiftUI products remain native Swift with no C++ dependency.

## Connected iPhone

Requirements: Xcode with Swift 6.4, a paired iPhone with Developer Mode enabled, a development signing identity, Python 3.12+, and Ruby with the `xcodeproj` gem. The project generator uses the installed gem; it does not add a dependency to the libraries. Keep the phone unlocked when installation or testing begins.

The development host also contains the pinned C++ comparator. Fetch and verify that development-only reference first, then list connected devices and use your development team ID:

```sh
xcrun devicectl list devices
python3 Scripts/benchmark.py --cpp-lto --verify-only
python3 Scripts/verify-device.py --device DEVICE_ID --team TEAM_ID \
  --reference Benchmarks/.build/reference/yoga
python3 Scripts/verify-device.py --device DEVICE_ID --team TEAM_ID \
  --reference Benchmarks/.build/reference/yoga --address-sanitizer
```

The generated host app runs the repository's existing XCTest files, including the complete upstream fixture interpreters. The same Core Graphics pixel checks run on macOS and iPhone. Test results remain in `.xcresult` bundles under `.build/device-tests`; the checked-in summary contains the production source digest and test counts.

The final revision passes all 38 tests on iPhone 16 Pro with iOS 27.0, in release and separate Address Sanitizer builds. This includes 26 core tests and 12 SwiftUI/API tests, including hidden-view rendering and hide/show transitions.

SwiftPM's tool-hosted tests cannot launch directly on physical iOS devices, so the script creates an ordinary development app and hosted test bundle. It may use Xcode's automatic development provisioning. It does not archive, upload, or submit the app.

Each source revision and test configuration gets its own build directory. Device benchmarking uses a separate directory as well. This avoids stale artifacts when SwiftPM changes between static and dynamic product linkage or a native class's private storage layout changes. A reused development build directory produced stale-code failures during validation; a fresh build of the identical source and a separate sanitizer build both passed.

The benchmark runner also fingerprints the compiled host inputs and compiler version. Installing a test host invalidates its benchmark installation marker, so `--skip-build` cannot silently measure a sanitizer app. The normal benchmark command always builds and installs the release host.

## Benchmark on iPhone

First make the pinned Yoga 3.2.1 reference available:

```sh
python3 Scripts/benchmark.py --cpp-lto --verify-only
```

Then run the physical-device comparison:

```sh
python3 Scripts/benchmark-device.py \
  --device DEVICE_ID --team TEAM_ID \
  --reference Benchmarks/.build/reference/yoga \
  --trials 10 --sizes 8,32,128 \
  --minimum-sample-ms 20 --minimum-iterations 100
python3 Scripts/benchmark-device-report.py
```

The runner verifies reference provenance, builds and installs a development app, and launches a fresh process for each engine/trial. Both engines use the same workload source as the desktop programs. The C++ reference is linked only into this validation app, through a small C entry point; the production products never import it.

Before timing, full geometry and mutation traces must match. A separate rounding check compares 140,000 results, including signed zero, extreme values, and all rounding modes. Timing uses equal iteration counts calibrated for each mode. Engine order is randomized within each trial pair. Construction, relayout, mutation, cached calls, and live heap remain separate results.

Each trial records thermal state and Low Power Mode. The runner pauses five seconds before each pair and waits for nominal or fair thermal state before calibration and every pair. Use `--maximum-start-thermal-state 0` to require nominal temperature instead. Cooling waits are outside timing and retained in the report. Serious/critical thermal state or Low Power Mode during a measured trial fails the run; let the phone cool or turn off Low Power Mode and repeat the complete run. No measured trials are selectively discarded. Partial checkpoints are clearly marked incomplete. Only untimed temperature checks retry transient device-transport failures.

Longer 100 ms attempts reached serious thermal state, including with cooling pauses. Nominal-only attempts either encountered an app-launch failure or stayed warm while waiting. Those attempts are excluded from the complete report. The recorded protocol uses shorter 20 ms batches, a minimum of 100 timed iterations, 100 warm-ups, and the same ten independent pairs. It allows recorded nominal/fair conditions with fixed cooling pauses and keeps the serious/critical rejection threshold intact. The entire matrix is restarted after an interrupted attempt; samples are never selected by their performance.

CPU cycles and instruction counters are unavailable through the public iOS SDK, so the report uses CPU time and elapsed time. Phone timings must not be described as hardware cycle measurements.

The [physical-device report](../Benchmarks/iPhoneResults.md) includes every case and confidence interval. `.xcresult` files and private device metadata stay in ignored build directories. Raw published measurements omit device serial numbers and identifiers.

Reports retain both the complete source snapshot and a separate native-core digest. Core benchmarks and Linux tests are validated against `Sources/Yoga`; SwiftUI benchmarks and full Mac/iPhone tests are validated against all production Swift source. The last visibility correction changed only SwiftUI, so the completed core measurements remain valid with their original snapshot identifiers. Run `python3 Scripts/validate-release-evidence.py` to check these scopes and report completeness.

## Linux Swift 6.4

Use the official Swift 6.4 Ubuntu 24.04 image with an immutable digest:

```sh
python3 Scripts/verify-linux.py
```

The script runs the native core suite with the checkout mounted read-only, networking disabled, and build artifacts in temporary container storage. It verifies that production source did not change during the run and saves [the result](../Benchmarks/results/linux.json) and [test log](../Benchmarks/results/linux.log). Docker must be installed and running; download the pinned official image first if it is not cached.

This validates Linux on the container's reported architecture. A Linux VM on Apple Silicon does not establish Linux x86_64 performance. SwiftUI remains an Apple-platform product.
