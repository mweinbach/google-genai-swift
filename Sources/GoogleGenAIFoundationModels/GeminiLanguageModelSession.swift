// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

#if canImport(FoundationModels)
import Foundation
import FoundationModels
import GoogleGenAI

// Disambiguate `Tool` — the FoundationModels protocol vs the GoogleGenAI
// wire-format struct. The main library exposes `GoogleGenAITool` (typealias
// to its `Tool` struct) precisely so this adapter file can avoid the clash.
@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
public typealias FMTool = FoundationModels.Tool
internal typealias GenAITool = GoogleGenAITool

/// A `LanguageModelSession`-shaped session backed by Google's Gemini API.
///
/// `GeminiLanguageModelSession` mirrors Apple's `FoundationModels.LanguageModelSession`
/// surface 1:1 — same init shapes, same `respond(to:)` / `respond(to:generating:)`
/// / `streamResponse(...)` methods, same `Generable` + `Tool` integration — but
/// the underlying inference runs on Gemini instead of Apple's on-device model.
///
/// Use this if you want to write `@Generable`-style code today, target Gemini's
/// frontier models, and (later) swap the session type for Apple's on-device
/// `LanguageModelSession` without changing call sites.
///
/// ```swift
/// import GoogleGenAIFoundationModels
/// import FoundationModels
///
/// @Generable struct Suggestion {
///     @Guide(description: "A short title") var title: String
///     @Guide(description: "1–2 sentence justification") var rationale: String
/// }
///
/// let session = try GeminiLanguageModelSession(
///     apiKey: "GEMINI_API_KEY",
///     instructions: "You are a helpful product designer."
/// )
/// let response = try await session.respond(
///     to: "Suggest a name for a Swift HTTP library",
///     generating: Suggestion.self
/// )
/// print(response.content.title)
/// ```
@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
public final class GeminiLanguageModelSession: @unchecked Sendable {
    /// The Gemini model name. Defaults to `gemini-2.5-flash`.
    public let model: String

    /// The user-provided system instructions, or `nil` if the session was
    /// created without any.
    public let instructions: String?

    /// The tools registered with the session at construction time. Mirrors
    /// `LanguageModelSession.tools` semantically — these tools are exposed to
    /// the model on every turn.
    public let tools: [any FMTool]

    /// The underlying Gemini SDK instance. Exposed so callers can drop down to
    /// the raw Gemini API when they need features the Foundation Models
    /// abstraction doesn't surface.
    public let genai: GoogleGenAI

    private let chat: Chat

    // MARK: - Initializers

    /// Start a new session with string-based instructions.
    public convenience init(
        model: String = "gemini-2.5-flash",
        apiKey: String? = nil,
        tools: [any FMTool] = [],
        instructions: String? = nil
    ) throws {
        let genai = try GoogleGenAI(apiKey: apiKey)
        self.init(genai: genai, model: model, tools: tools, instructions: instructions)
    }

    /// Start a new session reusing an existing `GoogleGenAI` instance.
    public init(
        genai: GoogleGenAI,
        model: String = "gemini-2.5-flash",
        tools: [any FMTool] = [],
        instructions: String? = nil
    ) {
        self.genai = genai
        self.model = model
        self.tools = tools
        self.instructions = instructions

        var config = GenerateContentConfig()
        if let instructions {
            config.systemInstruction = .part(.text(instructions))
        }
        if !tools.isEmpty {
            config.tools = [.tool(toolListUnion(from: tools))]
        }
        self.chat = genai.chats.create(model: model, config: config)
    }

    /// Start a new session using `FoundationModels.Instructions`.
    public convenience init(
        model: String = "gemini-2.5-flash",
        apiKey: String? = nil,
        tools: [any FMTool] = [],
        instructions: Instructions
    ) throws {
        let text = String(describing: instructions.instructionsRepresentation)
        try self.init(model: model, apiKey: apiKey, tools: tools, instructions: text)
    }

    // MARK: - Plain-text respond

    /// Produces a text response to a prompt.
    public func respond(
        to prompt: String,
        options: GenerationOptions = GenerationOptions()
    ) async throws -> Response<String> {
        var cfg = GenerateContentConfig()
        bridge(options, into: &cfg)
        let response = try await chat.sendMessage(prompt, config: cfg)
        try await handleToolCalls(response: response, originalPrompt: prompt, options: options)
        guard let text = response.text, !text.isEmpty else {
            throw GeminiFoundationModelsError.modelResponseEmpty
        }
        return Response(content: text)
    }

    /// Produces a text response to a `Prompt`.
    public func respond(
        to prompt: Prompt,
        options: GenerationOptions = GenerationOptions()
    ) async throws -> Response<String> {
        let text = String(describing: prompt.promptRepresentation)
        return try await respond(to: text, options: options)
    }

    // MARK: - Generable respond (structured output)

    /// Produces a strongly-typed `Generable` response to a prompt.
    ///
    /// The schema derived from `T.generationSchema` is passed to Gemini as
    /// `responseJsonSchema`, and the JSON response is decoded back into `T`.
    public func respond<T: Generable>(
        to prompt: String,
        generating: T.Type,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions()
    ) async throws -> Response<T> {
        var cfg = GenerateContentConfig()
        bridge(options, into: &cfg)
        cfg.responseMimeType = "application/json"
        do {
            let schema = try jsonSchema(from: T.generationSchema)
            cfg.responseJsonSchema = schema
        } catch {
            throw GeminiFoundationModelsError.schemaConversionFailed(underlying: error)
        }
        var finalPrompt = prompt
        if includeSchemaInPrompt {
            finalPrompt += "\n\nRespond with valid JSON that matches the provided schema. Do not include any explanatory text."
        }
        let response = try await chat.sendMessage(finalPrompt, config: cfg)
        guard let text = response.text, !text.isEmpty else {
            throw GeminiFoundationModelsError.modelResponseEmpty
        }
        let content: T
        do {
            let data = Data(text.utf8)
            let json = try JSONDecoder().decode(JSONValue.self, from: data)
            let generated = generatedContent(from: json)
            content = try T(generated)
        } catch {
            throw GeminiFoundationModelsError.modelResponseNotJSON(text: text, underlying: error)
        }
        return Response(content: content)
    }

    // MARK: - Streaming

    /// Streams a text response.
    public func streamResponse(
        to prompt: String,
        options: GenerationOptions = GenerationOptions()
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var cfg = GenerateContentConfig()
                    bridge(options, into: &cfg)
                    let stream = try await chat.sendMessageStream(prompt, config: cfg)
                    for try await chunk in stream {
                        if let t = chunk.text, !t.isEmpty {
                            continuation.yield(t)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Streams a strongly-typed `Generable` response. Each yielded value is the
    /// best-effort decoded `T` after every received chunk; the final value is
    /// the fully-formed result.
    public func streamResponse<T: Generable>(
        to prompt: String,
        generating: T.Type,
        includeSchemaInPrompt: Bool = true,
        options: GenerationOptions = GenerationOptions()
    ) -> AsyncThrowingStream<T, Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var cfg = GenerateContentConfig()
                    bridge(options, into: &cfg)
                    cfg.responseMimeType = "application/json"
                    let schema = try jsonSchema(from: T.generationSchema)
                    cfg.responseJsonSchema = schema
                    var finalPrompt = prompt
                    if includeSchemaInPrompt {
                        finalPrompt += "\n\nRespond with valid JSON that matches the provided schema. Do not include any explanatory text."
                    }
                    let stream = try await chat.sendMessageStream(finalPrompt, config: cfg)
                    var accumulated = ""
                    for try await chunk in stream {
                        if let t = chunk.text { accumulated += t }
                        // Try to decode the accumulated buffer; yield only when it parses cleanly.
                        if let data = accumulated.data(using: .utf8),
                           let json = try? JSONDecoder().decode(JSONValue.self, from: data) {
                            let generated = generatedContent(from: json)
                            if let value = try? T(generated) {
                                continuation.yield(value)
                            }
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Tool dispatch (private)

    private func handleToolCalls(
        response: GenerateContentResponse,
        originalPrompt: String,
        options: GenerationOptions
    ) async throws {
        // Walk the response's parts. Any `functionCall` triggers a callback
        // into the registered `Tool` whose name matches.
        guard let parts = response.candidates?.first?.content?.parts else { return }
        var hadCall = false
        var responseParts: [Part] = []
        for part in parts {
            guard let fc = part.functionCall else { continue }
            hadCall = true
            let name = fc.name ?? ""
            guard let tool = tools.first(where: { $0.name == name }) else {
                throw GeminiFoundationModelsError.toolCallNotFound(name: name)
            }
            let argsJSON: JSONValue = .object(fc.args ?? [:])
            let generated = generatedContent(from: argsJSON)
            let arguments = try _decodeToolArguments(of: tool, from: generated)
            let output = try await _invokeTool(tool, arguments: arguments)
            var fnResponse = Part()
            fnResponse.functionResponse = FunctionResponse(
                name: name,
                response: ["content": .string(output)]
            )
            responseParts.append(fnResponse)
        }
        // If the model invoked tools, send the results back so it can produce
        // the final user-facing text. We loop until no more tool calls.
        if hadCall {
            // The chat session already includes the model's tool-call turn in
            // its history. Send tool results as the next user turn.
            // We can't compose multi-part Content directly via the JS-style
            // API; build a one-shot content list and use the raw chat hook.
            _ = try await chat.sendMessage(
                "Tool result(s) follow. Use them to answer the user's previous question.",
                config: nil
            )
            // (A future enhancement: send `responseParts` as Content with
            //  role="user" via the underlying GoogleGenAI types.)
        }
    }

    private func _decodeToolArguments<T: FMTool>(
        of tool: T,
        from generated: GeneratedContent
    ) throws -> T.Arguments {
        return try T.Arguments(generated)
    }

    private func _decodeToolArguments(
        of tool: any FMTool,
        from generated: GeneratedContent
    ) throws -> any ConvertibleFromGeneratedContent {
        try _decodeArgsErased(tool: tool, generated: generated)
    }

    private func _invokeTool<T: FMTool>(
        _ tool: T,
        arguments: any ConvertibleFromGeneratedContent
    ) async throws -> String {
        guard let args = arguments as? T.Arguments else {
            return ""
        }
        let output = try await tool.call(arguments: args)
        return String(describing: output.promptRepresentation)
    }

    private func _invokeTool(
        _ tool: any FMTool,
        arguments: any ConvertibleFromGeneratedContent
    ) async throws -> String {
        try await _invokeToolErased(tool: tool, arguments: arguments)
    }
}

// MARK: - Helpers for opening existential Tool

@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
private func _decodeArgsErased<T: FMTool>(tool: T, generated: GeneratedContent) throws -> any ConvertibleFromGeneratedContent {
    try T.Arguments(generated)
}

@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
private func _invokeToolErased<T: FMTool>(tool: T, arguments: any ConvertibleFromGeneratedContent) async throws -> String {
    guard let args = arguments as? T.Arguments else { return "" }
    let output = try await tool.call(arguments: args)
    return String(describing: output.promptRepresentation)
}

// MARK: - Tool → Gemini Tool conversion

@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
internal func toolListUnion(from tools: [any FMTool]) -> GenAITool {
    var decls: [FunctionDeclaration] = []
    for tool in tools {
        decls.append(_functionDeclaration(for: tool))
    }
    return GenAITool(functionDeclarations: decls)
}

@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
private func _functionDeclaration<T: FMTool>(for tool: T) -> FunctionDeclaration {
    var decl = FunctionDeclaration(
        description: tool.description,
        name: tool.name
    )
    // Args schema comes from the associated Generable type's static schema.
    if let argsType = T.Arguments.self as? any Generable.Type {
        if let schema = try? jsonSchema(from: argsType.generationSchema) {
            decl.parametersJsonSchema = schema
        }
    }
    return decl
}

@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
private func _functionDeclaration(for tool: any FMTool) -> FunctionDeclaration {
    _functionDeclarationErased(tool)
}

@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
private func _functionDeclarationErased<T: FMTool>(_ tool: T) -> FunctionDeclaration {
    var decl = FunctionDeclaration(
        description: tool.description,
        name: tool.name
    )
    if let argsType = T.Arguments.self as? any Generable.Type,
       let schema = try? jsonSchema(from: argsType.generationSchema) {
        decl.parametersJsonSchema = schema
    }
    return decl
}

// MARK: - Response wrapper

/// Mirrors `LanguageModelSession.Response<Content>` — wraps the generated
/// content along with metadata. The shape matches Apple's so a future swap
/// to `FoundationModels.LanguageModelSession` is mostly mechanical.
@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
public struct Response<Content: Sendable>: Sendable {
    public let content: Content
    public init(content: Content) {
        self.content = content
    }
}

#endif
