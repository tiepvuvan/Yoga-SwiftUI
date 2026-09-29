// Derived from React Yoga 3.2.1. See THIRD_PARTY_NOTICES.md.
/// Rounds a layout coordinate using Yoga's pixel-grid rules.
@inline(__always) public func yogaRoundToPixelGrid(_ value: Double, scale: Double, forceCeil: Bool = false, forceFloor: Bool = false) -> Float {
    if scale == 0 { return Float(value) }
    var scaled = value * scale
    var fraction = fractionalPart(scaled)
    if fraction < 0 { fraction += 1 }
    if abs(fraction) < 0.0001 { scaled -= fraction }
    else if abs(fraction - 1) < 0.0001 { scaled = scaled - fraction + 1 }
    else if forceCeil { scaled = scaled - fraction + 1 }
    else if forceFloor { scaled -= fraction }
    else { scaled = scaled - fraction + (fraction > 0.5 || abs(fraction - 0.5) < 0.0001 ? 1 : 0) }
    return Float(scaled / scale)
}

// Truncation to an integer is a hardware operation. Subtraction is exact for
// finite binary floating-point inputs; preserve remainder's signed zero too.
@inline(__always) private func fractionalPart(_ value: Double) -> Double {
    let fraction = value - value.rounded(.towardZero)
    return fraction == 0 ? Double(signOf: value, magnitudeOf: 0) : fraction
}

extension LayoutNode {
    func roundToPixelGrid(absoluteLeft: Double, absoluteTop: Double) {
        let left = Double(layout.left)
        let top = Double(layout.top)
        let width = Double(layout.width)
        let height = Double(layout.height)
        let absoluteX = absoluteLeft + left
        let absoluteY = absoluteTop + top
        let scale = Double(configuration.pointScaleFactor)
        if scale != 0 {
            let text = measure != nil
            let fractionWidth = text ? fractionalPart(width * scale) : 0
            let fractionHeight = text ? fractionalPart(height * scale) : 0
            let fractionalWidth = text && abs(fractionWidth) >= 0.0001 && abs(fractionWidth - 1) >= 0.0001
            let fractionalHeight = text && abs(fractionHeight) >= 0.0001 && abs(fractionHeight - 1) >= 0.0001
            layout.left = yogaRoundToPixelGrid(left, scale: scale, forceFloor: text)
            layout.top = yogaRoundToPixelGrid(top, scale: scale, forceFloor: text)
            layout.width = yogaRoundToPixelGrid(absoluteX + width, scale: scale, forceCeil: text && fractionalWidth, forceFloor: text && !fractionalWidth)
                - yogaRoundToPixelGrid(absoluteX, scale: scale, forceFloor: text)
            layout.height = yogaRoundToPixelGrid(absoluteY + height, scale: scale, forceCeil: text && fractionalHeight, forceFloor: text && !fractionalHeight)
                - yogaRoundToPixelGrid(absoluteY, scale: scale, forceFloor: text)
        }
        for child in children { child.roundToPixelGrid(absoluteLeft: absoluteX, absoluteTop: absoluteY) }
    }
}
