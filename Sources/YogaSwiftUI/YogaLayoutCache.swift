import SwiftUI
import Yoga

/// Retains contiguous layout storage and one measurement context per subview.
final class YogaLayoutCache {
    let tree = YogaTree(configuration: .init(useWebDefaults: true))
    private(set) var nodes: [YogaNodeID] = []
    private var measurements: [YogaSubviewMeasure] = []

    func synchronize(_ subviews: LayoutSubviews, invalidate: Bool) {
        tree.reserveCapacity(subviews.count + 1)
        while measurements.count > subviews.count {
            tree.remove(nodes.removeLast())
            measurements.removeLast()
        }
        for (index, subview) in subviews.enumerated() {
            if index >= measurements.count {
                let measurement = YogaSubviewMeasure(subview)
                let node = tree.appendChild(to: tree.root)
                tree.setMeasure(for: node) { width, widthMode, height, heightMode in
                    measurement.measure(width: width, widthMode: widthMode, height: height, heightMode: heightMode)
                }
                tree.setBaseline(for: node) { layout, width, height in
                    measurement.baseline(layout: layout, width: width, height: height)
                }
                measurements.append(measurement)
                nodes.append(node)
            } else {
                measurements[index].subview = subview
                if invalidate { tree.markDirty(nodes[index]) }
            }
            var style = YogaStyle(useWebDefaults: true)
            style.applyItemValues(from: subview)
            tree.setStyle(style, for: nodes[index])
        }
    }
}
