import XCTest
import Yoga

final class StorageTests: XCTestCase {
    func testCompactOptionalScalarsAndClearedEdgesPreserveValueSemantics() {
        let properties: [WritableKeyPath<YogaStyle, Float?>] = [\.flex, \.flexGrow, \.flexShrink, \.aspectRatio]
        for property in properties {
            var style = YogaStyle()
            XCTAssertNil(style[keyPath: property])
            for value: Float in [-1.25, 0, Float.greatestFiniteMagnitude, .infinity, -.infinity] {
                style[keyPath: property] = value
                XCTAssertEqual(style[keyPath: property], value)
                var copy = style
                copy[keyPath: property] = nil
                XCTAssertNil(copy[keyPath: property])
                XCTAssertEqual(style[keyPath: property], value)
                XCTAssertEqual(copy, YogaStyle())
            }
            style[keyPath: property] = .nan
            XCTAssertEqual(style[keyPath: property]?.isNaN, true)
            style[keyPath: property] = nil
            XCTAssertEqual(style, YogaStyle())
        }
        var style = YogaStyle()
        style.setPosition(.percent(12), for: .left)
        style.setMargin(.point(3), for: .all)
        let copy = style
        style.setPosition(.undefined, for: .left)
        style.setMargin(.undefined, for: .all)
        XCTAssertEqual(style, YogaStyle())
        XCTAssertEqual(copy.position(for: .left), .percent(12))
        XCTAssertEqual(copy.margin(for: .all), .point(3))
    }

    func testGrowthAndReparentingPreserveValuesAndCallbacks() {
        let root = YogaNode()
        root.style.flexDirection = .row
        root.style.wrap = .wrap
        var children: [YogaNode] = []
        for index in 0..<300 {
            var style = YogaStyle()
            style.width = .point(Float(index % 17 + 10))
            style.height = .point(12)
            style.setMargin(.point(1), for: .all)
            children.append(root.appendChild(style: style))
        }
        root.calculateLayout(width: 320)
        for (index, child) in children.enumerated() {
            XCTAssertTrue(child.parent === root)
            XCTAssertEqual(child.layout.width, Float(index % 17 + 10))
            XCTAssertEqual(child.layout.margin.left, 1)
        }
        let other = YogaNode()
        let moved = root.removeChild(at: 117)
        moved.style.width = .auto
        moved.style.height = .auto
        moved.measure = { node, _, _, _, _ in
            XCTAssertTrue(node === moved)
            return YogaSize(width: 31, height: 19)
        }
        other.style.alignItems = .flexStart
        other.appendChild(moved)
        other.calculateLayout(width: 100)
        XCTAssertEqual(moved.layout.width, 31)
        XCTAssertEqual(moved.layout.height, 19)
        moved.measure = nil // Break the intentional self-capture in this test.
    }

    func testRecycledStorageReleasesCallbacksAndOldStyles() {
        final class Content {}
        let root = YogaNode()
        weak var releasedContent: Content?
        for _ in 0..<40 {
            do {
                let content = Content()
                releasedContent = content
                let node = root.appendChild()
                node.style.setPadding(.point(7), for: .all)
                node.measure = { [content] _, _, _, _, _ in
                    withExtendedLifetime(content) { YogaSize(width: 20, height: 10) }
                }
                root.calculateLayout()
                root.removeAllChildren()
            }
            XCTAssertNil(releasedContent)
            let fresh = root.appendChild()
            root.calculateLayout()
            XCTAssertNil(fresh.measure)
            XCTAssertEqual(fresh.style.padding(for: .all), .undefined)
            XCTAssertEqual(fresh.layout.width, 0)
            root.removeAllChildren()
        }
    }

    func testContentsAndAbsoluteTransitionsRefreshFlow() {
        let root = YogaNode()
        root.style.flexDirection = .row
        let group = root.appendChild()
        let leaf = group.appendChild()
        leaf.style.width = .point(20)
        leaf.style.height = .point(10)
        root.calculateLayout()
        XCTAssertEqual(group.layout.width, 20)
        group.style.display = .contents
        root.calculateLayout()
        XCTAssertEqual(group.layout.width, 0)
        XCTAssertEqual(root.layout.width, 20)
        XCTAssertFalse(group.isDirty)
        leaf.style.positionType = .absolute
        root.calculateLayout()
        XCTAssertEqual(root.layout.width, 0)
        leaf.style.positionType = .relative
        root.calculateLayout()
        XCTAssertEqual(root.layout.width, 20)
    }

    func testLengthStoragePreservesUnitsAndValueSemantics() {
        var style = YogaStyle()
        XCTAssertEqual(style.width, .auto)
        XCTAssertEqual(style.flexBasis, .auto)
        XCTAssertEqual(style.minWidth, .undefined)
        let values: [YogaValue] = [.undefined, .auto, .point(-1.25), .point(Float.greatestFiniteMagnitude), .percent(12.345)]
        for value in values {
            style.width = value; style.height = value; style.flexBasis = value
            style.minWidth = value; style.maxWidth = value
            style.minHeight = value; style.maxHeight = value
            var copy = style
            copy.width = .point(42)
            for actual in [style.width, style.height, style.flexBasis, style.minWidth, style.maxWidth, style.minHeight, style.maxHeight] {
                XCTAssertEqual(actual, value)
            }
            XCTAssertEqual(copy.width, .point(42))
            XCTAssertEqual(copy.height, value)
        }
    }
}
