# Modifier Reference

Choose a container setting on ``Flex`` or an item setting on a direct child. `yoga...` methods return `Flex`, so apply them before general SwiftUI modifiers such as `.background(_:)`. `flex...` methods attach SwiftUI layout values to the child.

```swift
Flex(direction: .row, justifyContent: .spaceBetween) {
    Text("Half width")
        .flexWidth(.percent(50))
        .flexShrink(0)
}
.yogaPadding(.point(16))
```

## Container modifiers

The `Flex` initializer covers direction, justification, item and line alignment, wrapping, and point-based row and column gaps. Additional container methods include:

| Purpose | Modifiers |
| --- | --- |
| Direction and alignment | `yogaLayoutDirection(_:)`, `yogaFlexDirection(_:)`, `yogaJustifyContent(_:)`, `yogaAlignItems(_:)`, `yogaAlignContent(_:)`, `yogaWrap(_:)` |
| Spacing and border | `yogaGap(_:for:)`, `yogaPadding(_:for:)`, `yogaBorder(_:for:)` |
| Dimensions | `yogaWidth(_:)`, `yogaHeight(_:)`, `yogaMinWidth(_:)`, `yogaMaxWidth(_:)`, `yogaMinHeight(_:)`, `yogaMaxHeight(_:)`, `yogaAspectRatio(_:)` |
| Box behavior | `yogaOverflow(_:)`, `yogaDisplay(_:)`, `yogaBoxSizing(_:)` |

`yogaGap(_:)` applies to both row and column gaps. Pass a Yoga gutter to change just one axis. Modifiers applied later override the same container property set earlier, including initializer values.

## Item modifiers

Apply these methods to a direct child of `Flex`:

| Purpose | Modifiers |
| --- | --- |
| Flex sizing | `flexBasis(_:)`, `flexGrow(_:)`, `flexShrink(_:)`, `flexFactor(_:)` |
| Dimensions | `flexWidth(_:)`, `flexHeight(_:)`, `flexMinWidth(_:)`, `flexMaxWidth(_:)`, `flexMinHeight(_:)`, `flexMaxHeight(_:)`, `flexAspectRatio(_:)` |
| Alignment and direction | `flexAlignSelf(_:)`, `flexLayoutDirection(_:)` |
| Edges and position | `flexMargin(_:for:)`, `flexPadding(_:for:)`, `flexBorder(_:for:)`, `flexPositionType(_:)`, `flexPosition(_:for:)` |
| Box behavior | `flexDisplay(_:)`, `flexOverflow(_:)`, `flexBoxSizing(_:)` |

`flexFactor(_:)` exposes Yoga's nonstandard `flex` shorthand. Positive values affect grow and negative values affect shrink. Prefer explicit grow, shrink, and basis modifiers when their intent matters independently.

For edge modifiers, `.all`, `.horizontal`, and `.vertical` provide grouped values. Physical edges and logical `.start` and `.end` can provide more specific values; Yoga resolves edge precedence. Yoga border widths affect layout but do not draw a line.

For examples, continue with <doc:ContainersAndItems>, <doc:SizingAndSpacing>, and <doc:PositioningAndVisibility>.
