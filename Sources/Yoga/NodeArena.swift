// All pointer ownership and growth lives here. Only initialized slots are moved
// and destroyed. Freed slots are reset before reuse; handles never escape layout.
final class NodeArena {
    private(set) var base: UnsafeMutablePointer<NodeState>
    private(set) var count = 0
    private(set) var capacity: Int
    private var free: [Int] = []
    private var nextGeneration: UInt64 = 0
    var isCalculating = false
    var isReleasing = false
    var topologyDirty = true

    init(capacity: Int = 1) {
        self.capacity = max(1, capacity)
        base = .allocate(capacity: self.capacity)
    }

    deinit {
        base.deinitialize(count: count)
        base.deallocate()
    }

    func reserveCapacity(_ minimum: Int) {
        precondition(!isCalculating && !isReleasing, "Cannot reenter tree storage growth")
        guard minimum > capacity else { return }
        let next = max(minimum, capacity * 2)
        let replacement = UnsafeMutablePointer<NodeState>.allocate(capacity: next)
        replacement.moveInitialize(from: base, count: count)
        base.deallocate()
        base = replacement
        capacity = next
    }

    @inline(__always) func allocate(_ value: consuming NodeState) -> Int {
        precondition(!isCalculating && !isReleasing, "Cannot reenter tree allocation")
        precondition(nextGeneration < .max, "Node identifier generations exhausted")
        nextGeneration += 1
        var value = consume value
        value.handleGeneration = nextGeneration
        topologyDirty = true
        if let slot = free.popLast() {
            base[slot] = consume value
            return slot
        }
        reserveCapacity(count + 1)
        let slot = count
        (base + slot).initialize(to: consume value)
        count += 1
        return slot
    }

    // Finish a construction batch with a compact store. Layout borrows have not
    // begun yet, so moving initialized values cannot invalidate a live handle.
    func trimExcessCapacity() {
        precondition(!isCalculating)
        while count > 0 && base[count - 1].handleGeneration == 0 {
            count -= 1
            (base + count).deinitialize(count: 1)
        }
        free.removeAll { $0 >= count }
        guard count > 0, capacity > count else { return }
        let replacement = UnsafeMutablePointer<NodeState>.allocate(capacity: count)
        replacement.moveInitialize(from: base, count: count)
        base.deallocate()
        base = replacement
        capacity = count
    }

    func release(_ slot: Int) {
        // The active root retains its complete subtree. A deinitializing handle
        // therefore belongs to an unrelated detached tree and has no live borrow.
        let wasReleasing = isReleasing
        isReleasing = true
        defer { isReleasing = wasReleasing }
        base[slot].handleGeneration = 0
        base[slot] = NodeState()
        free.append(slot)
        topologyDirty = true
    }
    func prepareTopologyIfNeeded(onlyRoot: Int? = nil) {
        guard topologyDirty else { return }
        let storage = base
        if let onlyRoot {
            Self.prepareTopology(onlyRoot, base: storage)
        } else {
            for slot in 0..<count where storage[slot].handleGeneration != 0 && storage[slot].parent < 0 {
                Self.prepareTopology(slot, base: storage)
            }
        }
        topologyDirty = false
        trimExcessCapacity()
    }

    private static func prepareTopology(_ index: Int, base: UnsafeMutablePointer<NodeState>, depth: Int = 0) {
        precondition(depth < 1024, "Layout trees must be less than 1024 nodes deep")
        if base[index].children.isEmpty {
            base[index].flattened = nil
            if !base[index].flow.isEmpty { base[index].flow = [] }
            return
        }
        precondition(depth + 1 < 1024, "Layout trees must be less than 1024 nodes deep")
        for child in base[index].children {
            if base[child].children.isEmpty {
                base[child].flattened = nil
                if !base[child].flow.isEmpty { base[child].flow = [] }
            } else {
                prepareTopology(child, base: base, depth: depth + 1)
            }
        }
        let children = base[index].children
        if children.contains(where: { base[$0].style.display == .contents }) {
            var flattened: [Int] = []
            for child in children {
                if base[child].style.display == .contents {
                    flattened.append(contentsOf: base[child].flattened ?? base[child].children)
                } else { flattened.append(child) }
            }
            base[index].flattened = flattened
        } else { base[index].flattened = nil }
        let layoutChildren = base[index].flattened ?? children
        if layoutChildren.contains(where: { base[$0].style.display == .none || base[$0].style.positionType == .absolute }) {
            base[index].flow = layoutChildren.filter { base[$0].style.display != .none && base[$0].style.positionType != .absolute }
        } else { base[index].flow = layoutChildren }
    }

}
