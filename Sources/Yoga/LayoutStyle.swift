// A nonowning read view. The arena cannot grow or mutate styles during layout.
struct LayoutStyle: StyleAccess {
    let record: UnsafeMutablePointer<NodeState>
    @inline(__always) var direction: YogaDirection { record.pointee.style.direction }
    @inline(__always) var flexDirection: YogaFlexDirection { record.pointee.style.flexDirection }
    @inline(__always) var justifyContent: YogaJustify { record.pointee.style.justifyContent }
    @inline(__always) var alignContent: YogaAlign { record.pointee.style.alignContent }
    @inline(__always) var alignItems: YogaAlign { record.pointee.style.alignItems }
    @inline(__always) var alignSelf: YogaAlign { record.pointee.style.alignSelf }
    @inline(__always) var positionType: YogaPositionType { record.pointee.style.positionType }
    @inline(__always) var wrap: YogaWrap { record.pointee.style.wrap }
    @inline(__always) var overflow: YogaOverflow { record.pointee.style.overflow }
    @inline(__always) var display: YogaDisplay { record.pointee.style.display }
    @inline(__always) var boxSizing: YogaBoxSizing { record.pointee.style.boxSizing }
    @inline(__always) var flex: Float? { record.pointee.style.flex }
    @inline(__always) var flexGrow: Float? { record.pointee.style.flexGrow }
    @inline(__always) var flexShrink: Float? { record.pointee.style.flexShrink }
    @inline(__always) var flexBasis: YogaValue { record.pointee.style.flexBasis }
    @inline(__always) var width: YogaValue { record.pointee.style.width }
    @inline(__always) var height: YogaValue { record.pointee.style.height }
    @inline(__always) var minWidth: YogaValue { record.pointee.style.minWidth }
    @inline(__always) var minHeight: YogaValue { record.pointee.style.minHeight }
    @inline(__always) var maxWidth: YogaValue { record.pointee.style.maxWidth }
    @inline(__always) var maxHeight: YogaValue { record.pointee.style.maxHeight }
    @inline(__always) var aspectRatio: Float? { record.pointee.style.aspectRatio }
    @inline(__always) var hasEdges: Bool { !record.pointee.style.edges.isEmpty }
    @inline(__always) var hasPaddingOrBorder: Bool { record.pointee.style.edgeKinds & 0b1100 != 0 }
    @inline(__always) var hasPositionsOrMargins: Bool { record.pointee.style.edgeKinds & 0b0011 != 0 }
    @inline(__always) var hasBoxEdges: Bool { record.pointee.style.edgeKinds & 0b1110 != 0 }
    @inline(__always) borrowing func hasEdgeKind(_ kind: UInt8) -> Bool { record.pointee.style.edgeKinds & (1 << kind) != 0 }
    @inline(__always) var dependsOnOwner: Bool {
        let units = record.pointee.style.lengthUnits
        return units & (units >> 1) & 0x1555 != 0 || record.pointee.style.hasPercentEdges
    }
    @inline(__always) func value(kind: UInt8, edge: UInt8) -> YogaValue {
        let key = kind * 9 + edge
        for entry in record.pointee.style.edges where entry.key == key { return entry.value }
        return .undefined
    }
}
