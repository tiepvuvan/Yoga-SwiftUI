import SwiftUI
import YogaBridge

/// Keeps a SwiftUI subview alive while Yoga invokes its synchronous C callbacks.
final class YogaSubviewMeasure {
    let subview: LayoutSubviews.Element

    init(_ subview: LayoutSubviews.Element) {
        self.subview = subview
    }
}

let yogaMeasureSubview: YGMeasureFunc = { node, width, widthMode, height, heightMode in
    guard let context = YGNodeGetContext(node) else {
        return YGSize(width: 0, height: 0)
    }
    let measurement = Unmanaged<YogaSubviewMeasure>.fromOpaque(context).takeUnretainedValue()
    let proposal = ProposedViewSize(
        width: widthMode == .undefined ? nil : CGFloat(width),
        height: heightMode == .undefined ? nil : CGFloat(height)
    )
    let size = measurement.subview.sizeThatFits(proposal)
    return YGSize(
        width: measuredDimension(size.width, limit: width, mode: widthMode),
        height: measuredDimension(size.height, limit: height, mode: heightMode)
    )
}

let yogaBaselineSubview: YGBaselineFunc = { node, width, height in
    guard let context = YGNodeGetContext(node) else { return height }
    let measurement = Unmanaged<YogaSubviewMeasure>.fromOpaque(context).takeUnretainedValue()
    let horizontalInset = YGNodeLayoutGetPadding(node, .left) + YGNodeLayoutGetPadding(node, .right)
        + YGNodeLayoutGetBorder(node, .left) + YGNodeLayoutGetBorder(node, .right)
    let verticalInset = YGNodeLayoutGetPadding(node, .top) + YGNodeLayoutGetPadding(node, .bottom)
        + YGNodeLayoutGetBorder(node, .top) + YGNodeLayoutGetBorder(node, .bottom)
    let dimensions = measurement.subview.dimensions(
        in: ProposedViewSize(
            width: CGFloat(max(0, width - horizontalInset)),
            height: CGFloat(max(0, height - verticalInset))
        )
    )
    return Float(dimensions[.firstTextBaseline])
        + YGNodeLayoutGetPadding(node, .top) + YGNodeLayoutGetBorder(node, .top)
}

private func measuredDimension(_ value: CGFloat, limit: Float, mode: YGMeasureMode) -> Float {
    switch mode {
    case .exactly: limit
    case .atMost: min(Float(value), limit)
    default: Float(value)
    }
}
