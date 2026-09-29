/// The size returned by a custom measurement function.
public struct YogaSize: Sendable, Equatable {
    public var width: Float
    public var height: Float

    public init(width: Float, height: Float) {
        self.width = width
        self.height = height
    }
}
