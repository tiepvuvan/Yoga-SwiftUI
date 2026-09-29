/// Resolved physical edge values, in layout units.
public struct YogaInsets: Sendable, Equatable {
    public var left: Float = 0
    public var top: Float = 0
    public var right: Float = 0
    public var bottom: Float = 0

    public init(left: Float = 0, top: Float = 0, right: Float = 0, bottom: Float = 0) {
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
    }

    public subscript(edge: YogaEdge) -> Float {
        get {
            switch edge {
            case .left: left
            case .top: top
            case .right: right
            case .bottom: bottom
            default: preconditionFailure("Resolved insets require a physical edge")
            }
        }
        set {
            switch edge {
            case .left: left = newValue
            case .top: top = newValue
            case .right: right = newValue
            case .bottom: bottom = newValue
            default: preconditionFailure("Resolved insets require a physical edge")
            }
        }
    }
}
