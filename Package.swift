// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MultiPartFormDataCoder",
    platforms: [.iOS(.v15), .macOS(.v13), .watchOS(.v9)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MultiPartFormDataCoder",
            targets: ["MultiPartFormDataCoder"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MultiPartFormDataCoder"),
        .testTarget(
            name: "MultiPartFormDataCoderTests",
            dependencies: ["MultiPartFormDataCoder"],
            resources: [.copy("Resources/test1.png"), .copy("Resources/test2.png")]
        )
    ]
)
