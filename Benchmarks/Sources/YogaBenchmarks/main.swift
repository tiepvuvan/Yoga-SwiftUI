import Foundation
import Yoga
import BenchmarkMetrics

let arguments = CommandLine.arguments
let workload = arguments.count > 1 ? arguments[1] : "flat"
let mode = arguments.count > 2 ? arguments[2] : "relayout"
let iterations = arguments.count > 3 ? Int(arguments[3]) ?? 1000 : 1000
let childCount = arguments.count > 4 ? Int(arguments[4]) ?? 128 : 128
let sampleCount = arguments.count > 5 ? Int(arguments[5]) ?? 7 : 7
let detachedConstruction = mode == "rebuild-detached"
precondition(childCount > 0 && sampleCount > 0)
precondition(["flat", "wrap", "deep", "measured", "absolute", "contents"].contains(workload))
precondition(["rebuild", "rebuild-detached", "relayout", "mutation", "cached", "dump", "trace", "memory", "allocations", "rounding"].contains(mode))
precondition(iterations > 0)
let config = YogaConfiguration(useWebDefaults: true)

func makeDetachedTree() -> YogaNode {
    var rootStyle = YogaStyle(useWebDefaults: true)
    rootStyle.alignItems = .flexStart
    rootStyle.alignContent = .flexStart
    if workload != "flat" && workload != "absolute" && workload != "deep" { rootStyle.wrap = .wrap }
    if workload == "wrap" {
        rootStyle.setGap(.point(3), for: .column)
        rootStyle.setGap(.point(5), for: .row)
    }
    let root = YogaNode(configuration: config, style: rootStyle)
    func add(_ parent: YogaNode, _ style: YogaStyle) -> YogaNode {
        if detachedConstruction {
            let child = YogaNode(configuration: config, style: style)
            parent.appendChild(child)
            return child
        }
        return parent.appendChild(style: style)
    }
    if workload == "deep" {
        func append(_ parent: YogaNode, _ depth: Int) {
            if depth == 0 { parent.style.height = .point(10); return }
            for _ in 0..<3 {
                var style = YogaStyle(useWebDefaults: true)
                style.flexDirection = depth.isMultiple(of: 2) ? .column : .row
                style.flexGrow = 1
                let child = add(parent, style)
                append(child, depth - 1)
            }
        }
        append(root, childCount <= 8 ? 2 : childCount <= 32 ? 3 : 5)
        return root
    }
    for index in 0..<childCount {
        var style = YogaStyle(useWebDefaults: true)
        style.width = .point(Float(12 + index % 7))
        style.height = .point(Float(10 + index % 5))
        if workload == "wrap" {
            style.width = index.isMultiple(of: 7) ? .percent(25) : .point(Float(22 + index % 5 * 10))
            style.minWidth = .point(16)
            style.maxWidth = .point(100)
        } else if workload == "measured" {
            style.width = .auto
            style.height = .auto
        } else if workload == "absolute" && index.isMultiple(of: 4) {
            style.positionType = .absolute
            style.width = .percent(15)
            style.setPosition(.percent(Float(index % 80)), for: .left)
            style.setPosition(.point(Float(index)), for: .top)
        } else if workload == "contents" && index.isMultiple(of: 8) {
            style.display = .contents
        }
        let child = add(root, style)
        if workload == "measured" {
            let intrinsic = Float(80 + index % 11)
            child.measure = { _, width, wm, height, hm in
                let w = wm == .exactly ? width : (wm == .atMost ? min(width, intrinsic) : intrinsic)
                let h = 20 * (intrinsic / max(1, w)).rounded(.up)
                return YogaSize(width: w, height: hm == .exactly ? height : (hm == .atMost ? min(height, h) : h))
            }
        }
        if style.display == .contents {
            for _ in 0..<2 {
                var grandStyle = YogaStyle(useWebDefaults: true)
                grandStyle.width = .point(25)
                grandStyle.height = .point(12)
                _ = add(child, grandStyle)
            }
        }
    }
    return root
}

func makeTree() -> YogaTree {
    var rootStyle = YogaStyle(useWebDefaults: true)
    rootStyle.alignItems = .flexStart
    rootStyle.alignContent = .flexStart
    if workload != "flat" && workload != "absolute" && workload != "deep" { rootStyle.wrap = .wrap }
    if workload == "wrap" {
        rootStyle.setGap(.point(3), for: .column)
        rootStyle.setGap(.point(5), for: .row)
    }
    let tree = YogaTree(configuration: config, style: rootStyle)
    let root = tree.root
    func add(_ parent: YogaNodeID, _ style: YogaStyle) -> YogaNodeID {
        tree.appendChild(to: parent, style: style)
    }
    if workload == "deep" {
        func append(_ parent: YogaNodeID, _ depth: Int) {
            if depth == 0 { tree.updateStyle(of: parent) { $0.height = .point(10) }; return }
            for _ in 0..<3 {
                var style = YogaStyle(useWebDefaults: true)
                style.flexDirection = depth.isMultiple(of: 2) ? .column : .row
                style.flexGrow = 1
                let child = add(parent, style)
                append(child, depth - 1)
            }
        }
        append(root, childCount <= 8 ? 2 : childCount <= 32 ? 3 : 5)
        return tree
    }
    for index in 0..<childCount {
        var style = YogaStyle(useWebDefaults: true)
        style.width = .point(Float(12 + index % 7))
        style.height = .point(Float(10 + index % 5))
        if workload == "wrap" {
            style.width = index.isMultiple(of: 7) ? .percent(25) : .point(Float(22 + index % 5 * 10))
            style.minWidth = .point(16)
            style.maxWidth = .point(100)
        } else if workload == "measured" {
            style.width = .auto
            style.height = .auto
        } else if workload == "absolute" && index.isMultiple(of: 4) {
            style.positionType = .absolute
            style.width = .percent(15)
            style.setPosition(.percent(Float(index % 80)), for: .left)
            style.setPosition(.point(Float(index)), for: .top)
        } else if workload == "contents" && index.isMultiple(of: 8) {
            style.display = .contents
        }
        let child = add(root, style)
        if workload == "measured" {
            let intrinsic = Float(80 + index % 11)
            tree.setMeasure(for: child) { width, wm, height, hm in
                let w = wm == .exactly ? width : (wm == .atMost ? min(width, intrinsic) : intrinsic)
                let h = 20 * (intrinsic / max(1, w)).rounded(.up)
                return YogaSize(width: w, height: hm == .exactly ? height : (hm == .atMost ? min(height, h) : h))
            }
        }
        if style.display == .contents {
            for _ in 0..<2 {
                var grandStyle = YogaStyle(useWebDefaults: true)
                grandStyle.width = .point(25)
                grandStyle.height = .point(12)
                _ = add(child, grandStyle)
            }
        }
    }
    return tree
}

func values(_ tree: YogaTree, node: YogaNodeID? = nil, into output: inout [[Float]]) {
    let id = node ?? tree.root
    let l = tree.layout(of: id)
    output.append([l.left, l.top, l.width, l.height, l.right, l.bottom,
                   l.margin.left, l.margin.top, l.margin.right, l.margin.bottom,
                   l.padding.left, l.padding.top, l.padding.right, l.padding.bottom,
                   l.border.left, l.border.top, l.border.right, l.border.bottom,
                   Float(l.direction.rawValue), l.hadOverflow ? 1 : 0])
    for index in 0..<tree.childCount(of: id) { values(tree, node: tree.child(at: index, of: id), into: &output) }
}

func mutate(_ tree: YogaTree, _ step: Int) {
    let child = tree.child(at: step % tree.childCount(of: tree.root), of: tree.root)
    if step % 6 == 5 {
        tree.updateStyle(of: tree.root) { $0.setGap(.point(Float(step % 7)), for: .row) }
        return
    }
    tree.updateStyle(of: child) { style in
        switch step % 6 {
        case 0: style.width = .percent(Float(5 + (step * 7) % 45))
        case 1: style.setMargin(.point(Float(step % 4)), for: .start)
        case 2: style.minWidth = .point(Float(step % 23))
        case 3: style.positionType = step.isMultiple(of: 9) ? .absolute : .relative
        default: style.display = step % 12 == 4 ? .none : .flex
        }
    }
}

let initial = makeTree()
let lastChild = initial.child(at: initial.childCount(of: initial.root) - 1, of: initial.root)
initial.calculateLayout(width: mode == "dump" ? Float(arguments.count > 3 ? arguments[3] : "320") ?? 320 : 320, height: 640)
var layoutValues: [[Float]] = []
values(initial, into: &layoutValues)
let checksum = layoutValues.flatMap { $0 }.reduce(0, +)
if mode == "rounding" {
    var state: UInt64 = 0x1a26c5b37
    let special: [Double] = [-0.0, 0, -0.5, 0.5, 0.499999, 0.500001, -0.99999, 0.99999, .infinity, -.infinity, .nan]
    var output: [UInt32?] = []
    for index in 0..<iterations {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        let value = index < special.count ? special[index] : Double(bitPattern: state)
        for scale: Double in [0.5, 1, 1.5, 2, 3, 0.001, 10000] {
            for flags in 0..<4 {
                let rounded = yogaRoundToPixelGrid(value, scale: scale, forceCeil: flags & 1 != 0, forceFloor: flags & 2 != 0)
                output.append(rounded.isNaN ? nil : rounded.bitPattern)
            }
        }
    }
    print(String(decoding: try JSONEncoder().encode(output), as: UTF8.self))
} else if mode == "dump" {
    print(String(decoding: try JSONEncoder().encode(layoutValues), as: UTF8.self))
} else if mode == "trace" {
    var trace: [[[Float]]] = []
    for step in 0..<iterations {
        mutate(initial, step)
        initial.calculateLayout(width: Float(320 + step % 3), height: 640,
                                direction: step.isMultiple(of: 2) ? .leftToRight : .rightToLeft)
        var snapshot: [[Float]] = []
        values(initial, into: &snapshot)
        trace.append(snapshot)
    }
    print(String(decoding: try JSONEncoder().encode(trace), as: UTF8.self))
} else if mode == "memory" {
    let count = iterations
    // Initialize runtime and allocator metadata before measuring live heap deltas.
    var trees: [YogaTree] = []
    trees.reserveCapacity(count)
    let before = yoga_benchmark_metrics()
    for _ in 0..<count { trees.append(makeTree()) }
    let constructed = yoga_benchmark_metrics()
    for tree in trees { tree.calculateLayout(width: 320, height: 640) }
    let laidOut = yoga_benchmark_metrics()
    let result: [String: Any] = ["engine": "swift", "workload": workload, "mode": mode, "trees": count,
        "nodes_per_tree": layoutValues.count, "checksum": checksum,
        "constructed_heap_bytes_per_tree": Double(constructed.heap_bytes - before.heap_bytes) / Double(count),
        "laid_out_heap_bytes_per_tree": Double(laidOut.heap_bytes - before.heap_bytes) / Double(count)]
    let json = try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys])
    withExtendedLifetime(trees) { print(String(decoding: json, as: UTF8.self)) }
} else {
    func work(_ index: Int) -> Float {
        if detachedConstruction {
            let root = makeDetachedTree()
            root.calculateLayout(width: 320, height: 640)
            return root.children.last?.layout.left ?? root.layout.height
        }
        if mode == "rebuild" {
            let root = makeTree()
            root.calculateLayout(width: 320, height: 640)
            return root.layout(of: root.child(at: root.childCount(of: root.root) - 1, of: root.root)).left
        }
        if mode == "mutation" { mutate(initial, index) }
        initial.calculateLayout(width: mode == "cached" ? 320 : (index.isMultiple(of: 2) ? 320 : 321), height: 640)
        return initial.layout(of: lastChild).left
    }
    var sink: Float = 0
    for index in 0..<100 { sink += work(index) }
    if mode == "allocations" {
        let available = yoga_benchmark_allocations_begin() != 0
        for index in 0..<iterations {
            initial.calculateLayout(width: index.isMultiple(of: 2) ? 320 : 321, height: 640)
            sink += initial.layout(of: lastChild).left
        }
        let counts = yoga_benchmark_allocations_end()
        let result: [String: Any] = ["engine": "swift", "workload": workload, "mode": mode,
            "iterations": iterations, "available": available && counts.available != 0,
            "allocations": counts.allocations, "allocated_bytes": counts.allocated_bytes, "sink": sink]
        print(String(decoding: try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys]), as: UTF8.self))
    } else {
    var samples: [[String: Any]] = []
    for _ in 0..<sampleCount {
        let before = yoga_benchmark_metrics()
        for index in 0..<iterations { sink += work(index) }
        let after = yoga_benchmark_metrics()
        samples.append(["wall_ns": Double(after.wall_ns - before.wall_ns) / Double(iterations),
                        "cpu_ns": Double(after.cpu_ns - before.cpu_ns) / Double(iterations),
                        "cycles": Double(after.cycles - before.cycles) / Double(iterations),
                        "instructions": Double(after.instructions - before.instructions) / Double(iterations)])
    }
    let result: [String: Any] = ["engine": "swift", "workload": workload, "mode": mode, "iterations": iterations,
        "checksum": checksum, "sink": sink, "nodes_per_tree": layoutValues.count, "requested_children": childCount, "hardware_counters_available": yoga_benchmark_metrics().hardware_counters_available != 0,
        "samples": samples]
    print(String(decoding: try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys]), as: UTF8.self))
    }
}
