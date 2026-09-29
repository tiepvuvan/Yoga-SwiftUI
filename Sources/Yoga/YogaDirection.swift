/// The inherited writing direction.
public enum YogaDirection: UInt8, CaseIterable, Sendable {
    case inherit
    case leftToRight
    case rightToLeft
}

public extension YogaDirection {
    /// Left-to-right writing direction, using the spelling from Yoga.
    static let LTR: Self = .leftToRight
    /// Right-to-left writing direction, using the spelling from Yoga.
    static let RTL: Self = .rightToLeft
}
