# ``Yoga``

Compute flexbox layouts with a native Swift engine.

## Overview

Yoga is a Swift 6.4 port of React Yoga 3.2.1's modern flexbox behavior. It calculates boxes for an owned tree of nodes, independent of SwiftUI. The library uses the Swift standard library and has no external dependencies or C++ interoperability requirement.

Create a ``YogaTree``, attach children, and calculate its layout. Read each node's geometry with its ``YogaNodeID`` to position your own content. The tree stores nodes together and validates identifiers at public API boundaries. For SwiftUI views, choose the separate `YogaSwiftUI` product and its modifier-based `Flex` container.

```swift
import Yoga

let tree = YogaTree(configuration: .init(useWebDefaults: true))
let title = tree.appendChild(to: tree.root)
tree.updateStyle(of: title) {
    $0.width = .percent(50)
    $0.height = .point(24)
}
tree.calculateLayout(width: 320, height: 48)
print(tree.layout(of: title).width) // 160
```

The port is maintained by Yoga-SwiftUI and is not an official Meta release. The upstream MIT license and attribution are retained in `THIRD_PARTY_NOTICES.md`.

## Topics

### Learn the engine

- <doc:GettingStarted>
- <doc:LayoutRules>
- <doc:MeasuringContent>
- <doc:OwnershipAndCaching>
- <doc:ConformanceAndPerformance>

### Build a tree

- ``YogaTree``
- ``YogaNodeID``
- ``YogaNode``
- ``YogaConfiguration``
- ``YogaStyle``

### Read geometry

- ``YogaLayout``
- ``YogaSize``
- ``YogaInsets``
- ``YogaValue``
- ``YogaUnit``
- ``YogaMeasureMode``
- ``yogaRoundToPixelGrid(_:scale:forceCeil:forceFloor:)``

### Configure layout

- ``YogaDirection``
- ``YogaFlexDirection``
- ``YogaJustify``
- ``YogaAlign``
- ``YogaWrap``
- ``YogaEdge``
- ``YogaGutter``
- ``YogaPositionType``
- ``YogaDisplay``
- ``YogaOverflow``
- ``YogaBoxSizing``
