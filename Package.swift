// swift-tools-version: 6.4
import PackageDescription

var products: [Product] = [.library(name: "Yoga", targets: ["Yoga"])]
var targets: [Target] = [
    .target(name: "Yoga"),
    .testTarget(name: "YogaTests", dependencies: ["Yoga"], resources: [.process("Fixtures")])
]

// SwiftUI is available when building Apple-platform clients on macOS.
// Other hosts can build and test the standalone, standard-library-only core.
#if os(macOS)
products.append(.library(name: "YogaSwiftUI", targets: ["YogaSwiftUI"]))
targets += [
    .target(name: "YogaSwiftUI", dependencies: ["Yoga"]),
    .testTarget(name: "YogaSwiftUITests", dependencies: ["YogaSwiftUI", "Yoga"])
]
#endif

let package = Package(
    name: "Yoga-SwiftUI",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .visionOS(.v1)],
    products: products,
    targets: targets,
    swiftLanguageModes: [.v6]
)
