enum LayoutMeasureCallback {
    case node((YogaNode, Float, YogaMeasureMode, Float, YogaMeasureMode) -> YogaSize)
    case content((Float, YogaMeasureMode, Float, YogaMeasureMode) -> YogaSize)
}

enum LayoutBaselineCallback {
    case node((YogaNode, Float, Float) -> Float)
    case content((YogaLayout, Float, Float) -> Float)
}
