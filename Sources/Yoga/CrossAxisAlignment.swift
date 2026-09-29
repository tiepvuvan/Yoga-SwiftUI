// Derived from React Yoga 3.2.1. See THIRD_PARTY_NOTICES.md.
extension LayoutNode {
    func alignLine(_ line: FlexLine, _ c: LayoutContext, containerCross: Float, totalCross: Float) {
        let style = _style
        for child in line.items {
            let childStyle = child._style
            var leading = c.leadingCross
            let align = alignment(of: child)
            let autoStart = childStyle.edgeValue(1, c.cross.start, c.direction) == .auto
            let autoEnd = childStyle.edgeValue(1, c.cross.end, c.direction) == .auto
            if align == .stretch && !autoStart && !autoEnd {
                if !childStyle.hasDefiniteLength(c.cross, c.innerCross) {
                    var mainSize = child.measured[c.main.dimension]
                    var crossSize = line.crossSize
                    if let ratio = childStyle.validAspectRatio {
                        crossSize = childStyle.margin(c.cross, c.innerWidth) + (c.main.isRow ? mainSize / ratio : mainSize * ratio)
                    }
                    mainSize += childStyle.margin(c.main, c.innerWidth)
                    var mainMode: YogaMeasureMode = .exactly
                    var crossMode: YogaMeasureMode = .exactly
                    child.constrain(c.main, c.direction, c.innerMain, c.innerWidth, &mainMode, &mainSize)
                    child.constrain(c.cross, c.direction, c.innerCross, c.innerWidth, &crossMode, &crossSize)
                    let width = c.main.isRow ? mainSize : crossSize
                    let height = c.main.isRow ? crossSize : mainSize
                    let doesNotGrow = style.alignContent != .stretch && style.wrap != .noWrap
                    child.layoutInternal(width, height, c.direction,
                                         width.isNaN || (!c.main.isRow && doesNotGrow) ? .undefined : .exactly,
                                         height.isNaN || (c.main.isRow && doesNotGrow) ? .undefined : .exactly,
                                         c.innerWidth, c.innerHeight, true, c.generation, c.depth)
                }
            } else {
                let remaining = containerCross - child.measured[c.cross.dimension] - childStyle.margin(c.cross, c.innerWidth)
                if autoStart && autoEnd { leading += maxDefined(0, remaining / 2) }
                else if autoEnd { /* An auto end margin absorbs remaining space. */ }
                else if autoStart { leading += maxDefined(0, remaining) }
                else if align == .center { leading += remaining / 2 }
                else if align != .flexStart { leading += remaining }
            }
            child.layout[position: c.cross.start] += totalCross + leading
        }
    }

    func alignLines(_ children: LayoutChildren, _ c: LayoutContext, lineCount: Int, totalCross: Float, crossGap: Float) {
        let style = _style
        var current = c.leadingCross
        var leadPerLine: Float = 0
        var extra: Float = 0
        let unclamped: Float
        if c.crossMode == .exactly { unclamped = c.innerCross + c.paddingCross }
        else if hasDefiniteLength(c.cross, c.crossOwner) { unclamped = resolvedDimension(c.cross, c.direction, c.crossOwner, c.ownerWidth) }
        else { unclamped = totalCross + c.paddingCross }
        let inner = bound(unclamped, c.cross, c.direction, c.ownerHeight, c.ownerWidth) - c.paddingCross
        let remaining = inner - totalCross
        var align = style.alignContent
        if remaining < 0 && (align == .stretch || align.rawValue >= YogaAlign.spaceBetween.rawValue) { align = .flexStart }
        switch align {
        case .flexEnd: current += remaining
        case .center: current += remaining / 2
        case .stretch: extra = remaining / Float(lineCount)
        case .spaceAround: current += remaining / (2 * Float(lineCount)); leadPerLine = remaining / Float(lineCount)
        case .spaceEvenly: leadPerLine = remaining / Float(lineCount + 1); current += leadPerLine
        case .spaceBetween: if lineCount > 1 { leadPerLine = remaining / Float(lineCount - 1) }
        default: break
        }
        var start = 0
        for index in 0..<lineCount {
            var end = start
            var lineHeight: Float = 0
            var ascent: Float = 0
            var descent: Float = 0
            while end < children.count && children[end].lineIndex == index {
                let child = children[end]

                    let childStyle = child._style
                if child.measured[c.cross.dimension] >= 0 {
                    lineHeight = maxDefined(lineHeight, child.measured[c.cross.dimension] + childStyle.margin(c.cross, c.innerWidth))
                }
                if alignment(of: child) == .baseline {
                    let a = child.calculateBaseline() + childStyle.edge(1, .top, c.direction, c.innerWidth)
                    ascent = maxDefined(ascent, a)
                    descent = maxDefined(descent, child.measured.y + childStyle.margin(.column, c.innerWidth) - a)
                    lineHeight = maxDefined(lineHeight, ascent + descent)
                }
                end += 1
            }
            if index != 0 { current += crossGap }
            lineHeight += extra
            for child in children[start..<end] {
                let childStyle = child._style
                switch alignment(of: child) {
                case .flexStart:
                    child.layout[position: c.cross.start] = current + childStyle.edge(0, c.cross.start, c.direction, c.innerWidth)
                case .flexEnd:
                    child.layout[position: c.cross.start] = current + lineHeight - childStyle.edge(1, c.cross.end, c.direction, c.innerWidth) - child.measured[c.cross.dimension]
                case .center:
                    child.layout[position: c.cross.start] = current + (lineHeight - child.measured[c.cross.dimension]) / 2
                case .stretch:
                    child.layout[position: c.cross.start] = current + childStyle.edge(1, c.cross.start, c.direction, c.innerWidth)
                    if !childStyle.hasDefiniteLength(c.cross, c.innerCross) {
                        let width = c.main.isRow ? child.measured.x + childStyle.margin(c.main, c.innerWidth) : leadPerLine + lineHeight
                        let height = !c.main.isRow ? child.measured.y + childStyle.margin(c.cross, c.innerWidth) : leadPerLine + lineHeight
                        if !approximatelyEqual(width, child.measured.x) || !approximatelyEqual(height, child.measured.y) {
                            child.layoutInternal(width, height, c.direction, .exactly, .exactly, c.innerWidth, c.innerHeight, true, c.generation, c.depth)
                        }
                    }
                case .baseline:
                    child.layout.top = current + ascent - child.calculateBaseline() + childStyle.edge(0, .top, c.direction, c.innerCross)
                default: break
                }
            }
            current += leadPerLine + lineHeight
            start = end
        }
    }
}
