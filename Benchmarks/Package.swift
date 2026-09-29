// swift-tools-version: 6.4
import PackageDescription

// This development-only package is outside the libraries' dependency graph.
var products: [Product] = [.executable(name: "yoga-bench", targets: ["YogaBenchmarks"])]
var targets: [Target] = [
    .target(name: "BenchmarkMetrics"),
    .executableTarget(name: "YogaBenchmarks", dependencies: [
        .product(name: "Yoga", package: "Yoga-SwiftUI"), "BenchmarkMetrics"
    ])
]
#if os(macOS)
products.append(.executable(name: "swiftui-bench", targets: ["SwiftUIBenchmarks"]))
targets.append(.executableTarget(name: "SwiftUIBenchmarks", dependencies: [
    .product(name: "YogaSwiftUI", package: "Yoga-SwiftUI"), "BenchmarkMetrics"
]))
#endif
let package = Package(
    name: "YogaBenchmarks",
    platforms: [.macOS(.v13)],
    products: products,
    dependencies: [.package(name: "Yoga-SwiftUI", path: "..")],
    targets: targets,
    swiftLanguageModes: [.v6]
)
