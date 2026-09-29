/// Whether a node generates a box, is hidden, or forwards its children.
public enum YogaDisplay: UInt8, CaseIterable, Sendable {
    case flex
    case none
    case contents
}
