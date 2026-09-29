# Yoga-SwiftUI 3.0

[![Swift version compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ftiepvuvan%2FYoga-SwiftUI%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/tiepvuvan/Yoga-SwiftUI)
[![Platform compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Ftiepvuvan%2FYoga-SwiftUI%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/tiepvuvan/Yoga-SwiftUI)

Native Swift flexbox, with a standalone layout engine and a SwiftUI integration.

Version 3 ports [React Yoga 3.2.1](https://github.com/react/yoga/tree/v3.2.1) to **Swift 6.4**. Both libraries are implemented in Swift and have no external dependencies. SwiftUI clients keep the modifier-based API introduced in v2.

**Release status:** 3.0.0 is in development. The conformance suite passes; benchmark results and remaining performance work are recorded in [Benchmarks](Benchmarks/README.md). The version is not tagged yet.

## Two products

| Product | Use it for | Import |
| --- | --- | --- |
| **Yoga** | Computing flexbox geometry without a UI framework | `import Yoga` |
| **YogaSwiftUI** | Laying out SwiftUI views with `Flex` and modifiers | `import YogaSwiftUI` |

The core uses only the Swift standard library. The SwiftUI product supports iOS 16+, macOS 13+, tvOS 16+, watchOS 9+, and visionOS 1+. On non-macOS build hosts, the manifest exposes the standalone core and its tests.

## SwiftUI quick start

```swift
import SwiftUI
import YogaSwiftUI

struct Example: View {
    var body: some View {
        Flex(
            direction: .row,
            justifyContent: .spaceBetween,
            alignItems: .center,
            columnGap: 12
        ) {
            Text("A flexible title")
                .flexWidth(.percent(50))
                .flexGrow(1)
                .flexShrink(1)
            Button("Edit") {}
                .flexShrink(0)
        }
    }
}
```

Use `yoga...` modifiers on a `Flex` container and `flex...` modifiers on its direct children. You do not construct a style object to use SwiftUI. Percentages use Yoga's **0–100 scale**: `.percent(50)` means 50%.

```swift
Flex(direction: .row, wrap: .wrap) {
    Text("One").flexBasis(.percent(50)).flexShrink(0)
    Text("Two").flexMargin(.auto, for: .start)
}
.yogaGap(.point(8), for: .column)
.yogaPadding(.point(16))
```

## Standalone core

```swift
import Yoga

let tree = YogaTree(configuration: .init(useWebDefaults: true))
let child = tree.appendChild(to: tree.root)
tree.updateStyle(of: child) {
    $0.width = .percent(50)
    $0.height = .point(24)
}

tree.calculateLayout(width: 320, height: 48)
print(tree.layout(of: child).width) // 160
```

`YogaTree` owns contiguous node storage; `YogaNodeID` identifies a node without allocating an object for it. Reuse a tree between layout passes. Style changes automatically invalidate ancestors; call `tree.markDirty(child)` when measured content changes. Keep each mutable tree on one actor or thread. Styles and output geometry are `Sendable` values. A reference-based `YogaNode` API is also available for applications that need individual node ownership.

## Installation

Use a **Swift 6.4 or newer** toolchain. Add the repository in Xcode and select a product, or use SwiftPM:

```swift
.package(url: "https://github.com/tiepvuvan/Yoga-SwiftUI.git", from: "3.0.0")
```

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "YogaSwiftUI", package: "Yoga-SwiftUI")
        // Choose "Yoga" instead for the standalone engine.
    ]
)
```

The version requirement becomes available after the `v3.0.0` tag is published. Use a local package dependency while evaluating this development checkout. Upgrading from v2? Remove `.interoperabilityMode(.Cxx)` if this was your target's only C++ dependency. The libraries no longer require a C++ toolchain or interoperability settings.

## Layout coverage

The native core supports Yoga's modern flexbox properties: directions and RTL, wrapping, justification, alignment and baselines, grow/shrink/basis, dimensions and min/max bounds, aspect ratio, gaps, margins and auto margins, padding, borders, relative/static/absolute positioning, display, overflow, and box sizing. Core `display: .contents` flattens layout participation while retaining node ownership.

Every direct SwiftUI child is a measured Yoga leaf. Nested `Flex` views remain separate SwiftUI layouts. Borders reserve space without drawing, scrolling needs a `ScrollView`, and `.contents` cannot flatten arbitrary SwiftUI descendants. See [How Flex Works](Sources/YogaSwiftUI/YogaSwiftUI.docc/HowFlexWorks.md).

## Correctness and performance

- **531 enabled upstream fixtures run through both core APIs**, with **31,712 geometry assertions**; all 17 upstream-disabled cases are retained and identified.
- Native tests cover ownership, cache invalidation, style mutations, baselines, rounding, and display transitions. SwiftUI tests verify rendered placement.
- All 38 core and SwiftUI tests pass on macOS and a physical iPhone 16 Pro, including Address Sanitizer. The 26 core tests pass on Linux aarch64 with Swift 6.4. See [device and Linux validation](Documentation/DeviceValidation.md).
- Separate benchmarks compare identical trees against pinned C++ Yoga 3.2.1 and identical SwiftUI views against the v2 commit.
- Benchmarks separate construction, resized layout, mutations, unchanged layouts, and retained heap. They use ten independent paired trials against optimized C++ with LTO, verify full geometry and mutation traces, and check warmed allocations separately. Read the [recorded results](Benchmarks/Results.md) for gains, regressions, and remaining release targets.
- The same core matrix runs on the [physical iPhone](Benchmarks/iPhoneResults.md), with recorded thermal state and cooling between trials. A separate 140,000-case differential verifies pixel rounding against C++.

```sh
swift test
python3 Scripts/benchmark.py --cpp-lto
```

The C++ reference and metrics helper are development-only tools outside the libraries' dependency graph. This port implements modern layout behavior, without legacy errata switches or the upstream C ABI.

## Documentation

Both products have DocC catalogs, configured for Swift Package Index hosting after publication:

- [Core documentation](https://swiftpackageindex.com/tiepvuvan/yoga-swiftui/main/documentation/yoga)
- [SwiftUI documentation](https://swiftpackageindex.com/tiepvuvan/yoga-swiftui/main/documentation/yogaswiftui)
- [Documentation index and local build instructions](Documentation/README.md)

| Learn about | Guide |
| --- | --- |
| A standalone layout tree | [Core Getting Started](Sources/Yoga/Yoga.docc/GettingStarted.md) |
| Text measurement and baselines | [Measuring Content](Sources/Yoga/Yoga.docc/MeasuringContent.md) |
| Tree lifetime, concurrency, and caching | [Ownership and Caching](Sources/Yoga/Yoga.docc/OwnershipAndCaching.md) |
| Your first SwiftUI layout | [SwiftUI Getting Started](Sources/YogaSwiftUI/YogaSwiftUI.docc/GettingStarted.md) |
| Container and item styling | [Containers and Items](Sources/YogaSwiftUI/YogaSwiftUI.docc/ContainersAndItems.md) |
| Every SwiftUI modifier | [Modifier Reference](Sources/YogaSwiftUI/YogaSwiftUI.docc/ModifierReference.md) |
| Upgrade from v2 | [Migrating to 3.0](Sources/YogaSwiftUI/YogaSwiftUI.docc/MigratingTo3.md) |

## License and attribution

Available under the [MIT License](LICENSE). The Swift port is maintained by this project and is not an official Meta release. Algorithms and conformance fixtures derive from Yoga, © Meta Platforms, Inc. and affiliates. See [third-party notices](THIRD_PARTY_NOTICES.md) for the reference commit and complete upstream license.
