// The identical executable source is compiled against v2 and the working tree.
import AppKit
import Foundation
import SwiftUI
import CryptoKit
import YogaSwiftUI
import BenchmarkMetrics

struct BenchmarkView: View {
    let measured: Bool
    var body: some View {
        Flex(direction: .row, alignItems: .flexStart, wrap: .wrap, columnGap: 3) {
            ForEach(0..<128, id: \.self) { index in
                if measured {
                    Text("Item \(index): a title that wraps")
                        .font(.system(size: 12))
                        .flexBasis(.point(75))
                        .flexShrink(1)
                } else {
                    Rectangle()
                        .fill(index.isMultiple(of: 2) ? Color.red : Color.blue)
                        .flexWidth(.point(Float(12 + index % 7)))
                        .flexHeight(.point(Float(10 + index % 5)))
                }
            }
        }
    }
}

let args = CommandLine.arguments
let workload = args.count > 1 ? args[1] : "shapes"
let iterations = args.count > 2 ? Int(args[2]) ?? 100 : 100
let sampleCount = args.count > 3 ? Int(args[3]) ?? 1 : 7
precondition(["shapes", "text"].contains(workload) && iterations > 0 && sampleCount > 0)
let view = BenchmarkView(measured: workload == "text")
let host = NSHostingView(rootView: view)
host.sizingOptions = []
@MainActor func work(_ index: Int) {
    host.setFrameSize(NSSize(width: index.isMultiple(of: 2) ? 320 : 321, height: 640))
    host.needsLayout = true
    host.layoutSubtreeIfNeeded()
}
for i in 0..<100 { work(i) }
var samples: [[String: Double]] = []
for _ in 0..<sampleCount {
    let before = yoga_benchmark_metrics()
    for i in 0..<iterations { work(i) }
    let after = yoga_benchmark_metrics()
    samples.append(["cpu_ns": Double(after.cpu_ns - before.cpu_ns) / Double(iterations),
                    "cycles": Double(after.cycles - before.cycles) / Double(iterations),
                    "instructions": Double(after.instructions - before.instructions) / Double(iterations),
                    "wall_ns": Double(after.wall_ns - before.wall_ns) / Double(iterations)])
}
// Pixel parity catches adapter differences that the core frame comparison misses.
var pixelDigests: [String: String] = [:]
for width in [320, 321] {
    let renderer = ImageRenderer(content: view)
    renderer.scale = 1
    renderer.proposedSize = ProposedViewSize(width: CGFloat(width), height: 640)
    guard let image = renderer.cgImage, let provider = image.dataProvider, let pixels = provider.data else {
        fatalError("Could not render the benchmark view")
    }
    pixelDigests[String(width)] = SHA256.hash(data: pixels as Data).map { String(format: "%02x", $0) }.joined()
}
// Warmed framework state is excluded. Retain 32 complete hosting-view trees.
var retained: [NSHostingView<BenchmarkView>] = []
retained.reserveCapacity(32)
let heapBefore = yoga_benchmark_metrics().heap_bytes
for _ in 0..<32 {
    let tree = NSHostingView(rootView: view)
    tree.sizingOptions = []
    tree.setFrameSize(NSSize(width: 320, height: 640))
    tree.layoutSubtreeIfNeeded()
    retained.append(tree)
}
let heapAfter = yoga_benchmark_metrics().heap_bytes
let result: [String: Any] = ["workload": workload, "iterations": iterations, "samples": samples,
    "live_heap_bytes_per_host": Double(Int64(heapAfter) - Int64(heapBefore)) / 32,
    "pixel_sha256_by_width": pixelDigests,
    "hardware_counters_available": yoga_benchmark_metrics().hardware_counters_available != 0]
let json = try JSONSerialization.data(withJSONObject: result, options: [.sortedKeys])
withExtendedLifetime(retained) { print(String(decoding: json, as: UTF8.self)) }
