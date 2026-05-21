// 01-hello.swift — the minimum viable call.
//
// Run as part of a SwiftPM target with `GoogleGenAI` as a dependency.

import Foundation
import GoogleGenAI

@main
struct Hello {
    static func main() async throws {
        let ai = try GoogleGenAI(apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")
        let response = try await ai.models.generateContent(
            model: "gemini-2.5-flash",
            contents: "Why is the sky blue? Answer in one sentence."
        )
        print(response.text ?? "<no response>")
    }
}
