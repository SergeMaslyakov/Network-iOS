// swift-tools-version:5.2

import PackageDescription

let package = Package(
    name: "NetworkFramework",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(name: "NetworkFramework", targets: ["NetworkFramework"])
    ],
    targets: [
        .target(name: "NetworkFramework", path: "Sources")
    ]
)
