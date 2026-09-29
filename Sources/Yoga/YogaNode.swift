// Derived from React Yoga 3.2.1. See THIRD_PARTY_NOTICES.md.

/// An owned node in a synchronous, native Swift flexbox tree.
///
/// Nodes retain their children and weakly reference their parent. Layout state
/// resides in shared contiguous storage. Keep a tree on one actor or thread.
public final class YogaNode {
    private var arena: NodeArena
    private var slot: Int
    @inline(__always) private var state: UnsafeMutablePointer<NodeState> { arena.base + slot }
    /// Children in insertion order, retained by this node.
    public private(set) var children: [YogaNode] = []
    /// The owning node, or nil for a detached root.
    public private(set) weak var parent: YogaNode?

    /// Value-type style; assigning a changed value invalidates the ancestors.
    public var style: YogaStyle {
        get { state.pointee.style }
        set {
            checkMutable()
            if state.pointee.style != newValue {
                if state.pointee.style.display != newValue.display || state.pointee.style.positionType != newValue.positionType {
                    arena.topologyDirty = true
                }
                markDirty()
                state.pointee.style = newValue
            }
        }
    }
    /// Immutable defaults and pixel scale for this node.
    public var configuration: YogaConfiguration { state.pointee.configuration }
    /// The most recent computed border box and resolved physical edges.
    public var layout: YogaLayout { state.pointee.layout }
    /// Whether this node needs fresh measurement or layout.
    public var isDirty: Bool { state.pointee.isDirty }
    /// Set during layout; clear it after consuming the geometry.
    public var hasNewLayout: Bool {
        get { state.pointee.hasNewLayout }
        set { checkMutable(); state.pointee.hasNewLayout = newValue }
    }
    /// Whether this child is preferred when deriving its parent's baseline.
    public var isReferenceBaseline: Bool {
        get { state.pointee.isReferenceBaseline }
        set {
            checkMutable()
            if newValue != state.pointee.isReferenceBaseline { markDirty(); state.pointee.isReferenceBaseline = newValue }
        }
    }
    /// Makes a static node establish a containing block for absolute descendants.
    public var alwaysFormsContainingBlock: Bool {
        get { state.pointee.alwaysFormsContainingBlock }
        set {
            checkMutable()
            if newValue != state.pointee.alwaysFormsContainingBlock { markDirty(); state.pointee.alwaysFormsContainingBlock = newValue }
        }
    }
    /// Measures content inside padding and borders. Call ``markDirty()`` when it changes.
    public var measure: ((YogaNode, Float, YogaMeasureMode, Float, YogaMeasureMode) -> YogaSize)? {
        get { if case .node(let callback) = state.pointee.measure { callback } else { nil } }
        set {
            checkMutable()
            precondition(newValue == nil || children.isEmpty, "A measured node must be a leaf")
            markDirty()
            arena.isReleasing = true
            defer { arena.isReleasing = false }
            state.pointee.measure = newValue.map(LayoutMeasureCallback.node)
        }
    }
    /// Distance from the top of the border box to the content's baseline.
    public var baseline: ((YogaNode, Float, Float) -> Float)? {
        get { if case .node(let callback) = state.pointee.baseline { callback } else { nil } }
        set {
            checkMutable(); markDirty()
            arena.isReleasing = true
            defer { arena.isReleasing = false }
            state.pointee.baseline = newValue.map(LayoutBaselineCallback.node)
        }
    }

    /// Creates a detached node. An omitted style follows the configuration defaults.
    public convenience init(configuration: YogaConfiguration = .init(), style: YogaStyle? = nil) {
        self.init(arena: NodeArena(), configuration: configuration, style: style)
    }

    private init(arena: NodeArena, configuration: YogaConfiguration, style: YogaStyle?) {
        self.arena = arena
        slot = arena.allocate(NodeState(style: style ?? YogaStyle(useWebDefaults: configuration.useWebDefaults), configuration: configuration))
        state.pointee.facade = .passUnretained(self)
    }

    deinit {
        // Children may outlive their parent. Their next root layout must not use
        // an old parent slot, even if the arena recycles it for another node.
        for child in children {
            child.state.pointee.parent = -1
            child.state.pointee.hasRootLayout = false
        }
        arena.release(slot)
    }

    @inline(__always) private func checkMutable() {
        precondition(!arena.isCalculating && !arena.isReleasing, "Cannot reenter a tree from layout or released content")
    }

    /// Reserves space for the expected total number of nodes in this tree's store.
    public func reserveCapacity(_ nodeCount: Int) {
        precondition(nodeCount >= 0, "Capacity must be nonnegative")
        arena.reserveCapacity(nodeCount)
    }

    /// Creates and appends a child directly in this tree's storage.
    ///
    /// Prefer this when constructing a tree to avoid transferring a detached
    /// node's storage. The child inherits this node's configuration.
    @discardableResult public func appendChild(style: YogaStyle? = nil) -> YogaNode {
        checkMutable()
        precondition(measure == nil, "A measured node must be a leaf")
        let child = YogaNode(arena: arena, configuration: configuration, style: style)
        children.append(child)
        child.parent = self
        child.state.pointee.parent = slot
        state.pointee.children.append(child.slot)
        markDirty()
        return child
    }

    /// Adds a detached child, rejecting cycles and shared ownership.
    public func insertChild(_ child: YogaNode, at index: Int) {
        checkMutable()
        child.checkMutable()
        precondition(measure == nil && child.parent == nil, "Insert a detached child into an unmeasured node")
        precondition(index >= 0 && index <= children.count, "Child index out of bounds")
        var ancestor: YogaNode? = self
        while let node = ancestor {
            precondition(node !== child, "A layout tree cannot contain a cycle")
            ancestor = node.parent
        }
        if child.arena !== arena { child.move(to: arena) }
        children.insert(child, at: index)
        child.parent = self
        child.state.pointee.parent = slot
        state.pointee.children.insert(child.slot, at: index)
        arena.topologyDirty = true
        child.markDirty()
        markDirty()
    }

    /// Appends a detached child to the end of the layout order.
    public func appendChild(_ child: YogaNode) { insertChild(child, at: children.count) }

    private func move(to destination: NodeArena) {
        let source = arena
        let oldSlot = slot
        let value = state.pointee
        slot = destination.allocate(value)
        arena = destination
        source.release(oldSlot)
        for child in children { child.move(to: destination); child.state.pointee.parent = slot }
        state.pointee.children = children.map(\.slot)
        state.pointee.flattened = nil
    }

    /// Detaches and returns a child, resetting its geometry and invalidating layout.
    @discardableResult public func removeChild(at index: Int) -> YogaNode {
        checkMutable()
        let child = children.remove(at: index)
        state.pointee.children.remove(at: index)
        child.parent = nil
        child.state.pointee.parent = -1
        child.state.pointee.layout = YogaLayout()
        arena.topologyDirty = true
        child.markDirty()
        markDirty()
        return child
    }

    /// Detaches every child while retaining the parent's child-buffer capacity.
    public func removeAllChildren() {
        checkMutable()
        for child in children {
            child.parent = nil
            child.state.pointee.parent = -1
            child.state.pointee.layout = YogaLayout()
            child.markDirty()
        }
        children.removeAll(keepingCapacity: true)
        state.pointee.children.removeAll(keepingCapacity: true)
        arena.topologyDirty = true
        markDirty()
    }

    /// Invalidates measurement and layout, propagating to the root.
    public func markDirty() {
        checkMutable()
        state.pointee.hasRootLayout = false
        state.pointee.computedFlexBasis = .nan
        state.pointee.cachedLayout = nil
        if !state.pointee.cachedMeasurements.isEmpty {
            state.pointee.cachedMeasurements.removeAll(keepingCapacity: true)
        }
        if !state.pointee.isDirty {
            state.pointee.isDirty = true
            parent?.markDirty()
        } else if let parent, !parent.isDirty { parent.markDirty() }
    }

    /// Computes a detached root in available space. `nil` requests intrinsic sizing.
    public func calculateLayout(width: Float? = nil, height: Float? = nil, direction: YogaDirection = .leftToRight) {
        checkMutable()
        precondition(parent == nil, "Calculate layout on a detached root")
        if LayoutNode(base: arena.base, index: slot).canReuseRootLayout(width: width, height: height, direction: direction) { return }
        if !state.pointee.hasRootLayout { markDirty() }
        arena.prepareTopologyIfNeeded()
        arena.isCalculating = true
        defer { arena.isCalculating = false }
        withExtendedLifetime(self) {
            LayoutNode(base: arena.base, index: slot).calculateLayout(width: width, height: height, direction: direction)
        }
    }
}
