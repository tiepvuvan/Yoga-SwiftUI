# Ownership and Caching

Reuse layout trees safely and invalidate only changed content.

## One owner for storage

A `YogaTree` owns all of its nodes. `YogaNodeID` is a checked identifier: it carries ownership and generation information so a removed node's identifier cannot refer to a newly created node. Identifiers do not keep the tree or its content alive. Use `tree.contains(id)` when an identifier may have been removed; other APIs reject stale identifiers and identifiers from another tree.

Reparent within a tree while preserving identifiers and descendants:

```swift
tree.append(child, to: newParent)
```

`tree.remove(child)` removes the entire subtree and invalidates its identifiers. The permanent root cannot be removed or reparented. `createNode` creates a detached node within the same store; attach it later or calculate it as a separate root. Measured nodes must remain leaves, and cycles are rejected.

`reserveCapacity` reserves node storage before a construction batch. After topology changes, layout preparation compacts unused capacity at the end of storage; unused interior slots are reused without changing live identifiers. Retaining an identifier for a removed node does not retain its callbacks or style.

Calculate layout on the permanent root or a detached node. Trees deeper than 1,023 nested layout visits are rejected to bound recursion. The practical depth limit may be lower on platforms with smaller stacks.

## Reference-based nodes

`YogaNode` provides individual reference identity, strong child ownership, and a weak parent. A retained child can outlive its parent. Remove a child before inserting it under another parent:

```swift
let moved = oldParent.removeChild(at: 0)
newParent.appendChild(moved)
```

For construction, prefer `parent.appendChild(style:)` to create nodes directly in shared storage. Constructing separate detached `YogaNode` objects and then attaching them transfers their storage and adds allocation work. `YogaTree` avoids these per-node objects and is the preferred API for performance-sensitive clients.

## Actor ownership and callbacks

`YogaStyle`, configuration, identifiers, lengths, and output geometry are `Sendable` values. `YogaTree` and `YogaNode` are mutable reference types and deliberately do not conform to `Sendable`. Keep each complete tree within one actor or thread. For parallel work, create a separate tree inside each worker and return geometry values.

A tree's configuration is immutable and shared by value across its nodes. Layout runs synchronously. Callbacks may inspect the tree, but must not mutate it, reserve storage, or reenter layout. These operations are rejected while layout borrows internal storage. The public API never exposes the internal pointers.

Avoid strong captures of the owning tree or node in a callback stored by that same owner. Such a capture creates a reference cycle. Capture the content needed for measurement, or use a weak owner reference when necessary.

## Invalidating changes

Style assignment compares values and marks changed nodes and ancestors dirty. `updateStyle` batches edits into one comparison and invalidation. Child changes, measurement changes, baseline changes, and containing-block changes also invalidate layout. Copying a style does not mutate the tree until it is assigned back.

External content changes require `tree.markDirty(id)` or `node.markDirty()`. Repeated layout with the same root proposal and direction returns existing rounded geometry. The reference API additionally exposes `hasNewLayout`, which callers can clear after consuming a result; an unchanged root cache hit leaves it cleared.

## Cache boundaries

Each node keeps one layout entry and up to four lazily allocated measurement entries. Entries retain no other trees. Percentage-dependent styles include owner dimensions in cache checks; styles without percentages can reuse results when their own constraints stay compatible. Measured leaves also use Yoga's compatible-size rules, including pixel-grid comparisons.

The cache size differs from the C++ implementation to reduce retained memory. Evicting measurements can increase callback work for some proposal sequences. Benchmark your actual view hierarchy and keep measurement callbacks inexpensive.
