# Yoga-SwiftUI 3.0.0 release notes

Status: prepared for review; not tagged or published. The strict construction performance gate below remains open.

## Native Swift, two products

Version 3 replaces the C++ runtime dependency with a Swift 6.4 port of React Yoga 3.2.1.

- **Yoga** computes flexbox geometry using only the Swift standard library.
- **YogaSwiftUI** integrates the same engine with SwiftUI through `Flex`, `flex...` item modifiers, and `yoga...` container modifiers.

The core supports modern Yoga flexbox behavior, including wrapping, RTL, baselines, percentages, min/max sizing, absolute positioning, and `display: contents`. SwiftUI keeps its measured-child layout boundary. Legacy upstream errata switches and the C ABI are not exposed.

## Construction, layout, and memory

`YogaTree` owns contiguous storage and exposes checked node identifiers. Reused traversal buffers, compact style storage, consuming record initialization, and bounded caches reduce copying and allocation work. `YogaNode` remains available when individual reference ownership is useful.

On the declared 18-case Apple M4 Pro suite, compared with optimized C++ Yoga with full link-time optimization:

| Operation | Measured change |
| --- | ---: |
| Construction, layout, and destruction | 19.2% fewer CPU cycles |
| Resized layout | 44.8% fewer CPU cycles |
| Style mutation | 21.1% fewer CPU cycles |
| Unchanged cached layout | 7.2% fewer CPU cycles |
| Retained engine heap | 31.7% lower |

All 18 warmed resize cases record zero native allocations. The two smallest measured-content and absolute-positioning construction cases remain 0.9% and 2.6% slower, respectively. Detached `YogaNode` construction has additional costs and is reported separately.

On a physical iPhone 16 Pro, the same 18-case core suite uses 21.9% less CPU time for construction, 47.2% less for resizing, and 31.9% less retained heap. Ten paired trials complete at fair thermal state with Low Power Mode off. Hardware cycle counts are unavailable on iOS.

The macOS SwiftUI comparison renders identical pixels to v2. Shape and text layouts use 4.1% and 5.9% less CPU time, respectively, with smaller retained hosting-view heap. These measurements include framework overhead and the visibility fix.

See the [complete desktop results](../Benchmarks/Results.md), [physical-device report](../Benchmarks/iPhoneResults.md), and [methodology](../Benchmarks/README.md) for confidence intervals, every case, and limitations. These are measurements of declared workloads, not universal speed guarantees.

## Verified behavior

- All 531 enabled upstream generated fixtures pass through both core APIs: 31,712 geometry assertions. The 17 upstream-disabled cases remain explicitly identified.
- All 38 core and SwiftUI tests pass on macOS and a physical iPhone 16 Pro, including separate Address Sanitizer runs and rendered-pixel checks.
- All 26 core tests pass on Linux aarch64 with the pinned official Swift 6.4 image.
- A 140,000-result differential verifies pixel rounding against C++.
- Hidden SwiftUI children and containers no longer render through fallback placement; hide/show transitions have dedicated pixel regression tests.
- Generic iOS, tvOS, watchOS, and visionOS simulator builds pass. Both DocC catalogs compile with warnings treated as errors.

## Upgrade from v2

Use Swift 6.4 or later. Keep the `YogaSwiftUI` product for views, or choose `Yoga` for standalone layout. Remove C++ interoperability settings if this package was your only C++ dependency.

The modifier names and 0–100 percentage scale remain unchanged. Explicit `YG...` types become `Yoga...` types. `YogaDimension` now aliases the native `YogaValue` struct; replace enum pattern matching with its `unit` and `value` properties. The [migration guide](../Sources/YogaSwiftUI/YogaSwiftUI.docc/MigratingTo3.md) includes examples.

Apple deployment minima remain iOS 16, macOS 13, tvOS 16, watchOS 9, and visionOS 1. Both products have DocC catalogs configured for Swift Package Index hosting after publication.

## Open release gate

The original target requires at least 20% fewer construction cycles, including the upper 95% confidence bound. The current mean is 19.2% lower, with an upper ratio bound of 0.811 rather than the required 0.800. That criterion has not been relaxed. Review the [implementation record](PerformanceImplementation.md) and [release checklist](ReleaseChecklist.md) before tagging 3.0.0.
