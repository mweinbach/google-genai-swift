// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

// End-to-end smoke test exercising the canonical js-genai equivalent calls.
// Reads the API key from the `GEMINI_API_KEY` env var so secrets aren't
// committed to source. Run with:
//
//     GEMINI_API_KEY=... swift run SmokeTest
//
// Mirrors:
//     const ai = new GoogleGenAI({apiKey});
//     const r = await ai.models.generateContent({model, contents});
//     console.log(r.text);

import Foundation
import GoogleGenAI

@main
struct SmokeTest {
    static func main() async {
        guard let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"],
              !apiKey.isEmpty else {
            print("ERROR: GEMINI_API_KEY environment variable is not set.")
            exit(1)
        }

        do {
            // ── 1. Init (JS-style)
            print("[1/4] Initializing GoogleGenAI(apiKey:) …")
            let ai = try GoogleGenAI(apiKey: apiKey)
            print("      vertexai = \(ai.vertexai)")

            // ── 2. generateContent — the canonical JS example
            print("[2/4] ai.models.generateContent(model:, contents:) …")
            let r1 = try await ai.models.generateContent(
                model: "gemini-2.5-flash",
                contents: "Why is the sky blue? Answer in one short sentence."
            )
            let text1 = r1.text ?? "<no text>"
            print("      → \(text1)")

            // ── 3. Streaming
            print("[3/4] ai.models.generateContentStream(model:, contents:) …")
            var streamedChunks = 0
            let stream = try await ai.models.generateContentStream(
                model: "gemini-2.5-flash",
                contents: "Count from 1 to 5, separated by spaces."
            )
            var accumulated = ""
            for try await chunk in stream {
                streamedChunks += 1
                if let chunkText = chunk.text { accumulated += chunkText }
            }
            print("      → \(streamedChunks) chunks, total text: \(accumulated.trimmingCharacters(in: .whitespacesAndNewlines))")

            // ── 4. Chat
            print("[4/4] ai.chats.create(model:) + chat.sendMessage(_:) …")
            let chat = ai.chats.create(model: "gemini-2.5-flash")
            let r2 = try await chat.sendMessage("Hi! My favorite color is teal. Remember that.")
            let text2 = r2.text ?? "<no text>"
            print("      first turn → \(text2.prefix(120))…")
            let r3 = try await chat.sendMessage("What did I tell you my favorite color was?")
            let text3 = r3.text ?? "<no text>"
            print("      second turn → \(text3.prefix(120))…")

            print("\n✓ All four smoke-test calls completed successfully.")
        } catch let err as ApiError {
            print("✗ ApiError: status=\(err.status) message=\(err.message)")
            exit(1)
        } catch let err as GenAIError {
            print("✗ GenAIError: \(err)")
            exit(1)
        } catch {
            print("✗ Unexpected error: \(error)")
            exit(1)
        }
    }
}
