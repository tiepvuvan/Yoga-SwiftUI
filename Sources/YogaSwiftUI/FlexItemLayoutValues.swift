import SwiftUI
import YogaBridge

protocol FlexItemProperty {
    associatedtype Value
    static func apply(_ value: Value, to style: inout YogaStyle)
}

struct FlexItemValueKey<Property: FlexItemProperty>: LayoutValueKey {
    static var defaultValue: Property.Value? { nil }
}

enum AlignSelfProperty: FlexItemProperty {
    static func apply(_ value: YGAlign, to style: inout YogaStyle) { style.alignSelf = value }
}

enum BasisProperty: FlexItemProperty {
    static func apply(_ value: YogaDimension, to style: inout YogaStyle) { style.flexBasis = value }
}

enum GrowProperty: FlexItemProperty {
    static func apply(_ value: Float, to style: inout YogaStyle) { style.flexGrow = value }
}

enum ShrinkProperty: FlexItemProperty {
    static func apply(_ value: Float, to style: inout YogaStyle) { style.flexShrink = value }
}

enum FactorProperty: FlexItemProperty {
    static func apply(_ value: Float, to style: inout YogaStyle) { style.flex = value }
}

enum WidthProperty: FlexItemProperty {
    static func apply(_ value: YogaDimension, to style: inout YogaStyle) { style.width = value }
}

enum HeightProperty: FlexItemProperty {
    static func apply(_ value: YogaDimension, to style: inout YogaStyle) { style.height = value }
}

enum MinWidthProperty: FlexItemProperty {
    static func apply(_ value: YogaDimension, to style: inout YogaStyle) { style.minWidth = value }
}

enum MaxWidthProperty: FlexItemProperty {
    static func apply(_ value: YogaDimension, to style: inout YogaStyle) { style.maxWidth = value }
}

enum MinHeightProperty: FlexItemProperty {
    static func apply(_ value: YogaDimension, to style: inout YogaStyle) { style.minHeight = value }
}

enum MaxHeightProperty: FlexItemProperty {
    static func apply(_ value: YogaDimension, to style: inout YogaStyle) { style.maxHeight = value }
}

enum AspectRatioProperty: FlexItemProperty {
    static func apply(_ value: Float, to style: inout YogaStyle) { style.aspectRatio = value }
}

enum PositionTypeProperty: FlexItemProperty {
    static func apply(_ value: YGPositionType, to style: inout YogaStyle) { style.positionType = value }
}

enum LayoutDirectionProperty: FlexItemProperty {
    static func apply(_ value: YGDirection, to style: inout YogaStyle) { style.direction = value }
}

enum DisplayProperty: FlexItemProperty {
    static func apply(_ value: YGDisplay, to style: inout YogaStyle) { style.display = value }
}

enum OverflowProperty: FlexItemProperty {
    static func apply(_ value: YGOverflow, to style: inout YogaStyle) { style.overflow = value }
}

enum BoxSizingProperty: FlexItemProperty {
    static func apply(_ value: YGBoxSizing, to style: inout YogaStyle) { style.boxSizing = value }
}

extension YogaStyle {
    mutating func applyItemValues(from subview: LayoutSubviews.Element) {
        apply(FactorProperty.self, from: subview)
        apply(GrowProperty.self, from: subview)
        apply(ShrinkProperty.self, from: subview)
        apply(BasisProperty.self, from: subview)
        apply(AlignSelfProperty.self, from: subview)
        apply(WidthProperty.self, from: subview)
        apply(HeightProperty.self, from: subview)
        apply(MinWidthProperty.self, from: subview)
        apply(MaxWidthProperty.self, from: subview)
        apply(MinHeightProperty.self, from: subview)
        apply(MaxHeightProperty.self, from: subview)
        apply(AspectRatioProperty.self, from: subview)
        apply(PositionTypeProperty.self, from: subview)
        apply(LayoutDirectionProperty.self, from: subview)
        apply(DisplayProperty.self, from: subview)
        apply(OverflowProperty.self, from: subview)
        apply(BoxSizingProperty.self, from: subview)

        applyEdges(PositionCategory.self, from: subview)
        applyEdges(MarginCategory.self, from: subview)
        applyEdges(PaddingCategory.self, from: subview)
        applyEdges(BorderCategory.self, from: subview)
    }

    private mutating func apply<Property: FlexItemProperty>(
        _ property: Property.Type,
        from subview: LayoutSubviews.Element
    ) {
        if let value = subview[FlexItemValueKey<Property>.self] {
            Property.apply(value, to: &self)
        }
    }

    private mutating func applyEdges<Category: FlexEdgeCategory>(
        _ category: Category.Type,
        from subview: LayoutSubviews.Element
    ) {
        applyEdge(category, AllEdge.self, from: subview)
        applyEdge(category, HorizontalEdge.self, from: subview)
        applyEdge(category, VerticalEdge.self, from: subview)
        applyEdge(category, LeftEdge.self, from: subview)
        applyEdge(category, TopEdge.self, from: subview)
        applyEdge(category, RightEdge.self, from: subview)
        applyEdge(category, BottomEdge.self, from: subview)
        applyEdge(category, StartEdge.self, from: subview)
        applyEdge(category, EndEdge.self, from: subview)
    }

    private mutating func applyEdge<Category: FlexEdgeCategory, Edge: FlexEdgeTag>(
        _ category: Category.Type,
        _ edge: Edge.Type,
        from subview: LayoutSubviews.Element
    ) {
        if let value = subview[FlexEdgeValueKey<Category, Edge>.self] {
            Category.apply(value, to: &self, edge: Edge.value)
        }
    }
}
