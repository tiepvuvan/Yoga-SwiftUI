import SwiftUI
import YogaSwiftUI
import XCTest

final class PublicAPITests: XCTestCase {
    @MainActor func testPublicModifiersCompileWithoutImportingYogaBridge() {
        let view = Flex(direction: .row, justifyContent: .center) {
            Text("Child")
                .flexWidth(.percent(50))
                .flexGrow(1)
                .flexShrink(0)
                .flexMargin(.auto, for: .left)
                .flexPadding(.point(8), for: .horizontal)
                .flexAlignSelf(.center)
        }
        .yogaGap(.point(8))
        .yogaPadding(.point(12))
        .yogaOverflow(.hidden)
        _ = view
    }
}
