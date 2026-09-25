/// A Yoga length. Percentages use Yoga's 0–100 scale (`.percent(50)` is 50%).
public enum YogaDimension: Sendable {
    /// Let Yoga determine the dimension automatically.
    case auto
    /// A percentage on Yoga's 0–100 scale: `50` means 50%.
    case percent(Float)
    /// An absolute length in layout points.
    case point(Float)
}
