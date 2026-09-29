struct FlexLine {
    var items: Slice<LayoutChildren>
    var sizeConsumed: Float = 0
    var grow: Float = 0
    var shrink: Float = 0
    var autoMargins = 0
    var freeSpace: Float = 0
    var mainSize: Float = 0
    var crossSize: Float = 0
}
