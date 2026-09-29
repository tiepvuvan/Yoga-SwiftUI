# Measuring Content

Provide intrinsic sizes and baselines for text, images, or custom content.

## Measurement constraints

A measured node must be a leaf. Yoga supplies the available content-box width and height, excluding padding and borders, with an independent mode on each axis:

| Mode | Meaning |
| --- | --- |
| `.undefined` | Measure the natural size; the numeric constraint is NaN. |
| `.atMost` | Fit within the supplied limit. |
| `.exactly` | Use the supplied size. |

Return finite, nonnegative dimensions. The callback may be skipped when both dimensions are exact, or when a compatible cached measurement exists.

```swift
let tree = YogaTree()
let image = tree.appendChild(to: tree.root)
tree.setMeasure(for: image) { width, widthMode, height, heightMode in
    let natural = YogaSize(width: 80, height: 40)
    func fit(_ value: Float, _ limit: Float, _ mode: YogaMeasureMode) -> Float {
        switch mode {
        case .undefined: value
        case .atMost: min(value, limit)
        case .exactly: limit
        }
    }
    return YogaSize(width: fit(natural.width, width, widthMode),
                    height: fit(natural.height, height, heightMode))
}
```

Text callbacks should measure wrapping under the proposed width. They should not assume a fixed call order or one invocation per layout pass.

## Baselines

`setBaseline(for:_:)` supplies the resolved box and its measured width and height. Return the baseline's distance from the top of the border box. For text, include top padding and borders in that offset. For example, content with a baseline ten points below its content-box top can use:

```swift
tree.setBaseline(for: image) { layout, _, _ in
    layout.border.top + layout.padding.top + 10
}
```

Without a callback, Yoga derives a baseline from the first suitable child or the node's height. Use `setReferenceBaseline(_:for:)` to select a child and `alignItems: .baseline` on a row to align siblings. The reference-based `YogaNode` API offers equivalent `measure` and `baseline` properties whose callbacks also receive the node.

## Content changes

When content changes without a style change, invalidate the measured leaf before calculating again:

```swift
tree.markDirty(image)
tree.calculateLayout(width: 320)
```

Callbacks must return consistent measurements for unchanged content and compatible constraints. Keep content measurement on the tree's actor or thread; UIKit, AppKit, and SwiftUI measurement generally belongs on the main actor. A callback may read layout state but must not mutate or reenter the tree. Avoid strongly capturing the tree in a callback it owns.
