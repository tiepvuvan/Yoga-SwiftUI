/// A compact native length. `.percent(50)` means 50%.
///
/// Plain scalar storage lets the optimizer copy styles without per-value enum
/// payload handling. Inspect ``unit`` and ``value`` when reading a length.
@frozen public struct YogaValue: Sendable, Equatable {
    public let value: Float
    public let unit: YogaUnit

    private init(_ value: Float, _ unit: YogaUnit) { self.value = value; self.unit = unit }

    // Internal reconstruction from the lossless packed style representation.
    init(rawValue: Float, unit: YogaUnit) { self.value = rawValue; self.unit = unit }

    /// No explicit value; edge fallbacks and defaults may apply.
    public static let undefined = Self(0, .undefined)
    /// Let the layout algorithm choose the value.
    public static let auto = Self(0, .auto)
    /// An absolute length in layout units. Nonfinite input clears the value.
    public static func point(_ value: Float) -> Self { value.isFinite ? Self(value, .point) : .undefined }
    /// A percentage on the 0–100 scale. Nonfinite input clears the value.
    public static func percent(_ value: Float) -> Self { value.isFinite ? Self(value, .percent) : .undefined }

    @inline(__always) var isDefined: Bool { unit != .undefined }
    @inline(__always) var isPercent: Bool { unit == .percent }
    @inline(__always) func resolve(_ reference: Float) -> Float {
        switch unit {
        case .point: value
        case .percent: value * reference * 0.01
        default: .nan
        }
    }
}
