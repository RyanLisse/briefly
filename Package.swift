// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "briefly",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .executable(name: "briefly", targets: ["brieflyExec"]),
        .library(name: "brieflyCLI", targets: ["brieflyCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk", from: "0.9.0"),
        .package(url: "https://github.com/apple/swift-log", from: "1.6.0"),
        .package(url: "https://github.com/steipete/ElevenLabsKit", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "brieflyCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ElevenLabsKit", package: "ElevenLabsKit"),
            ],
            path: "Sources/brieflyCLI",
            exclude: ["AGENTS.md", "MCP/AGENTS.md", "Commands/AGENTS.md", "Services/AGENTS.md"]
        ),
        .executableTarget(
            name: "brieflyExec",
            dependencies: ["brieflyCLI"],
            path: "Sources/brieflyExec"
        ),
        .testTarget(
            name: "brieflyTests",
            dependencies: ["brieflyCLI"],
            path: "Tests/brieflyTests",
            exclude: ["AGENTS.md"]
        ),
    ],
    swiftLanguageModes: [.v6]
)