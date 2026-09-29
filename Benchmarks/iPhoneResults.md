# Physical iPhone performance

Measured on **iPhone 16 Pro**, iOS **27.0**, at 2026-09-29T09:31:09.606936+00:00.

Native core digest: `0698f0133a28c84591a0d16fe6eb0f1596c8e01b0cff04591513a445a11e808e`. Full source snapshot when measured: `526e4ad346a7b18a12a7fb2c7a8a32c0ef0738dbe6be88d931d3be1c4aed9d56`. Reference: Yoga 3.2.1, `042f5013152eb81c1552dec945b88f7b95ca350f`.

Ratios are Swift/C++; below 1 is better. Brackets are 95% paired bootstrap intervals. Every case has equal weight in the suite means. The raw [device report](results/iphone.json) preserves every trial and its thermal/power state.

Each engine/trial uses a fresh application process. Engine order is randomized within 10 pairs. Timed modes run in fixed order inside that process, each with 100 warm-ups and equal iteration counts calibrated to at least 20 ms for the faster engine. Retained-heap measurement follows separately. C++ uses -O3, NDEBUG, and full LTO; Swift uses release -O and whole-module optimization.

**Hardware CPU cycles and instruction counts are unavailable through the public iOS SDK. These tables report measured CPU time and wall time; neither is presented as a cycle count.** Live heap is an allocator delta for 128 retained trees, not peak memory or process RSS.

## Suite summary

| Mode | CPU time ratio | Wall time ratio |
| --- | ---: | ---: |
| rebuild | 0.781 [0.776, 0.786] | 0.781 [0.775, 0.786] |
| relayout | 0.528 [0.526, 0.531] | 0.527 [0.525, 0.530] |
| mutation | 0.736 [0.732, 0.739] | 0.737 [0.733, 0.740] |
| cached | 0.761 [0.757, 0.766] | 0.763 [0.759, 0.768] |

Retained live heap ratio: **0.681 [0.680, 0.682]**.

## Every case

| Workload / size | Nodes | Rebuild CPU | Resized CPU | Mutation CPU | Cached CPU | Heap |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| flat / 8 | 9 | 0.798 [0.773, 0.824] | 0.563 [0.547, 0.582] | 0.833 [0.820, 0.848] | 0.762 [0.749, 0.775] | 0.659 [0.655, 0.665] |
| flat / 32 | 33 | 0.721 [0.705, 0.743] | 0.495 [0.482, 0.512] | 0.815 [0.795, 0.837] | 0.766 [0.741, 0.793] | 0.597 [0.597, 0.597] |
| flat / 128 | 129 | 0.700 [0.690, 0.710] | 0.483 [0.477, 0.490] | 0.713 [0.699, 0.725] | 0.797 [0.783, 0.811] | 0.605 [0.605, 0.605] |
| wrap / 8 | 9 | 0.771 [0.741, 0.806] | 0.558 [0.544, 0.574] | 0.844 [0.831, 0.859] | 0.761 [0.746, 0.774] | 0.664 [0.657, 0.671] |
| wrap / 32 | 33 | 0.691 [0.673, 0.706] | 0.507 [0.501, 0.514] | 0.739 [0.729, 0.752] | 0.782 [0.766, 0.797] | 0.599 [0.598, 0.600] |
| wrap / 128 | 129 | 0.644 [0.637, 0.651] | 0.449 [0.443, 0.455] | 0.659 [0.653, 0.667] | 0.810 [0.791, 0.831] | 0.606 [0.605, 0.606] |
| deep / 8 | 13 | 0.886 [0.846, 0.932] | 0.615 [0.601, 0.630] | 0.703 [0.691, 0.716] | 0.751 [0.730, 0.778] | 0.774 [0.768, 0.779] |
| deep / 32 | 40 | 0.837 [0.815, 0.857] | 0.618 [0.608, 0.629] | 0.644 [0.632, 0.655] | 0.773 [0.755, 0.790] | 0.820 [0.818, 0.821] |
| deep / 128 | 364 | 0.736 [0.721, 0.753] | 0.625 [0.603, 0.649] | 0.641 [0.626, 0.658] | 0.751 [0.730, 0.774] | 0.831 [0.831, 0.831] |
| measured / 8 | 9 | 0.934 [0.908, 0.964] | 0.595 [0.581, 0.611] | 0.866 [0.858, 0.877] | 0.748 [0.728, 0.768] | 0.770 [0.759, 0.781] |
| measured / 32 | 33 | 0.866 [0.848, 0.883] | 0.574 [0.565, 0.584] | 0.800 [0.782, 0.819] | 0.756 [0.744, 0.771] | 0.741 [0.740, 0.741] |
| measured / 128 | 129 | 0.778 [0.761, 0.794] | 0.477 [0.471, 0.484] | 0.650 [0.639, 0.662] | 0.765 [0.751, 0.780] | 0.752 [0.752, 0.752] |
| absolute / 8 | 9 | 0.967 [0.940, 0.996] | 0.640 [0.627, 0.654] | 0.820 [0.805, 0.834] | 0.739 [0.722, 0.756] | 0.688 [0.683, 0.693] |
| absolute / 32 | 33 | 0.857 [0.842, 0.871] | 0.555 [0.548, 0.561] | 0.795 [0.785, 0.805] | 0.737 [0.715, 0.760] | 0.630 [0.630, 0.630] |
| absolute / 128 | 129 | 0.817 [0.804, 0.833] | 0.543 [0.535, 0.552] | 0.710 [0.695, 0.726] | 0.762 [0.746, 0.778] | 0.639 [0.639, 0.639] |
| contents / 8 | 11 | 0.792 [0.772, 0.815] | 0.475 [0.462, 0.490] | 0.771 [0.757, 0.787] | 0.736 [0.714, 0.760] | 0.636 [0.633, 0.639] |
| contents / 32 | 41 | 0.693 [0.668, 0.710] | 0.432 [0.426, 0.439] | 0.709 [0.693, 0.726] | 0.748 [0.726, 0.771] | 0.653 [0.653, 0.653] |
| contents / 128 | 161 | 0.660 [0.646, 0.673] | 0.394 [0.387, 0.401] | 0.602 [0.588, 0.615] | 0.766 [0.751, 0.781] | 0.662 [0.662, 0.662] |

## Correctness and conditions

- All 18 cases match full C++ geometry at widths 320 and 321 and throughout 128 mutation steps each.
- 140,000 pixel-rounding results match C++ bit for bit; NaNs are compared by classification.
- The complete core and SwiftUI XCTest suite runs in the same development host; see [device correctness](results/iphone-tests.json).
- Recorded thermal states: [1] (0 = nominal, 1 = fair). The runner fails the run if serious/critical state or Low Power Mode is observed.
- A fixed 5-second pause precedes each pair, followed by a wait for thermal state at or below 1 (0 = nominal, 1 = fair). These waits are excluded from timings and recorded in the raw report. Every measured trial is retained.
- The phone is connected by USB. Display, OS background work, and CPU frequency are not controlled; confidence intervals describe the fixed suite on this device.
- The development app links both engines so launch environment and framework overhead are shared. Construction, layout, and destruction are timed inside the app; app launch, JSON, and device transport are excluded.
- This validates the native core on physical hardware. The pinned-v2 end-to-end SwiftUI performance comparison remains the macOS hosting-view experiment; iPhone SwiftUI correctness is checked separately.

Reproduce with `python3 Scripts/benchmark-device.py --device DEVICE_ID --team TEAM_ID --minimum-sample-ms 20 --minimum-iterations 100 --cooldown-seconds 5 --maximum-start-thermal-state 1`, then `python3 Scripts/benchmark-device-report.py`. See the [methodology](README.md) for installation, signing, and test commands.
