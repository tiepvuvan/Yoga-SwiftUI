struct LayoutChildren: RandomAccessCollection {
    let base: UnsafeMutablePointer<NodeState>
    let indices: [Int]
    var startIndex: Int { indices.startIndex }
    var endIndex: Int { indices.endIndex }
    @inline(__always) subscript(index: Int) -> LayoutNode {
        LayoutNode(base: base, index: indices[index])
    }
}
