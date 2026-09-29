import Foundation
import XCTest
import Yoga

final class UpstreamFixtureTests: XCTestCase {
    private var fixtureBundle: Bundle {
        #if SWIFT_PACKAGE
        Bundle.module
        #else
        Bundle(for: UpstreamFixtureTests.self)
        #endif
    }

    struct Fixture: Decodable {
        var name: String
        var source: String
        var upstreamSkipped: Bool
        var operations: [[String]]
    }

    func testAllGeneratedYoga321Fixtures() throws {
        let url = try XCTUnwrap(fixtureBundle.url(forResource: "yoga-3.2.1", withExtension: "json"))
        let fixtures = try JSONDecoder().decode([Fixture].self, from: Data(contentsOf: url))
        XCTAssertEqual(fixtures.count, 548, "The import must preserve the entire upstream generated suite")
        XCTAssertEqual(fixtures.count(where: \.upstreamSkipped), 17, "Only upstream's own disabled cases may be skipped")
        var failures: [String] = []
        var assertions = 0
        for fixture in fixtures where !fixture.upstreamSkipped {
            var nodes: [String: YogaNode] = [:]
            var texts: [String: String] = [:]
            var failed = false
            var direction = ""
            for op in fixture.operations {
                switch op[0] {
                case "new": nodes[op[1]] = YogaNode()
                case "text": texts[op[1]] = op[2]
                case "measure":
                    let text = try XCTUnwrap(texts[op[1]])
                    nodes[op[1]]?.measure = { _, width, wm, height, hm in intrinsic(text, width, wm, height, hm) }
                case "insert":
                    let parent = try XCTUnwrap(nodes[op[1]])
                    parent.insertChild(try XCTUnwrap(nodes[op[2]]), at: try XCTUnwrap(Int(op[3])))
                case "style": try applyStyle(op, node: XCTUnwrap(nodes[op[2]]))
                case "layout":
                    direction = op[4]
                    let node = try XCTUnwrap(nodes[op[1]])
                    node.calculateLayout(width: Float(op[2]), height: Float(op[3]), direction: op[4] == "YGDirectionRTL" ? .rightToLeft : .leftToRight)
                case "expect":
                    let layout = try XCTUnwrap(nodes[op[1]]).layout
                    let actual: Float
                    switch op[2] {
                    case "Left": actual = layout.left
                    case "Top": actual = layout.top
                    case "Width": actual = layout.width
                    case "Height": actual = layout.height
                    default: throw FixtureError.unknown(op[2])
                    }
                    let expected = try number(op[3])
                    assertions += 1
                    if abs(actual - expected) > max(0.0001, abs(expected) * Float.ulpOfOne * 4) || !actual.isFinite {
                        if !failed { failures.append("\(fixture.source)/\(fixture.name) \(direction) \(op[1]).\(op[2]): expected \(expected), got \(actual)") }
                        failed = true
                    }
                default: throw FixtureError.unknown(op[0])
                }
            }
        }
        print("Yoga 3.2.1 conformance: \(531 - failures.count)/531 active fixtures, \(assertions) assertions; 17 disabled upstream")
        XCTAssertTrue(failures.isEmpty, "\n" + failures.joined(separator: "\n"))
    }
    func testAllGeneratedFixturesThroughTreeHandles() throws {
        let url = try XCTUnwrap(fixtureBundle.url(forResource: "yoga-3.2.1", withExtension: "json"))
        let fixtures = try JSONDecoder().decode([Fixture].self, from: Data(contentsOf: url))
        XCTAssertEqual(fixtures.count, 548, "The import must preserve the entire upstream generated suite")
        XCTAssertEqual(fixtures.count(where: \.upstreamSkipped), 17, "Only upstream's own disabled cases may be skipped")
        var failures: [String] = []
        var assertions = 0
        for fixture in fixtures where !fixture.upstreamSkipped {
            let tree = YogaTree()
            var nodes: [String: TreeFixtureNode] = [:]
            var texts: [String: String] = [:]
            var failed = false
            var direction = ""
            for op in fixture.operations {
                switch op[0] {
                case "new": nodes[op[1]] = TreeFixtureNode(tree: tree)
                case "text": texts[op[1]] = op[2]
                case "measure":
                    let text = try XCTUnwrap(texts[op[1]])
                    nodes[op[1]]?.measure = { _, width, wm, height, hm in intrinsic(text, width, wm, height, hm) }
                case "insert":
                    let parent = try XCTUnwrap(nodes[op[1]])
                    parent.insertChild(try XCTUnwrap(nodes[op[2]]), at: try XCTUnwrap(Int(op[3])))
                case "style": try applyStyle(op, node: XCTUnwrap(nodes[op[2]]))
                case "layout":
                    direction = op[4]
                    let node = try XCTUnwrap(nodes[op[1]])
                    node.calculateLayout(width: Float(op[2]), height: Float(op[3]), direction: op[4] == "YGDirectionRTL" ? .rightToLeft : .leftToRight)
                case "expect":
                    let layout = try XCTUnwrap(nodes[op[1]]).layout
                    let actual: Float
                    switch op[2] {
                    case "Left": actual = layout.left
                    case "Top": actual = layout.top
                    case "Width": actual = layout.width
                    case "Height": actual = layout.height
                    default: throw FixtureError.unknown(op[2])
                    }
                    let expected = try number(op[3])
                    assertions += 1
                    if abs(actual - expected) > max(0.0001, abs(expected) * Float.ulpOfOne * 4) || !actual.isFinite {
                        if !failed { failures.append("\(fixture.source)/\(fixture.name) \(direction) \(op[1]).\(op[2]): expected \(expected), got \(actual)") }
                        failed = true
                    }
                default: throw FixtureError.unknown(op[0])
                }
            }
        }
        print("YogaTree 3.2.1 conformance: \(531 - failures.count)/531 active fixtures, \(assertions) assertions; 17 disabled upstream")
        XCTAssertTrue(failures.isEmpty, "\n" + failures.joined(separator: "\n"))
    }
}

private enum FixtureError: Error { case unknown(String) }

private func number(_ value: String) throws -> Float {
    if value.contains("/") {
        let parts = value.split(separator: "/").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else { throw FixtureError.unknown(value) }
        return try number(parts[0]) / number(parts[1])
    }
    guard let result = Float(value.replacingOccurrences(of: "f", with: "")) else { throw FixtureError.unknown(value) }
    return result
}

private func enumValue<E: CaseIterable>(_ value: String, prefix: String, type: E.Type = E.self) throws -> E {
    let suffix = value.dropFirst(prefix.count).lowercased()
    guard let result = E.allCases.first(where: { String(describing: $0).lowercased() == suffix }) else { throw FixtureError.unknown(value) }
    return result
}

private func applyStyle<Node: FixtureStyleNode>(_ op: [String], node: Node) throws {
    let key = op[1]
    let value = op.last ?? ""
    switch key {
    case "FlexDirection": node.style.flexDirection = try enumValue(value, prefix: "YGFlexDirection")
    case "JustifyContent": node.style.justifyContent = try enumValue(value, prefix: "YGJustify")
    case "AlignContent": node.style.alignContent = try enumValue(value, prefix: "YGAlign")
    case "AlignItems": node.style.alignItems = try enumValue(value, prefix: "YGAlign")
    case "AlignSelf": node.style.alignSelf = try enumValue(value, prefix: "YGAlign")
    case "PositionType": node.style.positionType = try enumValue(value, prefix: "YGPositionType")
    case "FlexWrap": node.style.wrap = try enumValue(value, prefix: "YGWrap")
    case "Overflow": node.style.overflow = try enumValue(value, prefix: "YGOverflow")
    case "Display": node.style.display = try enumValue(value, prefix: "YGDisplay")
    case "BoxSizing": node.style.boxSizing = try enumValue(value, prefix: "YGBoxSizing")
    case "FlexGrow": node.style.flexGrow = try number(value)
    case "FlexShrink": node.style.flexShrink = try number(value)
    case "AspectRatio": node.style.aspectRatio = try number(value)
    case "Border": node.style.setBorder(try number(value), for: try enumValue(op[3], prefix: "YGEdge"))
    default:
        let length: YogaValue
        let property: String
        if key.hasSuffix("Auto") { length = .auto; property = String(key.dropLast(4)) }
        else if key.hasSuffix("Percent") { length = .percent(try number(value)); property = String(key.dropLast(7)) }
        else { length = .point(try number(value)); property = key }
        switch property {
        case "Width": node.style.width = length
        case "Height": node.style.height = length
        case "MinWidth": node.style.minWidth = length
        case "MinHeight": node.style.minHeight = length
        case "MaxWidth": node.style.maxWidth = length
        case "MaxHeight": node.style.maxHeight = length
        case "FlexBasis": node.style.flexBasis = length
        case "Margin": node.style.setMargin(length, for: try enumValue(op[3], prefix: "YGEdge"))
        case "Padding": node.style.setPadding(length, for: try enumValue(op[3], prefix: "YGEdge"))
        case "Position": node.style.setPosition(length, for: try enumValue(op[3], prefix: "YGEdge"))
        case "Gap": node.style.setGap(length, for: try enumValue(op[3], prefix: "YGGutter"))
        default: throw FixtureError.unknown(key)
        }
    }
}

// Port of tests/util/TestUtil.cpp::IntrinsicSizeMeasure, using the same word widths.
private func intrinsic(_ text: String, _ width: Float, _ wm: YogaMeasureMode, _ height: Float, _ hm: YogaMeasureMode) -> YogaSize {
    let textWidth = Float(text.utf8.count) * 10
    let measuredWidth = wm == .exactly ? width : (wm == .atMost ? min(textWidth, width) : textWidth)
    let words = text.split(separator: " ", omittingEmptySubsequences: false)
    let longest = Float(words.map { $0.utf8.count }.max() ?? 0) * 10
    let limit = max(longest, measuredWidth)
    var measuredHeight: Float = 10
    if textWidth > limit {
        var lines: Float = 1
        var current: Float = 0
        for word in words {
            let wordWidth = Float(word.utf8.count) * 10
            if wordWidth > limit {
                if current > 0 { lines += 1 }
                lines += 1; current = 0
            } else if current + wordWidth <= limit { current += wordWidth + 10 }
            else { lines += 1; current = wordWidth + 10 }
        }
        measuredHeight = (current == 0 ? lines - 1 : lines) * 10
    }
    return YogaSize(width: measuredWidth, height: hm == .exactly ? height : (hm == .atMost ? min(measuredHeight, height) : measuredHeight))
}

private protocol FixtureStyleNode: AnyObject {
    var style: YogaStyle { get set }
}
extension YogaNode: FixtureStyleNode {}

private final class TreeFixtureNode: FixtureStyleNode {
    let tree: YogaTree
    let id: YogaNodeID
    init(tree: YogaTree) { self.tree = tree; id = tree.createNode() }
    var style: YogaStyle {
        get { tree.style(of: id) }
        set { tree.setStyle(newValue, for: id) }
    }
    var layout: YogaLayout { tree.layout(of: id) }
    var measure: ((YogaNode?, Float, YogaMeasureMode, Float, YogaMeasureMode) -> YogaSize)? {
        get { nil }
        set {
            if let newValue { tree.setMeasure(for: id) { newValue(nil, $0, $1, $2, $3) } }
            else { tree.setMeasure(for: id, nil) }
        }
    }
    func insertChild(_ child: TreeFixtureNode, at index: Int) { tree.append(child.id, to: id, at: index) }
    func calculateLayout(width: Float?, height: Float?, direction: YogaDirection) {
        tree.calculateLayout(root: id, width: width, height: height, direction: direction)
    }
}
