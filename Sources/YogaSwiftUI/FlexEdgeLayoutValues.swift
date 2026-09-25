import SwiftUI
import YogaBridge

protocol FlexEdgeCategory {
    associatedtype Value
    static func apply(_ value: Value, to style: inout YogaStyle, edge: YGEdge)
}

enum PositionCategory: FlexEdgeCategory {
    static func apply(_ value: YogaDimension, to style: inout YogaStyle, edge: YGEdge) {
        style.setPosition(value, for: edge)
    }
}

enum MarginCategory: FlexEdgeCategory {
    static func apply(_ value: YogaDimension, to style: inout YogaStyle, edge: YGEdge) {
        style.setMargin(value, for: edge)
    }
}

enum PaddingCategory: FlexEdgeCategory {
    static func apply(_ value: YogaDimension, to style: inout YogaStyle, edge: YGEdge) {
        style.setPadding(value, for: edge)
    }
}

enum BorderCategory: FlexEdgeCategory {
    static func apply(_ value: Float, to style: inout YogaStyle, edge: YGEdge) {
        style.setBorder(value, for: edge)
    }
}

protocol FlexEdgeTag {
    static var value: YGEdge { get }
}

enum LeftEdge: FlexEdgeTag { static let value: YGEdge = .left }
enum TopEdge: FlexEdgeTag { static let value: YGEdge = .top }
enum RightEdge: FlexEdgeTag { static let value: YGEdge = .right }
enum BottomEdge: FlexEdgeTag { static let value: YGEdge = .bottom }
enum StartEdge: FlexEdgeTag { static let value: YGEdge = .start }
enum EndEdge: FlexEdgeTag { static let value: YGEdge = .end }
enum HorizontalEdge: FlexEdgeTag { static let value: YGEdge = .horizontal }
enum VerticalEdge: FlexEdgeTag { static let value: YGEdge = .vertical }
enum AllEdge: FlexEdgeTag { static let value: YGEdge = .all }

struct FlexEdgeValueKey<Category: FlexEdgeCategory, Edge: FlexEdgeTag>: LayoutValueKey {
    static var defaultValue: Category.Value? { nil }
}

extension View {
    @ViewBuilder
    func flexEdgeValue<Category: FlexEdgeCategory>(
        _ value: Category.Value,
        for edge: YGEdge,
        category: Category.Type
    ) -> some View {
        switch edge {
        case .left: layoutValue(key: FlexEdgeValueKey<Category, LeftEdge>.self, value: value)
        case .top: layoutValue(key: FlexEdgeValueKey<Category, TopEdge>.self, value: value)
        case .right: layoutValue(key: FlexEdgeValueKey<Category, RightEdge>.self, value: value)
        case .bottom: layoutValue(key: FlexEdgeValueKey<Category, BottomEdge>.self, value: value)
        case .start: layoutValue(key: FlexEdgeValueKey<Category, StartEdge>.self, value: value)
        case .end: layoutValue(key: FlexEdgeValueKey<Category, EndEdge>.self, value: value)
        case .horizontal: layoutValue(key: FlexEdgeValueKey<Category, HorizontalEdge>.self, value: value)
        case .vertical: layoutValue(key: FlexEdgeValueKey<Category, VerticalEdge>.self, value: value)
        case .all: layoutValue(key: FlexEdgeValueKey<Category, AllEdge>.self, value: value)
        default: self
        }
    }
}
