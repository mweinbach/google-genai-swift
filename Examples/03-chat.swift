// 03-chat.swift — multi-turn conversation with auto history.

import Foundation
import GoogleGenAI

@main
struct ChatExample {
    static func main() async throws {
        let ai = try GoogleGenAI(apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")

        let chat = ai.chats.create(
            model: "gemini-2.5-flash",
            config: GenerateContentConfig(
                systemInstruction: .part(.text("You are a friendly assistant who remembers what users tell you."))
            )
        )

        _ = try await chat.sendMessage("My favorite color is teal.")
        _ = try await chat.sendMessage("I have two cats named Pixel and Pebble.")

        let r = try await chat.sendMessage("What did I tell you about my pets and color?")
        print(r.text ?? "")
    }
}
