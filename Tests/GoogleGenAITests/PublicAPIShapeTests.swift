// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Testing
@testable import GoogleGenAI

/// Compile-only smoke tests that verify the public API surface matches the
/// JavaScript SDK's call shape. These tests do NOT make network calls — they
/// build a `GoogleGenAI` instance with a dummy API key and assert that the
/// expected methods exist with the expected signatures.
///
/// If any of these stop compiling, the public API has drifted from js-genai.
@Suite("Public API shape")
struct PublicAPIShapeTests {

    @Test func initStyles() throws {
        // Variant 1: explicit options struct
        _ = try GoogleGenAI(options: GoogleGenAIOptions(apiKey: "test"))

        // Variant 2: JS-style flattened args
        _ = try GoogleGenAI(apiKey: "test")

        // Variant 3: Vertex / Enterprise mode
        let _: () throws -> GoogleGenAI = {
            try GoogleGenAI(
                enterprise: true,
                project: "p",
                location: "us-central1"
            )
        }
        // (don't actually invoke — would require Vertex auth)
    }

    @Test func resourceSurfaceMatchesJS() throws {
        let ai = try GoogleGenAI(apiKey: "test")
        // Each of these maps 1:1 to a `readonly` property in js-genai's client.ts.
        let _: Models = ai.models
        let _: Live = ai.live
        let _: Batches = ai.batches
        let _: Chats = ai.chats
        let _: Caches = ai.caches
        let _: Files = ai.files
        let _: Operations = ai.operations
        let _: Tokens = ai.authTokens
        let _: Tunings = ai.tunings
        let _: FileSearchStores = ai.fileSearchStores
    }

    @Test func jsStyleGenerateContent() throws {
        let ai = try GoogleGenAI(apiKey: "test")
        // The JS canonical example must compile in Swift:
        //   const r = await ai.models.generateContent({model, contents});
        let _: () async throws -> GenerateContentResponse = {
            try await ai.models.generateContent(
                model: "gemini-2.5-flash",
                contents: "Why is the sky blue?"
            )
        }
        // And the verbose form must still work:
        let _: () async throws -> GenerateContentResponse = {
            try await ai.models.generateContent(GenerateContentParameters(
                model: "gemini-2.5-flash",
                contents: .part(.text("Why is the sky blue?"))
            ))
        }
    }

    @Test func jsStyleStreamingAndOthers() throws {
        let ai = try GoogleGenAI(apiKey: "test")
        let _: () async throws -> AsyncThrowingStream<GenerateContentResponse, Error> = {
            try await ai.models.generateContentStream(
                model: "gemini-2.5-flash",
                contents: "Tell me a story"
            )
        }
        let _: () async throws -> EmbedContentResponse = {
            try await ai.models.embedContent(
                model: "text-embedding-004",
                contents: ["What is your name?", "What is your favorite color?"]
            )
        }
        let _: () async throws -> CountTokensResponse = {
            try await ai.models.countTokens(model: "gemini-2.5-flash", contents: "hi")
        }
        let _: () async throws -> GenerateImagesResponse = {
            try await ai.models.generateImages(model: "imagen-3", prompt: "A cat")
        }
    }

    @Test func jsStyleChats() throws {
        let ai = try GoogleGenAI(apiKey: "test")
        let chat = ai.chats.create(model: "gemini-2.5-flash")
        let _: () async throws -> GenerateContentResponse = {
            try await chat.sendMessage("Hello!")
        }
        let _: () async throws -> AsyncThrowingStream<GenerateContentResponse, Error> = {
            try await chat.sendMessageStream("Tell me a longer story.")
        }
    }

    @Test func envInitFallsBackOnError() {
        // Without env vars or apiKey, init throws — guarded by .invalidArgument.
        do {
            _ = try GoogleGenAI(options: GoogleGenAIOptions())
            // If env happens to have GOOGLE_API_KEY set in this process, the
            // init succeeds — that's fine for this smoke test.
        } catch GenAIError.invalidArgument {
            // Expected when no env-provided auth is available.
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }
}
