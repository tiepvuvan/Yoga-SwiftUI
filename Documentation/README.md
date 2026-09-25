# Documentation

Yoga-SwiftUI's guides live in the [`YogaSwiftUI.docc` catalog](../Sources/YogaSwiftUI/YogaSwiftUI.docc). DocC combines those articles with public Swift symbols to make a searchable documentation site. The [Swift Package Index documentation page](https://swiftpackageindex.com/tiepvuvan/yoga-swiftui/main/documentation/yogaswiftui) is the hosted entry point after the repository changes are published and indexed.

## Start here

1. [Getting Started](../Sources/YogaSwiftUI/YogaSwiftUI.docc/GettingStarted.md) — requirements, installation, and a first row.
2. [How Flex Works](../Sources/YogaSwiftUI/YogaSwiftUI.docc/HowFlexWorks.md) — the Yoga and SwiftUI layout boundary.
3. [Containers and Items](../Sources/YogaSwiftUI/YogaSwiftUI.docc/ContainersAndItems.md) — configure a container and its direct children.

## Layout guides

- [Sizing and Spacing](../Sources/YogaSwiftUI/YogaSwiftUI.docc/SizingAndSpacing.md)
- [Alignment, Wrapping, and Direction](../Sources/YogaSwiftUI/YogaSwiftUI.docc/AlignmentWrappingAndDirection.md)
- [Positioning and Visibility](../Sources/YogaSwiftUI/YogaSwiftUI.docc/PositioningAndVisibility.md)
- [Migrating to 2.0](../Sources/YogaSwiftUI/YogaSwiftUI.docc/MigratingTo2.md)
- [Modifier Reference](../Sources/YogaSwiftUI/YogaSwiftUI.docc/ModifierReference.md) — every public container and item modifier.

## Build the documentation locally

Open the package in Xcode and choose **Product > Build Documentation**, or run:

```sh
xcodebuild docbuild -scheme Yoga-SwiftUI -destination 'generic/platform=macOS'
```

Xcode creates a `YogaSwiftUI.doccarchive` that you can inspect in its documentation viewer. The root [`.spi.yml`](../.spi.yml) asks Swift Package Index to build and host documentation for the `YogaSwiftUI` target. The index already lists the package and will refresh its default-branch documentation after the changes are pushed. A published `v2.0.0` tag supplies versioned package resolution.
