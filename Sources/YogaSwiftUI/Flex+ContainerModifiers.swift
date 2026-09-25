import SwiftUI
import YogaBridge

public extension Flex {
    /// Overrides the layout direction inherited from SwiftUI.
    func yogaLayoutDirection(_ value: YGDirection) -> Self {
        updating { $0.direction = value }
    }

    /// Changes the main axis of this container.
    func yogaFlexDirection(_ value: YGFlexDirection) -> Self {
        updating { $0.flexDirection = value }
    }

    /// Distributes children along the main axis.
    func yogaJustifyContent(_ value: YGJustify) -> Self {
        updating { $0.justifyContent = value }
    }

    /// Aligns children across the main axis.
    func yogaAlignItems(_ value: YGAlign) -> Self {
        updating { $0.alignItems = value }
    }

    /// Distributes wrapped lines across the cross axis.
    func yogaAlignContent(_ value: YGAlign) -> Self {
        updating { $0.alignContent = value }
    }

    /// Controls whether children wrap onto additional lines.
    func yogaWrap(_ value: YGWrap) -> Self {
        updating { $0.wrap = value }
    }

    /// Sets a point or percentage gap between children or lines.
    func yogaGap(_ value: YogaDimension, for gutter: YGGutter = .all) -> Self {
        updating {
            if gutter == .all {
                $0.setGap(value, for: .row)
                $0.setGap(value, for: .column)
            } else {
                $0.setGap(value, for: gutter)
            }
        }
    }

    /// Sets padding inside the Yoga container.
    func yogaPadding(_ value: YogaDimension, for edge: YGEdge = .all) -> Self {
        updating { $0.setPadding(value, for: edge) }
    }

    /// Reserves a border width in Yoga layout. Draw the border with SwiftUI.
    func yogaBorder(_ width: CGFloat, for edge: YGEdge = .all) -> Self {
        updating { $0.setBorder(Float(width), for: edge) }
    }

    /// Sets the container's Yoga width.
    func yogaWidth(_ value: YogaDimension) -> Self {
        updating { $0.width = value }
    }

    /// Sets the container's Yoga height.
    func yogaHeight(_ value: YogaDimension) -> Self {
        updating { $0.height = value }
    }

    /// Sets the container's minimum Yoga width.
    func yogaMinWidth(_ value: YogaDimension) -> Self {
        updating { $0.minWidth = value }
    }

    /// Sets the container's maximum Yoga width.
    func yogaMaxWidth(_ value: YogaDimension) -> Self {
        updating { $0.maxWidth = value }
    }

    /// Sets the container's minimum Yoga height.
    func yogaMinHeight(_ value: YogaDimension) -> Self {
        updating { $0.minHeight = value }
    }

    /// Sets the container's maximum Yoga height.
    func yogaMaxHeight(_ value: YogaDimension) -> Self {
        updating { $0.maxHeight = value }
    }

    /// Controls Yoga overflow. Hidden overflow also clips this SwiftUI view.
    func yogaOverflow(_ value: YGOverflow) -> Self {
        updating { $0.overflow = value }
    }

    /// Controls participation of this container's Yoga root in layout.
    func yogaDisplay(_ value: YGDisplay) -> Self {
        updating { $0.display = value }
    }

    /// Chooses whether dimensions include padding and border.
    func yogaBoxSizing(_ value: YGBoxSizing) -> Self {
        updating { $0.boxSizing = value }
    }

    /// Sets the container's width-to-height ratio.
    func yogaAspectRatio(_ value: CGFloat) -> Self {
        updating { $0.aspectRatio = Float(value) }
    }

    private func updating(_ change: (inout YogaStyle) -> Void) -> Self {
        var copy = self
        change(&copy.style)
        return copy
    }
}
