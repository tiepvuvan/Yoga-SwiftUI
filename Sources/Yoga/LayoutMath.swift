// Derived from React Yoga 3.2.1. See THIRD_PARTY_NOTICES.md.
@inline(__always) func maxDefined(_ a: Float, _ b: Float) -> Float { a.isNaN ? b : (b.isNaN ? a : max(a, b)) }
@inline(__always) func minDefined(_ a: Float, _ b: Float) -> Float { a.isNaN ? b : (b.isNaN ? a : min(a, b)) }
@inline(__always) func orZero(_ a: Float) -> Float { a.isNaN ? 0 : a }
@inline(__always) func approximatelyEqual(_ a: Float, _ b: Float) -> Bool { abs(a - b) < 0.0001 || (a.isNaN && b.isNaN) }

extension YogaFlexDirection {
    @inline(__always) var isRow: Bool { self == .row || self == .rowReverse }
    @inline(__always) var dimension: Int { isRow ? 0 : 1 }
    @inline(__always) var start: YogaEdge {
        switch self { case .row: .left; case .rowReverse: .right; case .column: .top; case .columnReverse: .bottom }
    }
    @inline(__always) var end: YogaEdge {
        switch self { case .row: .right; case .rowReverse: .left; case .column: .bottom; case .columnReverse: .top }
    }
    @inline(__always) func resolved(_ direction: YogaDirection) -> Self {
        guard direction == .rightToLeft else { return self }
        switch self { case .row: return .rowReverse; case .rowReverse: return .row; default: return self }
    }
    @inline(__always) func cross(_ direction: YogaDirection) -> Self { isRow ? .column : YogaFlexDirection.row.resolved(direction) }
    @inline(__always) func inlineStart(_ direction: YogaDirection) -> YogaEdge { isRow ? (direction == .rightToLeft ? .right : .left) : .top }
    @inline(__always) func inlineEnd(_ direction: YogaDirection) -> YogaEdge { isRow ? (direction == .rightToLeft ? .left : .right) : .bottom }
}
