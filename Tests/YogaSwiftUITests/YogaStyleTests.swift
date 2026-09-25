import XCTest
import YogaBridge
@testable import YogaSwiftUI

final class YogaStyleTests: XCTestCase {
    func testWrappingGapsAndPadding() {
        let root = YGNodeNew()!
        defer { YGNodeFreeRecursive(root) }

        var container = YogaStyle()
        container.width = .point(100)
        container.height = .point(50)
        container.flexDirection = .row
        container.wrap = .wrap
        container.setPadding(.point(5), for: .all)
        container.setGap(.point(5), for: .row)
        container.setGap(.point(10), for: .column)
        container.apply(to: root)

        for index in 0..<3 {
            let child = YGNodeNew()!
            var item = YogaStyle()
            item.width = .point(40)
            item.height = .point(10)
            item.apply(to: child)
            YGNodeInsertChild(root, child, index)
        }
        YGNodeCalculateLayout(root, 100, 50, .LTR)

        XCTAssertEqual(YGNodeLayoutGetLeft(YGNodeGetChild(root, 0)), 5)
        XCTAssertEqual(YGNodeLayoutGetLeft(YGNodeGetChild(root, 1)), 55)
        XCTAssertEqual(YGNodeLayoutGetLeft(YGNodeGetChild(root, 2)), 5)
        XCTAssertEqual(YGNodeLayoutGetTop(YGNodeGetChild(root, 2)), 20)
    }

    func testAbsolutePositionAndPercentDimensions() {
        let root = YGNodeNew()!
        defer { YGNodeFreeRecursive(root) }
        YGNodeStyleSetWidth(root, 200)
        YGNodeStyleSetHeight(root, 100)

        let child = YGNodeNew()!
        var item = YogaStyle()
        item.positionType = .absolute
        item.width = .percent(50)
        item.height = .point(20)
        item.setPosition(.percent(25), for: .left)
        item.setPosition(.point(10), for: .top)
        item.apply(to: child)
        YGNodeInsertChild(root, child, 0)
        YGNodeCalculateLayout(root, 200, 100, .LTR)

        XCTAssertEqual(YGNodeLayoutGetLeft(child), 50)
        XCTAssertEqual(YGNodeLayoutGetTop(child), 10)
        XCTAssertEqual(YGNodeLayoutGetWidth(child), 100)
    }

    func testFlexGrowAndAlignSelf() {
        let root = YGNodeNew()!
        defer { YGNodeFreeRecursive(root) }
        YGNodeStyleSetWidth(root, 200)
        YGNodeStyleSetHeight(root, 60)
        YGNodeStyleSetFlexDirection(root, .row)
        YGNodeStyleSetAlignItems(root, .flexStart)

        let fixed = YGNodeNew()!
        YGNodeStyleSetWidth(fixed, 30)
        YGNodeStyleSetHeight(fixed, 20)
        YGNodeInsertChild(root, fixed, 0)

        let growing = YGNodeNew()!
        var item = YogaStyle()
        item.flexGrow = 1
        item.height = .point(20)
        item.alignSelf = .center
        item.apply(to: growing)
        YGNodeInsertChild(root, growing, 1)
        YGNodeCalculateLayout(root, 200, 60, .LTR)

        XCTAssertEqual(YGNodeLayoutGetWidth(growing), 170)
        XCTAssertEqual(YGNodeLayoutGetTop(growing), 20)
    }
}
