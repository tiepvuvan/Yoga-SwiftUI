// Shared style math is specialized for public values and borrowed layout views.
// Keep these operations in one implementation so both paths resolve identically.
protocol StyleAccess {
    var direction: YogaDirection { get }
    var flexDirection: YogaFlexDirection { get }
    var justifyContent: YogaJustify { get }
    var alignContent: YogaAlign { get }
    var alignItems: YogaAlign { get }
    var alignSelf: YogaAlign { get }
    var positionType: YogaPositionType { get }
    var wrap: YogaWrap { get }
    var overflow: YogaOverflow { get }
    var display: YogaDisplay { get }
    var boxSizing: YogaBoxSizing { get }
    var flex: Float? { get }
    var flexGrow: Float? { get }
    var flexShrink: Float? { get }
    var flexBasis: YogaValue { get }
    var width: YogaValue { get }
    var height: YogaValue { get }
    var minWidth: YogaValue { get }
    var minHeight: YogaValue { get }
    var maxWidth: YogaValue { get }
    var maxHeight: YogaValue { get }
    var aspectRatio: Float? { get }
    var hasEdges: Bool { get }
    var hasPaddingOrBorder: Bool { get }
    var hasPositionsOrMargins: Bool { get }
    var hasBoxEdges: Bool { get }
    borrowing func hasEdgeKind(_ kind: UInt8) -> Bool
    func value(kind: UInt8, edge: UInt8) -> YogaValue
}

extension StyleAccess {
    @inline(__always) borrowing func position(for edge: YogaEdge) -> YogaValue { value(kind: 0, edge: edge.rawValue) }
    @inline(__always) borrowing func gap(for gutter: YogaGutter) -> YogaValue { value(kind: 4, edge: gutter.rawValue) }
    @inline(__always) borrowing func edgeValue(_ kind: UInt8, _ edge: YogaEdge, _ direction: YogaDirection) -> YogaValue {
        if !hasEdgeKind(kind) { return .undefined }
        if edge == .left || edge == .right {
            let logical: YogaEdge = (edge == .left) == (direction != .rightToLeft) ? .start : .end
            let value = value(kind: kind, edge: logical.rawValue)
            if value.isDefined { return value }
        }
        let physical = value(kind: kind, edge: edge.rawValue)
        if physical.isDefined { return physical }
        let grouped = value(kind: kind, edge: (edge == .left || edge == .right) ? YogaEdge.horizontal.rawValue : YogaEdge.vertical.rawValue)
        if grouped.isDefined { return grouped }
        return value(kind: kind, edge: YogaEdge.all.rawValue)
    }

    @inline(__always) borrowing func edge(_ kind: UInt8, _ edge: YogaEdge, _ direction: YogaDirection, _ width: Float) -> Float {
        let value = edgeValue(kind, edge, direction).resolve(width)
        return kind >= 2 ? maxDefined(0, value) : orZero(value)
    }

    @inline(__always) borrowing func margin(_ axis: YogaFlexDirection, _ width: Float) -> Float {
        if !hasEdgeKind(1) { return 0 }
        return edge(1, axis.start, .leftToRight, width) + edge(1, axis.end, .leftToRight, width)
    }

    @inline(__always) borrowing func paddingBorder(_ axis: YogaFlexDirection, _ direction: YogaDirection, _ width: Float) -> Float {
        if !hasPaddingOrBorder { return 0 }
        return paddingBorder(axis.start, direction, width) + paddingBorder(axis.end, direction, width)
    }

    @inline(__always) borrowing func paddingBorder(_ edge: YogaEdge, _ direction: YogaDirection, _ width: Float) -> Float {
        if !hasPaddingOrBorder { return 0 }
        return self.edge(2, edge, direction, width) + self.edge(3, edge, direction, 0)
    }

    @inline(__always) borrowing func gap(_ axis: YogaFlexDirection, _ reference: Float) -> Float {
        if !hasEdgeKind(4) { return 0 }
        let value = gap(for: axis.isRow ? .column : .row)
        return maxDefined(0, (value.isDefined ? value : gap(for: .all)).resolve(reference))
    }

    @inline(__always) borrowing func dimension(_ axis: YogaFlexDirection) -> YogaValue { axis.isRow ? width : height }
    @inline(__always) borrowing func minimum(_ axis: YogaFlexDirection) -> YogaValue { axis.isRow ? minWidth : minHeight }
    @inline(__always) borrowing func maximum(_ axis: YogaFlexDirection) -> YogaValue { axis.isRow ? maxWidth : maxHeight }
    @inline(__always) borrowing func resolved(_ value: YogaValue, _ axis: YogaFlexDirection, _ direction: YogaDirection, _ reference: Float, _ width: Float) -> Float {
        value.resolve(reference) + (boxSizing == .contentBox ? paddingBorder(axis, direction, width) : 0)
    }
}
