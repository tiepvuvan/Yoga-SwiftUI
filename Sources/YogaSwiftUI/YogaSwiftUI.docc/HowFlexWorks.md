# How Flex Works

Understand the boundary between Yoga's calculated boxes and SwiftUI views.

A `Flex` container creates a Yoga root node. Every direct SwiftUI child becomes one measured Yoga leaf. Yoga asks SwiftUI for the child's natural size under the current constraints, calculates its box, and gives SwiftUI the resulting placement size and position.

This model supports text that wraps as available width changes, flex grow and shrink, baseline alignment, and Yoga's container and item styles.

## Container and item scopes

Set properties that organize siblings on the container:

- Flex direction, wrapping, justification, cross-axis alignment, and gaps.
- Root padding and dimensions.
- The layout direction when you intentionally override SwiftUI's environment.

Set properties that describe one child on that child:

- Grow, shrink, basis, width, height, and min/max dimensions.
- Self-alignment, margins, aspect ratio, and absolute positioning.

An item is a Yoga leaf. Setting `justifyContent` or `flexDirection` on a plain child does not rearrange that child's internal SwiftUI views. Wrap those views in another `Flex` to create a nested container. Each nested `Flex` is calculated as its own SwiftUI layout; nested containers are not one shared Yoga node tree.

## Measurement and drawing

Yoga controls layout geometry, not every visual behavior:

- Yoga border widths reserve space but do not draw a line. Use a SwiftUI drawing modifier to render a border.
- `overflow: .hidden` clips the corresponding SwiftUI view. `overflow: .scroll` needs a SwiftUI `ScrollView` to provide scrolling.
- `display: .none` removes a child from layout and placement.
- Yoga's `display: .contents` cannot flatten arbitrary descendants of an opaque SwiftUI child.

A `Flex` uses SwiftUI's layout direction unless `yogaLayoutDirection(_:)` overrides it. A direct child can override the direction used for its logical edges with `flexLayoutDirection(_:)`. For exact behavior of each Yoga property, see the [Yoga documentation](https://www.yogalayout.dev/docs/styling/).
