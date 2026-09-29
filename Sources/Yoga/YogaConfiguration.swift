/// Immutable configuration copied into each node. Layout trees are synchronously owned
/// by their caller; create separate trees for concurrent layout work.
public struct YogaConfiguration: Sendable, Equatable {
    /// Use row direction, stretch line alignment, and a shrink factor of one.
    public let useWebDefaults: Bool
    /// Physical pixels per layout unit. Zero disables pixel rounding.
    public let pointScaleFactor: Float

    public init(useWebDefaults: Bool = false, pointScaleFactor: Float = 1) {
        precondition(pointScaleFactor.isFinite && pointScaleFactor >= 0)
        self.useWebDefaults = useWebDefaults
        self.pointScaleFactor = pointScaleFactor
    }
}
