// Derived from React Yoga 3.2.1. See THIRD_PARTY_NOTICES.md.
extension LayoutNode {
    @discardableResult
    func layoutInternal(_ width: Float, _ height: Float, _ ownerDirection: YogaDirection,
                        _ widthMode: YogaMeasureMode, _ heightMode: YogaMeasureMode,
                        _ ownerWidth: Float, _ ownerHeight: Float, _ performLayout: Bool,
                        _ generation: UInt64, _ depth: Int) -> Bool {
        precondition(depth < 1024, "Layout trees must be less than 1024 nodes deep")
        let needsVisit = (isDirty && self.generation != generation) || lastOwnerDirection != ownerDirection
        if needsVisit {
            cachedLayout = nil
            if !cachedMeasurements.isEmpty { cachedMeasurements.removeAll(keepingCapacity: true) }
        }
        let style = _style
        let cached: LayoutCacheEntry?
        if needsVisit { cached = nil }
        else if measure != nil {
            func compatible(_ entry: LayoutCacheEntry) -> Bool {
                entry.compatibleMeasurement(width, height, widthMode, heightMode, ownerWidth, ownerHeight,
                                            style: style, scale: configuration.pointScaleFactor)
            }
            if let entry = cachedLayout, compatible(entry) { cached = entry }
            else { cached = cachedMeasurements.first(where: compatible) }
        } else {
            let dependsOnOwner = style.dependsOnOwner
            if let entry = cachedLayout,
               entry.matches(width, height, widthMode, heightMode, ownerWidth, ownerHeight, dependsOnOwner: dependsOnOwner) { cached = entry }
            else if !performLayout {
                cached = cachedMeasurements.first { $0.matches(width, height, widthMode, heightMode, ownerWidth, ownerHeight, dependsOnOwner: dependsOnOwner) }
            } else { cached = nil }
        }
        if !needsVisit, let cached {
            measured = cached.measured
        } else {
            precondition(!isCalculating, "Layout callbacks cannot reenter layout")
            isCalculating = true
            layoutImplementation(width, height, ownerDirection, widthMode, heightMode,
                                 ownerWidth, ownerHeight, performLayout, generation, depth + 1)
            isCalculating = false
            lastOwnerDirection = ownerDirection
            let entry = LayoutCacheEntry(width: width, height: height, ownerWidth: ownerWidth, ownerHeight: ownerHeight,
                                         widthMode: widthMode, heightMode: heightMode, measured: measured)
            if performLayout { cachedLayout = entry }
            else {
                if cachedMeasurements.count == 4 { cachedMeasurements.removeAll(keepingCapacity: true) }
                cachedMeasurements.append(entry)
            }
        }
        if performLayout {
            layout.width = measured.x
            layout.height = measured.y
            hasNewLayout = true
            isDirty = false
        }
        self.generation = generation
        return needsVisit || cached == nil
    }

    func constrain(_ axis: YogaFlexDirection, _ direction: YogaDirection, _ reference: Float, _ ownerWidth: Float,
                   _ mode: inout YogaMeasureMode, _ size: inout Float) {
        let style = _style
        let maximum = style.resolved(style.maximum(axis), axis, direction, reference, ownerWidth) + style.margin(axis, ownerWidth)
        if mode == .undefined {
            if !maximum.isNaN { mode = .atMost; size = maximum }
        } else if !maximum.isNaN && (size.isNaN || size > maximum) { size = maximum }
    }

    func computeBasis(for child: LayoutNode, in context: LayoutContext) {
        let style = _style
        let childStyle = child._style
        let main = context.main
        let direction = context.direction
        let width = context.innerWidth
        let height = context.innerHeight
        let mainSize = main.isRow ? width : height
        var basis = childStyle.flexBasis
        if basis == .auto || !basis.isDefined {
            basis = (childStyle.flex ?? 0) > 0 && !child.configuration.useWebDefaults ? .point(0) : .auto
        }
        let resolvedBasis = childStyle.resolved(basis, main, direction, mainSize, width)
        let definiteWidth = childStyle.hasDefiniteLength(.row, width)
        let definiteHeight = childStyle.hasDefiniteLength(.column, height)
        if !resolvedBasis.isNaN && !mainSize.isNaN {
            child.computedFlexBasis = maxDefined(resolvedBasis, childStyle.paddingBorder(main, direction, width))
        } else if main.isRow && definiteWidth {
            child.computedFlexBasis = maxDefined(childStyle.resolvedDimension(.row, direction, width, width), childStyle.paddingBorder(.row, direction, width))
        } else if !main.isRow && definiteHeight {
            child.computedFlexBasis = maxDefined(childStyle.resolvedDimension(.column, direction, height, width), childStyle.paddingBorder(.column, direction, width))
        } else {
            var childWidth: Float = .nan
            var childHeight: Float = .nan
            var widthMode: YogaMeasureMode = .undefined
            var heightMode: YogaMeasureMode = .undefined
            let marginRow = childStyle.margin(.row, width)
            let marginColumn = childStyle.margin(.column, width)
            if definiteWidth {
                childWidth = childStyle.resolvedDimension(.row, direction, width, width) + marginRow
                widthMode = .exactly
            }
            if definiteHeight {
                childHeight = childStyle.resolvedDimension(.column, direction, height, width) + marginColumn
                heightMode = .exactly
            }
            if (!main.isRow || style.overflow != .scroll) && childWidth.isNaN && !width.isNaN {
                childWidth = width; widthMode = .atMost
            }
            if (main.isRow || style.overflow != .scroll) && childHeight.isNaN && !height.isNaN {
                childHeight = height; heightMode = .atMost
            }
            if let ratio = childStyle.validAspectRatio {
                if !main.isRow && widthMode == .exactly {
                    childHeight = marginColumn + (childWidth - marginRow) / ratio; heightMode = .exactly
                } else if main.isRow && heightMode == .exactly {
                    childWidth = marginRow + (childHeight - marginColumn) * ratio; widthMode = .exactly
                }
            }
            if !main.isRow && !definiteWidth && !width.isNaN && context.widthMode == .exactly
                && alignment(of: child) == .stretch && widthMode != .exactly {
                childWidth = width; widthMode = .exactly
                if let ratio = childStyle.validAspectRatio {
                    childHeight = (childWidth - marginRow) / ratio; heightMode = .exactly
                }
            }
            if main.isRow && !definiteHeight && !height.isNaN && context.heightMode == .exactly
                && alignment(of: child) == .stretch && heightMode != .exactly {
                childHeight = height; heightMode = .exactly
                if let ratio = childStyle.validAspectRatio {
                    childWidth = (childHeight - marginColumn) * ratio; widthMode = .exactly
                }
            }
            child.constrain(.row, direction, width, width, &widthMode, &childWidth)
            child.constrain(.column, direction, height, width, &heightMode, &childHeight)
            child.layoutInternal(childWidth, childHeight, direction, widthMode, heightMode,
                                 width, height, false, context.generation, context.depth)
            child.computedFlexBasis = maxDefined(child.measured[main.dimension], childStyle.paddingBorder(main, direction, width))
        }
    }

    func measureLeaf(_ width: Float, _ height: Float, _ widthMode: YogaMeasureMode, _ heightMode: YogaMeasureMode,
                     _ direction: YogaDirection, _ ownerWidth: Float, _ ownerHeight: Float) {
        let paddingWidth = layout.padding.left + layout.padding.right + layout.border.left + layout.border.right
        let paddingHeight = layout.padding.top + layout.padding.bottom + layout.border.top + layout.border.bottom
        if let measure, widthMode != .exactly || heightMode != .exactly {
            let innerWidth: Float = widthMode == .undefined ? .nan : max(0, width - paddingWidth)
            let innerHeight: Float = heightMode == .undefined ? .nan : max(0, height - paddingHeight)
            let size: YogaSize
            switch measure {
            case .node(let callback): size = callback(facade, innerWidth, widthMode, innerHeight, heightMode)
            case .content(let callback): size = callback(innerWidth, widthMode, innerHeight, heightMode)
            }
            measured.x = bound(widthMode == .exactly ? width : maxDefined(0, size.width) + paddingWidth, .row, direction, ownerWidth, ownerWidth)
            measured.y = bound(heightMode == .exactly ? height : maxDefined(0, size.height) + paddingHeight, .column, direction, ownerHeight, ownerWidth)
        } else {
            measured.x = bound(widthMode == .exactly ? width : paddingWidth, .row, direction, ownerWidth, ownerWidth)
            measured.y = bound(heightMode == .exactly ? height : paddingHeight, .column, direction, ownerHeight, ownerWidth)
        }
    }
}

extension StyleAccess {
    @inline(__always) var validAspectRatio: Float? {
        guard let aspectRatio, aspectRatio.isFinite && aspectRatio > 0 else { return nil }
        return aspectRatio
    }
}
