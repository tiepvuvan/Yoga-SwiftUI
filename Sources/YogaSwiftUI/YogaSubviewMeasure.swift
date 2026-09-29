import SwiftUI
import Yoga

/// Reuses one SwiftUI measurement context per child throughout the cache lifetime.
final class YogaSubviewMeasure {
    var subview: LayoutSubviews.Element

    init(_ subview: LayoutSubviews.Element) { self.subview = subview }

    func measure(width: Float, widthMode: YogaMeasureMode, height: Float, heightMode: YogaMeasureMode) -> YogaSize {
        let size = subview.sizeThatFits(ProposedViewSize(
            width: widthMode == .undefined ? nil : CGFloat(width),
            height: heightMode == .undefined ? nil : CGFloat(height)
        ))
        return YogaSize(width: dimension(Float(size.width), limit: width, mode: widthMode),
                        height: dimension(Float(size.height), limit: height, mode: heightMode))
    }

    func baseline(layout: YogaLayout, width: Float, height: Float) -> Float {
        let horizontal = layout.padding.left + layout.padding.right + layout.border.left + layout.border.right
        let vertical = layout.padding.top + layout.padding.bottom + layout.border.top + layout.border.bottom
        let dimensions = subview.dimensions(in: ProposedViewSize(width: CGFloat(max(0, width - horizontal)),
                                                                 height: CGFloat(max(0, height - vertical))))
        return Float(dimensions[.firstTextBaseline]) + layout.padding.top + layout.border.top
    }

    private func dimension(_ value: Float, limit: Float, mode: YogaMeasureMode) -> Float {
        switch mode {
        case .exactly: limit
        case .atMost: min(value, limit)
        case .undefined: value
        }
    }
}
