// Four optional scalars share presence bits in YogaStyle. Values keep their full
// Float representation, including the distinction between nil and a present NaN.
struct OptionalStyleValues: Sendable, Equatable {
    var flex: Float = 0
    var flexGrow: Float = 0
    var flexShrink: Float = 0
    var aspectRatio: Float = 0
}
