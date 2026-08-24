// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "CareerPilot",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "CareerPilotCore", targets: ["CareerPilotCore"])
    ],
    targets: [
        .target(name: "CareerPilotCore"),
        .testTarget(
            name: "CareerPilotCoreTests",
            dependencies: ["CareerPilotCore"]
        )
    ]
)
