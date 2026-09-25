// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Yoga-SwiftUI",
    platforms: [.iOS(.v16), .macOS(.v13), .tvOS(.v16), .watchOS(.v9), .visionOS(.v1)],
    products: [
        .library(
            name: "YogaSwiftUI",
            targets: ["YogaSwiftUI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/react/yoga.git", exact: "3.2.1")
    ],
    targets: [
        .target(
            name: "YogaSwiftUI",
            dependencies: ["YogaBridge"],
            swiftSettings: [.interoperabilityMode(.Cxx)]),
        // Yoga's SwiftPM target exposes its repository root as public headers.
        // This narrow target imports only the supported public Yoga API.
        .target(
            name: "YogaBridge",
            dependencies: [.product(name: "yoga", package: "yoga")]),
        .testTarget(
            name: "YogaSwiftUITests",
            dependencies: ["YogaSwiftUI", "YogaBridge"],
            swiftSettings: [.interoperabilityMode(.Cxx)])
    ],
    swiftLanguageModes: [.v6],
    cxxLanguageStandard: .cxx20
)
