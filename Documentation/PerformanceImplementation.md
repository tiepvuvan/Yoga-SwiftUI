# Performance implementation and verification

Implemented and measured September 29, 2026, on `codex/native-yoga-3`. The package remains an unreleased 3.0.0 development version. This record closes the initial architecture experiment and identifies the performance gates still open.

## Measured outcome

The [full report](../Benchmarks/Results.md) contains all 18 cases and raw samples. Both languages use shipping release optimization; C++ additionally enables full LTO. Each case has ten independent paired trials. Ratios below one favor Swift.

| Measure | Swift / C++ | 95% interval | Outcome on the declared suite |
| --- | ---: | ---: | --- |
| Resized layout cycles | 0.552 | 0.549–0.554 | 44.8% fewer cycles; about 1.83× throughput by elapsed time |
| Style mutation cycles | 0.789 | 0.787–0.792 | 21.1% fewer cycles |
| Unchanged cached cycles | 0.928 | 0.924–0.933 | 7.2% fewer cycles |
| Construction + layout + destruction cycles | 0.808 | 0.806–0.811 | 19.2% fewer cycles; narrowly short of the 20% target |
| Retained live heap | 0.683 | 0.683–0.683 | 31.7% less heap overall; every case below C++ |
| Warmed resize allocations | 0 | Direct event count | Zero allocations in 1,000 layouts for each of 18 cases |

Resized layout wins in every case, using 33–60% fewer cycles. Mutation and cached layout also win in every case. Construction ranges from 35% fewer to 2.6% more cycles: the smallest measured-content case is 0.9% slower and the smallest absolute-positioning case is 2.6% slower. Every individual primary cycle comparison remains within the plan's 5% regression ceiling. Constructing separate reference-based `YogaNode` objects and attaching them remains substantially more expensive; the full report publishes this convenience path separately.

SwiftUI renders identical pixels to v2 at widths 320 and 321 in every trial. Shape layouts use 4.1% less CPU time and 2.2% less retained hosting-view heap; text layouts use 5.9% less CPU time and about 0.8% less heap. The confidence intervals are in the report. These measurements include framework overhead and the final visibility correction.

The separate [iPhone 16 Pro run](../Benchmarks/iPhoneResults.md) completes the same 18-case matrix and ten paired trials. Construction uses 21.9% less CPU time, resized layout 47.2% less, mutation 26.4% less, and cached layout 23.9% less; retained engine heap is 31.9% lower. Every recorded trial stayed at fair thermal state with Low Power Mode off. Public iOS APIs do not expose hardware cycles, so these CPU-time results do not close the desktop construction-cycle gate.

The original [performance plan](PerformancePlan.md) asked for at least 20% fewer construction and resized-layout cycles independently, including the upper confidence bound. Resized layout exceeds that target and reaches the 1.5–2× throughput stretch range on this suite. Construction has improved from a regression to a clear overall win, but its upper bound of 0.811 still misses 0.800. The strict combined performance release gate remains open; it has not been silently relaxed. Zero warmed allocations, cached-layout parity, and 30% lower aggregate retained heap are achieved on this matrix. None of these results is a universal performance guarantee.

## Architecture shipped in the working tree

### Tree ownership and layout access

`YogaTree` owns one contiguous store of node records. `YogaNodeID` carries a tree identity, slot, and monotonically increasing generation. Public accesses validate ownership and lifetime. Identifiers survive storage growth and same-tree reparenting, but removal invalidates them and their descendants. The identity token prevents another tree from reusing an old identifier's ownership identity. Retaining an identifier does not retain the tree or content.

The layout kernel uses temporary indexed pointer views into that store. It does not traverse per-node objects or weak parent references. Storage is frozen throughout synchronous layout; mutations, growth, and layout reentry from callbacks are rejected. Public APIs expose values and checked identifiers, never pointers. Growth moves initialized values, removal releases owned fields, freed slots are reset before reuse, and unused trailing storage is reclaimed before the next layout borrow begins. Layout preparation bounds recursion before walking the tree.

`YogaNode` preserves individual reference identity, strong children, weak parents, detached child lifetime, and callbacks that receive the node. It uses the same kernel and record storage. `appendChild(style:)` constructs directly in shared storage; attaching independently constructed nodes transfers their records. The preferred core API and the SwiftUI adapter use `YogaTree` directly.

### Work removed from repeated layout

- Borrow individual style fields through `LayoutStyle`; avoid copying a full style with reference-counted edge storage at each helper call.
- Store seven length units in 14 bits while preserving seven full Float values. No quantization or change in percentage representation.
- Store four optional scalars as full Float values with shared presence bits; preserve nil, signed zero, infinities, and NaN without a sentinel encoding.
- Cache edge categories and percentage dependency flags when a style changes. Skip resolution for absent categories.
- Prepare flattened `display: contents` and in-flow child indices after structural, display, or positioning changes. Reuse the buffers across layout passes.
- Use slices into existing child-index storage for flex lines.
- Reuse up to four measurement entries per node, with in-place mutation instead of accidental copy-on-write churn.
- Check an unchanged root's cached proposal before entering the layout kernel.
- Remove an unused generation field and an allocating temporary axis array. The allocation hook identified that array as a 34-byte allocation per visited container per resize.

SwiftUI retains the tree, identifiers, and measurement contexts across proposals. It refreshes subview references and invalidates measurements through SwiftUI's cache lifecycle; the existing view modifiers remain unchanged.

Hidden items and containers now suppress drawing, hit testing, and accessibility while preserving their SwiftUI view type. Explicit zero-size placement prevents fallback placement from rendering a skipped child. Three pixel regressions cover hidden children, hidden containers, and hide/show transitions; they reproduce failures in the previous implementation and pass on Mac and iPhone after the fix.

### Construction and rounding follow-up

Fresh `YogaTree` storage starts with room for 16 records and doubles as needed. This is the public default, not a benchmark-only hint. Consuming initialization moves node records into storage; direct child construction avoids a temporary public identifier. Invalidation is skipped before the tree's first layout, while every record is already dirty and has no cached results. After the first layout, all style and content changes follow normal invalidation.

Topology preparation visits the known root directly until detached nodes are created. It handles leaves without recursive calls, while retaining the depth guard and the complete scan for independent roots. Sparse style edges are inserted into sorted storage in one pass. Empty measurement-cache clearing is skipped. None of these paths selects a particular benchmark shape or changes layout behavior.

Pixel rounding replaces floating remainder by subtraction of the integral part, explicitly preserving signed zero. It computes fractional dimensions only for measured leaves. A 140,000-result differential verifies the public Float result bit for bit against C++, including extreme values and all rounding flags; NaNs are compared by classification.

### Experiments and numerical fidelity

The first arena prototype still forwarded entire styles and did not solve the primary copying cost. Field-level borrowing produced the major retained-layout improvement. An alternative that kept class nodes while borrowing styles was slower than the arena on measured flat/deep relayouts and was rejected.

Optional array storage was also tested for empty child lists, traversal buffers, measurement caches, and style edges. It made mutation substantially slower because mutation through computed storage added copy-on-write work. That experiment was reverted; the final engine keeps ordinary stored arrays.

An isolated follow-up made the public tree style parameters consuming. Its three-trial construction mean moved from roughly 0.808 to 0.801, less than a 1% improvement, and still did not establish the target. It was not adopted. The verified production revision remains unchanged by that experiment.

Disassembly also showed register saves before the construction invalidation guard. Moving that guard into a tiny inlined wrapper produced a three-trial construction ratio of 0.807, essentially unchanged. That variant was not adopted either.

Explicit compiler cross-module optimization produced exploratory ratios of 0.802 for construction, 0.548 for resizing, 0.791 for mutation, and 0.966 for cached calls. It did not establish the construction target and worsened cached calls. The release configuration therefore retains ordinary SwiftPM optimization; this experiment is excluded from the final report.

Full geometry traces exposed Float32 differences from C++ fused multiply-add operations, including overflow flags. Flex distribution now uses explicit `Float.addingProduct` where needed. The default direction of a reset layout matches the reference's inherited direction. The harness compares original binary32 values exactly; it does not hide differences with a broad epsilon.

The library keeps ordinary Swift preconditions and exclusivity checks. It does not use relaxed floating-point compilation, unchecked optimization, pointer tagging, or per-node atomics. Node ownership remains confined to one actor or thread. Standard-library storage types with newer OS availability would raise the deployment floor, so allocation is encapsulated in the small internal arena owner instead.

## Verification performed

Final production Swift source digest, used by the SwiftUI benchmark and Mac/iPhone correctness records:

`fdc9f00884bddb991c797da615d43b15ad9489cdbfe71eed33273beea4139f22`

The native `Yoga` source digest is `0698f0133a28c84591a0d16fe6eb0f1596c8e01b0cff04591513a445a11e808e`. Desktop/device core benchmarks and Linux core tests match this digest. They ran before the SwiftUI-only visibility correction and retain their original complete-source snapshot in the raw reports. The evidence validator checks the measured product's source scope instead of relabeling earlier measurements as a new run.

| Check | Result |
| --- | --- |
| macOS release XCTest suite | 38 tests pass: 26 core and 12 SwiftUI/API |
| Upstream corpus through `YogaNode` | All 531 enabled fixtures; 15,856 geometry assertions |
| Upstream corpus through `YogaTree` | All 531 enabled fixtures; 15,856 geometry assertions |
| macOS Address Sanitizer debug suite | Same 38 tests pass; no sanitizer errors |
| Physical iPhone 16 Pro, iOS 27.0 | All 38 tests pass in release and a separate Address Sanitizer debug build, including SwiftUI rendering |
| Linux aarch64, Swift 6.4.0 / Ubuntu 24.04 | All 26 core tests pass in a pinned official container with the checkout read-only and networking disabled |
| Storage regressions | Growth, slot reuse, stale IDs, wrong owners, callback release, reparenting, repeated grow/shrink, style units, and contents/absolute transitions |
| C++ differential matrix | 18 cases; full geometry at two widths plus 128 mutation steps each |
| C++ pixel rounding | 140,000 exact results per platform, with NaNs compared by classification |
| SwiftUI versus v2 | Identical rendered pixels at two widths for shapes and text, in all ten trial pairs |
| iOS / tvOS / watchOS / visionOS | Generic simulator builds pass |
| macOS documentation | Both DocC catalogs compile with warnings treated as errors; arm64 and x86_64 source builds |
| Package boundaries | Production manifest exposes native Swift targets without external dependencies or C++ interoperability |

The 17 upstream-disabled fixtures remain identified. Generated fixture coverage does not imply that all upstream APIs, legacy errata, or experimental switches are exposed.

Reproduce the commands in the [release checklist](ReleaseChecklist.md) and [benchmark guide](../Benchmarks/README.md). Allocation checks use a runtime-probed macOS diagnostic hook in the development metrics executable only. Instrumentation is disabled during timing. Raw reports retain all measurements and process order; pre-optimization reports are preserved separately.

## Remaining work before performance claims expand

1. **Construction target:** the aggregate win is 19.2%, below the strict 20% criterion. Small measured and absolute-positioning trees retain minor regressions. Further work must earn its place through independent measurements and retain checked ownership; a near miss is not a pass.
2. **Broader workloads:** add held-out application trees, larger stress cases, dense edge styles, structural edits, and dynamic nested SwiftUI content. The current differential traces vary styles and constraints; lifecycle changes are covered by native tests rather than C++ differential sequences.
3. **Additional metrics:** request latency distributions, peak memory, allocation churn during structural edits, and reliable cache/branch counters remain unmeasured. Batch means cannot establish p95 or p99 latency.
4. **Broader deployment coverage:** physical iPhone correctness and Linux aarch64 correctness are verified. Other iPhone generations, physical watches, Linux x86_64, and Linux performance remain outside this run. Simulator builds establish compilation, not device performance.
5. **Release:** review the new public API and unsafe-storage implementation, resolve the construction gate or explicitly revise the performance release criterion, then follow the publishing checklist. No tag or hosted documentation publication is implied by these local checks.
