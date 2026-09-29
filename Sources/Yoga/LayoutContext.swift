struct LayoutContext {
    var direction: YogaDirection
    var main: YogaFlexDirection
    var cross: YogaFlexDirection
    var widthMode: YogaMeasureMode
    var heightMode: YogaMeasureMode
    var mainMode: YogaMeasureMode
    var crossMode: YogaMeasureMode
    var innerWidth: Float
    var innerHeight: Float
    var innerMain: Float
    var innerCross: Float
    var ownerWidth: Float
    var ownerHeight: Float
    var mainOwner: Float
    var crossOwner: Float
    var paddingMain: Float
    var paddingCross: Float
    var leadingCross: Float
    var mainOverflows = false
    var performLayout: Bool
    var generation: UInt64
    var depth: Int
}
