// 07-structured-output.swift — strongly-typed responses via Apple's @Generable macro
// and the GoogleGenAIFoundationModels adapter.
//
// Requires macOS 26+ / iOS 26+ / iPadOS 26+ / visionOS 26+.

import Foundation
#if canImport(FoundationModels)
import FoundationModels
import GoogleGenAIFoundationModels

@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
@Generable struct Recipe {
    @Guide(description: "The dish name")
    var name: String

    @Guide(description: "1–3 sentence description")
    var summary: String

    @Guide(description: "Ingredients with quantities and units")
    var ingredients: [String]

    @Guide(description: "Step-by-step preparation instructions")
    var steps: [String]
}

@main
struct StructuredOutputExample {
    static func main() async throws {
        guard #available(macOS 26.0, iOS 26.0, visionOS 26.0, *) else {
            print("This example requires macOS 26+ / iOS 26+.")
            return
        }
        let session = try GeminiLanguageModelSession(
            apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "",
            instructions: "You are a friendly chef."
        )
        let r = try await session.respond(
            to: "Give me a simple recipe for cacio e pepe.",
            generating: Recipe.self
        )
        let recipe = r.content
        print("=== \(recipe.name) ===")
        print(recipe.summary, "\n")
        print("Ingredients:")
        for i in recipe.ingredients { print("  •", i) }
        print("\nSteps:")
        for (i, step) in recipe.steps.enumerated() {
            print("  \(i + 1). \(step)")
        }
    }
}
#else
@main
struct StructuredOutputExample {
    static func main() {
        print("This example requires Apple's FoundationModels framework (macOS 26+ / iOS 26+).")
    }
}
#endif
