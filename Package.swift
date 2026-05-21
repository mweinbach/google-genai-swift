// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "GoogleGenAI",
    platforms: [
        .macOS(.v15),
        .iOS(.v18),
        .tvOS(.v18),
        .watchOS(.v11),
        .visionOS(.v2)
    ],
    products: [
        .library(
            name: "GoogleGenAI",
            targets: ["GoogleGenAI"]
        ),
        // Foundation Models–shaped adapter. Available on macOS 26+, iOS 26+,
        // iPadOS 26+, visionOS 26+ — wherever Apple's `FoundationModels`
        // framework is available.
        .library(
            name: "GoogleGenAIFoundationModels",
            targets: ["GoogleGenAIFoundationModels"]
        ),
        .executable(
            name: "SmokeTest",
            targets: ["SmokeTest"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "GoogleGenAI",
            dependencies: [],
            path: "Sources/GoogleGenAI"
        ),
        .target(
            name: "GoogleGenAIFoundationModels",
            dependencies: ["GoogleGenAI"],
            path: "Sources/GoogleGenAIFoundationModels"
        ),
        .executableTarget(
            name: "SmokeTest",
            dependencies: ["GoogleGenAI", "GoogleGenAIFoundationModels"],
            path: "Sources/SmokeTest"
        ),
        .testTarget(
            name: "GoogleGenAITests",
            dependencies: ["GoogleGenAI"],
            path: "Tests/GoogleGenAITests"
        )
    ],
    swiftLanguageModes: [.v6]
)
