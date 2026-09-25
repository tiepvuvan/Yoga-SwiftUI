# Yoga-SwiftUI

Flexbox layout for SwiftUI, powered by the [official Yoga engine](https://github.com/react/yoga).

Yoga-SwiftUI gives SwiftUI views Yoga's layout rules while SwiftUI continues to measure and render their content. Configure a `Flex` container with initializer options and `yoga...` modifiers. Configure its direct children with `flex...` modifiers.

## At a glance

- **SwiftUI native:** a custom `Layout` for iOS 16+, macOS 13+, and watchOS 9+.
- **Official Yoga dependency:** pinned to the upstream 3.2.1 release.
- **Broad Yoga style coverage:** direction, wrapping, alignment, grow/shrink/basis, dimensions, edges, positioning, display, overflow, and box sizing, without constructing a style object.
- **Swift 6:** uses Swift/C++ interoperability and a C++20 toolchain.

## Quick start

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

A `Flex` arranges its direct children. Container options such as `justifyContent` belong on `Flex`; item options such as `flexGrow` belong on a direct child. Percentages use Yoga's **0–100 scale**: `.percent(50)` means 50%.

## Installation

Add `https://github.com/tiepvuvan/Yoga-SwiftUI.git` in Xcode, or declare the package in `Package.swift`:

```swift
.package(
    url: "https://github.com/tiepvuvan/Yoga-SwiftUI.git",
    from: "2.0.0"
)
```

Every consuming target must enable C++ interoperability:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "YogaSwiftUI", package: "Yoga-SwiftUI")
    ],
    swiftSettings: [.interoperabilityMode(.Cxx)]
)
```

In an Xcode app target, set **C++ and Objective-C Interoperability** to **C++ / Objective-C++**. This is a [Swift requirement for targets that depend on C++ interoperable packages](https://www.swift.org/documentation/cxx-interop/project-build-setup/). The `2.0.0` version requirement will resolve after the `v2.0.0` Git tag is published.

## Documentation

The [documentation guide](Documentation/README.md) links to task-focused articles covering installation, layout, sizing, alignment, positioning, and migration. The same articles and generated API reference are configured for the [Swift Package Index documentation site](https://swiftpackageindex.com/tiepvuvan/yoga-swiftui/main/documentation/yogaswiftui).

| Learn about | Guide |
| --- | --- |
| Install and build a first layout | [Getting Started](Sources/YogaSwiftUI/YogaSwiftUI.docc/GettingStarted.md) |
| Container and child styling | [Containers and Items](Sources/YogaSwiftUI/YogaSwiftUI.docc/ContainersAndItems.md) |
| Percentages, flex sizing, gaps, and edges | [Sizing and Spacing](Sources/YogaSwiftUI/YogaSwiftUI.docc/SizingAndSpacing.md) |
| Wrapping, alignment, and RTL | [Alignment, Wrapping, and Direction](Sources/YogaSwiftUI/YogaSwiftUI.docc/AlignmentWrappingAndDirection.md) |
| Absolute positions and visibility | [Positioning and Visibility](Sources/YogaSwiftUI/YogaSwiftUI.docc/PositioningAndVisibility.md) |
| Every container and item modifier | [Modifier Reference](Sources/YogaSwiftUI/YogaSwiftUI.docc/ModifierReference.md) |
| Upgrade from 1.x | [Migrating to 2.0](Sources/YogaSwiftUI/YogaSwiftUI.docc/MigratingTo2.md) |

## More Yoga properties

```swift
Flex(direction: .row, wrap: .wrap) {
    Text("One")
        .flexBasis(.percent(50))
        .flexGrow(1)
        .flexMargin(.auto, for: .start)
    Text("Two")
}
.yogaGap(.point(8), for: .column)
.yogaPadding(.point(16))
```

`yoga...` modifiers configure the `Flex` container. `flex...` modifiers set layout values on direct children. Use `.flexWidth(.percent(50))` for a Yoga width; SwiftUI's `.frame(width:)` has different layout behavior.

Each direct SwiftUI child is a measured Yoga leaf. Nested `Flex` views work as nested SwiftUI layouts; they are not one shared Yoga tree. Yoga border widths reserve space without drawing a line, scrolling needs a SwiftUI `ScrollView`, and `display: .contents` cannot flatten arbitrary SwiftUI descendants. See [How Flex Works](Sources/YogaSwiftUI/YogaSwiftUI.docc/HowFlexWorks.md) for the layout model and its limits.

## License

Yoga-SwiftUI is available under the [MIT License](LICENSE). Yoga is © Meta Platforms, Inc. and [MIT licensed](https://github.com/react/yoga/blob/main/LICENSE).
