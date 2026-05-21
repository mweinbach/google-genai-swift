// 02-streaming.swift — token streaming.

import Foundation
import GoogleGenAI

@main
struct StreamingExample {
    static func main() async throws {
        let ai = try GoogleGenAI(apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")
        let stream = try await ai.models.generateContentStream(
            model: "gemini-2.5-flash",
            contents: "Write a short haiku about Swift."
        )
        for try await chunk in stream {
            if let text = chunk.text {
                print(text, terminator: "")
                fflush(stdout)
            }
        }
        print()  // trailing newline
    }
}
