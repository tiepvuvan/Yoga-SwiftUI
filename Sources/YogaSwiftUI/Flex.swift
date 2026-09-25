import SwiftUI
import YogaBridge

/// A SwiftUI container laid out by Yoga's flexbox engine.
public struct Flex<Content: View>: View {
    @Environment(\.layoutDirection) private var layoutDirection

    var style: YogaStyle
    private let content: Content

    /// Creates a flex container with common container options.
    ///
    /// Use `yoga...` modifiers on the container for additional Yoga properties.
    /// Apply `flex...` modifiers to direct children for item properties.
    public init(
        direction: YGFlexDirection = .row,
        justifyContent: YGJustify = .flexStart,
        alignItems: YGAlign = .flexStart,
        alignContent: YGAlign = .flexStart,
        wrap: YGWrap = .noWrap,
        rowGap: CGFloat = 0,
        columnGap: CGFloat = 0,
        @ViewBuilder contentBuilder: @escaping () -> Content
    ) {
        var style = YogaStyle()
        style.flexDirection = direction
        style.justifyContent = justifyContent
        style.alignItems = alignItems
        style.alignContent = alignContent
        style.wrap = wrap
        if rowGap != 0 { style.setGap(.point(Float(rowGap)), for: .row) }
        if columnGap != 0 { style.setGap(.point(Float(columnGap)), for: .column) }
        self.style = style
        self.content = contentBuilder()
    }

    @ViewBuilder public var body: some View {
        if style.overflow == .hidden {
            layout.clipped()
        } else {
            layout
        }
    }

    private var layout: some View {
        YogaFlexLayout(style: style, layoutDirection: yogaDirection) {
            content
        }
    }

    private var yogaDirection: YGDirection {
        switch layoutDirection {
        case .leftToRight: .LTR
        case .rightToLeft: .RTL
        @unknown default: .LTR
        }
    }
}
