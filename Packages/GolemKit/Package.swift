// swift-tools-version: 6.0

// GolemKit is the code shared by the Golem app and its extensions:
// settings, the plea rules, the Golem's wording, and the Screen Time glue.
//
// The plain-Swift parts (settings, plea rules, wording) also build on macOS,
// so `swift test` runs in seconds without a simulator.

import PackageDescription

let package = Package(
    name: "GolemKit",
    platforms: [.iOS("17.4"), .macOS(.v14)],
    products: [
        .library(name: "GolemKit", targets: ["GolemKit"]),
    ],
    targets: [
        .target(name: "GolemKit"),
        .testTarget(name: "GolemKitTests", dependencies: ["GolemKit"]),
    ]
)
