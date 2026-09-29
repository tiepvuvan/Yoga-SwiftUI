import SwiftUI
import Yoga

// Skipped Layout subviews can still receive SwiftUI's fallback placement.
// Keep view identity stable while hiding drawing, interaction, and accessibility.
struct YogaVisibility: ViewModifier {
    let display: YogaDisplay

    func body(content: Content) -> some View {
        content
            .opacity(display == .none ? 0 : 1)
            .allowsHitTesting(display != .none)
            .accessibilityHidden(display == .none)
    }
}
