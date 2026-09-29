import SwiftUI
import XCTest
import YogaSwiftUI

final class VisibilityTests: XCTestCase {
    @MainActor func testHiddenChildDoesNotRenderAtFallbackPlacement() throws {
        let view = Flex(direction: .row) {
            Rectangle().fill(.red).flexWidth(.point(20)).flexHeight(.point(20)).flexDisplay(.none)
            Rectangle().fill(.blue).flexWidth(.point(20)).flexHeight(.point(20))
        }.frame(width: 100, height: 20).background(.white)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        let pixels = try PixelImage(renderer.cgImage)
        XCTAssertGreaterThan(try XCTUnwrap(pixels.colorAt(x: 10, y: 10)).blueComponent, 0.9)
        let background = try (20..<100).map { try XCTUnwrap(pixels.colorAt(x: $0, y: 10)) }
        XCTAssertTrue(background.allSatisfy { $0.redComponent > 0.9 && $0.blueComponent > 0.9 })
        XCTAssertLessThan(try XCTUnwrap(pixels.colorAt(x: 10, y: 10)).redComponent, 0.5)
    }
    @MainActor func testVisibilityCanChangeOnAnExistingRenderer() throws {
        func content(hidden: Bool) -> some View {
            Flex(direction: .row) {
                Rectangle().fill(.red).frame(width: 20, height: 20).flexDisplay(hidden ? .none : .flex)
                Rectangle().fill(.blue).frame(width: 20, height: 20)
            }.frame(width: 100, height: 20).background(.white)
        }
        let renderer = ImageRenderer(content: content(hidden: false))
        renderer.scale = 1
        for hidden in [false, true, false] {
            renderer.content = content(hidden: hidden)
            let pixels = try PixelImage(renderer.cgImage)
            let first = try XCTUnwrap(pixels.colorAt(x: 10, y: 10))
            let second = try XCTUnwrap(pixels.colorAt(x: 30, y: 10))
            if hidden {
                XCTAssertGreaterThan(first.blueComponent, 0.9)
                XCTAssertLessThan(first.redComponent, 0.5)
                XCTAssertGreaterThan(second.redComponent, 0.9)
                XCTAssertGreaterThan(second.blueComponent, 0.9)
            } else {
                XCTAssertGreaterThan(first.redComponent, 0.9)
                XCTAssertLessThan(first.blueComponent, 0.5)
                XCTAssertGreaterThan(second.blueComponent, 0.9)
                XCTAssertLessThan(second.redComponent, 0.5)
            }
        }
    }

    @MainActor func testHiddenContainerDoesNotRenderChildren() throws {
        let view = Flex { Rectangle().fill(.red).frame(width: 20, height: 20) }
            .yogaDisplay(.none).frame(width: 100, height: 20).background(.white)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        let pixels = try PixelImage(renderer.cgImage)
        let background = try (0..<100).map { try XCTUnwrap(pixels.colorAt(x: $0, y: 10)) }
        XCTAssertTrue(background.allSatisfy { $0.redComponent > 0.9 && $0.blueComponent > 0.9 })
    }
}
