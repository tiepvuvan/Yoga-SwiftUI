# Changelog

## 3.0.0 — Unreleased

- Require Swift 6.4 and replace the C++ runtime dependency with a native Swift port of React Yoga 3.2.1.
- Publish two libraries: `Yoga` for standalone layout and `YogaSwiftUI` for SwiftUI.
- Remove YogaBridge and consumer C++ interoperability requirements.
- Add `YogaTree` with contiguous storage and checked `YogaNodeID` handles, plus a reference-based `YogaNode` convenience API.
- Add value-type styles, measurement and baseline callbacks, dirty propagation, pixel rounding, and bounded caches.
- Borrow style fields inside layout, pack length units without reducing Float precision, prepare child traversal lists after structural changes, and reuse warmed layout storage.
- Reduce construction copies with consuming initialization, a small default storage reserve, direct child insertion, and deferred invalidation until first layout. Pack optional scalar presence without reducing Float precision and insert sparse edges in order.
- Preserve modifier-based SwiftUI styling and retain a `YogaTree` between measurement and placement.
- Fix hidden SwiftUI children and containers rendering through fallback placement, preserving view identity across hide/show transitions and disabling hidden interaction and accessibility.
- Replace public `YG*` types with `Yoga*` types; `YogaDimension` aliases the native `YogaValue`.
- Import all 548 generated upstream fixtures, with 531 enabled cases exercised through both core APIs and 31,712 geometry assertions. Add storage lifetime, stale identifier, mutation, cache, and rendering regressions; validate with Address Sanitizer.
- Match C++ fused arithmetic during flex distribution and include direction and overflow in benchmark conformance checks.
- Optimize pixel rounding while preserving signed zero and verify 140,000 differential results against C++.
- Add reproducible C++ core and pinned-v2 SwiftUI benchmarks with independent paired trials, confidence intervals, full geometry mutation traces, and separate allocation checks. Publish construction costs and remaining targets alongside improvements in retained layout.
- Add a core DocC catalog, v3 migration guide, and hosting configuration for both products.
- Add reproducible physical-iPhone tests and benchmarks with thermal controls, and Linux validation using a pinned Swift 6.4 image. All 38 core/SwiftUI tests pass on macOS and iPhone, including Address Sanitizer; all 26 core tests pass on Linux aarch64.

## 2.0.0

- Replace the Yoga fork with the official `react/yoga` 3.2.1 Swift package.
- Require Swift 6 and enable C++ interoperability for the library. Clients must enable C++ interoperability in their targets.
- Configure containers with `Flex` initializer options and `yoga...` modifiers, and direct children with `flex...` modifiers. The public API no longer requires constructing a style object.
- Expose Yoga's flexbox properties through these modifiers, including edge spacing, positioning, dimensions, display, overflow, box sizing, and aspect ratio.
- Measure SwiftUI children through Yoga's measure callbacks, including baseline alignment.
- Release Yoga nodes and configuration with the layout cache, and recalculate placement for the actual bounds.
- Correct percentage usage to Yoga's 0–100 scale.
- Add DocC guides, generated API documentation, and Swift Package Index hosting configuration.
- Declare tvOS 16+ and visionOS 1+ support, and display Swift Package Index compatibility badges.
