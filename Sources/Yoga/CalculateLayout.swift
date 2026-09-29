// Derived from React Yoga 3.2.1. Copyright (c) Meta Platforms, Inc. and affiliates.
// Licensed under the MIT license in THIRD_PARTY_NOTICES.md.
extension LayoutNode {
    func layoutImplementation(_ width: Float, _ height: Float, _ ownerDirection: YogaDirection,
                              _ widthMode: YogaMeasureMode, _ heightMode: YogaMeasureMode,
                              _ ownerWidth: Float, _ ownerHeight: Float, _ performLayout: Bool,
                              _ generation: UInt64, _ depth: Int) {
        let style = _style
        if style.display == .none { zeroLayout(); return }
        let direction = resolveDirection(ownerDirection)
        layout.direction = direction
        if !style.hasBoxEdges {
            layout.margin = YogaInsets()
            layout.padding = YogaInsets()
            layout.border = YogaInsets()
        } else {
            for edge: YogaEdge in [.left, .top, .right, .bottom] {
                layout.margin[edge] = style.edge(1, edge, direction, ownerWidth)
                layout.padding[edge] = style.edge(2, edge, direction, ownerWidth)
                layout.border[edge] = style.edge(3, edge, direction, 0)
            }
        }
        let marginWidth = style.margin(.row, ownerWidth)
        let marginHeight = style.margin(.column, ownerWidth)
        let layoutChildren = layoutChildren()
        if measure != nil || layoutChildren.isEmpty {
            measureLeaf(width - marginWidth, height - marginHeight, widthMode, heightMode, direction, ownerWidth, ownerHeight)
            return
        }
        if !performLayout && ((widthMode == .atMost && width - marginWidth <= 0)
            || (heightMode == .atMost && height - marginHeight <= 0) || (widthMode == .exactly && heightMode == .exactly)) {
            measured.x = bound(width.isNaN || (widthMode == .atMost && width < marginWidth) ? 0 : width - marginWidth, .row, direction, ownerWidth, ownerWidth)
            measured.y = bound(height.isNaN || (heightMode == .atMost && height < marginHeight) ? 0 : height - marginHeight, .column, direction, ownerHeight, ownerWidth)
            return
        }
        layout.hadOverflow = false
        let main = style.flexDirection.resolved(direction)
        let cross = main.cross(direction)
        let padWidth = style.paddingBorder(.row, direction, ownerWidth)
        let padHeight = style.paddingBorder(.column, direction, ownerWidth)
        let innerWidth = availableInner(width - marginWidth, .row, direction, ownerWidth, ownerWidth, padWidth)
        let innerHeight = availableInner(height - marginHeight, .column, direction, ownerHeight, ownerWidth, padHeight)
        var c = LayoutContext(direction: direction, main: main, cross: cross, widthMode: widthMode, heightMode: heightMode,
                              mainMode: main.isRow ? widthMode : heightMode, crossMode: main.isRow ? heightMode : widthMode,
                              innerWidth: innerWidth, innerHeight: innerHeight, innerMain: main.isRow ? innerWidth : innerHeight,
                              innerCross: main.isRow ? innerHeight : innerWidth, ownerWidth: ownerWidth, ownerHeight: ownerHeight,
                              mainOwner: main.isRow ? ownerWidth : ownerHeight, crossOwner: main.isRow ? ownerHeight : ownerWidth,
                              paddingMain: main.isRow ? padWidth : padHeight, paddingCross: main.isRow ? padHeight : padWidth,
                              leadingCross: style.paddingBorder(cross.start, direction, ownerWidth),
                              performLayout: performLayout, generation: generation, depth: depth)
        var singleFlexChild: LayoutNode?
        if c.mainMode == .exactly {
            for child in layoutChildren where child.isFlexible {
                if singleFlexChild != nil || approximatelyEqual(child.grow, 0) || approximatelyEqual(child.shrink, 0) {
                    singleFlexChild = nil; break
                }
                singleFlexChild = child
            }
        }
        var totalBasis: Float = 0
        let flow = LayoutChildren(base: base, indices: record.pointee.flow)
        for child in layoutChildren {
            let childStyle = child._style
            if childStyle.display == .none { child.zeroLayout(); continue }
            if performLayout { child.setPosition(child.resolveDirection(direction), innerWidth, innerHeight) }
            if childStyle.positionType == .absolute { continue }
            if child == singleFlexChild {
                child.computedFlexBasis = 0
            } else { computeBasis(for: child, in: c) }
            totalBasis += child.computedFlexBasis + childStyle.margin(main, innerWidth)
        }
        if layoutChildren.count > 1 { totalBasis += style.gap(main, c.innerMain) * Float(layoutChildren.count - 1) }
        c.mainOverflows = c.mainMode != .undefined && totalBasis > c.innerMain
        let wraps = style.wrap != .noWrap
        if wraps && c.mainOverflows && c.mainMode == .atMost { c.mainMode = .exactly }
        let baselineLayout = main.isRow && (style.alignItems == .baseline || flow.contains { $0._style.alignSelf == .baseline })
        let crossGap = style.gap(cross, c.innerCross)
        var totalCross: Float = 0
        var maxMain: Float = 0
        var lineCount = 0
        var start = 0
        repeat {
            var end = start
            var line = FlexLine(items: flow[start..<start])
            let gap = style.gap(main, c.innerMain)
            while end < flow.count {
                let child = flow[end]

                let childStyle = child._style
                let basis = childStyle.boundMinMax(child.computedFlexBasis, main, direction, c.mainOwner, ownerWidth)
                let size = basis + childStyle.margin(main, innerWidth) + (end == start ? 0 : gap)
                if wraps && end > start && line.sizeConsumed + size > c.innerMain { break }
                child.lineIndex = lineCount
                line.sizeConsumed += size
                if childStyle.edgeValue(1, main.start, ownerDirection) == .auto { line.autoMargins += 1 }
                if childStyle.edgeValue(1, main.end, ownerDirection) == .auto { line.autoMargins += 1 }
                if child.isFlexible { line.grow += child.grow; line.shrink -= child.shrink * child.computedFlexBasis }
                end += 1
            }
            line.items = flow[start..<end]
            if line.grow > 0 && line.grow < 1 { line.grow = 1 }
            if line.shrink > 0 && line.shrink < 1 { line.shrink = 1 }
            var basedOnContent = false
            if c.mainMode != .exactly {
                let minimum = style.resolved(style.minimum(main), main, direction, c.mainOwner, ownerWidth) - c.paddingMain
                let maximum = style.resolved(style.maximum(main), main, direction, c.mainOwner, ownerWidth) - c.paddingMain
                if !minimum.isNaN && line.sizeConsumed < minimum { c.innerMain = minimum }
                else if !maximum.isNaN && line.sizeConsumed > maximum { c.innerMain = maximum }
                else {
                    if line.grow == 0 || parent == nil || grow == 0 { c.innerMain = line.sizeConsumed }
                    basedOnContent = true
                }
            }
            if !basedOnContent && !c.innerMain.isNaN { line.freeSpace = c.innerMain - line.sizeConsumed }
            else if line.sizeConsumed < 0 { line.freeSpace = -line.sizeConsumed }
            if performLayout || c.crossMode != .exactly { resolveFlexibleLengths(&line, c) }
            layout.hadOverflow = layout.hadOverflow || line.freeSpace < 0
            justify(&line, c, baselineLayout: baselineLayout)
            var containerCross = c.innerCross
            if c.crossMode != .exactly {
                containerCross = bound(line.crossSize + c.paddingCross, cross, direction, c.crossOwner, ownerWidth) - c.paddingCross
            }
            if !wraps && c.crossMode == .exactly { line.crossSize = c.innerCross }
            if !wraps { line.crossSize = bound(line.crossSize + c.paddingCross, cross, direction, c.crossOwner, ownerWidth) - c.paddingCross }
            if performLayout { alignLine(line, c, containerCross: containerCross, totalCross: totalCross) }
            totalCross += line.crossSize + (lineCount == 0 ? 0 : crossGap)
            maxMain = maxDefined(maxMain, line.mainSize)
            lineCount += 1
            start = end
        } while start < flow.count
        if performLayout && (wraps || baselineLayout) {
            alignLines(flow, c, lineCount: lineCount, totalCross: totalCross, crossGap: crossGap)
        }
        measured.x = bound(width - marginWidth, .row, direction, ownerWidth, ownerWidth)
        measured.y = bound(height - marginHeight, .column, direction, ownerHeight, ownerWidth)
        if c.mainMode == .undefined || (style.overflow != .scroll && c.mainMode == .atMost) {
            measured[main.dimension] = bound(maxMain, main, direction, c.mainOwner, ownerWidth)
        } else if c.mainMode == .atMost {
            measured[main.dimension] = maxDefined(c.paddingMain, minDefined(c.innerMain + c.paddingMain, boundMinMax(maxMain, main, direction, c.mainOwner, ownerWidth)))
        }
        if c.crossMode == .undefined || (style.overflow != .scroll && c.crossMode == .atMost) {
            measured[cross.dimension] = bound(totalCross + c.paddingCross, cross, direction, c.crossOwner, ownerWidth)
        } else if c.crossMode == .atMost {
            measured[cross.dimension] = maxDefined(c.paddingCross, minDefined(c.innerCross + c.paddingCross, boundMinMax(totalCross + c.paddingCross, cross, direction, c.crossOwner, ownerWidth)))
        }
        if performLayout {
            if style.wrap == .wrapReverse {
                for child in flow {
                    child.layout[position: cross.start] = measured[cross.dimension] - child.layout[position: cross.start] - child.measured[cross.dimension]
                }
            }
            setTrailingPositions(flow, main)
            setTrailingPositions(flow, cross)
            if style.positionType != .static || alwaysFormsContainingBlock || depth == 1 {
                layoutAbsoluteDescendants(containing: self, direction: direction,
                                          widthMode: main.isRow ? c.mainMode : c.crossMode,
                                          leftOffset: 0, topOffset: 0, generation: generation, depth: depth)
            }
        }
    }

    private func availableInner(_ available: Float, _ axis: YogaFlexDirection, _ direction: YogaDirection,
                                _ reference: Float, _ ownerWidth: Float, _ padding: Float) -> Float {
        let style = _style
        let inner = available - padding
        if inner.isNaN { return inner }
        let minimum = style.resolved(style.minimum(axis), axis, direction, reference, ownerWidth)
        let maximum = style.resolved(style.maximum(axis), axis, direction, reference, ownerWidth)
        return maxDefined(minDefined(inner, maximum.isNaN ? Float.greatestFiniteMagnitude : maximum - padding), minimum.isNaN ? 0 : minimum - padding)
    }

    func setTrailingPosition(_ child: LayoutNode, _ axis: YogaFlexDirection) {
        child.layout[position: axis.end] = measured[axis.dimension] - child.measured[axis.dimension] - child.layout[position: axis.start]
    }

    // Iterating a dynamically constructed two-element Array allocated once per
    // container in optimized builds. Keep axis dispatch outside the child loop.
    private func setTrailingPositions(_ children: LayoutChildren, _ axis: YogaFlexDirection) {
        if axis == .rowReverse || axis == .columnReverse {
            for child in children { setTrailingPosition(child, axis) }
        }
    }
}
