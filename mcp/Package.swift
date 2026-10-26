// swift-tools-version: 6.0
import PackageDescription

// The same sources ship inside ButterKit.app as Contents/MacOS/butterkit-mcp.
// This manifest exists so you can read, build and audit them on their own.
let package = Package(
    name: "butterkit-mcp",
    platforms: [
        .macOS("26.0"),
    ],
    dependencies: [
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk", exact: "0.12.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "butterkit-mcp",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "Sources/butterkit-mcp",
            swiftSettings: [
                // Matches the Xcode target: Swift 5 language mode with Approachable Concurrency.
                .swiftLanguageMode(.v5),
                .enableUpcomingFeature("DisableOutwardActorInference"),
                .enableUpcomingFeature("GlobalActorIsolatedTypesUsability"),
                .enableUpcomingFeature("InferIsolatedConformances"),
                .enableUpcomingFeature("InferSendableFromCaptures"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            ]
        ),
    ]
)
