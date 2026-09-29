import XCTest
import Yoga

final class TreeLifecycleTests: XCTestCase {
    func testDetachedRootsPrepareIndependentTopology() {
        let tree = YogaTree()
        let detached = tree.createNode()
        let group = tree.appendChild(to: detached)
        let child = tree.appendChild(to: group)
        tree.updateStyle(of: child) { $0.width = .point(20); $0.height = .point(10) }
        tree.calculateLayout(root: detached)
        XCTAssertEqual(tree.layout(of: group).width, 20)
        tree.updateStyle(of: group) { $0.display = .contents }
        tree.calculateLayout() // Preparing one root must also refresh detached roots.
        tree.calculateLayout(root: detached)
        XCTAssertEqual(tree.layout(of: group).width, 0)
        XCTAssertEqual(tree.layout(of: detached).width, 20)
        tree.append(child, to: tree.root)
        tree.remove(group)
        tree.calculateLayout(root: detached)
        tree.calculateLayout()
        XCTAssertEqual(tree.layout(of: detached).width, 0)
        XCTAssertEqual(tree.layout(of: tree.root).width, 20)
    }

    func testIdentifiersSurviveGrowthButRejectDeletionAndOtherOwners() {
        let tree = YogaTree()
        let first = tree.appendChild(to: tree.root)
        for index in 0..<500 {
            let id = tree.appendChild(to: tree.root)
            tree.updateStyle(of: id) { $0.width = .point(Float(index + 1)); $0.height = .point(1) }
        }
        XCTAssertTrue(tree.contains(first))
        let other = YogaTree()
        XCTAssertFalse(other.contains(first))
        tree.remove(first)
        XCTAssertFalse(tree.contains(first))
        let reused = tree.appendChild(to: tree.root)
        XCTAssertNotEqual(first, reused)
        XCTAssertTrue(tree.contains(reused))
        tree.calculateLayout()
        XCTAssertFalse(tree.contains(first))
    }

    func testReparentingAndRemovalInvalidateDescendantHandles() {
        let tree = YogaTree()
        tree.updateStyle(of: tree.root) { $0.alignItems = .flexStart }
        let a = tree.appendChild(to: tree.root)
        let b = tree.appendChild(to: tree.root)
        let leaf = tree.appendChild(to: a)
        tree.updateStyle(of: leaf) { $0.width = .point(20); $0.height = .point(10) }
        tree.calculateLayout()
        XCTAssertEqual(tree.layout(of: a).width, 20)
        tree.append(leaf, to: b)
        tree.calculateLayout()
        XCTAssertEqual(tree.layout(of: a).width, 0)
        XCTAssertEqual(tree.layout(of: b).width, 20)
        XCTAssertTrue(tree.contains(leaf))
        tree.remove(b)
        XCTAssertFalse(tree.contains(leaf))
        XCTAssertFalse(tree.contains(b))
        tree.calculateLayout()
        XCTAssertEqual(tree.layout(of: tree.root).width, 0)
    }

    func testMeasurementInvalidationAndBaselineCallbacks() {
        let tree = YogaTree()
        tree.updateStyle(of: tree.root) { $0.flexDirection = .row; $0.alignItems = .baseline }
        let a = tree.appendChild(to: tree.root)
        let b = tree.appendChild(to: tree.root)
        var calls = 0
        var width: Float = 20
        tree.setMeasure(for: a) { _, _, _, _ in calls += 1; return YogaSize(width: width, height: 10) }
        tree.setBaseline(for: a) { _, _, _ in 7 }
        tree.updateStyle(of: b) { $0.width = .point(30); $0.height = .point(20) }
        tree.setBaseline(for: b) { _, _, _ in 12 }
        tree.calculateLayout()
        XCTAssertEqual(tree.layout(of: a).top + 7, tree.layout(of: b).top + 12)
        let firstCalls = calls
        tree.calculateLayout()
        XCTAssertEqual(calls, firstCalls)
        width = 40
        tree.markDirty(a)
        tree.calculateLayout()
        XCTAssertEqual(tree.layout(of: a).width, 40)
        XCTAssertGreaterThan(calls, firstCalls)
    }

    func testHandleDoesNotKeepTreeOrContentAlive() {
        final class Content {}
        weak var weakTree: YogaTree?
        weak var weakContent: Content?
        let retainedID: YogaNodeID
        do {
            let tree = YogaTree()
            weakTree = tree
            let content = Content()
            weakContent = content
            retainedID = tree.appendChild(to: tree.root)
            tree.setMeasure(for: retainedID) { [content] _, _, _, _ in
                withExtendedLifetime(content) { YogaSize(width: 10, height: 10) }
            }
        }
        XCTAssertNil(weakTree)
        XCTAssertNil(weakContent)
        XCTAssertFalse(YogaTree().contains(retainedID))
    }

    func testRepeatedGrowShrinkAndReusePreserveStaleHandleChecks() {
        let tree = YogaTree()
        var stale: [YogaNodeID] = []
        for _ in 0..<12 {
            var nodes: [YogaNodeID] = []
            for _ in 0..<100 { nodes.append(tree.appendChild(to: tree.root)) }
            tree.calculateLayout(width: 320)
            for node in nodes.reversed() { tree.remove(node) }
            tree.calculateLayout(width: 320)
            stale.append(contentsOf: nodes)
            XCTAssertTrue(stale.allSatisfy { !tree.contains($0) })
        }
    }
}
