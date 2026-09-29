# Documentation

Version 3 has two DocC catalogs. Each combines task-focused guides with the public API reference.

| Product | Local catalog | Hosted entry point after publication |
| --- | --- | --- |
| Yoga | [Yoga.docc](../Sources/Yoga/Yoga.docc) | [Core documentation](https://swiftpackageindex.com/tiepvuvan/yoga-swiftui/main/documentation/yoga) |
| YogaSwiftUI | [YogaSwiftUI.docc](../Sources/YogaSwiftUI/YogaSwiftUI.docc) | [SwiftUI documentation](https://swiftpackageindex.com/tiepvuvan/yoga-swiftui/main/documentation/yogaswiftui) |

## Standalone core

1. [Getting Started](../Sources/Yoga/Yoga.docc/GettingStarted.md) — products, configuration, and a first layout.
2. [Layout Rules](../Sources/Yoga/Yoga.docc/LayoutRules.md) — defaults, property coverage, edges, percentages, positioning, and rounding.
3. [Measuring Content](../Sources/Yoga/Yoga.docc/MeasuringContent.md) — constraints, intrinsic sizes, baselines, and invalidation.
4. [Ownership and Caching](../Sources/Yoga/Yoga.docc/OwnershipAndCaching.md) — tree lifetime, actors, and reuse.
5. [Conformance and Performance](../Sources/Yoga/Yoga.docc/ConformanceAndPerformance.md) — reference version, coverage, and measurement limits.

## SwiftUI

1. [Getting Started](../Sources/YogaSwiftUI/YogaSwiftUI.docc/GettingStarted.md)
2. [How Flex Works](../Sources/YogaSwiftUI/YogaSwiftUI.docc/HowFlexWorks.md)
3. [Containers and Items](../Sources/YogaSwiftUI/YogaSwiftUI.docc/ContainersAndItems.md)
4. [Sizing and Spacing](../Sources/YogaSwiftUI/YogaSwiftUI.docc/SizingAndSpacing.md)
5. [Alignment, Wrapping, and Direction](../Sources/YogaSwiftUI/YogaSwiftUI.docc/AlignmentWrappingAndDirection.md)
6. [Positioning and Visibility](../Sources/YogaSwiftUI/YogaSwiftUI.docc/PositioningAndVisibility.md)
7. [Modifier Reference](../Sources/YogaSwiftUI/YogaSwiftUI.docc/ModifierReference.md)
8. [Migrating to 3.0](../Sources/YogaSwiftUI/YogaSwiftUI.docc/MigratingTo3.md)

For older clients, the historical [v1-to-v2 migration](../Sources/YogaSwiftUI/YogaSwiftUI.docc/MigratingTo2.md) explains modifier renames and percentage changes.

## Build locally

With Swift 6.4 selected, open the package in Xcode and choose **Product > Build Documentation**, or run:

```sh
xcodebuild docbuild -scheme Yoga-SwiftUI-Package -destination 'generic/platform=macOS'
```

The build generates `Yoga.doccarchive` and `YogaSwiftUI.doccarchive`. The root [`.spi.yml`](../.spi.yml) configures both documentation targets. Swift Package Index publishes them after the changes reach the default branch and its builder supports the required toolchain; local validation does not confirm hosted publication. A published `v3.0.0` Git tag supplies versioned package resolution.

## Development and release

- [Benchmarks and raw measurements](../Benchmarks/README.md)
- [Performance plan for 3.0](PerformancePlan.md)
- [Performance implementation and verification](PerformanceImplementation.md)
- [Physical iPhone and Linux validation](DeviceValidation.md)
- [Physical iPhone performance](../Benchmarks/iPhoneResults.md)
- [Release checklist](ReleaseChecklist.md)
- [Prepared 3.0.0 release notes](ReleaseNotes3.md)
- [Changelog](../CHANGELOG.md)
- [Upstream license and provenance](../THIRD_PARTY_NOTICES.md)
