// Storage owns values; it never owns the public node handles.
struct NodeState {
    var style: YogaStyle
    var configuration: YogaConfiguration
    var layout = YogaLayout()
    var measured = SIMD2<Float>(repeating: 0)
    var computedFlexBasis: Float = .nan
    var generation: UInt64 = 0
    var rootGeneration: UInt64 = 0
    var lastOwnerDirection: YogaDirection = .inherit
    var lineIndex = 0
    var cachedLayout: LayoutCacheEntry?
    var cachedMeasurements: [LayoutCacheEntry] = []
    var isCalculating = false
    var hasRootLayout = false
    var isDirty = true
    var hasNewLayout = true
    var isReferenceBaseline = false
    var alwaysFormsContainingBlock = false
    var measure: LayoutMeasureCallback?
    var baseline: LayoutBaselineCallback?
    var handleGeneration: UInt64 = 0
    var facade: Unmanaged<YogaNode>?
    var parent = -1
    var children: [Int] = []
    var flattened: [Int]?
    var flow: [Int] = []

    @inline(__always) init(style: consuming YogaStyle = YogaStyle(), configuration: YogaConfiguration = YogaConfiguration()) {
        self.style = consume style
        self.configuration = configuration
    }
}
