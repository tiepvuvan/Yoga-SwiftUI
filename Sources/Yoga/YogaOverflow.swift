/// How overflow affects measurement. Rendering and scrolling belong to the host.
public enum YogaOverflow: UInt8, CaseIterable, Sendable {
    case visible
    case hidden
    case scroll
}
