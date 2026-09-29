// Derived from React Yoga 3.2.1. See THIRD_PARTY_NOTICES.md.
extension LayoutNode {
    func resolveFlexibleLengths(_ line: inout FlexLine, _ c: LayoutContext) {
        let style = _style
        let originalFreeSpace = line.freeSpace
        var delta: Float = 0
        // Yoga's two-pass distribution freezes children that hit min/max bounds,
        // then redistributes their unused share among the remaining children.
        for child in line.items {
            let childStyle = child._style
            let basis = childStyle.boundMinMax(child.computedFlexBasis, c.main, c.direction, c.mainOwner, c.ownerWidth)
            if line.freeSpace < 0 {
                let factor = -child.shrink * basis
                if factor != 0 {
                    let base = basis.addingProduct(line.freeSpace / line.shrink, factor)
                    let bound = childStyle.bound(base, c.main, c.direction, c.innerMain, c.innerWidth)
                    if base.isFinite && bound.isFinite && base != bound {
                        delta += bound - basis
                        line.shrink -= -child.shrink * child.computedFlexBasis
                    }
                }
            } else if line.freeSpace > 0 && child.grow != 0 {
                let base = basis.addingProduct(line.freeSpace / line.grow, child.grow)
                let bound = childStyle.bound(base, c.main, c.direction, c.innerMain, c.innerWidth)
                if base.isFinite && bound.isFinite && base != bound {
                    delta += bound - basis
                    line.grow -= child.grow
                }
            }
        }
        line.freeSpace -= delta
        delta = 0
        for child in line.items {
            let childStyle = child._style
            let basis = childStyle.boundMinMax(child.computedFlexBasis, c.main, c.direction, c.mainOwner, c.ownerWidth)
            var mainSize = basis
            if line.freeSpace < 0 {
                let factor = -child.shrink * basis
                if factor != 0 {
                    let size = line.shrink == 0 ? basis + factor : basis.addingProduct(line.freeSpace / line.shrink, factor)
                    mainSize = childStyle.bound(size, c.main, c.direction, c.innerMain, c.innerWidth)
                }
            } else if line.freeSpace > 0 && child.grow != 0 {
                mainSize = childStyle.bound(basis.addingProduct(line.freeSpace / line.grow, child.grow), c.main, c.direction, c.innerMain, c.innerWidth)
            }
            delta += mainSize - basis
            let marginMain = childStyle.margin(c.main, c.innerWidth)
            let marginCross = childStyle.margin(c.cross, c.innerWidth)
            mainSize += marginMain
            var crossSize: Float
            var crossMode: YogaMeasureMode
            var mainMode: YogaMeasureMode = .exactly
            let stretch = alignment(of: child) == .stretch
                && childStyle.edgeValue(1, c.cross.start, c.direction) != .auto
                && childStyle.edgeValue(1, c.cross.end, c.direction) != .auto
            let definiteCross = childStyle.hasDefiniteLength(c.cross, c.innerCross)
            if let ratio = childStyle.validAspectRatio {
                crossSize = (c.main.isRow ? (mainSize - marginMain) / ratio : (mainSize - marginMain) * ratio) + marginCross
                crossMode = .exactly
            } else if !c.innerCross.isNaN && !definiteCross && c.crossMode == .exactly
                        && !(style.wrap != .noWrap && c.mainOverflows) && stretch {
                crossSize = c.innerCross; crossMode = .exactly
            } else if !definiteCross {
                crossSize = c.innerCross; crossMode = crossSize.isNaN ? .undefined : .atMost
            } else {
                crossSize = childStyle.resolvedDimension(c.cross, c.direction, c.innerCross, c.innerWidth) + marginCross
                let loose = childStyle.processedDimension(c.cross).isPercent && c.crossMode != .exactly
                crossMode = crossSize.isNaN || loose ? .undefined : .exactly
            }
            child.constrain(c.main, c.direction, c.innerMain, c.innerWidth, &mainMode, &mainSize)
            child.constrain(c.cross, c.direction, c.innerCross, c.innerWidth, &crossMode, &crossSize)
            child.layoutInternal(c.main.isRow ? mainSize : crossSize, c.main.isRow ? crossSize : mainSize,
                                 c.direction, c.main.isRow ? mainMode : crossMode, c.main.isRow ? crossMode : mainMode,
                                 c.innerWidth, c.innerHeight, c.performLayout && !(stretch && !definiteCross), c.generation, c.depth)
            layout.hadOverflow = layout.hadOverflow || child.layout.hadOverflow
        }
        line.freeSpace = originalFreeSpace - delta
    }

    func justify(_ line: inout FlexLine, _ c: LayoutContext, baselineLayout: Bool) {
        let style = _style
        let leading = style.paddingBorder(c.main.start, c.direction, c.ownerWidth)
        let trailing = style.paddingBorder(c.main.end, c.direction, c.ownerWidth)
        if c.mainMode == .atMost && line.freeSpace > 0 {
            let minimum = style.resolved(style.minimum(c.main), c.main, c.direction, c.mainOwner, c.ownerWidth)
            line.freeSpace = minimum.isNaN ? 0 : maxDefined(0, minimum - leading - trailing - (c.innerMain - line.freeSpace))
        }
        var lead: Float = 0
        var between = style.gap(c.main, c.innerMain)
        let justify: YogaJustify = line.freeSpace < 0 && style.justifyContent.rawValue >= YogaJustify.spaceBetween.rawValue ? .flexStart : style.justifyContent
        if line.autoMargins == 0 {
            switch justify {
            case .center: lead = line.freeSpace / 2
            case .flexEnd: lead = line.freeSpace
            case .spaceBetween: if line.items.count > 1 { between += line.freeSpace / Float(line.items.count - 1) }
            case .spaceEvenly: lead = line.freeSpace / Float(line.items.count + 1); between += lead
            case .spaceAround: if !line.items.isEmpty { lead = line.freeSpace / Float(line.items.count) / 2; between += lead * 2 }
            case .flexStart: break
            }
        }
        line.mainSize = leading + lead
        var ascent: Float = 0
        var descent: Float = 0
        for (offset, child) in line.items.enumerated() {
            let childStyle = child._style
            if childStyle.edgeValue(1, c.main.start, c.direction) == .auto && line.freeSpace > 0 {
                line.mainSize += line.freeSpace / Float(line.autoMargins)
            }
            if c.performLayout { child.layout[position: c.main.start] += line.mainSize }
            if offset != line.items.count - 1 { line.mainSize += between }
            if childStyle.edgeValue(1, c.main.end, c.direction) == .auto && line.freeSpace > 0 {
                line.mainSize += line.freeSpace / Float(line.autoMargins)
            }
            if !c.performLayout && c.crossMode == .exactly {
                line.mainSize += childStyle.margin(c.main, c.innerWidth) + child.computedFlexBasis
                line.crossSize = c.innerCross
            } else {
                line.mainSize += child.measured[c.main.dimension] + childStyle.margin(c.main, c.innerWidth)
                if baselineLayout {
                    let a = child.calculateBaseline() + childStyle.edge(1, .top, c.direction, c.innerWidth)
                    ascent = maxDefined(ascent, a)
                    descent = maxDefined(descent, child.measured.y + childStyle.margin(.column, c.innerWidth) - a)
                } else {
                    line.crossSize = maxDefined(line.crossSize, child.measured[c.cross.dimension] + childStyle.margin(c.cross, c.innerWidth))
                }
            }
        }
        line.mainSize += trailing
        if baselineLayout { line.crossSize = ascent + descent }
    }
}
