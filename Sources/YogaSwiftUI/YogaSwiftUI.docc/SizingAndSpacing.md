# Sizing and Spacing

Choose point, percentage, and automatic dimensions, then control free space with flex properties.

## Dimensions and percentages

`YogaDimension` has three cases: `.point`, `.percent`, and `.auto`. Percentages use Yoga's **0–100 scale**:

```swift
Text("Half width")
    .flexWidth(.percent(50))
    .flexMinWidth(.point(80))
```

`.percent(50)` means 50%, not 0.5%. A percentage needs a definite containing size along the relevant axis. When a parent proposes an unspecified or unbounded size, a percentage may not produce the size you expect; give the `Flex` container a definite frame or dimension when that relationship matters.

Use the corresponding `flex...` modifier for a child's width, height, and minimum or maximum dimension. Use `yoga...` dimension modifiers on the `Flex` container. A child's unspecified dimensions are measured from its SwiftUI content.

## Grow, shrink, and basis

`flexBasis` sets an item's initial size along the main axis. `flexGrow` distributes remaining space; `flexShrink` distributes a shortage. The package uses Yoga web defaults for unspecified style values.

```swift
Flex(direction: .row, columnGap: 8) {
    Text("Primary")
        .flexBasis(.point(100))
        .flexGrow(2)
        .flexShrink(1)
    Text("Secondary")
        .flexBasis(.point(80))
        .flexGrow(1)
        .flexShrink(1)
}
```

When a child must not shrink, set `.flexShrink(0)`. Use min/max dimensions when the child has a useful size limit.

## Gaps, margins, padding, and borders

A gap belongs to the container. Use the convenience `rowGap` and `columnGap` parameters for point gaps, or `yogaGap(_:for:)` for point or percentage values.

Margins belong to children. Padding and border widths reserve space inside a Yoga box. Edge values may be physical (`.left`, `.right`, `.top`, `.bottom`), logical (`.start` and `.end`), or grouped (`.horizontal`, `.vertical`, `.all`).

```swift
Flex {
    Text("Item")
        .flexMargin(.auto, for: .left)
        .flexPadding(.point(12), for: .horizontal)
        .flexBorder(1)
}
.yogaPadding(.point(16))
```

An automatic margin can absorb free space. Yoga's border width only affects layout; draw a visible border with SwiftUI.

## Aspect ratio and box sizing

Set `flexAspectRatio(_:)` on an item or `yogaAspectRatio(_:)` on a container when one dimension should follow the other. `flexBoxSizing(_:)` and `yogaBoxSizing(_:)` choose whether specified dimensions include padding and border (`.borderBox`) or describe only content (`.contentBox`).

For alignment after sizing, see <doc:AlignmentWrappingAndDirection>.
