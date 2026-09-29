// Development-only reference executable. Never linked into either Swift library.
#include <yoga/Yoga.h>
#include "Sources/BenchmarkMetrics/include/BenchmarkMetrics.h"
#include <algorithm>
#include <bit>
#include <limits>
#include <cmath>
#include <cstdlib>
#include <functional>
#include <iomanip>
#include <iostream>
#include <string>
#include <vector>

static std::string workload;
static YGConfigRef config;
static int childCount = 128;

static YGSize measure(YGNodeConstRef node, float width, YGMeasureMode wm, float height, YGMeasureMode hm) {
  float intrinsic = float(80 + (reinterpret_cast<uintptr_t>(YGNodeGetContext(node)) - 1) % 11);
  float w = wm == YGMeasureModeExactly ? width : (wm == YGMeasureModeAtMost ? std::min(width, intrinsic) : intrinsic);
  float h = 20 * std::ceil(intrinsic / std::max(1.0f, w));
  return {w, hm == YGMeasureModeExactly ? height : (hm == YGMeasureModeAtMost ? std::min(height, h) : h)};
}

static YGNodeRef makeTree() {
  auto root = YGNodeNewWithConfig(config);
  YGNodeStyleSetAlignItems(root, YGAlignFlexStart);
  YGNodeStyleSetAlignContent(root, YGAlignFlexStart);
  if (workload == "deep") {
    std::function<void(YGNodeRef, int)> append = [&](YGNodeRef parent, int depth) {
      if (depth == 0) { YGNodeStyleSetHeight(parent, 10); return; }
      for (int i = 0; i < 3; ++i) {
        auto child = YGNodeNewWithConfig(config);
        YGNodeStyleSetFlexDirection(child, depth % 2 == 0 ? YGFlexDirectionColumn : YGFlexDirectionRow);
        YGNodeStyleSetFlexGrow(child, 1);
        YGNodeInsertChild(parent, child, i);
        append(child, depth - 1);
      }
    };
    append(root, childCount <= 8 ? 2 : childCount <= 32 ? 3 : 5);
    return root;
  }
  if (workload != "flat" && workload != "absolute") YGNodeStyleSetFlexWrap(root, YGWrapWrap);
  if (workload == "wrap") {
    YGNodeStyleSetGap(root, YGGutterColumn, 3);
    YGNodeStyleSetGap(root, YGGutterRow, 5);
  }
  for (int index = 0; index < childCount; ++index) {
    auto child = YGNodeNewWithConfig(config);
    YGNodeStyleSetWidth(child, 12 + index % 7);
    YGNodeStyleSetHeight(child, 10 + index % 5);
    if (workload == "wrap") {
      if (index % 7 == 0) YGNodeStyleSetWidthPercent(child, 25);
      else YGNodeStyleSetWidth(child, 22 + index % 5 * 10);
      YGNodeStyleSetMinWidth(child, 16);
      YGNodeStyleSetMaxWidth(child, 100);
    } else if (workload == "measured") {
      YGNodeStyleSetWidthAuto(child);
      YGNodeStyleSetHeightAuto(child);
      YGNodeSetContext(child, reinterpret_cast<void *>(uintptr_t(index + 1)));
      YGNodeSetMeasureFunc(child, measure);
    } else if (workload == "absolute" && index % 4 == 0) {
      YGNodeStyleSetPositionType(child, YGPositionTypeAbsolute);
      YGNodeStyleSetWidthPercent(child, 15);
      YGNodeStyleSetPositionPercent(child, YGEdgeLeft, index % 80);
      YGNodeStyleSetPosition(child, YGEdgeTop, index);
    } else if (workload == "contents" && index % 8 == 0) {
      YGNodeStyleSetDisplay(child, YGDisplayContents);
      for (int j = 0; j < 2; ++j) {
        auto grandchild = YGNodeNewWithConfig(config);
        YGNodeStyleSetWidth(grandchild, 25);
        YGNodeStyleSetHeight(grandchild, 12);
        YGNodeInsertChild(child, grandchild, j);
      }
    }
    YGNodeInsertChild(root, child, index);
  }
  return root;
}

static void values(YGNodeRef node, std::vector<std::vector<float>>& output) {
  output.push_back({YGNodeLayoutGetLeft(node), YGNodeLayoutGetTop(node), YGNodeLayoutGetWidth(node), YGNodeLayoutGetHeight(node),
    YGNodeLayoutGetRight(node), YGNodeLayoutGetBottom(node),
    YGNodeLayoutGetMargin(node, YGEdgeLeft), YGNodeLayoutGetMargin(node, YGEdgeTop), YGNodeLayoutGetMargin(node, YGEdgeRight), YGNodeLayoutGetMargin(node, YGEdgeBottom),
    YGNodeLayoutGetPadding(node, YGEdgeLeft), YGNodeLayoutGetPadding(node, YGEdgeTop), YGNodeLayoutGetPadding(node, YGEdgeRight), YGNodeLayoutGetPadding(node, YGEdgeBottom),
    YGNodeLayoutGetBorder(node, YGEdgeLeft), YGNodeLayoutGetBorder(node, YGEdgeTop), YGNodeLayoutGetBorder(node, YGEdgeRight), YGNodeLayoutGetBorder(node, YGEdgeBottom),
    float(YGNodeLayoutGetDirection(node)), YGNodeLayoutGetHadOverflow(node) ? 1.0f : 0.0f});
  for (size_t i = 0; i < YGNodeGetChildCount(node); ++i) values(YGNodeGetChild(node, i), output);
}

static void mutate(YGNodeRef root, int step) {
  auto child = YGNodeGetChild(root, step % YGNodeGetChildCount(root));
  switch (step % 6) {
    case 0: YGNodeStyleSetWidthPercent(child, 5 + (step * 7) % 45); break;
    case 1: YGNodeStyleSetMargin(child, YGEdgeStart, step % 4); break;
    case 2: YGNodeStyleSetMinWidth(child, step % 23); break;
    case 3: YGNodeStyleSetPositionType(child, step % 9 == 0 ? YGPositionTypeAbsolute : YGPositionTypeRelative); break;
    case 4: YGNodeStyleSetDisplay(child, step % 12 == 4 ? YGDisplayNone : YGDisplayFlex); break;
    default: YGNodeStyleSetGap(root, YGGutterRow, step % 7); break;
  }
}

static void printValues(const std::vector<std::vector<float>>& rows) {
  std::cout << '[';
  for (size_t i = 0; i < rows.size(); ++i) {
    if (i) std::cout << ',';
    std::cout << '[';
    for (size_t j = 0; j < rows[i].size(); ++j) {
      if (j) std::cout << ',';
      std::cout << rows[i][j];
    }
    std::cout << ']';
  }
  std::cout << ']';
}

int main(int argc, char** argv) {
  workload = argc > 1 ? argv[1] : "flat";
  std::string mode = argc > 2 ? argv[2] : "relayout";
  int iterations = argc > 3 ? std::stoi(argv[3]) : 1000;
  childCount = argc > 4 ? std::stoi(argv[4]) : 128;
  int sampleCount = argc > 5 ? std::stoi(argv[5]) : 7;
  if (iterations <= 0 || childCount <= 0 || sampleCount <= 0) return 2;
  config = YGConfigNew();
  YGConfigSetUseWebDefaults(config, true);
  auto initial = makeTree();
  YGNodeCalculateLayout(initial, mode == "dump" && argc > 3 ? std::stof(argv[3]) : 320, 640, YGDirectionLTR);
  std::vector<std::vector<float>> layoutValues;
  values(initial, layoutValues);
  auto lastChild = YGNodeGetChild(initial, YGNodeGetChildCount(initial) - 1);
  float checksum = 0;
  for (const auto& row : layoutValues) for (float value : row) checksum += value;
  std::cout << std::setprecision(12);
  if (mode == "rounding") {
    uint64_t state = 0x1a26c5b37;
    const double special[] = {-0.0, 0, -0.5, 0.5, 0.499999, 0.500001, -0.99999, 0.99999,
      std::numeric_limits<double>::infinity(), -std::numeric_limits<double>::infinity(), std::numeric_limits<double>::quiet_NaN()};
    bool first = true;
    std::cout << '[';
    for (int index = 0; index < iterations; ++index) {
      state = state * UINT64_C(6364136223846793005) + UINT64_C(1442695040888963407);
      double value = index < 11 ? special[index] : std::bit_cast<double>(state);
      for (double scale : {0.5, 1.0, 1.5, 2.0, 3.0, 0.001, 10000.0}) {
        for (int flags = 0; flags < 4; ++flags) {
          float rounded = YGRoundValueToPixelGrid(value, scale, flags & 1, flags & 2);
          if (!first) std::cout << ',';
          first = false;
          if (std::isnan(rounded)) std::cout << "null";
          else std::cout << std::bit_cast<uint32_t>(rounded);
        }
      }
    }
    std::cout << "]\n";
  } else if (mode == "dump") {
    printValues(layoutValues);
    std::cout << '\n';
  } else if (mode == "trace") {
    std::cout << '[';
    for (int step = 0; step < iterations; ++step) {
      mutate(initial, step);
      YGNodeCalculateLayout(initial, 320 + step % 3, 640, step % 2 == 0 ? YGDirectionLTR : YGDirectionRTL);
      std::vector<std::vector<float>> snapshot;
      values(initial, snapshot);
      if (step) std::cout << ',';
      printValues(snapshot);
    }
    std::cout << "]\n";
  } else if (mode == "memory") {
    std::vector<YGNodeRef> trees;
    trees.reserve(iterations);
    auto before = yoga_benchmark_metrics();
    for (int i = 0; i < iterations; ++i) trees.push_back(makeTree());
    auto constructed = yoga_benchmark_metrics();
    for (auto tree : trees) YGNodeCalculateLayout(tree, 320, 640, YGDirectionLTR);
    auto laidOut = yoga_benchmark_metrics();
    std::cout << "{\"engine\":\"cpp\",\"workload\":\"" << workload << "\",\"mode\":\"memory\",\"trees\":" << iterations
              << ",\"nodes_per_tree\":" << layoutValues.size() << ",\"checksum\":" << checksum
              << ",\"constructed_heap_bytes_per_tree\":" << double(constructed.heap_bytes - before.heap_bytes) / iterations
              << ",\"laid_out_heap_bytes_per_tree\":" << double(laidOut.heap_bytes - before.heap_bytes) / iterations << "}\n";
    for (auto tree : trees) YGNodeFreeRecursive(tree);
  } else {
    auto work = [&](int index) {
      bool rebuild = mode == "rebuild" || mode == "rebuild-detached";
      auto root = rebuild ? makeTree() : initial;
      if (mode == "mutation") mutate(root, index);
      float width = (mode != "relayout" && mode != "mutation" && mode != "allocations") || index % 2 == 0 ? 320 : 321;
      YGNodeCalculateLayout(root, width, 640, YGDirectionLTR);
      float value = YGNodeLayoutGetLeft(rebuild ? YGNodeGetChild(root, YGNodeGetChildCount(root) - 1) : lastChild);
      if (rebuild) YGNodeFreeRecursive(root);
      return value;
    };
    float sink = 0;
    for (int i = 0; i < 100; ++i) sink += work(i);
    if (mode == "allocations") {
      bool available = yoga_benchmark_allocations_begin();
      for (int i = 0; i < iterations; ++i) sink += work(i);
      auto counts = yoga_benchmark_allocations_end();
      std::cout << "{\"engine\":\"cpp\",\"workload\":\"" << workload << "\",\"mode\":\"allocations\",\"iterations\":" << iterations
                << ",\"available\":" << (available && counts.available ? "true" : "false")
                << ",\"allocations\":" << counts.allocations << ",\"allocated_bytes\":" << counts.allocated_bytes << ",\"sink\":" << sink << "}\n";
      YGNodeFreeRecursive(initial);
      YGConfigFree(config);
      return 0;
    }
    std::vector<std::vector<double>> samples;
    for (int sample = 0; sample < sampleCount; ++sample) {
      auto before = yoga_benchmark_metrics();
      for (int i = 0; i < iterations; ++i) sink += work(i);
      auto after = yoga_benchmark_metrics();
      samples.push_back({double(after.wall_ns - before.wall_ns) / iterations,
                         double(after.cpu_ns - before.cpu_ns) / iterations,
                         double(after.cycles - before.cycles) / iterations,
                         double(after.instructions - before.instructions) / iterations});
    }
    std::cout << "{\"engine\":\"cpp\",\"workload\":\"" << workload << "\",\"mode\":\"" << mode << "\",\"iterations\":" << iterations
              << ",\"nodes_per_tree\":" << layoutValues.size() << ",\"requested_children\":" << childCount
              << ",\"checksum\":" << checksum << ",\"sink\":" << sink
              << ",\"hardware_counters_available\":" << (yoga_benchmark_metrics().hardware_counters_available ? "true" : "false") << ",\"samples\":[";
    for (size_t i = 0; i < samples.size(); ++i) {
      if (i) std::cout << ',';
      auto& s = samples[i];
      std::cout << "{\"wall_ns\":" << s[0] << ",\"cpu_ns\":" << s[1] << ",\"cycles\":" << s[2] << ",\"instructions\":" << s[3] << '}';
    }
    std::cout << "]}\n";
  }
  YGNodeFreeRecursive(initial);
  YGConfigFree(config);
  return 0;
}
