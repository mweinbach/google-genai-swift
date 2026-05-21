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
        .executableTarget(
            name: "SmokeTest",
            dependencies: ["GoogleGenAI"],
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
