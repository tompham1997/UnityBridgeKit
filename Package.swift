// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UnityBridgeKit",
    platforms: [
        .iOS(.v15),
        .visionOS(.v2),
        .macOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "UnityBridgeKit",
            targets: ["UnityBridgeKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/hmlongco/Factory.git", exact: "2.5.2"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "UnityBridgeKit",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .testTarget(
            name: "UnityBridgeKitTests",
            dependencies: ["UnityBridgeKit"]
        ),
    ],
    swiftLanguageModes: [
        .v6
    ]
)
