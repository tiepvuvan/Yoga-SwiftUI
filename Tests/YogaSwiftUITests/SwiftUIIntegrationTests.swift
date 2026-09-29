import SwiftUI
import XCTest
import YogaSwiftUI

final class SwiftUIIntegrationTests: XCTestCase {
    @MainActor func testChangedTextInvalidatesIntrinsicMeasurements() throws {
        let renderer = ImageRenderer(content: ChangingText(title: "A"))
        renderer.scale = 1
        let before = try XCTUnwrap(renderer.cgImage).width
        renderer.content = ChangingText(title: "A much longer title")
        let after = try XCTUnwrap(renderer.cgImage).width
        XCTAssertGreaterThan(after, before)
    }

    @MainActor func testFlexPlacesSwiftUIChildren() throws {
        let view = Flex(direction: .row, justifyContent: .spaceBetween) {
            Rectangle().fill(.red).flexWidth(.point(20)).flexHeight(.point(20))
            Rectangle().fill(.blue).flexWidth(.point(20)).flexHeight(.point(20))
        }
        .frame(width: 100, height: 20)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        let bitmap = try PixelImage(renderer.cgImage)
        let left = try XCTUnwrap(bitmap.colorAt(x: 10, y: 10))
        let middle = try XCTUnwrap(bitmap.colorAt(x: 50, y: 10))
        let right = try XCTUnwrap(bitmap.colorAt(x: 90, y: 10))
        XCTAssertGreaterThan(left.redComponent, 0.9)
        XCTAssertGreaterThan(left.redComponent, left.blueComponent)
        XCTAssertLessThan(middle.alphaComponent, 0.1)
        XCTAssertGreaterThan(right.blueComponent, 0.9)
        XCTAssertGreaterThan(right.blueComponent, right.redComponent)
    }

    @MainActor func testChildPaddingOffsetsItsSwiftUIContent() throws {
        let view = Flex {
            Rectangle().fill(.red)
                .flexWidth(.point(40))
                .flexHeight(.point(20))
                .flexPadding(.point(0))
                .flexPadding(.point(10), for: .left)
        }
        .frame(width: 40, height: 20)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        let bitmap = try PixelImage(renderer.cgImage)
        let inset = try XCTUnwrap(bitmap.colorAt(x: 5, y: 10))
        let content = try XCTUnwrap(bitmap.colorAt(x: 15, y: 10))

        XCTAssertLessThan(inset.alphaComponent, 0.1)
        XCTAssertGreaterThan(content.redComponent, 0.9)
    }

    @MainActor func testContainerGapModifierOverridesInitializerGap() throws {
        let view = Flex(direction: .row, columnGap: 3) {
            Rectangle().fill(.red).flexWidth(.point(20)).flexHeight(.point(20))
            Rectangle().fill(.blue).flexWidth(.point(20)).flexHeight(.point(20))
        }
        .yogaGap(.point(10))
        .frame(width: 50, height: 20)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        let bitmap = try PixelImage(renderer.cgImage)
        let gap = try XCTUnwrap(bitmap.colorAt(x: 25, y: 10))
        let second = try XCTUnwrap(bitmap.colorAt(x: 35, y: 10))

        XCTAssertLessThan(gap.alphaComponent, 0.1)
        XCTAssertGreaterThan(second.blueComponent, 0.9)
    }

    @MainActor func testAbsoluteItemUsesPercentWidthAndEdgeOffsets() throws {
        let view = Flex {
            Rectangle().fill(.red)
                .flexWidth(.point(20))
                .flexHeight(.point(20))
            Rectangle().fill(.blue)
                .flexPositionType(.absolute)
                .flexWidth(.percent(50))
                .flexHeight(.point(10))
                .flexPosition(.point(0), for: .right)
                .flexPosition(.point(0), for: .bottom)
        }
        .frame(width: 100, height: 40)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        let bitmap = try PixelImage(renderer.cgImage)
        let empty = try XCTUnwrap(bitmap.colorAt(x: 40, y: 35))
        let positioned = try XCTUnwrap(bitmap.colorAt(x: 75, y: 35))

        XCTAssertLessThan(empty.alphaComponent, 0.1)
        XCTAssertGreaterThan(positioned.blueComponent, 0.9)
    }
}

private struct ChangingText: View {
    let title: String
    var body: some View {
        Flex { Text(title).font(.system(size: 12)) }
    }
}
