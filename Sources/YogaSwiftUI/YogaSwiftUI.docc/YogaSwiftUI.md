# ``YogaSwiftUI``

Build flexbox layouts in SwiftUI with Yoga.

## Overview

`Flex` is a SwiftUI layout container backed by [Yoga](https://github.com/react/yoga). It gives you Yoga's flex direction, wrapping, alignment, growth, spacing, sizing, and positioning while letting SwiftUI measure and draw each view.

Start with the convenience initializer for common rows and columns. Use `yoga...` modifiers on the container and `flex...` modifiers on its direct children for the rest of Yoga's layout properties.

```swift
Flex(direction: .row, justifyContent: .spaceBetween, alignItems: .center) {
    Text("Leading")
    Text("Trailing")
}
```

Yoga-SwiftUI requires Swift 6 and C++ interoperability. See <doc:GettingStarted> before adding it to an app.

## Topics

### Start here

- <doc:GettingStarted>
- <doc:HowFlexWorks>

### Build layouts

- <doc:ContainersAndItems>
- <doc:SizingAndSpacing>
- <doc:AlignmentWrappingAndDirection>
- <doc:PositioningAndVisibility>

### Upgrade and reference

- <doc:MigratingTo2>
- ``Flex``
- ``YogaDimension``

### Advanced API

- <doc:ModifierReference>
