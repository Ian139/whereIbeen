// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "WhereIBeen",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "WhereIBeen",
            targets: ["WhereIBeen", "Models"]),
    ],
    dependencies: [
        // Add any other dependencies here if needed
    ],
    targets: [
        .target(
            name: "WhereIBeen",
            dependencies: [
                "Models"
            ]),
        .target(
            name: "Models",
            dependencies: []),
        .testTarget(
            name: "WhereIBeenTests",
            dependencies: ["WhereIBeen"]),
    ]
) 