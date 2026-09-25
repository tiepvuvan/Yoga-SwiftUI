# Containers and Items

Configure a `Flex` container with its initializer and `yoga...` modifiers. Use `flex...` modifiers on direct children.

## Configure a container

The convenience initializer accepts flex direction, justification, alignment, wrapping, and row and column gaps:

```swift
Flex(
    direction: .row,
    justifyContent: .spaceBetween,
    alignItems: .center,
    wrap: .wrap,
    rowGap: 8,
    columnGap: 12
) {
    Text("One")
    Text("Two")
    Text("Three")
}
```

Chain container modifiers for properties such as padding, percentage gaps, or box sizing:

```swift
Flex(direction: .row, alignItems: .center, wrap: .wrap) {
    Text("One")
    Text("Two")
}
.yogaGap(.percent(5), for: .column)
.yogaPadding(.point(16))
.yogaBoxSizing(.borderBox)
```

Container modifiers return `Flex`, so apply them before general SwiftUI modifiers such as `.background(_:)`. They override the matching initializer value. Yoga's web defaults apply to other properties.

## Configure a direct child

The short modifiers suit individual item properties:

```swift
Flex(direction: .row, columnGap: 8) {
    Text("Flexible")
        .flexGrow(1)
        .flexShrink(1)
    Text("Fixed")
        .flexShrink(0)
}
```

Chain modifiers when a child needs several properties:

```swift
Flex {
    Text("Styled item")
        .flexGrow(1)
        .flexBasis(.point(100))
        .flexMinWidth(.point(60))
        .flexAlignSelf(.center)
        .flexMargin(.point(8), for: .start)
}
```

Child modifiers act only when the view is a direct child of `Flex`. Container properties such as justification and wrapping belong on `Flex` itself; a plain child is a measured Yoga leaf. See <doc:ModifierReference> for the complete modifier list.

For values and percentage rules, see <doc:SizingAndSpacing>. For the meaning of a direct child, see <doc:HowFlexWorks>.
