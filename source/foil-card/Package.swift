// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "FoilCard",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    products: [
        .library(name: "FoilCard", targets: ["FoilCard"]),
    ],
    targets: [
        .target(name: "FoilCard"),
        // A small Mac app to try the card: `swift run FoilCardDemo`.
        .executableTarget(
            name: "FoilCardDemo",
            dependencies: ["FoilCard"],
            resources: [.copy("Resources/card.webp")]
        ),
    ]
)
