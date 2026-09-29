import SwiftUI
public import Yoga

public extension View {
    /// Overrides the cross-axis alignment of this direct `Flex` child.
    func flexAlignSelf(_ value: YogaAlign) -> some View {
        layoutValue(key: FlexItemValueKey<AlignSelfProperty>.self, value: value)
    }

    /// Sets the initial size of this item along its parent's main axis.
    func flexBasis(_ value: YogaDimension) -> some View {
        layoutValue(key: FlexItemValueKey<BasisProperty>.self, value: value)
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
    func flexPositionType(_ value: YogaPositionType) -> some View {
        layoutValue(key: FlexItemValueKey<PositionTypeProperty>.self, value: value)
    }

    /// Overrides the direction used for logical edges on this item.
    func flexLayoutDirection(_ value: YogaDirection) -> some View {
        layoutValue(key: FlexItemValueKey<LayoutDirectionProperty>.self, value: value)
    }

    /// Controls whether this item participates in Yoga layout.
    func flexDisplay(_ value: YogaDisplay) -> some View {
        modifier(YogaVisibility(display: value))
            .layoutValue(key: FlexItemValueKey<DisplayProperty>.self, value: value)
    }

    /// Controls Yoga overflow for this item. Hidden overflow clips its SwiftUI content.
    @ViewBuilder
    func flexOverflow(_ value: YogaOverflow) -> some View {
        if value == .hidden {
            clipped().layoutValue(key: FlexItemValueKey<OverflowProperty>.self, value: value)
        } else {
            layoutValue(key: FlexItemValueKey<OverflowProperty>.self, value: value)
        }
    }

    /// Chooses whether the item's dimensions include padding and border.
    func flexBoxSizing(_ value: YogaBoxSizing) -> some View {
        layoutValue(key: FlexItemValueKey<BoxSizingProperty>.self, value: value)
    }

    /// Sets an inset for this item's Yoga position.
    func flexPosition(_ value: YogaDimension, for edge: YogaEdge) -> some View {
        flexEdgeValue(value, for: edge, category: PositionCategory.self)
    }

    /// Sets a Yoga margin on this item.
    func flexMargin(_ value: YogaDimension, for edge: YogaEdge = .all) -> some View {
        flexEdgeValue(value, for: edge, category: MarginCategory.self)
    }

    /// Sets Yoga padding inside this item's box.
    func flexPadding(_ value: YogaDimension, for edge: YogaEdge = .all) -> some View {
        flexEdgeValue(value, for: edge, category: PaddingCategory.self)
    }

    /// Reserves Yoga border width on this item. Draw the border with SwiftUI.
    func flexBorder(_ width: CGFloat, for edge: YogaEdge = .all) -> some View {
        flexEdgeValue(Float(width), for: edge, category: BorderCategory.self)
    }
}
