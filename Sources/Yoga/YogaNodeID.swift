/// A stable identifier owned by one ``YogaTree``.
///
/// An identifier does not keep its tree alive. Removing a node invalidates its
/// identifier, including when the storage slot is subsequently reused.
public struct YogaNodeID: Hashable, Sendable {
    let identity: TreeIdentity
    let slot: Int
    let generation: UInt64

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.identity === rhs.identity && lhs.slot == rhs.slot && lhs.generation == rhs.generation
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(identity))
        hasher.combine(slot)
        hasher.combine(generation)
    }
}

// Handles retain this small identity token, preventing address reuse from making
// an old handle appear to belong to a subsequently created tree.
final class TreeIdentity: Sendable {}
