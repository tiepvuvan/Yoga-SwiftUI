# Layout Rules

Choose dimensions, alignment, spacing, and positioning using Yoga's flexbox rules.

## Defaults

``YogaConfiguration`` defaults to Yoga's non-web configuration: column direction, `alignContent: .flexStart`, and a zero shrink factor. `useWebDefaults: true` selects row direction, stretched line alignment, and a shrink factor of one. Both configurations use relative positioning and border-box sizing. When providing your own style at initialization, construct it with the same `useWebDefaults` choice.

The SwiftUI `Flex` convenience initializer chooses its own familiar defaults: row direction and start alignment for items and lines.

## Property coverage

| Intent | Core API |
| --- | --- |
| Flow and writing direction | `flexDirection`, `direction`, `wrap` |
| Distribute and align children | `justifyContent`, `alignItems`, `alignContent`, `alignSelf` |
| Flexible sizing | `flexGrow`, `flexShrink`, `flexBasis`, `flex` |
| Dimensions | `width`, `height`, `minWidth`, `minHeight`, `maxWidth`, `maxHeight`, `aspectRatio` |
| Spacing | `setGap`, `setMargin`, `setPadding`, `setBorder` |
| Positioning | `positionType`, `setPosition`, `alwaysFormsContainingBlock` on the node |
| Box behavior | `boxSizing`, `overflow`, `display` |
| Intrinsic content and baselines | `measure`, `baseline`, `isReferenceBaseline` on the node |

## Lengths and edges

`.point(12)` is twelve layout units. `.percent(50)` is fifty percent, using the 0–100 scale. `.auto` requests automatic sizing or margins where supported. `.undefined` removes an explicit value so grouped edge fallbacks can apply. Nonfinite inputs to `.point` and `.percent` become `.undefined`.

Logical `.start` and `.end` edges follow the layout direction. More specific overrides take precedence over `.horizontal`, `.vertical`, and `.all`. Margins and padding expressed as percentages use the owner's width, including top and bottom edges. Gap percentages follow their corresponding axis.

Use `YogaValue.unit` and `YogaValue.value` to inspect a length. Auto and undefined lengths have no numeric layout size; their stored scalar is zero.

## Sizing and overflow

Yoga resolves flex bases, groups items into lines, distributes free space, applies min/max constraints, and then aligns the resulting boxes. A definite width on a shrinking child can become smaller; use `flexShrink = 0` to preserve it. `boxSizing: .contentBox` adds padding and borders outside declared dimensions.

`overflow` changes sizing rules and ``YogaLayout/hadOverflow`` reports overflow. The core never clips, scrolls, or draws. Those are responsibilities of your rendering layer.

## Absolute, static, and contents nodes

Absolute nodes do not participate in normal flex flow. Their offsets resolve against a containing block. Static nodes do not apply relative offsets or establish containing blocks unless `alwaysFormsContainingBlock` is enabled. The root always acts as a containing block.

`display: .none` clears the node and descendant layouts. `display: .contents` keeps ownership intact while promoting descendants into the parent's flex flow. A contents node has a zero box; promoted children's coordinates use the effective layout parent.

## Rounding

`pointScaleFactor` is physical pixels per layout unit: use `2` for half-point alignment or `0` to disable rounding. Measured content uses Yoga's text rounding rules to avoid truncating content. Calculations use `Float`, with `Double` intermediates for pixel rounding, matching the reference engine's precision model.
