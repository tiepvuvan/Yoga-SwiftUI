// Derived from React Yoga 3.2.1. Copyright (c) Meta Platforms, Inc. and affiliates.
// Licensed under the MIT license in THIRD_PARTY_NOTICES.md.

/// Native flexbox style values. SwiftUI users configure these through modifiers.
///
/// Edge overrides use one copy-on-write buffer, allocated only when an edge or
/// gap is set. Unstyled nodes share the empty buffer.
public struct YogaStyle: Sendable, Equatable, StyleAccess {
    /// The writing direction inherited by descendants.
    public var direction: YogaDirection = .inherit
    /// The main axis used to arrange children.
    public var flexDirection: YogaFlexDirection = .column
    /// Distribution of remaining space along the main axis.
    public var justifyContent: YogaJustify = .flexStart
    /// Distribution of wrapped lines along the cross axis.
    public var alignContent: YogaAlign = .flexStart
    /// Default cross-axis alignment for children.
    public var alignItems: YogaAlign = .stretch
    /// A child alignment override; auto inherits the container alignment.
    public var alignSelf: YogaAlign = .auto
    /// Whether the node participates in flow or uses a containing block.
    public var positionType: YogaPositionType = .relative
    /// Whether children form multiple flex lines.
    public var wrap: YogaWrap = .noWrap
    /// Sizing rules for content extending outside the box; does not draw or scroll.
    public var overflow: YogaOverflow = .visible
    /// Whether the node has a box, is hidden, or promotes its children.
    public var display: YogaDisplay = .flex
    /// Whether declared dimensions include padding and borders.
    public var boxSizing: YogaBoxSizing = .borderBox
    /// Yoga flex shorthand; prefer explicit grow, shrink, and basis values.
    public var flex: Float? {
        get { optionalPresence & 1 != 0 ? optionalValues.flex : nil }
        set {
            optionalValues.flex = newValue ?? 0
            if newValue != nil { optionalPresence |= 1 }
            else { optionalPresence &= ~1 }
        }
    }
    /// The share of positive free space; nil uses the flex shorthand or zero.
    public var flexGrow: Float? {
        get { optionalPresence & 2 != 0 ? optionalValues.flexGrow : nil }
        set {
            optionalValues.flexGrow = newValue ?? 0
            if newValue != nil { optionalPresence |= 2 }
            else { optionalPresence &= ~2 }
        }
    }
    /// The shrink factor; nil uses the configuration default or flex shorthand.
    public var flexShrink: Float? {
        get { optionalPresence & 4 != 0 ? optionalValues.flexShrink : nil }
        set {
            optionalValues.flexShrink = newValue ?? 0
            if newValue != nil { optionalPresence |= 4 }
            else { optionalPresence &= ~4 }
        }
    }
    /// The initial main-axis size before distributing free space.
    public var flexBasis: YogaValue {
        get { YogaValue(rawValue: lengths.flexBasis, unit: YogaUnit(rawValue: UInt8((lengthUnits >> 0) & 3))!) }
        set {
            lengths.flexBasis = newValue.value
            lengthUnits = (lengthUnits & ~(3 << 0)) | (UInt16(newValue.unit.rawValue) << 0)
        }
    }
    /// The declared width of the box.
    public var width: YogaValue {
        get { YogaValue(rawValue: lengths.width, unit: YogaUnit(rawValue: UInt8((lengthUnits >> 2) & 3))!) }
        set {
            lengths.width = newValue.value
            lengthUnits = (lengthUnits & ~(3 << 2)) | (UInt16(newValue.unit.rawValue) << 2)
        }
    }
    /// The declared height of the box.
    public var height: YogaValue {
        get { YogaValue(rawValue: lengths.height, unit: YogaUnit(rawValue: UInt8((lengthUnits >> 4) & 3))!) }
        set {
            lengths.height = newValue.value
            lengthUnits = (lengthUnits & ~(3 << 4)) | (UInt16(newValue.unit.rawValue) << 4)
        }
    }
    /// The minimum width; undefined leaves it unconstrained.
    public var minWidth: YogaValue {
        get { YogaValue(rawValue: lengths.minWidth, unit: YogaUnit(rawValue: UInt8((lengthUnits >> 6) & 3))!) }
        set {
            lengths.minWidth = newValue.value
            lengthUnits = (lengthUnits & ~(3 << 6)) | (UInt16(newValue.unit.rawValue) << 6)
        }
    }
    /// The minimum height; undefined leaves it unconstrained.
    public var minHeight: YogaValue {
        get { YogaValue(rawValue: lengths.minHeight, unit: YogaUnit(rawValue: UInt8((lengthUnits >> 8) & 3))!) }
        set {
            lengths.minHeight = newValue.value
            lengthUnits = (lengthUnits & ~(3 << 8)) | (UInt16(newValue.unit.rawValue) << 8)
        }
    }
    /// The maximum width; undefined leaves it unconstrained.
    public var maxWidth: YogaValue {
        get { YogaValue(rawValue: lengths.maxWidth, unit: YogaUnit(rawValue: UInt8((lengthUnits >> 10) & 3))!) }
        set {
            lengths.maxWidth = newValue.value
            lengthUnits = (lengthUnits & ~(3 << 10)) | (UInt16(newValue.unit.rawValue) << 10)
        }
    }
    /// The maximum height; undefined leaves it unconstrained.
    public var maxHeight: YogaValue {
        get { YogaValue(rawValue: lengths.maxHeight, unit: YogaUnit(rawValue: UInt8((lengthUnits >> 12) & 3))!) }
        set {
            lengths.maxHeight = newValue.value
            lengthUnits = (lengthUnits & ~(3 << 12)) | (UInt16(newValue.unit.rawValue) << 12)
        }
    }
    /// Width divided by height; nonpositive and nonfinite ratios are ignored.
    public var aspectRatio: Float? {
        get { optionalPresence & 8 != 0 ? optionalValues.aspectRatio : nil }
        set {
            optionalValues.aspectRatio = newValue ?? 0
            if newValue != nil { optionalPresence |= 8 }
            else { optionalPresence &= ~8 }
        }
    }
    // Seven scalar values share a two-bit unit tag each. No precision is lost.
    private var lengths = StyleLengths()
    private var optionalValues = OptionalStyleValues()
    private var optionalPresence: UInt8 = 0
    var lengthUnits: UInt16 = 0b01_01_01
    var edgeKinds: UInt8 = 0
    var hasPercentEdges = false
    var edges: [EdgeValue] = []
    @inline(__always) var hasEdges: Bool { !edges.isEmpty }
    @inline(__always) var hasPaddingOrBorder: Bool { edgeKinds & 0b1100 != 0 }
    @inline(__always) var hasPositionsOrMargins: Bool { edgeKinds & 0b0011 != 0 }
    @inline(__always) var hasBoxEdges: Bool { edgeKinds & 0b1110 != 0 }
    @inline(__always) borrowing func hasEdgeKind(_ kind: UInt8) -> Bool { edgeKinds & (1 << kind) != 0 }

    var dependsOnOwner: Bool {
        lengthUnits & (lengthUnits >> 1) & 0x1555 != 0 || hasPercentEdges
    }

    /// Creates default style values, optionally using Yoga's web defaults.
    public init(useWebDefaults: Bool = false) {
        if useWebDefaults {
            flexDirection = .row
            alignContent = .stretch
        }
    }

    /// Sets a relative or absolute edge offset.
    public mutating func setPosition(_ value: YogaValue, for edge: YogaEdge) { set(value, kind: 0, edge: edge.rawValue) }
    /// Sets an outside spacing override; auto margins absorb free space.
    public mutating func setMargin(_ value: YogaValue, for edge: YogaEdge) { set(value, kind: 1, edge: edge.rawValue) }
    /// Sets an inside spacing override. Auto and undefined clear the override.
    public mutating func setPadding(_ value: YogaValue, for edge: YogaEdge) { set(value == .auto ? .undefined : value, kind: 2, edge: edge.rawValue) }
    /// Reserves a nonnegative border width without drawing it.
    public mutating func setBorder(_ value: Float, for edge: YogaEdge) { set(.point(value), kind: 3, edge: edge.rawValue) }
    /// Sets line or item spacing. Auto and undefined clear the override.
    public mutating func setGap(_ value: YogaValue, for gutter: YogaGutter = .all) { set(value == .auto ? .undefined : value, kind: 4, edge: gutter.rawValue) }
    /// Returns the explicit offset for an edge, without resolving fallbacks.
    public borrowing func position(for edge: YogaEdge) -> YogaValue { get(kind: 0, edge: edge.rawValue) }
    /// Returns the explicit margin for an edge, without resolving fallbacks.
    public borrowing func margin(for edge: YogaEdge) -> YogaValue { get(kind: 1, edge: edge.rawValue) }
    /// Returns the explicit padding for an edge, without resolving fallbacks.
    public borrowing func padding(for edge: YogaEdge) -> YogaValue { get(kind: 2, edge: edge.rawValue) }
    /// Returns an explicit border width, or NaN when unset.
    public borrowing func border(for edge: YogaEdge) -> Float { get(kind: 3, edge: edge.rawValue).resolve(0) }
    /// Returns the explicit gutter value, without resolving fallbacks.
    public borrowing func gap(for gutter: YogaGutter) -> YogaValue { get(kind: 4, edge: gutter.rawValue) }

    struct EdgeValue: Sendable, Equatable {
        var value: YogaValue
        var key: UInt8
    }

    private mutating func set(_ value: YogaValue, kind: UInt8, edge: UInt8) {
        let key = kind * 9 + edge
        var index = 0
        while index < edges.count && edges[index].key < key { index += 1 }
        if index < edges.count && edges[index].key == key {
            if value.isDefined { edges[index].value = value }
            else {
                edges.remove(at: index)
            }
        } else if value.isDefined {
            if edges.isEmpty { edges.reserveCapacity(2) }
            edges.insert(EdgeValue(value: value, key: key), at: index)
        }
        if value.isDefined { edgeKinds |= 1 << kind }
        else if !edges.contains(where: { $0.key / 9 == kind }) { edgeKinds &= ~(1 << kind) }
        if value.isPercent { hasPercentEdges = true }
        else if hasPercentEdges { hasPercentEdges = edges.contains { $0.value.isPercent } }
    }

    @inline(__always) private borrowing func get(kind: UInt8, edge: UInt8) -> YogaValue {
        let key = kind * 9 + edge
        for entry in edges where entry.key == key { return entry.value }
        return .undefined
    }

    @inline(__always) borrowing func value(kind: UInt8, edge: UInt8) -> YogaValue { get(kind: kind, edge: edge) }
}
