// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SkylineLayout",
    platforms: [.macOS(.v10_14), .iOS(.v16), .tvOS(.v16), .visionOS(.v1), .macCatalyst(.v14),.watchOS(.v9)],
    products: [
      // Products define the executables and libraries a package produces, making them visible to other packages.
      .library(
        name: "SkylineLayout",
        targets: ["SkylineLayout"]),
    ], dependencies: [
      .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SkylineLayout"),
        .testTarget(
            name: "SkylineLayoutTests",
            dependencies: ["SkylineLayout"]
        ),
    ]
)
