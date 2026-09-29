/// A computed border box, relative to its layout parent.
public struct YogaLayout: Sendable, Equatable {
    public internal(set) var left: Float = 0
    public internal(set) var top: Float = 0
    public internal(set) var right: Float = 0
    public internal(set) var bottom: Float = 0
    public internal(set) var width: Float = 0
    public internal(set) var height: Float = 0
    public internal(set) var margin = YogaInsets()
    public internal(set) var padding = YogaInsets()
    public internal(set) var border = YogaInsets()
    public internal(set) var direction: YogaDirection = .inherit
    public internal(set) var hadOverflow = false

    subscript(position edge: YogaEdge) -> Float {
        get {
            switch edge {
            case .left: left
            case .top: top
            case .right: right
            case .bottom: bottom
            default: preconditionFailure("Position requires a physical edge")
            }
        }
        set {
            switch edge {
            case .left: left = newValue
            case .top: top = newValue
            case .right: right = newValue
            case .bottom: bottom = newValue
            default: preconditionFailure("Position requires a physical edge")
            }
        }
    }
}
