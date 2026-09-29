// Temporary handles are created only while the arena is frozen by calculateLayout.
// No pointer or borrowed style is exposed through the public API.
struct LayoutNode: Equatable {
    let base: UnsafeMutablePointer<NodeState>
    let index: Int
    @inline(__always) var record: UnsafeMutablePointer<NodeState> { base + index }
    @inline(__always) var _style: LayoutStyle { LayoutStyle(record: record) }
    @inline(__always) var facade: YogaNode { record.pointee.facade!.takeUnretainedValue() }
    @inline(__always) var children: LayoutChildren { LayoutChildren(base: base, indices: record.pointee.children) }
    @inline(__always) var parent: LayoutNode? {
        record.pointee.parent < 0 ? nil : LayoutNode(base: base, index: record.pointee.parent)
    }
    @inline(__always) var configuration: YogaConfiguration {
        get { record.pointee.configuration }
        nonmutating set { record.pointee.configuration = newValue }
    }
    @inline(__always) var layout: YogaLayout {
        get { record.pointee.layout }
        nonmutating set { record.pointee.layout = newValue }
    }
    @inline(__always) var measured: SIMD2<Float> {
        get { record.pointee.measured }
        nonmutating set { record.pointee.measured = newValue }
    }
    @inline(__always) var computedFlexBasis: Float {
        get { record.pointee.computedFlexBasis }
        nonmutating set { record.pointee.computedFlexBasis = newValue }
    }
    @inline(__always) var generation: UInt64 {
        get { record.pointee.generation }
        nonmutating set { record.pointee.generation = newValue }
    }
    @inline(__always) var rootGeneration: UInt64 {
        get { record.pointee.rootGeneration }
        nonmutating set { record.pointee.rootGeneration = newValue }
    }
    @inline(__always) var lastOwnerDirection: YogaDirection {
        get { record.pointee.lastOwnerDirection }
        nonmutating set { record.pointee.lastOwnerDirection = newValue }
    }
    @inline(__always) var lineIndex: Int {
        get { record.pointee.lineIndex }
        nonmutating set { record.pointee.lineIndex = newValue }
    }
    @inline(__always) var cachedLayout: LayoutCacheEntry? {
        get { record.pointee.cachedLayout }
        nonmutating set { record.pointee.cachedLayout = newValue }
    }
    @inline(__always) var cachedMeasurements: [LayoutCacheEntry] {
        _read { yield record.pointee.cachedMeasurements }
        nonmutating _modify { yield &record.pointee.cachedMeasurements }
    }
    @inline(__always) var isCalculating: Bool {
        get { record.pointee.isCalculating }
        nonmutating set { record.pointee.isCalculating = newValue }
    }
    @inline(__always) var hasRootLayout: Bool {
        get { record.pointee.hasRootLayout }
        nonmutating set { record.pointee.hasRootLayout = newValue }
    }
    @inline(__always) var isDirty: Bool {
        get { record.pointee.isDirty }
        nonmutating set { record.pointee.isDirty = newValue }
    }
    @inline(__always) var hasNewLayout: Bool {
        get { record.pointee.hasNewLayout }
        nonmutating set { record.pointee.hasNewLayout = newValue }
    }
    @inline(__always) var isReferenceBaseline: Bool {
        get { record.pointee.isReferenceBaseline }
        nonmutating set { record.pointee.isReferenceBaseline = newValue }
    }
    @inline(__always) var alwaysFormsContainingBlock: Bool {
        get { record.pointee.alwaysFormsContainingBlock }
        nonmutating set { record.pointee.alwaysFormsContainingBlock = newValue }
    }
    @inline(__always) var measure: LayoutMeasureCallback? {
        get { record.pointee.measure }
        nonmutating set { record.pointee.measure = newValue }
    }
    @inline(__always) var baseline: LayoutBaselineCallback? {
        get { record.pointee.baseline }
        nonmutating set { record.pointee.baseline = newValue }
    }
    @inline(__always) func canReuseRootLayout(width: Float?, height: Float?, direction: YogaDirection) -> Bool {
        guard hasRootLayout && !isDirty && lastOwnerDirection == direction, let entry = cachedLayout else { return false }
        let ownerWidth = width.flatMap { $0.isFinite ? $0 : nil } ?? .nan
        let ownerHeight = height.flatMap { $0.isFinite ? $0 : nil } ?? .nan
        return approximatelyEqual(entry.ownerWidth, ownerWidth) && approximatelyEqual(entry.ownerHeight, ownerHeight)
    }

    func calculateLayout(width: Float? = nil, height: Float? = nil, direction: YogaDirection = .leftToRight) {
        let ownerWidth = width.flatMap { $0.isFinite ? $0 : nil } ?? .nan
        let ownerHeight = height.flatMap { $0.isFinite ? $0 : nil } ?? .nan
        // With an unchanged style, equal root proposals imply equal resolved
        // constraints. Return before resolving dimensions or touching children.
        if !isDirty && lastOwnerDirection == direction, let cachedLayout,
           approximatelyEqual(cachedLayout.ownerWidth, ownerWidth),
           approximatelyEqual(cachedLayout.ownerHeight, ownerHeight) { return }
        rootGeneration &+= 1
        let resolvedDirection = resolveDirection(direction)
        var available = SIMD2<Float>(ownerWidth, ownerHeight)
        var modes: (YogaMeasureMode, YogaMeasureMode) = (.undefined, .undefined)
        for axis: YogaFlexDirection in [.row, .column] {
            let reference = axis.isRow ? ownerWidth : ownerHeight
            let margin = _style.margin(axis, ownerWidth)
            let size = resolvedDimension(axis, resolvedDirection, reference, ownerWidth)
            let maximum = _style.resolved(_style.maximum(axis), axis, resolvedDirection, reference, ownerWidth)
            var mode: YogaMeasureMode = reference.isNaN ? .undefined : .exactly
            if hasDefiniteLength(axis, reference) {
                available[axis.dimension] = size + margin
                mode = .exactly
            } else if maximum >= 0 {
                available[axis.dimension] = maximum
                mode = .atMost
            }
            if axis.isRow { modes.0 = mode } else { modes.1 = mode }
        }
        if !isDirty && lastOwnerDirection == direction,
           let cachedLayout, cachedLayout.matches(available.x, available.y, modes.0, modes.1, ownerWidth, ownerHeight, dependsOnOwner: _style.dependsOnOwner) {
            return
        }
        layoutInternal(available.x, available.y, direction, modes.0, modes.1, ownerWidth, ownerHeight, true, rootGeneration, 0)
        // Cache hits restore unrounded measured dimensions. Finish the root pass
        // even when compatible measurements made a full recalculation unnecessary.
        setPosition(layout.direction, ownerWidth, ownerHeight, isRoot: true)
        roundToPixelGrid(absoluteLeft: 0, absoluteTop: 0)
        hasRootLayout = true
    }

    @inline(__always) func resolveDirection(_ owner: YogaDirection) -> YogaDirection {
        _style.direction == .inherit ? (owner == .inherit ? .leftToRight : owner) : _style.direction
    }

    @inline(__always) func processedDimension(_ axis: YogaFlexDirection) -> YogaValue {
        _style.processedDimension(axis)
    }

    @inline(__always) func hasDefiniteLength(_ axis: YogaFlexDirection, _ reference: Float) -> Bool {
        _style.hasDefiniteLength(axis, reference)
    }

    @inline(__always) func resolvedDimension(_ axis: YogaFlexDirection, _ direction: YogaDirection, _ reference: Float, _ width: Float) -> Float {
        _style.resolvedDimension(axis, direction, reference, width)
    }

    @inline(__always) func boundMinMax(_ value: Float, _ axis: YogaFlexDirection, _ direction: YogaDirection, _ reference: Float, _ width: Float) -> Float {
        _style.boundMinMax(value, axis, direction, reference, width)
    }

    @inline(__always) func bound(_ value: Float, _ axis: YogaFlexDirection, _ direction: YogaDirection, _ reference: Float, _ width: Float) -> Float {
        _style.bound(value, axis, direction, reference, width)
    }

    @inline(__always) var grow: Float { _style.flexGrow ?? maxDefined(0, _style.flex ?? 0) }
    @inline(__always) var shrink: Float {
        if let value = _style.flexShrink { return value }
        if !configuration.useWebDefaults, let flex = _style.flex, flex < 0 { return -flex }
        return configuration.useWebDefaults ? 1 : 0
    }
    @inline(__always) var isFlexible: Bool { _style.positionType != .absolute && (grow != 0 || shrink != 0) }

    @inline(__always) func alignment(of child: LayoutNode) -> YogaAlign {
        let value = child._style.alignSelf == .auto ? _style.alignItems : child._style.alignSelf
        return value == .baseline && !_style.flexDirection.isRow ? .flexStart : value
    }

    func layoutChildren() -> LayoutChildren {
        if record.pointee.flattened != nil { resetContents() }
        return LayoutChildren(base: base, indices: record.pointee.flattened ?? record.pointee.children)
    }

    private func resetContents() {
        for child in children where child._style.display == .contents {
            child.layout = YogaLayout()
            child.measured = .zero
            child.hasNewLayout = true
            child.isDirty = false
            child.resetContents()
        }
    }

    func zeroLayout() {
        layout = YogaLayout()
        measured = .zero
        hasNewLayout = true
        isDirty = false
        cachedLayout = nil
        if !cachedMeasurements.isEmpty { cachedMeasurements.removeAll(keepingCapacity: true) }
        for child in children { child.zeroLayout() }
    }

    func relativePosition(_ axis: YogaFlexDirection, _ direction: YogaDirection, _ reference: Float) -> Float {
        let style = _style
        if style.positionType == .static { return 0 }
        let start = style.edgeValue(0, axis.inlineStart(direction), direction)
        if start.isDefined && start != .auto { return orZero(start.resolve(reference)) }
        return -style.edge(0, axis.inlineEnd(direction), direction, reference)
    }

    func setPosition(_ direction: YogaDirection, _ ownerWidth: Float, _ ownerHeight: Float, isRoot: Bool = false) {
        let style = _style
        if !style.hasPositionsOrMargins {
            layout.left = 0; layout.top = 0; layout.right = 0; layout.bottom = 0
            return
        }
        let rootDirection: YogaDirection = isRoot ? .leftToRight : direction
        let main = style.flexDirection.resolved(rootDirection)
        for axis in [main, main.cross(rootDirection)] {
            let relative = relativePosition(axis, rootDirection, axis.isRow ? ownerWidth : ownerHeight)
            for edge in [axis.inlineStart(direction), axis.inlineEnd(direction)] {
                layout[position: edge] = style.edge(1, edge, direction, ownerWidth) + relative
            }
        }
    }

    func calculateBaseline() -> Float {
        if let baseline {
            let value: Float
            switch baseline {
            case .node(let callback): value = callback(facade, measured.x, measured.y)
            case .content(let callback): value = callback(layout, measured.x, measured.y)
            }
            precondition(value.isFinite, "A baseline callback must return a finite value")
            return value
        }
        var first: LayoutNode?
        for child in layoutChildren() {
            if child.lineIndex > 0 { break }
            if child._style.positionType == .absolute || child._style.display == .none { continue }
            if first == nil { first = child }
            if alignment(of: child) == .baseline || child.isReferenceBaseline { first = child; break }
        }
        guard let first else { return measured.y }
        return first.calculateBaseline() + first.layout.top
    }
}
