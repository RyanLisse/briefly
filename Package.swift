// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "briefly",
    platforms: [
        .macOS(.v26),
    ],
    products: [
        .executable(name: "briefly", targets: ["Executable"]),
        .library(name: "BrieflyCore", targets: ["Core"]),
        .library(name: "BrieflyCLI", targets: ["CLI"]),
        .library(name: "BrieflyMCP", targets: ["BrieflyMCP"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk", from: "0.9.0"),
        .package(url: "https://github.com/apple/swift-log", from: "1.6.0"),
        .package(url: "https://github.com/steipete/ElevenLabsKit", from: "0.1.0"),
        .package(path: "Vendor/GabGab"),
    ],
    targets: [
        // Core library - framework-agnostic, no CLI dependencies
        .target(
            name: "Core",
            dependencies: [
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ElevenLabsKit", package: "ElevenLabsKit"),
                "GabGab",
            ],
            path: "Sources/Core",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            ]
        ),

        // CLI executable - uses ArgumentParser
        .executableTarget(
            name: "Executable",
            dependencies: ["CLI"],
            path: "Sources/Executable",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            ]
        ),

        // CLI library - commands using ArgumentParser
        .target(
            name: "CLI",
            dependencies: [
                "Core",
                "BrieflyMCP",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/CLI",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            ]
        ),

        // MCP library - server with handler pattern
        .target(
            name: "BrieflyMCP",
            dependencies: [
                "Core",
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "Sources/MCP",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency"),
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
            ]
        ),

        .testTarget(
            name: "BrieflyCoreTests",
            dependencies: ["Core"],
            path: "Tests/BrieflyCoreTests",
            exclude: ["AGENTS.md"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
