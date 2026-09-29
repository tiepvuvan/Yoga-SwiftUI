/// A physical, logical, or grouped edge.
public enum YogaEdge: UInt8, CaseIterable, Sendable {
    case left
    case top
    case right
    case bottom
    case start
    case end
    case horizontal
    case vertical
    case all
}
