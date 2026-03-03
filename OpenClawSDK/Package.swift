// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "OpenClawSDK",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "OpenClawSDK",
            targets: ["OpenClawSDK"]
        )
    ],
    targets: [
        .target(
            name: "OpenClawSDK",
            path: "Sources/OpenClawSDK"
        ),
        .testTarget(
            name: "OpenClawSDKTests",
            dependencies: ["OpenClawSDK"],
            path: "Tests/OpenClawSDKTests"
        ),
    ]
)
