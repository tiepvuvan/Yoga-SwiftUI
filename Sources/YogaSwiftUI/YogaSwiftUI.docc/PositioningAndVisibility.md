# Positioning and Visibility

Use Yoga positions and display rules for overlays and conditional layout.

## Absolute position

An absolutely positioned item does not consume space in the flex flow. Set its position type and at least one edge offset:

```swift
Flex {
    Text("Card content")
    Circle().fill(.red)
        .flexPositionType(.absolute)
        .flexWidth(.point(20))
        .flexHeight(.point(20))
        .flexPosition(.point(0), for: .top)
        .flexPosition(.point(0), for: .end)
}
```

Logical `.start` and `.end` edges follow layout direction. Use `.percent` for offsets relative to Yoga's containing block. `.relative` keeps an item's place in the flex flow while applying offsets; `.static` ignores those offsets.

## Visibility and overflow

Use `.flexDisplay(.none)` to remove an item from Yoga's layout and SwiftUI placement. `.flexDisplay(.flex)` restores it.

Use `.yogaOverflow(.hidden)` to clip a `Flex` container or `.flexOverflow(.hidden)` to clip a child. `.scroll` changes Yoga's layout overflow behavior but does not add a scrolling interaction. Wrap the content in SwiftUI's `ScrollView` when scrolling is required.

Yoga's `display: .contents` expects descendants to participate directly in an ancestor Yoga tree. SwiftUI presents each child to this package as one opaque measured leaf, so `.contents` cannot flatten arbitrary nested SwiftUI views. Use a nested `Flex` for a nested layout and keep `display` at `.flex` for that child.

See <doc:HowFlexWorks> for the layout model and <doc:SizingAndSpacing> for containing sizes.
