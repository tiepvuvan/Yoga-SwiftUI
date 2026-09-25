# Getting Started

Install Yoga-SwiftUI and make your first flex layout.

## Requirements

Yoga-SwiftUI 2.0 supports iOS 16+, macOS 13+, and watchOS 9+. It requires Swift 6 and a C++20-capable toolchain. Each client target that imports or depends on `YogaSwiftUI` must enable Swift/C++ interoperability.

## Add the package

In Xcode, add `https://github.com/tiepvuvan/Yoga-SwiftUI.git` as a package dependency and select the `YogaSwiftUI` library.

In a package manifest, add the repository and enable interoperability on your target:

```swift
dependencies: [
    .package(
        url: "https://github.com/tiepvuvan/Yoga-SwiftUI.git",
        from: "2.0.0"
    )
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "YogaSwiftUI", package: "Yoga-SwiftUI")
        ],
        swiftSettings: [.interoperabilityMode(.Cxx)]
    )
]
```

In an Xcode app target, set **C++ and Objective-C Interoperability** to **C++ / Objective-C++**. A consumer target must opt in because [Swift requires C++ interoperability throughout the dependency chain](https://www.swift.org/documentation/cxx-interop/project-build-setup/).

> Important: The `from: "2.0.0"` requirement becomes available after the v2.0.0 tag is published.

## Create a row

Import the library and place views inside `Flex`. The values on the container control the placement of its direct children.

```swift
import SwiftUI
import YogaSwiftUI

struct ToolbarRow: View {
    var body: some View {
        Flex(
            direction: .row,
            justifyContent: .spaceBetween,
            alignItems: .center,
            columnGap: 12
        ) {
            Text("Today")
            Button("Add") {}
        }
    }
}
```

## Grow an item

A modifier on a direct child supplies an item property to Yoga. Here the text takes remaining width and can shrink when space is tight.

```swift
Flex(direction: .row, alignItems: .center, columnGap: 12) {
    Text("A title that can use the available width")
        .flexGrow(1)
        .flexShrink(1)
    Button("Edit") {}
        .flexShrink(0)
}
```

To use margins, padding, percentages, positioning, and the other Yoga styles, continue with <doc:ContainersAndItems> and <doc:SizingAndSpacing>.
