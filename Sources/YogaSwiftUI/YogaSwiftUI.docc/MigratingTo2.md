# Migrating to 2.0

Update the dependency, enable C++ interoperability, and review percentage values.

## Dependency and toolchain

Version 2 replaces the `tiepvuvan/yoga` fork with the official `react/yoga` 3.2.1 release. The package requires Swift 6 and compiles Yoga with C++20.

Enable `.interoperabilityMode(.Cxx)` on each SwiftPM target that imports or depends on `YogaSwiftUI`. For an Xcode app target, choose **C++ / Objective-C++** for **C++ and Objective-C Interoperability**. See <doc:GettingStarted> for the complete manifest example.

## Percentage values

Yoga interprets percentages on a 0–100 scale. Review any `YogaDimension.percent` value written as a fraction:

| Intended size | Version 1 value | Version 2 value |
| --- | --- | --- |
| 50% width | `.percent(0.5)` | `.percent(50)` |
| 25% basis | `.percent(0.25)` | `.percent(25)` |

## API and layout behavior

The familiar `Flex` convenience parameters and `flexGrow`, `flexShrink`, and `flexBasis` child modifiers remain. Version 2 uses direct modifiers for the rest of Yoga's properties. Set container values with `yoga...` modifiers and direct child values with `flex...` modifiers:

```swift
Flex(direction: .row, wrap: .wrap) {
    Text("Item")
        .flexWidth(.percent(50))
        .flexShrink(0)
        .flexMargin(.point(8), for: .start)
}
.yogaGap(.point(12))
.yogaPadding(.point(16))
```

Rename the 1.x child modifiers `width`, `height`, `minWidth`, `maxWidth`, `minHeight`, `maxHeight`, and `alignSelf` to their `flex...` equivalents. Set `justifyContent`, `alignItems`, `alignContent`, `flexDirection`, and `flexWrap` on a nested `Flex` instead of a plain child; a plain child is a measured Yoga leaf and cannot rearrange its internal SwiftUI views. See <doc:ModifierReference> for all names.

If you previously changed a `Flex` property after initialization, use its initializer parameter or the matching `yoga...` modifier. Public layout value key types from 1.x are implementation details in version 2; use the view modifiers to set item values.

Version 2 measures SwiftUI children under Yoga's actual constraints. It also uses Yoga's current layout behavior rather than opting into all legacy errata. Check layouts that depended on previous intrinsic-size or spacing behavior, especially nested text and fixed dimensions.

Published package versions come from Git tags. The `v2.0.0` tag must be published before `from: "2.0.0"` can resolve from GitHub.
