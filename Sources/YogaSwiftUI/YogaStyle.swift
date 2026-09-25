import YogaBridge

/// Internal Yoga node configuration. Public callers use container and item modifiers.
struct YogaStyle: Sendable {
    /// Overrides the inherited left-to-right or right-to-left layout direction.
    var direction: YGDirection?
    /// Chooses the main axis and its order.
    var flexDirection: YGFlexDirection?
    /// Distributes children along the main axis.
    var justifyContent: YGJustify?
    /// Distributes wrapped lines along the cross axis.
    var alignContent: YGAlign?
    /// Aligns children along the cross axis.
    var alignItems: YGAlign?
    /// Overrides cross-axis alignment for a direct child.
    var alignSelf: YGAlign?
    /// Selects static, relative, or absolute positioning.
    var positionType: YGPositionType?
    /// Controls whether children wrap to additional lines.
    var wrap: YGWrap?
    /// Controls Yoga overflow behavior. Hidden overflow also clips the SwiftUI view.
    var overflow: YGOverflow?
    /// Controls participation in layout; `none` removes an item from placement.
    var display: YGDisplay?
    /// Chooses whether specified dimensions include padding and border.
    var boxSizing: YGBoxSizing?

    /// Yoga's flex shorthand. Prefer grow, shrink, and basis for explicit behavior.
    var flex: Float?
    /// Relative share of remaining space along the main axis.
    var flexGrow: Float?
    /// Relative share of the size reduction when space is insufficient.
    var flexShrink: Float?
    /// Initial size along the main axis before growth or shrinkage.
    var flexBasis: YogaDimension?
    /// Preferred width of the Yoga box.
    var width: YogaDimension?
    /// Preferred height of the Yoga box.
    var height: YogaDimension?
    /// Minimum width of the Yoga box.
    var minWidth: YogaDimension?
    /// Minimum height of the Yoga box.
    var minHeight: YogaDimension?
    /// Maximum width of the Yoga box.
    var maxWidth: YogaDimension?
    /// Maximum height of the Yoga box.
    var maxHeight: YogaDimension?
    /// Width-to-height ratio used when Yoga derives one dimension from the other.
    var aspectRatio: Float?

    private var positions: [(YGEdge, YogaDimension)] = []
    private var margins: [(YGEdge, YogaDimension)] = []
    private var paddings: [(YGEdge, YogaDimension)] = []
    private var borders: [(YGEdge, Float)] = []
    private var gaps: [(YGGutter, YogaDimension)] = []

    /// Creates a style with no explicit values; Yoga uses its configured web defaults.
    init() {}

    /// Sets an inset for relative or absolute positioning. Static positioning ignores insets.
    /// Logical `start` and `end` edges follow layout direction.
    mutating func setPosition(_ value: YogaDimension, for edge: YGEdge) {
        positions.removeAll { $0.0 == edge }
        positions.append((edge, value))
    }

    /// Sets a margin on a physical, logical, or grouped edge.
    /// Use `.auto` to let a margin absorb free space.
    mutating func setMargin(_ value: YogaDimension, for edge: YGEdge) {
        margins.removeAll { $0.0 == edge }
        margins.append((edge, value))
    }

    /// Sets padding inside the Yoga box. `.auto` clears an explicit value.
    mutating func setPadding(_ value: YogaDimension, for edge: YGEdge) {
        paddings.removeAll { $0.0 == edge }
        paddings.append((edge, value))
    }

    /// Reserves border width in layout; draw the border with SwiftUI.
    mutating func setBorder(_ value: Float, for edge: YGEdge) {
        borders.removeAll { $0.0 == edge }
        borders.append((edge, value))
    }

    /// Sets row, column, or all gaps. Percentages use the 0–100 scale.
    mutating func setGap(_ value: YogaDimension, for gutter: YGGutter) {
        gaps.removeAll { $0.0 == gutter }
        gaps.append((gutter, value))
    }

    func apply(to node: YGNodeRef) {
        if let direction { YGNodeStyleSetDirection(node, direction) }
        if let flexDirection { YGNodeStyleSetFlexDirection(node, flexDirection) }
        if let justifyContent { YGNodeStyleSetJustifyContent(node, justifyContent) }
        if let alignContent { YGNodeStyleSetAlignContent(node, alignContent) }
        if let alignItems { YGNodeStyleSetAlignItems(node, alignItems) }
        if let alignSelf { YGNodeStyleSetAlignSelf(node, alignSelf) }
        if let positionType { YGNodeStyleSetPositionType(node, positionType) }
        if let wrap { YGNodeStyleSetFlexWrap(node, wrap) }
        if let overflow { YGNodeStyleSetOverflow(node, overflow) }
        if let display { YGNodeStyleSetDisplay(node, display) }
        if let boxSizing { YGNodeStyleSetBoxSizing(node, boxSizing) }
        if let flex { YGNodeStyleSetFlex(node, flex) }
        if let flexGrow { YGNodeStyleSetFlexGrow(node, flexGrow) }
        if let flexShrink { YGNodeStyleSetFlexShrink(node, flexShrink) }
        if let flexBasis { applyFlexBasis(flexBasis, to: node) }
        if let width { applyWidth(width, to: node) }
        if let height { applyHeight(height, to: node) }
        if let minWidth { applyMinWidth(minWidth, to: node) }
        if let minHeight { applyMinHeight(minHeight, to: node) }
        if let maxWidth { applyMaxWidth(maxWidth, to: node) }
        if let maxHeight { applyMaxHeight(maxHeight, to: node) }
        if let aspectRatio { YGNodeStyleSetAspectRatio(node, aspectRatio) }

        for (edge, value) in positions {
            switch value {
            case .auto: YGNodeStyleSetPositionAuto(node, edge)
            case .point(let points): YGNodeStyleSetPosition(node, edge, points)
            case .percent(let percent): YGNodeStyleSetPositionPercent(node, edge, percent)
            }
        }
        for (edge, value) in margins {
            switch value {
            case .auto: YGNodeStyleSetMarginAuto(node, edge)
            case .point(let points): YGNodeStyleSetMargin(node, edge, points)
            case .percent(let percent): YGNodeStyleSetMarginPercent(node, edge, percent)
            }
        }
        for (edge, value) in paddings {
            switch value {
            case .auto: YGNodeStyleSetPadding(node, edge, Float.nan)
            case .point(let points): YGNodeStyleSetPadding(node, edge, points)
            case .percent(let percent): YGNodeStyleSetPaddingPercent(node, edge, percent)
            }
        }
        for (edge, value) in borders {
            YGNodeStyleSetBorder(node, edge, value)
        }
        for (gutter, value) in gaps {
            switch value {
            case .auto: YGNodeStyleSetGap(node, gutter, Float.nan)
            case .point(let points): YGNodeStyleSetGap(node, gutter, points)
            case .percent(let percent): YGNodeStyleSetGapPercent(node, gutter, percent)
            }
        }
    }
}

private func applyFlexBasis(_ value: YogaDimension, to node: YGNodeRef) {
    switch value {
    case .auto: YGNodeStyleSetFlexBasisAuto(node)
    case .point(let points): YGNodeStyleSetFlexBasis(node, points)
    case .percent(let percent): YGNodeStyleSetFlexBasisPercent(node, percent)
    }
}

private func applyWidth(_ value: YogaDimension, to node: YGNodeRef) {
    switch value {
    case .auto: YGNodeStyleSetWidthAuto(node)
    case .point(let points): YGNodeStyleSetWidth(node, points)
    case .percent(let percent): YGNodeStyleSetWidthPercent(node, percent)
    }
}

private func applyHeight(_ value: YogaDimension, to node: YGNodeRef) {
    switch value {
    case .auto: YGNodeStyleSetHeightAuto(node)
    case .point(let points): YGNodeStyleSetHeight(node, points)
    case .percent(let percent): YGNodeStyleSetHeightPercent(node, percent)
    }
}

private func applyMinWidth(_ value: YogaDimension, to node: YGNodeRef) {
    switch value {
    case .auto: YGNodeStyleSetMinWidth(node, Float.nan)
    case .point(let points): YGNodeStyleSetMinWidth(node, points)
    case .percent(let percent): YGNodeStyleSetMinWidthPercent(node, percent)
    }
}

private func applyMinHeight(_ value: YogaDimension, to node: YGNodeRef) {
    switch value {
    case .auto: YGNodeStyleSetMinHeight(node, Float.nan)
    case .point(let points): YGNodeStyleSetMinHeight(node, points)
    case .percent(let percent): YGNodeStyleSetMinHeightPercent(node, percent)
    }
}

private func applyMaxWidth(_ value: YogaDimension, to node: YGNodeRef) {
    switch value {
    case .auto: YGNodeStyleSetMaxWidth(node, Float.nan)
    case .point(let points): YGNodeStyleSetMaxWidth(node, points)
    case .percent(let percent): YGNodeStyleSetMaxWidthPercent(node, percent)
    }
}

private func applyMaxHeight(_ value: YogaDimension, to node: YGNodeRef) {
    switch value {
    case .auto: YGNodeStyleSetMaxHeight(node, Float.nan)
    case .point(let points): YGNodeStyleSetMaxHeight(node, points)
    case .percent(let percent): YGNodeStyleSetMaxHeightPercent(node, percent)
    }
}
