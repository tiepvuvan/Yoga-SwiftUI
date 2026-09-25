import SwiftUI
import YogaBridge

struct YogaFlexLayout: Layout {
    var style: YogaStyle
    var layoutDirection: YGDirection

    func makeCache(subviews: Subviews) -> YogaLayoutCache {
        YogaLayoutCache()
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout YogaLayoutCache
    ) -> CGSize {
        calculate(proposal: proposal, subviews: subviews, cache: cache)
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout YogaLayoutCache
    ) {
        // The actual bounds can differ from the size proposal used during measurement.
        _ = calculate(proposal: ProposedViewSize(bounds.size), subviews: subviews, cache: cache)
        if YGNodeStyleGetDisplay(cache.root) == .none { return }
        for (index, subview) in subviews.enumerated() {
            guard let node = YGNodeGetChild(cache.root, index) else { continue }
            if YGNodeStyleGetDisplay(node) == .none { continue }
            let leftInset = CGFloat(YGNodeLayoutGetPadding(node, .left) + YGNodeLayoutGetBorder(node, .left))
            let rightInset = CGFloat(YGNodeLayoutGetPadding(node, .right) + YGNodeLayoutGetBorder(node, .right))
            let topInset = CGFloat(YGNodeLayoutGetPadding(node, .top) + YGNodeLayoutGetBorder(node, .top))
            let bottomInset = CGFloat(YGNodeLayoutGetPadding(node, .bottom) + YGNodeLayoutGetBorder(node, .bottom))
            let frame = CGRect(
                x: bounds.minX + CGFloat(YGNodeLayoutGetLeft(node)) + leftInset,
                y: bounds.minY + CGFloat(YGNodeLayoutGetTop(node)) + topInset,
                width: max(0, CGFloat(YGNodeLayoutGetWidth(node)) - leftInset - rightInset),
                height: max(0, CGFloat(YGNodeLayoutGetHeight(node)) - topInset - bottomInset)
            )
            subview.place(at: frame.origin, anchor: .topLeading, proposal: ProposedViewSize(frame.size))
        }
    }

    private func calculate(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: YogaLayoutCache
    ) -> CGSize {
        cache.reset()
        let availableWidth = proposal.width.flatMap { $0.isFinite ? Float(max(0, $0)) : nil }
        let availableHeight = proposal.height.flatMap { $0.isFinite ? Float(max(0, $0)) : nil }
        if let availableWidth { YGNodeStyleSetWidth(cache.root, availableWidth) }
        if let availableHeight { YGNodeStyleSetHeight(cache.root, availableHeight) }
        style.apply(to: cache.root)

        for (index, subview) in subviews.enumerated() {
            guard let node = YGNodeNewWithConfig(cache.config) else {
                fatalError("Yoga could not allocate a child node")
            }
            var childStyle = YogaStyle()
            childStyle.applyItemValues(from: subview)
            childStyle.apply(to: node)

            let measurement = YogaSubviewMeasure(subview)
            cache.retain(measurement)
            YGNodeSetContext(node, Unmanaged.passUnretained(measurement).toOpaque())
            YGNodeSetMeasureFunc(node, yogaMeasureSubview)
            YGNodeSetBaselineFunc(node, yogaBaselineSubview)
            YGNodeInsertChild(cache.root, node, index)
        }

        YGNodeCalculateLayout(
            cache.root,
            availableWidth ?? Float.nan,
            availableHeight ?? Float.nan,
            layoutDirection
        )
        return CGSize(
            width: CGFloat(YGNodeLayoutGetWidth(cache.root)),
            height: CGFloat(YGNodeLayoutGetHeight(cache.root))
        )
    }
}
