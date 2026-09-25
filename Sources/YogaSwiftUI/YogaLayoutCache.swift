import YogaBridge

/// Owns all Yoga allocations for a SwiftUI Layout cache.
final class YogaLayoutCache {
    let config: YGConfigRef
    let root: YGNodeRef
    private(set) var measurements: [YogaSubviewMeasure] = []

    init() {
        guard let config = YGConfigNew() else {
            fatalError("Yoga could not allocate a layout configuration")
        }
        YGConfigSetUseWebDefaults(config, true)
        YGConfigSetErrata(config, .none)
        guard let root = YGNodeNewWithConfig(config) else {
            YGConfigFree(config)
            fatalError("Yoga could not allocate a root node")
        }
        self.config = config
        self.root = root
    }

    deinit {
        YGNodeFreeRecursive(root)
        YGConfigFree(config)
    }

    func reset() {
        while YGNodeGetChildCount(root) > 0 {
            guard let child = YGNodeGetChild(root, 0) else { break }
            YGNodeRemoveChild(root, child)
            YGNodeFree(child)
        }
        measurements.removeAll()
        YGNodeReset(root)
    }

    func retain(_ measurement: YogaSubviewMeasure) {
        measurements.append(measurement)
    }
}
