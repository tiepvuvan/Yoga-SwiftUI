# Getting Started

Install Yoga-SwiftUI and make your first flex layout.

## Requirements

Yoga-SwiftUI 3.0 supports iOS 16+, macOS 13+, tvOS 16+, watchOS 9+, and visionOS 1+. It requires Swift 6.4 or later. Both the layout engine and SwiftUI integration are native Swift, with no external dependencies.

## Add the package

In Xcode, add `https://github.com/tiepvuvan/Yoga-SwiftUI.git` as a package dependency and select the `YogaSwiftUI` library.

In a package manifest, add the repository and select your target's product:

```swift
dependencies: [
    .package(
        url: "https://github.com/tiepvuvan/Yoga-SwiftUI.git",
        from: "3.0.0"
    )
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "YogaSwiftUI", package: "Yoga-SwiftUI")
        ]
    )
]
```

If upgrading from v2, remove this package's C++ interoperability setting. Choose the separate `Yoga` product when you need standalone layout geometry without SwiftUI.

> Important: The `from: "3.0.0"` requirement becomes available after the v3.0.0 tag is published. Use a local package dependency to evaluate the development checkout.

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
