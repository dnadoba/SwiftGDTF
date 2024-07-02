// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftGDTF",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftGDTF",
            targets: ["SwiftGDTF"]),
    ],
    dependencies: [
        .package(url: "https://github.com/drmohundro/SWXMLHash.git", from: "7.0.0"),
        .package(url: "https://github.com/weichsel/ZIPFoundation", .upToNextMajor(from: "0.9.19")),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftGDTF",
            dependencies: [
                .product(name: "SWXMLHash", package: "SWXMLHash"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation")
            ]),
        .testTarget(
            name: "SwiftGDTFTests",
            dependencies: ["SwiftGDTF"]),
    ]
)
