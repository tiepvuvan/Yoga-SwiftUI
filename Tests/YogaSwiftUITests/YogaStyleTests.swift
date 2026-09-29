import XCTest
import Yoga
import YogaSwiftUI

final class YogaStyleTests: XCTestCase {
    func testWrappingGapsAndPadding() {
        let root = YogaNode()

        var container = YogaStyle()
        container.width = .point(100)
        container.height = .point(50)
        container.flexDirection = .row
        container.wrap = .wrap
        container.setPadding(.point(5), for: .all)
        container.setGap(.point(5), for: .row)
        container.setGap(.point(10), for: .column)
        root.style = container

        for index in 0..<3 {
            let child = YogaNode()
            var item = YogaStyle()
            item.width = .point(40)
            item.height = .point(10)
            child.style = item
            root.insertChild(child, at: index)
        }
        root.calculateLayout(width: 100, height: 50)

        XCTAssertEqual(root.children[0].layout.left, 5)
        XCTAssertEqual(root.children[1].layout.left, 55)
        XCTAssertEqual(root.children[2].layout.left, 5)
        XCTAssertEqual(root.children[2].layout.top, 20)
    }

    func testAbsolutePositionAndPercentDimensions() {
        let root = YogaNode()
        root.style.width = .point(200)
        root.style.height = .point(100)

        let child = YogaNode()
        var item = YogaStyle()
        item.positionType = .absolute
        item.width = .percent(50)
        item.height = .point(20)
        item.setPosition(.percent(25), for: .left)
        item.setPosition(.point(10), for: .top)
        child.style = item
        root.insertChild(child, at: 0)
        root.calculateLayout(width: 200, height: 100)

        XCTAssertEqual(child.layout.left, 50)
        XCTAssertEqual(child.layout.top, 10)
        XCTAssertEqual(child.layout.width, 100)
    }

    func testFlexGrowAndAlignSelf() {
        let root = YogaNode()
        root.style.width = .point(200)
        root.style.height = .point(60)
        root.style.flexDirection = .row
        root.style.alignItems = .flexStart

        let fixed = YogaNode()
        fixed.style.width = .point(30)
        fixed.style.height = .point(20)
        root.insertChild(fixed, at: 0)

        let growing = YogaNode()
        var item = YogaStyle()
        item.flexGrow = 1
        item.height = .point(20)
        item.alignSelf = .center
        growing.style = item
        root.insertChild(growing, at: 1)
        root.calculateLayout(width: 200, height: 60)

        XCTAssertEqual(growing.layout.width, 170)
        XCTAssertEqual(growing.layout.top, 20)
    }
}
