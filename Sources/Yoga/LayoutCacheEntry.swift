// Derived from React Yoga 3.2.1. See THIRD_PARTY_NOTICES.md.
struct LayoutCacheEntry {
    var width: Float
    var height: Float
    var ownerWidth: Float
    var ownerHeight: Float
    var widthMode: YogaMeasureMode
    var heightMode: YogaMeasureMode
    var measured: SIMD2<Float>

    func matches(_ width: Float, _ height: Float, _ widthMode: YogaMeasureMode, _ heightMode: YogaMeasureMode,
                 _ ownerWidth: Float, _ ownerHeight: Float, dependsOnOwner: Bool = true) -> Bool {
        self.widthMode == widthMode && self.heightMode == heightMode
            && approximatelyEqual(self.width, width) && approximatelyEqual(self.height, height)
            && (!dependsOnOwner || (approximatelyEqual(self.ownerWidth, ownerWidth) && approximatelyEqual(self.ownerHeight, ownerHeight)))
    }

    func compatibleMeasurement(_ width: Float, _ height: Float, _ widthMode: YogaMeasureMode, _ heightMode: YogaMeasureMode,
                               _ ownerWidth: Float, _ ownerHeight: Float, style: LayoutStyle, scale: Float) -> Bool {
        if style.dependsOnOwner && (!approximatelyEqual(self.ownerWidth, ownerWidth) || !approximatelyEqual(self.ownerHeight, ownerHeight)) { return false }
        return compatibleAxis(width, widthMode, self.width, self.widthMode, measured.x, style.margin(.row, ownerWidth), scale)
            && compatibleAxis(height, heightMode, self.height, self.heightMode, measured.y, style.margin(.column, ownerWidth), scale)
    }

    private func compatibleAxis(_ size: Float, _ mode: YogaMeasureMode, _ oldSize: Float, _ oldMode: YogaMeasureMode,
                                _ measured: Float, _ margin: Float, _ scale: Float) -> Bool {
        if measured < 0 { return false }
        let effective = scale == 0 ? size : yogaRoundToPixelGrid(Double(size), scale: Double(scale))
        let oldEffective = scale == 0 ? oldSize : yogaRoundToPixelGrid(Double(oldSize), scale: Double(scale))
        if mode == oldMode && approximatelyEqual(effective, oldEffective) { return true }
        let inner = size - margin
        if mode == .exactly && approximatelyEqual(inner, measured) { return true }
        let fits = inner >= measured || approximatelyEqual(inner, measured)
        if mode == .atMost && oldMode == .undefined && fits { return true }
        return mode == .atMost && oldMode == .atMost && oldSize > inner && fits
    }
}
