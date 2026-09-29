import XCTest
import Yoga

final class NodeLifecycleTests: XCTestCase {
    func testStylesAreValuesAndInvalidateAncestors() {
        let root = YogaNode()
        let container = YogaNode()
        let leaf = YogaNode()
        leaf.style.width = .point(20)
        leaf.style.height = .point(10)
        container.appendChild(leaf)
        root.appendChild(container)
        root.calculateLayout()
        XCTAssertEqual(root.layout.width, 20)
        var copy = leaf.style
        copy.width = .point(40)
        copy.setPadding(.point(3), for: .all)
        XCTAssertEqual(leaf.style.width, .point(20))
        XCTAssertEqual(leaf.style.padding(for: .all), .undefined)
        leaf.style = copy
        XCTAssertTrue(root.isDirty)
        XCTAssertTrue(container.isDirty)
        root.calculateLayout()
        XCTAssertEqual(root.layout.width, 40)
        XCTAssertFalse(leaf.isDirty)
        leaf.style = copy
        XCTAssertFalse(root.isDirty, "Assigning an unchanged style preserves the cache")
    }

    func testMeasuredContentInvalidationAndRepeatedLayout() {
        let root = YogaNode()
        let text = YogaNode()
        var calls = 0
        var intrinsicWidth: Float = 32
        text.measure = { _, _, _, _, _ in
            calls += 1
            return YogaSize(width: intrinsicWidth, height: 12)
        }
        root.style.alignItems = .flexStart
        root.appendChild(text)
        root.calculateLayout()
        let firstCalls = calls
        XCTAssertGreaterThan(firstCalls, 0)
        XCTAssertEqual(root.layout.width, 32)
        root.calculateLayout()
        XCTAssertEqual(calls, firstCalls)
        intrinsicWidth = 64
        text.markDirty()
        root.calculateLayout()
        XCTAssertGreaterThan(calls, firstCalls)
        XCTAssertEqual(root.layout.width, 64)
    }

    func testRemovalReparentingAndOwnership() {
        var root: YogaNode? = YogaNode()
        let child = YogaNode()
        weak var weakRoot = root
        root?.appendChild(child)
        root?.calculateLayout(width: 100, height: 40)
        let removed = root?.removeChild(at: 0)
        XCTAssertTrue(removed === child)
        XCTAssertNil(child.parent)
        XCTAssertEqual(child.layout.width, 0)
        let newParent = YogaNode()
        newParent.appendChild(child)
        newParent.calculateLayout(width: 50, height: 30)
        XCTAssertEqual(child.layout.width, 50)
        root = nil
        XCTAssertNil(weakRoot)
        newParent.removeAllChildren()
        XCTAssertNil(child.parent)
    }

    func testParentsDoNotFormRetainCycles() {
        weak var weakRoot: YogaNode?
        weak var weakChild: YogaNode?
        do {
            let root = YogaNode()
            let child = YogaNode()
            weakRoot = root
            weakChild = child
            root.appendChild(child)
        }
        XCTAssertNil(weakRoot)
        XCTAssertNil(weakChild)
    }

    func testRoundedLayoutRemainsStableOnCacheHits() {
        let root = YogaNode(configuration: .init(pointScaleFactor: 2))
        root.style.width = .point(10.3)
        root.style.height = .point(8.3)
        root.calculateLayout()
        let original = root.layout
        root.hasNewLayout = false
        for _ in 0..<10 { root.calculateLayout() }
        XCTAssertEqual(root.layout, original)
        XCTAssertEqual(root.layout.width, 10.5)
        XCTAssertFalse(root.hasNewLayout)
    }

    func testDisplayTransitionsInvalidateFlattenedChildren() {
        let root = YogaNode()
        root.style.flexDirection = .row
        let group = YogaNode()
        let leaf = YogaNode()
        leaf.style.width = .point(20)
        leaf.style.height = .point(10)
        group.appendChild(leaf)
        root.appendChild(group)
        root.calculateLayout()
        XCTAssertEqual(root.layout.width, 20)
        group.style.display = .none
        root.calculateLayout()
        XCTAssertEqual(root.layout.width, 0)
        XCTAssertEqual(leaf.layout.width, 0)
        group.style.display = .contents
        root.calculateLayout()
        XCTAssertEqual(root.layout.width, 20)
        XCTAssertEqual(group.layout.width, 0)
        XCTAssertEqual(leaf.layout.width, 20)
        leaf.style.width = .point(30)
        root.calculateLayout()
        XCTAssertEqual(root.layout.width, 30)
        group.style.display = .flex
        root.calculateLayout()
        XCTAssertEqual(group.layout.width, 30)
    }

    func testBaselineCallbackAlignsSiblings() {
        let root = YogaNode()
        root.style.flexDirection = .row
        root.style.alignItems = .baseline
        let first = YogaNode()
        first.style.width = .point(30)
        first.style.height = .point(20)
        first.baseline = { _, _, _ in 8 }
        let second = YogaNode()
        second.style.width = .point(20)
        second.style.height = .point(30)
        second.baseline = { _, _, _ in 18 }
        root.appendChild(first)
        root.appendChild(second)
        root.calculateLayout()
        XCTAssertEqual(first.layout.top + 8, second.layout.top + 18)
        first.baseline = { _, _, _ in 12 }
        XCTAssertTrue(root.isDirty)
        root.calculateLayout()
        XCTAssertEqual(first.layout.top + 12, second.layout.top + 18)
    }

    func testReusedTreeMatchesFreshLayoutAfterMutations() {
        let root = makeTree()
        for step in 0..<40 {
            root.style.wrap = step.isMultiple(of: 2) ? .wrap : .noWrap
            root.children[step % 9].style.width = .percent(Float(10 + step))
            root.children[(step + 3) % 9].style.setMargin(.point(Float(step % 5)), for: .start)
            root.children[(step + 5) % 9].style.display = step.isMultiple(of: 3) ? .none : .flex
            let fresh = clone(root)
            let width = Float(80 + step * 7)
            let direction: YogaDirection = step.isMultiple(of: 2) ? .leftToRight : .rightToLeft
            root.calculateLayout(width: width, height: 160, direction: direction)
            fresh.calculateLayout(width: width, height: 160, direction: direction)
            assertLayoutsEqual(root, fresh, step: step)
        }
    }

    func testCompatibleMeasuredConstraintsReuseTheCallback() {
        let root = YogaNode()
        root.style.alignItems = .flexStart
        let leaf = YogaNode()
        var calls = 0
        leaf.measure = { _, _, _, _, _ in
            calls += 1
            return YogaSize(width: 30, height: 12)
        }
        root.appendChild(leaf)
        root.calculateLayout(width: 100)
        let originalCalls = calls
        root.calculateLayout(width: 80)
        XCTAssertEqual(leaf.layout.width, 30)
        XCTAssertEqual(calls, originalCalls, "An existing measurement still fits a tighter limit")
        leaf.markDirty()
        root.calculateLayout(width: 80)
        XCTAssertGreaterThan(calls, originalCalls)
    }

    func testPercentageInsetsInvalidateWhenOnlyOwnerWidthChanges() {
        let root = YogaNode()
        root.style.alignItems = .flexStart
        let leaf = YogaNode()
        leaf.style.width = .point(80)
        leaf.style.setPadding(.percent(10), for: .vertical)
        root.appendChild(leaf)
        root.calculateLayout(width: 200)
        XCTAssertEqual(leaf.layout.height, 40)
        root.calculateLayout(width: 400)
        XCTAssertEqual(leaf.layout.height, 80)
        XCTAssertEqual(leaf.layout.padding.top, 40)
    }

    func testAutoPaddingAndGapRestoreGroupedFallbacks() {
        let root = YogaNode()
        root.style.setPadding(.point(10), for: .all)
        root.style.setPadding(.point(20), for: .left)
        root.style.setPadding(.auto, for: .left)
        root.style.setGap(.point(8))
        root.style.setGap(.point(20), for: .column)
        root.style.setGap(.auto, for: .column)
        XCTAssertEqual(root.style.padding(for: .left), .undefined)
        XCTAssertEqual(root.style.gap(for: .column), .undefined)
        root.calculateLayout()
        XCTAssertEqual(root.layout.padding.left, 10)
    }

    func testRetainedChildCanBecomeARootAfterItsParentIsReleased() {
        let child = YogaNode()
        child.style.width = .point(20)
        child.style.height = .point(10)
        do {
            let parent = YogaNode()
            parent.style.flexDirection = .row
            parent.style.justifyContent = .flexEnd
            parent.appendChild(child)
            parent.calculateLayout(width: 100, height: 40)
            XCTAssertEqual(child.layout.left, 80)
        }
        XCTAssertNil(child.parent)
        child.calculateLayout(width: 100, height: 40)
        XCTAssertEqual(child.layout.left, 0)
        XCTAssertEqual(child.layout.width, 20)
    }

    func testChangedRootProposalPreservesPixelRoundingOnCacheHits() {
        let root = YogaNode(configuration: .init(pointScaleFactor: 2))
        root.style.width = .point(10.3)
        root.style.height = .point(8.3)
        root.style.setPosition(.point(0.3), for: .left)
        let child = YogaNode(configuration: root.configuration)
        child.style.width = .point(2.3)
        child.style.height = .point(2.3)
        child.style.setPosition(.point(0.3), for: .left)
        root.appendChild(child)
        root.calculateLayout(width: 100, height: 40)
        let expected = root.layout
        let childExpected = child.layout
        root.calculateLayout(width: 200, height: 80)
        XCTAssertEqual(root.layout, expected)
        XCTAssertEqual(child.layout, childExpected)

        let measured = YogaNode(configuration: .init(pointScaleFactor: 2))
        measured.measure = { _, _, _, _, _ in YogaSize(width: 10.3, height: 8.3) }
        measured.style.maxWidth = .point(100)
        measured.calculateLayout(width: 300)
        let measuredExpected = measured.layout
        measured.calculateLayout(width: 200)
        XCTAssertEqual(measured.layout, measuredExpected)
    }

    private func makeTree() -> YogaNode {
        let root = YogaNode(configuration: .init(useWebDefaults: true, pointScaleFactor: 2))
        root.style.setGap(.point(3))
        for i in 0..<9 {
            let child = YogaNode(configuration: root.configuration)
            child.style.width = .point(Float(10 + i * 5))
            child.style.height = .point(Float(10 + i * 2))
            child.style.flexGrow = Float(i % 3)
            child.style.minWidth = .point(8)
            child.style.maxWidth = .point(70)
            child.style.setPadding(.percent(2), for: .all)
            let grandchild = YogaNode(configuration: root.configuration)
            grandchild.style.width = .percent(60)
            grandchild.style.height = .percent(70)
            child.appendChild(grandchild)
            root.appendChild(child)
        }
        return root
    }

    private func clone(_ node: YogaNode) -> YogaNode {
        let copy = YogaNode(configuration: node.configuration, style: node.style)
        for child in node.children { copy.appendChild(clone(child)) }
        return copy
    }

    private func assertLayoutsEqual(_ a: YogaNode, _ b: YogaNode, step: Int) {
        XCTAssertEqual(a.layout, b.layout, "Cache diverged from a fresh layout at mutation \(step)")
        for (left, right) in zip(a.children, b.children) { assertLayoutsEqual(left, right, step: step) }
    }
}
