# Migrating to 3.0

Move to Swift 6.4 and the native layout engine.

## Toolchain and dependencies

Use Swift 6.4 or later. Keep `YogaSwiftUI` as your SwiftPM product for views. Choose the new `Yoga` product for standalone layout calculations.

Remove `.interoperabilityMode(.Cxx)` from consuming targets if Yoga-SwiftUI was their only C++ dependency. In Xcode, reset the equivalent C++ interoperability build setting unless another dependency needs it. Remove direct `YogaBridge` or upstream `yoga` imports used only with this package. Version 3 has no external runtime dependencies.

The Apple deployment minima remain iOS 16, macOS 13, tvOS 16, watchOS 9, and visionOS 1. A `from: "3.0.0"` dependency resolves after the release tag is published.

## SwiftUI modifiers stay familiar

```swift
Flex(direction: .row, wrap: .wrap) {
    Text("A title")
        .flexWidth(.percent(50))
        .flexShrink(0)
}
.yogaGap(.point(12))
```

The `flex...` and `yoga...` modifier names and the 0–100 percentage scale are unchanged. SwiftUI callers still do not need to initialize a style object. Most code using inferred enum cases continues to compile.

## Replace explicit C++ types

| Version 2 | Version 3 |
| --- | --- |
| `YGDirection` | `YogaDirection` |
| `YGFlexDirection` | `YogaFlexDirection` |
| `YGJustify`, `YGAlign` | `YogaJustify`, `YogaAlign` |
| `YGWrap`, `YGEdge`, `YGGutter` | `YogaWrap`, `YogaEdge`, `YogaGutter` |
| `YGDisplay`, `YGOverflow` | `YogaDisplay`, `YogaOverflow` |
| `YGPositionType`, `YGBoxSizing` | `YogaPositionType`, `YogaBoxSizing` |
| `YGValue` inputs | `YogaValue` or `YogaDimension` |

Import `Yoga` when explicitly naming core types. `.LTR` and `.RTL` remain convenience aliases; new code can use `.leftToRight` and `.rightToLeft`.

`YogaDimension` is now a type alias for the native `YogaValue` struct. `.point(12)`, `.percent(50)`, and `.auto` keep their construction syntax. Code that pattern-matched the old enum must inspect `unit` and `value` instead:

```swift
let width = YogaDimension.percent(50)
if width.unit == .percent {
    print(width.value) // 50
}
```

The overload accepting upstream `YGValue` is removed. Use `YogaValue` explicitly to resolve any ambiguous overloads.

## Layout and performance

The reference remains Yoga 3.2.1 with modern layout behavior. The native port passes the enabled generated reference fixtures, while ownership and cache behavior follow Swift conventions. It does not expose the upstream C API or legacy errata switches.

The SwiftUI cache owns a `YogaTree`, retaining node identifiers and measurement callbacks between proposals. For custom core measurement, call `tree.markDirty(id)` when external content changes. Mutable trees stay within one actor or thread. `YogaNode` remains available for clients that need reference ownership for individual nodes.

The benchmark report separates retained core layout, construction, mutations, cached calls, and memory. Results include confidence intervals and regressions; read them before relying on a performance change. SwiftUI measurements include framework overhead and are reported separately against v2.
