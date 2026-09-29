# Getting Started

Install the core and calculate a row without a UI framework.

## Choose a product

Version 3 requires Swift 6.4 or later. Add the package to your manifest, then choose `Yoga` for standalone layout:

```swift
.package(url: "https://github.com/tiepvuvan/Yoga-SwiftUI.git", from: "3.0.0")
```

```swift
.target(
    name: "YourTarget",
    dependencies: [.product(name: "Yoga", package: "Yoga-SwiftUI")]
)
```

The version requirement resolves once `v3.0.0` is published. Until then, use a local package dependency to evaluate the development checkout. The core uses only the Swift standard library; `YogaSwiftUI` is an additional product available when building Apple-platform clients on macOS. No consumer interoperability setting is required.

## Lay out two children

Build styles as local values when constructing many nodes. Passing a complete style when appending a child avoids repeated invalidation during setup. Reserve the expected total node count before a construction batch when it is known.

```swift
import Yoga

let configuration = YogaConfiguration(useWebDefaults: true, pointScaleFactor: 2)
var rowStyle = YogaStyle(useWebDefaults: true)
rowStyle.alignItems = .center
rowStyle.setGap(.point(12))
rowStyle.setPadding(.point(8), for: .all)
let tree = YogaTree(configuration: configuration, style: rowStyle, capacity: 3)

var titleStyle = YogaStyle(useWebDefaults: true)
titleStyle.flexGrow = 1
// A fixed intrinsic height; the flexible width uses the remaining row space.
titleStyle.height = .point(24)
let title = tree.appendChild(to: tree.root, style: titleStyle)
let accessory = tree.appendChild(to: tree.root)
tree.updateStyle(of: accessory) {
    $0.width = .point(40)
    $0.height = .point(24)
    $0.flexShrink = 0
}

tree.calculateLayout(width: 320, height: 48)
print(tree.layout(of: title), tree.layout(of: accessory))
// title: x = 8, y = 12, width = 252, height = 24
// accessory: x = 272, y = 12, width = 40, height = 24
```

Coordinates are relative to a node's layout parent. ``YogaLayout/width`` and ``YogaLayout/height`` describe its border box. Use the padding and border insets to derive its content box.

## Change a layout

```swift
tree.updateStyle(of: accessory) { $0.width = .point(56) }
tree.calculateLayout(width: 320, height: 48)
```

Changing a node's style invalidates its ancestors. Reuse trees across updates to benefit from measurement and layout caching. For text or other content with an intrinsic size, continue with <doc:MeasuringContent>.
