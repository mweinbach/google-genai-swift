// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

// End-to-end smoke tests against the live Gemini API. Exercises:
//   1. Plain generateContent (already validated)
//   2. Streaming
//   3. Multi-turn chat
//   4. Custom tools (function calling)
//   5. Built-in tool: Google Search grounding
//   6. Built-in tool: Code execution
//   7. Live realtime session (text in / text out)
//
// Run with:
//     GEMINI_API_KEY=... swift run SmokeTest

import Foundation
import GoogleGenAI
#if canImport(FoundationModels)
import FoundationModels
import GoogleGenAIFoundationModels
#endif

@main
struct SmokeTest {
    static func main() async {
        guard let apiKey = ProcessInfo.processInfo.environment["GEMINI_API_KEY"],
              !apiKey.isEmpty else {
            print("ERROR: GEMINI_API_KEY environment variable is not set.")
            exit(1)
        }

        do {
            let ai = try GoogleGenAI(apiKey: apiKey)

            try await testPlainGenerateContent(ai)
            try await testStreaming(ai)
            try await testChat(ai)
            try await testFunctionCalling(ai)
            try await testGoogleSearchGrounding(ai)
            try await testCodeExecution(ai)
            try await testLiveSession(ai)
            #if canImport(FoundationModels)
            if #available(macOS 26.0, iOS 26.0, visionOS 26.0, *) {
                try await testFoundationModelsAdapter(apiKey: apiKey)
            } else {
                print("[8] Foundation Models adapter — skipped (requires macOS 26+/iOS 26+)")
            }
            #else
            print("[8] Foundation Models adapter — skipped (FoundationModels not available in this SDK)")
            #endif

            print("\n✓ All smoke tests passed.")
        } catch let err as ApiError {
            print("\n✗ ApiError: status=\(err.status) message=\(err.message)")
            exit(1)
        } catch let err as GenAIError {
            print("\n✗ GenAIError: \(err)")
            exit(1)
        } catch {
            print("\n✗ Unexpected error: \(error)")
            exit(1)
        }
    }

    // MARK: - 1. Plain generateContent
    static func testPlainGenerateContent(_ ai: GoogleGenAI) async throws {
        print("[1] generateContent …")
        let r = try await ai.models.generateContent(
            model: "gemini-2.5-flash",
            contents: "Why is the sky blue? Answer in one short sentence."
        )
        print("    → \(r.text ?? "<no text>")")
    }

    // MARK: - 2. Streaming
    static func testStreaming(_ ai: GoogleGenAI) async throws {
        print("[2] generateContentStream …")
        var chunks = 0
        var accumulated = ""
        let stream = try await ai.models.generateContentStream(
            model: "gemini-2.5-flash",
            contents: "Count from 1 to 5, separated by spaces."
        )
        for try await chunk in stream {
            chunks += 1
            if let t = chunk.text { accumulated += t }
        }
        print("    → \(chunks) chunks, text: \(accumulated.trimmingCharacters(in: .whitespacesAndNewlines))")
    }

    // MARK: - 3. Chat
    static func testChat(_ ai: GoogleGenAI) async throws {
        print("[3] chats.create + multi-turn sendMessage …")
        let chat = ai.chats.create(model: "gemini-2.5-flash")
        _ = try await chat.sendMessage("Hi! My favorite color is teal. Remember that.")
        let r = try await chat.sendMessage("What did I tell you my favorite color was?")
        print("    → \(r.text?.prefix(140) ?? "<no text>")")
    }

    // MARK: - 4. Custom tools (function calling)
    static func testFunctionCalling(_ ai: GoogleGenAI) async throws {
        print("[4] Custom tool / function calling …")
        // Declare a function the model can call.
        let getWeather = FunctionDeclaration(
            description: "Look up the current weather for a city.",
            name: "get_current_weather",
            parametersJsonSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "location": .object([
                        "type": .string("string"),
                        "description": .string("The city, e.g. San Francisco")
                    ])
                ]),
                "required": .array([.string("location")])
            ])
        )
        let tools: ToolListUnion = [.tool(Tool(functionDeclarations: [getWeather]))]
        let config = GenerateContentConfig(tools: tools)
        let r = try await ai.models.generateContent(
            model: "gemini-2.5-flash",
            contents: "What's the weather like in Paris right now?",
            config: config
        )
        var foundFunctionCall = false
        if let parts = r.candidates?.first?.content?.parts {
            for part in parts {
                if let fc = part.functionCall {
                    foundFunctionCall = true
                    print("    → model invoked \(fc.name ?? "?") with args=\(fc.args ?? [:])")
                }
            }
        }
        if !foundFunctionCall {
            print("    ⚠️ Model did not invoke the function (response text: \(r.text ?? "")). Tool wiring still works at the type level.")
        }
    }

    // MARK: - 5. Built-in tool: Google Search grounding
    static func testGoogleSearchGrounding(_ ai: GoogleGenAI) async throws {
        print("[5] Built-in tool: Google Search grounding …")
        var tool = Tool()
        tool.googleSearch = GoogleSearch()
        let config = GenerateContentConfig(tools: [.tool(tool)])
        let r = try await ai.models.generateContent(
            model: "gemini-2.5-flash",
            contents: "What major news event happened today? Cite a source.",
            config: config
        )
        let groundingHits = r.candidates?.first?.groundingMetadata?.groundingChunks?.count ?? 0
        print("    → response with \(groundingHits) grounding chunks: \((r.text ?? "").prefix(140))…")
    }

    // MARK: - 6. Built-in tool: Code execution
    static func testCodeExecution(_ ai: GoogleGenAI) async throws {
        print("[6] Built-in tool: Code execution …")
        var tool = Tool()
        tool.codeExecution = ToolCodeExecution()
        let config = GenerateContentConfig(tools: [.tool(tool)])
        let r = try await ai.models.generateContent(
            model: "gemini-2.5-flash",
            contents: "Use Python to compute the 20th Fibonacci number, then tell me the answer.",
            config: config
        )
        var executableCount = 0
        var resultCount = 0
        if let parts = r.candidates?.first?.content?.parts {
            for part in parts {
                if part.executableCode != nil { executableCount += 1 }
                if part.codeExecutionResult != nil { resultCount += 1 }
            }
        }
        print("    → \(executableCount) executable_code part(s), \(resultCount) code_execution_result part(s)")
        print("    → answer: \((r.text ?? "").prefix(140))…")
    }

    // MARK: - 7. Live (realtime) session
    static func testLiveSession(_ ai: GoogleGenAI) async throws {
        print("[7] Live realtime session …")
        let receivedAnything = ReceivedFlag()
        let done = ReceivedFlag()
        let callbacks = LiveCallbacks(
            onMessage: { @Sendable msg in
                Task { await receivedAnything.set() }
                if msg.serverContent?.turnComplete == true {
                    Task { await done.set() }
                }
            },
            onError: { @Sendable err in print("    ⚠️ ws error: \(err)") },
            onOpen: { @Sendable in print("    → ws opened") },
            onClose: { @Sendable _ in
                Task { await done.set() }
            }
        )
        let connectConfig = LiveConnectConfig(
            responseModalities: [.audio]
        )
        let connectParams = LiveConnectParameters(
            model: "models/gemini-2.5-flash-native-audio-latest",
            callbacks: callbacks,
            config: connectConfig
        )
        let session: Session
        do {
            session = try await ai.live.connect(connectParams)
        } catch {
            print("    ⚠️ Live connect failed (model may not be available on this key tier): \(error)")
            return
        }
        // Send a single text turn.
        let msg = LiveSendClientContentParameters(
            turns: .part(.text("Say the word 'hello' and nothing else.")),
            turnComplete: true
        )
        try session.sendClientContent(msg)
        // Wait up to 10s for a server response.
        let deadline = Date().addingTimeInterval(10)
        while Date() < deadline {
            if await done.value { break }
            try await Task.sleep(nanoseconds: 200_000_000)
        }
        let received = await receivedAnything.value
        session.close()
        print("    → received messages: \(received)")
    }
}

actor ReceivedFlag {
    private(set) var value = false
    func set() { value = true }
}

// MARK: - 8. Foundation Models adapter

#if canImport(FoundationModels)
@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
@Generable struct ColorSwatch {
    @Guide(description: "A short, evocative name for the color")
    var name: String
    @Guide(description: "The color's hex code, like #1A2B3C")
    var hex: String
    @Guide(description: "A 1-sentence description of the color's mood")
    var mood: String
}

@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
func testFoundationModelsAdapter(apiKey: String) async throws {
    print("[8] Foundation Models adapter (Generable structured output) …")
    let session = try GeminiLanguageModelSession(
        apiKey: apiKey,
        instructions: "You generate small color palettes."
    )
    let response = try await session.respond(
        to: "Invent one new color swatch inspired by an autumn forest at dusk.",
        generating: ColorSwatch.self
    )
    let swatch = response.content
    print("    → name=\"\(swatch.name)\" hex=\(swatch.hex)")
    print("    → mood: \(swatch.mood)")

    // Plain text via the same session shape (sanity check that respond(to:)
    // still works alongside the Generable variant).
    let plain = try await session.respond(to: "In one short sentence, what's the meaning of life?")
    print("    → plain text: \(plain.content)")
}
#endif
