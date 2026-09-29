// Derived from React Yoga 3.2.1. See THIRD_PARTY_NOTICES.md.
extension LayoutNode {
    func layoutAbsoluteDescendants(containing: LayoutNode, direction: YogaDirection, widthMode: YogaMeasureMode,
                                   leftOffset: Float, topOffset: Float, generation: UInt64, depth: Int) {
        let style = _style
        let containingWidth = containing.measured.x - containing._style.edge(3, .left, .leftToRight, 0) - containing._style.edge(3, .right, .leftToRight, 0)
        let containingHeight = containing.measured.y - containing._style.edge(3, .top, .leftToRight, 0) - containing._style.edge(3, .bottom, .leftToRight, 0)
        for child in layoutChildren() {
            let childStyle = child._style
            if childStyle.display == .none { continue }
            if childStyle.positionType == .absolute {
                layoutAbsolute(child, containing: containing, width: containingWidth, height: containingHeight,
                               widthMode: widthMode, direction: direction, generation: generation, depth: depth)
                let main = style.flexDirection.resolved(direction)
                for axis in [main, main.cross(direction)] where axis == .rowReverse || axis == .columnReverse {
                    (child.hasInsets(axis) ? containing : self).setTrailingPosition(child, axis)
                }
                if child.hasInsets(.row) { child.layout.left -= leftOffset }
                if child.hasInsets(.column) { child.layout.top -= topOffset }
            } else if childStyle.positionType == .static && !child.alwaysFormsContainingBlock {
                child.layoutAbsoluteDescendants(containing: containing, direction: child.resolveDirection(direction), widthMode: widthMode,
                                                leftOffset: leftOffset + child.layout.left, topOffset: topOffset + child.layout.top,
                                                generation: generation, depth: depth + 1)
                child.hasNewLayout = true
            }
        }
    }

    private func hasInsets(_ axis: YogaFlexDirection) -> Bool {
        let style = _style
        let edges: [YogaEdge] = axis.isRow ? [.left, .right, .start, .end, .horizontal, .all] : [.top, .bottom, .vertical, .all]
        return edges.contains { style.position(for: $0).isDefined }
    }

    private func layoutAbsolute(_ child: LayoutNode, containing: LayoutNode, width: Float, height: Float,
                                widthMode: YogaMeasureMode, direction: YogaDirection, generation: UInt64, depth: Int) {
        let style = _style
        let childStyle = child._style
        let main = style.flexDirection.resolved(direction)
        var size = SIMD2<Float>(repeating: .nan)
        let margin = SIMD2<Float>(childStyle.margin(.row, width), childStyle.margin(.column, width))
        for axis: YogaFlexDirection in [.row, .column] {
            let reference = axis.isRow ? width : height
            if childStyle.hasDefiniteLength(axis, reference) {
                size[axis.dimension] = childStyle.resolvedDimension(axis, direction, reference, width) + margin[axis.dimension]
            } else {
                let start = childStyle.edgeValue(0, axis.start, direction)
                let end = childStyle.edgeValue(0, axis.end, direction)
                if start.isDefined && end.isDefined && start != .auto && end != .auto {
                    let value = containing.measured[axis.dimension]
                        - containing._style.edge(3, axis.start, direction, 0) - containing._style.edge(3, axis.end, direction, 0)
                        - orZero(start.resolve(reference)) - orZero(end.resolve(reference))
                    size[axis.dimension] = childStyle.bound(value, axis, direction, reference, width)
                }
            }
        }
        if size.x.isNaN != size.y.isNaN, let ratio = childStyle.validAspectRatio {
            if size.x.isNaN { size.x = margin.x + (size.y - margin.y) * ratio }
            else { size.y = margin.y + (size.x - margin.x) / ratio }
        }
        if size.x.isNaN || size.y.isNaN {
            var childWidthMode: YogaMeasureMode = size.x.isNaN ? .undefined : .exactly
            let childHeightMode: YogaMeasureMode = size.y.isNaN ? .undefined : .exactly
            if !main.isRow && size.x.isNaN && widthMode != .undefined && width > 0 {
                size.x = width; childWidthMode = .atMost
            }
            child.layoutInternal(size.x, size.y, direction, childWidthMode, childHeightMode, width, height, false, generation, depth)
            size = child.measured + margin
        }
        child.layoutInternal(size.x, size.y, direction, .exactly, .exactly, width, height, true, generation, depth)
        positionAbsolute(child, containing: containing, axis: main, mainAxis: true, width: width, height: height, direction: direction)
        positionAbsolute(child, containing: containing, axis: main.cross(direction), mainAxis: false, width: width, height: height, direction: direction)
    }

    private func positionAbsolute(_ child: LayoutNode, containing: LayoutNode, axis: YogaFlexDirection, mainAxis: Bool,
                                  width: Float, height: Float, direction: YogaDirection) {
        let style = _style
        let childStyle = child._style
        let reference = axis.isRow ? width : height
        let startEdge = axis.inlineStart(direction)
        let endEdge = axis.inlineEnd(direction)
        let start = childStyle.edgeValue(0, startEdge, direction)
        let end = childStyle.edgeValue(0, endEdge, direction)
        var position: Float
        if start.isDefined && start != .auto {
            position = orZero(start.resolve(reference)) + containing._style.edge(3, startEdge, direction, 0)
                + childStyle.edge(1, startEdge, direction, reference)
            if startEdge != axis.start { position = containing.measured[axis.dimension] - child.measured[axis.dimension] - position }
        } else if end.isDefined && end != .auto {
            position = containing.measured[axis.dimension] - child.measured[axis.dimension]
                - containing._style.edge(3, endEdge, direction, 0) - childStyle.edge(1, endEdge, direction, reference) - orZero(end.resolve(reference))
            if startEdge != axis.start { position = containing.measured[axis.dimension] - child.measured[axis.dimension] - position }
        } else {
            var align: YogaAlign
            if mainAxis {
                switch style.justifyContent {
                case .flexEnd: align = .flexEnd
                case .center, .spaceAround, .spaceEvenly: align = .center
                default: align = .flexStart
                }
            } else {
                align = alignment(of: child)
                if style.wrap == .wrapReverse {
                    if align == .flexEnd { align = .flexStart }
                    else if align != .center { align = .flexEnd }
                }
            }
            let leading = layout.border[axis.start] + layout.padding[axis.start]
            let trailing = layout.border[axis.end] + layout.padding[axis.end]
            let startMargin = childStyle.edge(1, axis.start, direction, width)
            if align == .flexEnd {
                position = measured[axis.dimension] - child.measured[axis.dimension] - trailing - childStyle.edge(1, axis.end, direction, width)
            } else if align == .center {
                position = (measured[axis.dimension] - leading - trailing - child.measured[axis.dimension] - childStyle.margin(axis, width)) / 2 + leading + startMargin
            } else { position = leading + startMargin }
        }
        child.layout[position: axis.start] = position
    }
}
