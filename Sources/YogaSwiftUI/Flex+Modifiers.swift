import SwiftUI
import YogaBridge

public extension View {
    /// Overrides the cross-axis alignment of this direct `Flex` child.
    func flexAlignSelf(_ value: YGAlign) -> some View {
        layoutValue(key: FlexItemValueKey<AlignSelfProperty>.self, value: value)
    }

    /// Sets the initial size of this item along its parent's main axis.
    func flexBasis(_ value: YogaDimension) -> some View {
        layoutValue(key: FlexItemValueKey<BasisProperty>.self, value: value)
    }

    /// Compatibility overload for Yoga's C value type.
    func flexBasis(_ value: YGValue) -> some View {
        let dimension: YogaDimension
        switch value.unit {
        case .point: dimension = .point(value.value)
        case .percent: dimension = .percent(value.value)
        default: dimension = .auto
        }
        return flexBasis(dimension)
    }

    /// Sets this item's share of remaining space.
    func flexGrow(_ value: CGFloat) -> some View {
        layoutValue(key: FlexItemValueKey<GrowProperty>.self, value: Float(value))
    }

    /// Sets this item's share of a space shortage.
    func flexShrink(_ value: CGFloat) -> some View {
        layoutValue(key: FlexItemValueKey<ShrinkProperty>.self, value: Float(value))
    }

    /// Sets Yoga's nonstandard `flex` shorthand on this item.
    func flexFactor(_ value: CGFloat) -> some View {
        layoutValue(key: FlexItemValueKey<FactorProperty>.self, value: Float(value))
    }

    /// Sets this item's Yoga width.
    func flexWidth(_ value: YogaDimension) -> some View {
        layoutValue(key: FlexItemValueKey<WidthProperty>.self, value: value)
    }

    /// Sets this item's Yoga height.
    func flexHeight(_ value: YogaDimension) -> some View {
        layoutValue(key: FlexItemValueKey<HeightProperty>.self, value: value)
    }

    /// Sets this item's minimum Yoga width.
    func flexMinWidth(_ value: YogaDimension) -> some View {
        layoutValue(key: FlexItemValueKey<MinWidthProperty>.self, value: value)
    }

    /// Sets this item's maximum Yoga width.
    func flexMaxWidth(_ value: YogaDimension) -> some View {
        layoutValue(key: FlexItemValueKey<MaxWidthProperty>.self, value: value)
    }

    /// Sets this item's minimum Yoga height.
    func flexMinHeight(_ value: YogaDimension) -> some View {
        layoutValue(key: FlexItemValueKey<MinHeightProperty>.self, value: value)
    }

    /// Sets this item's maximum Yoga height.
    func flexMaxHeight(_ value: YogaDimension) -> some View {
        layoutValue(key: FlexItemValueKey<MaxHeightProperty>.self, value: value)
    }

    /// Sets the item's width-to-height ratio.
    func flexAspectRatio(_ value: CGFloat) -> some View {
        layoutValue(key: FlexItemValueKey<AspectRatioProperty>.self, value: Float(value))
    }

    /// Sets absolute, relative, or static Yoga positioning for this item.
    func flexPositionType(_ value: YGPositionType) -> some View {
        layoutValue(key: FlexItemValueKey<PositionTypeProperty>.self, value: value)
    }

    /// Overrides the direction used for logical edges on this item.
    func flexLayoutDirection(_ value: YGDirection) -> some View {
        layoutValue(key: FlexItemValueKey<LayoutDirectionProperty>.self, value: value)
    }

    /// Controls whether this item participates in Yoga layout.
    func flexDisplay(_ value: YGDisplay) -> some View {
        layoutValue(key: FlexItemValueKey<DisplayProperty>.self, value: value)
    }

    /// Controls Yoga overflow for this item. Hidden overflow clips its SwiftUI content.
    @ViewBuilder
    func flexOverflow(_ value: YGOverflow) -> some View {
        if value == .hidden {
            clipped().layoutValue(key: FlexItemValueKey<OverflowProperty>.self, value: value)
        } else {
            layoutValue(key: FlexItemValueKey<OverflowProperty>.self, value: value)
        }
    }

    /// Chooses whether the item's dimensions include padding and border.
    func flexBoxSizing(_ value: YGBoxSizing) -> some View {
        layoutValue(key: FlexItemValueKey<BoxSizingProperty>.self, value: value)
    }

    /// Sets an inset for this item's Yoga position.
    func flexPosition(_ value: YogaDimension, for edge: YGEdge) -> some View {
        flexEdgeValue(value, for: edge, category: PositionCategory.self)
    }

    /// Sets a Yoga margin on this item.
    func flexMargin(_ value: YogaDimension, for edge: YGEdge = .all) -> some View {
        flexEdgeValue(value, for: edge, category: MarginCategory.self)
    }

    /// Sets Yoga padding inside this item's box.
    func flexPadding(_ value: YogaDimension, for edge: YGEdge = .all) -> some View {
        flexEdgeValue(value, for: edge, category: PaddingCategory.self)
    }

    /// Reserves Yoga border width on this item. Draw the border with SwiftUI.
    func flexBorder(_ width: CGFloat, for edge: YGEdge = .all) -> some View {
        flexEdgeValue(Float(width), for: edge, category: BorderCategory.self)
    }
}
