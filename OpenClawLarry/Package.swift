// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OpenClawLarry",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "OpenClawLarry",
            targets: ["OpenClawLarry"]
        )
    ],
    dependencies: [
        // Our OpenClaw Swift SDK (local package)
        .package(path: "../OpenClawSDK"),
        // Keychain access for secure token storage
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    ],
    targets: [
        .target(
            name: "OpenClawLarry",
            dependencies: [
                "OpenClawSDK",
                "KeychainAccess",
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "OpenClawLarryTests",
            dependencies: ["OpenClawLarry"],
            path: "Tests"
        ),
    ]
)
