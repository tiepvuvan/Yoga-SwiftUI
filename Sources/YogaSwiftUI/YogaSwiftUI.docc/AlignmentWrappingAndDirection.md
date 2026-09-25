# Alignment, Wrapping, and Direction

Place items along the main axis, align them across it, and adapt rows for right-to-left interfaces.

## Main and cross axes

`flexDirection` chooses the main axis. In a row, `justifyContent` distributes horizontal space and `alignItems` controls vertical alignment. In a column, those roles rotate with the axes. Use `alignSelf` on a child to override the container's cross-axis alignment.

```swift
Flex(
    direction: .row,
    justifyContent: .spaceBetween,
    alignItems: .center
) {
    Text("Leading")
    Text("Trailing").flexAlignSelf(.flexEnd)
}
```

`alignContent` controls the spacing between wrapped lines when the container has extra room on its cross axis. It does not replace `alignItems` for alignment within one line.

## Wrapping

Set `wrap: .wrap` to allow items to continue on another line. `rowGap` separates rows, while `columnGap` separates items in the row.

```swift
Flex(
    direction: .row,
    wrap: .wrap,
    rowGap: 8,
    columnGap: 8
) {
    ForEach(["Swift", "Yoga", "Layout"], id: \.self) { tag in
        Text(tag)
            .padding(6)
            .background(.quaternary)
    }
}
```

Yoga also supports `.wrapReverse`, `.rowReverse`, and `.columnReverse` through its enum values. A finite container width is usually needed to observe wrapping.

## Right-to-left layout

`Flex` reads SwiftUI's `layoutDirection` environment and passes it to Yoga. Prefer logical edges such as `.start` and `.end` when adding margins or position offsets so they follow the interface direction.

```swift
Flex(direction: .row) {
    Text("Localized item")
        .flexMargin(.point(12), for: .start)
}
```

Set `yogaLayoutDirection(_:)` on `Flex` only when the Yoga layout should intentionally differ from SwiftUI's environment. Yoga's `.baseline` alignment uses SwiftUI's first text baseline for measured children.
