import SwiftUI
import Yoga

struct YogaFlexLayout: Layout {
    var style: YogaStyle
    var layoutDirection: YogaDirection

    func makeCache(subviews: Subviews) -> YogaLayoutCache {
        let cache = YogaLayoutCache()
        cache.synchronize(subviews, invalidate: true)
        return cache
    }

    func updateCache(_ cache: inout YogaLayoutCache, subviews: Subviews) {
        cache.synchronize(subviews, invalidate: true)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout YogaLayoutCache) -> CGSize {
        calculate(proposal: proposal, subviews: subviews, cache: cache)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout YogaLayoutCache) {
        _ = calculate(proposal: ProposedViewSize(bounds.size), subviews: subviews, cache: cache)
        let containerIsHidden = cache.tree.style(of: cache.tree.root).display == .none
        for (index, subview) in subviews.enumerated() {
            let node = cache.nodes[index]
            if containerIsHidden || cache.tree.style(of: node).display == .none {
                subview.place(at: bounds.origin, anchor: .topLeading, proposal: .zero)
                continue
            }
            let layout = cache.tree.layout(of: node)
            let left = layout.padding.left + layout.border.left
            let right = layout.padding.right + layout.border.right
            let top = layout.padding.top + layout.border.top
            let bottom = layout.padding.bottom + layout.border.bottom
            let size = CGSize(width: CGFloat(max(0, layout.width - left - right)), height: CGFloat(max(0, layout.height - top - bottom)))
            subview.place(at: CGPoint(x: bounds.minX + CGFloat(layout.left + left), y: bounds.minY + CGFloat(layout.top + top)),
                          anchor: .topLeading, proposal: ProposedViewSize(size))
        }
    }

    private func calculate(proposal: ProposedViewSize, subviews: Subviews, cache: YogaLayoutCache) -> CGSize {
        cache.synchronize(subviews, invalidate: false)
        cache.tree.setStyle(style, for: cache.tree.root)
        cache.tree.calculateLayout(width: proposal.width.flatMap { $0.isFinite ? Float(max(0, $0)) : nil },
                                   height: proposal.height.flatMap { $0.isFinite ? Float(max(0, $0)) : nil },
                                   direction: layoutDirection)
        return CGSize(width: CGFloat(cache.tree.layout(of: cache.tree.root).width), height: CGFloat(cache.tree.layout(of: cache.tree.root).height))
    }
}
