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
        // OpenClaw Swift SDK
        .package(url: "https://github.com/openclaw/openclaw-swift-sdk.git", from: "1.0.0"),
        // Keychain access for secure token storage
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", from: "4.2.2"),
    ],
    targets: [
        .target(
            name: "OpenClawLarry",
            dependencies: [
                .product(name: "OpenClawSDK", package: "openclaw-swift-sdk"),
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
