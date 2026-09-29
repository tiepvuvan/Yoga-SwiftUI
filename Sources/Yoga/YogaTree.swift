/// A flexbox tree with contiguous storage and lightweight node identifiers.
///
/// Keep each tree on one actor or thread. Layout is synchronous. Measurement
/// callbacks may read the tree, but must not mutate or reenter it. Identifiers
/// are checked for ownership and lifetime at every public access.
public final class YogaTree {
    private let arena: NodeArena
    private let identity = TreeIdentity()
    // Direct child construction keeps a single root. Once detached nodes exist,
    // topology preparation conservatively visits every root in the store.
    private var mayHaveDetachedNodes = false
    private var hasPerformedLayout = false
    /// The tree's permanent root node.
    public let root: YogaNodeID
    /// Defaults used by every node created in this tree.
    public let configuration: YogaConfiguration

    /// Creates a root and optionally reserves storage for an expected node count.
    public init(configuration: YogaConfiguration = .init(), style: YogaStyle? = nil, capacity: Int = 16) {
        precondition(capacity >= 0, "Capacity must be nonnegative")
        self.configuration = configuration
        arena = NodeArena(capacity: max(1, capacity))
        let slot = arena.allocate(NodeState(style: style ?? YogaStyle(useWebDefaults: configuration.useWebDefaults), configuration: configuration))
        root = YogaNodeID(identity: identity, slot: slot, generation: arena.base[slot].handleGeneration)
    }

    /// Whether an identifier still names a live node in this tree.
    public func contains(_ node: YogaNodeID) -> Bool {
        node.identity === identity && node.slot >= 0 && node.slot < arena.count
            && arena.base[node.slot].handleGeneration == node.generation
    }

    @inline(__always) private func checked(_ node: YogaNodeID) -> Int {
        precondition(contains(node), "Node identifier is stale or belongs to another tree")
        return node.slot
    }

    @inline(__always) private func checkMutable() {
        precondition(!arena.isCalculating && !arena.isReleasing, "Cannot reenter a tree from layout or released content")
    }

    private func identifier(_ slot: Int) -> YogaNodeID {
        YogaNodeID(identity: identity, slot: slot, generation: arena.base[slot].handleGeneration)
    }

    /// Reserves total node capacity before a construction batch.
    public func reserveCapacity(_ capacity: Int) {
        precondition(capacity >= 0, "Capacity must be nonnegative")
        arena.reserveCapacity(capacity)
    }

    /// Creates a detached node that can be attached with ``append(_:to:at:)``.
    public func createNode(style: YogaStyle? = nil) -> YogaNodeID {
        checkMutable()
        mayHaveDetachedNodes = true
        return identifier(arena.allocate(NodeState(style: style ?? YogaStyle(useWebDefaults: configuration.useWebDefaults), configuration: configuration)))
    }

    /// Creates a child directly in the tree's storage.
    @discardableResult public func appendChild(to parent: YogaNodeID, style: YogaStyle? = nil) -> YogaNodeID {
        checkMutable()
        let parentIndex = checked(parent)
        precondition(arena.base[parentIndex].measure == nil, "A measured node must be a leaf")
        let child = arena.allocate(NodeState(style: style ?? YogaStyle(useWebDefaults: configuration.useWebDefaults), configuration: configuration))
        let storage = arena.base
        storage[parentIndex].children.append(child)
        storage[child].parent = parentIndex
        invalidate(parentIndex)
        return identifier(child)
    }

    /// Attaches or reparents a node, preserving its identifier and descendants.
    ///
    /// When moving within the same parent, `index` refers to the child list after
    /// the moving node has been removed. Omit it to append at the end.
    public func append(_ child: YogaNodeID, to parent: YogaNodeID, at index: Int? = nil) {
        checkMutable()
        let childIndex = checked(child)
        let parentIndex = checked(parent)
        precondition(child != root && arena.base[parentIndex].measure == nil, "Cannot move the permanent root or attach to a measured node")
        var ancestor = parentIndex
        while ancestor >= 0 {
            precondition(ancestor != childIndex, "A layout tree cannot contain a cycle")
            ancestor = arena.base[ancestor].parent
        }
        let oldParent = arena.base[childIndex].parent
        let targetCount = arena.base[parentIndex].children.count - (oldParent == parentIndex ? 1 : 0)
        let insertion = index ?? targetCount
        precondition(insertion >= 0 && insertion <= targetCount, "Child index out of bounds")
        if oldParent >= 0 {
            arena.base[oldParent].children.removeAll { $0 == childIndex }
            invalidate(oldParent)
        }
        arena.base[childIndex].parent = parentIndex
        arena.base[parentIndex].children.insert(childIndex, at: insertion)
        arena.topologyDirty = true
        invalidate(childIndex)
    }

    /// Removes a node and all its descendants, invalidating their identifiers.
    public func remove(_ node: YogaNodeID) {
        checkMutable()
        let index = checked(node)
        precondition(node != root, "Remove the root's children instead of its permanent root")
        let parent = arena.base[index].parent
        if parent >= 0 {
            arena.base[parent].children.removeAll { $0 == index }
            invalidate(parent)
        }
        removeSubtree(index)
    }

    private func removeSubtree(_ index: Int) {
        var pending = [index]
        while let next = pending.popLast() {
            pending.append(contentsOf: arena.base[next].children)
            arena.release(next)
        }
    }

    /// The number of direct children, without allocating a collection.
    public func childCount(of node: YogaNodeID) -> Int { arena.base[checked(node)].children.count }
    /// Returns a direct child in insertion order.
    public func child(at index: Int, of node: YogaNodeID) -> YogaNodeID {
        identifier(arena.base[checked(node)].children[index])
    }
    /// Returns a copy of a node's style for editing or inspection.
    public func style(of node: YogaNodeID) -> YogaStyle { arena.base[checked(node)].style }
    /// Replaces a style and invalidates its dependent ancestors once.
    public func setStyle(_ style: YogaStyle, for node: YogaNodeID) {
        checkMutable()
        let index = checked(node)
        guard arena.base[index].style != style else { return }
        if arena.base[index].style.display != style.display || arena.base[index].style.positionType != style.positionType {
            arena.topologyDirty = true
        }
        arena.base[index].style = style
        invalidate(index)
    }
    /// Applies a batch of style edits with one comparison and invalidation.
    public func updateStyle(of node: YogaNodeID, _ update: (inout YogaStyle) -> Void) {
        checkMutable()
        var style = style(of: node)
        update(&style)
        setStyle(style, for: node)
    }
    /// The most recent layout, including padding, borders, and overflow state.
    public func layout(of node: YogaNodeID) -> YogaLayout { arena.base[checked(node)].layout }
    /// Whether the node requires layout after a style or content change.
    public func isDirty(_ node: YogaNodeID) -> Bool { arena.base[checked(node)].isDirty }
    /// Invalidates cached measurements after external content changes.
    public func markDirty(_ node: YogaNodeID) { checkMutable(); invalidate(checked(node)) }

    private func invalidate(_ index: Int) {
        // Every fresh record already starts dirty, without cached layout data.
        // Construction edits have nothing to invalidate before the first pass.
        guard hasPerformedLayout else { return }
        let storage = arena.base
        var current = index
        repeat {
            let wasDirty = storage[current].isDirty
            storage[current].hasRootLayout = false
            storage[current].computedFlexBasis = .nan
            storage[current].cachedLayout = nil
            if !storage[current].cachedMeasurements.isEmpty {
                storage[current].cachedMeasurements.removeAll(keepingCapacity: true)
            }
            storage[current].isDirty = true
            current = storage[current].parent
            if wasDirty && (current < 0 || storage[current].isDirty) { break }
        } while current >= 0
    }

    /// Sets an intrinsic content measurement callback on a leaf.
    public func setMeasure(for node: YogaNodeID, _ callback: ((Float, YogaMeasureMode, Float, YogaMeasureMode) -> YogaSize)?) {
        checkMutable()
        let index = checked(node)
        precondition(callback == nil || arena.base[index].children.isEmpty, "A measured node must be a leaf")
        arena.isReleasing = true
        defer { arena.isReleasing = false }
        arena.base[index].measure = callback.map(LayoutMeasureCallback.content)
        invalidate(index)
    }
    /// Sets a baseline callback, receiving the resolved box and its measured size.
    public func setBaseline(for node: YogaNodeID, _ callback: ((YogaLayout, Float, Float) -> Float)?) {
        checkMutable()
        let index = checked(node)
        arena.isReleasing = true
        defer { arena.isReleasing = false }
        arena.base[index].baseline = callback.map(LayoutBaselineCallback.content)
        invalidate(index)
    }
    /// Selects a child when deriving a container's baseline.
    public func setReferenceBaseline(_ value: Bool, for node: YogaNodeID) {
        checkMutable()
        let index = checked(node)
        if arena.base[index].isReferenceBaseline != value {
            arena.base[index].isReferenceBaseline = value
            invalidate(index)
        }
    }
    /// Controls whether a static node establishes an absolute containing block.
    public func setAlwaysFormsContainingBlock(_ value: Bool, for node: YogaNodeID) {
        checkMutable()
        let index = checked(node)
        if arena.base[index].alwaysFormsContainingBlock != value {
            arena.base[index].alwaysFormsContainingBlock = value
            invalidate(index)
        }
    }

    /// Computes the permanent root, or a specified detached root, synchronously.
    public func calculateLayout(root node: YogaNodeID? = nil, width: Float? = nil, height: Float? = nil, direction: YogaDirection = .leftToRight) {
        checkMutable()
        let index = checked(node ?? root)
        precondition(arena.base[index].parent < 0, "Calculate layout on a detached root")
        if LayoutNode(base: arena.base, index: index).canReuseRootLayout(width: width, height: height, direction: direction) { return }
        if !arena.base[index].hasRootLayout { invalidate(index) }
        hasPerformedLayout = true
        arena.prepareTopologyIfNeeded(onlyRoot: mayHaveDetachedNodes ? nil : index)
        arena.isCalculating = true
        defer { arena.isCalculating = false }
        withExtendedLifetime(self) {
            LayoutNode(base: arena.base, index: index).calculateLayout(width: width, height: height, direction: direction)
        }
    }
}
