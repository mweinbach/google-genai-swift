// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Validation helpers

/// Returns true if the response is valid, false otherwise.
private func isValidResponse(_ response: GenerateContentResponse) -> Bool {
    guard let candidates = response.candidates, !candidates.isEmpty else {
        return false
    }
    guard let content = candidates[0].content else {
        return false
    }
    return isValidContent(content)
}

private func isValidContent(_ content: Content) -> Bool {
    guard let parts = content.parts, !parts.isEmpty else {
        return false
    }
    for part in parts {
        if isEmptyPart(part) {
            return false
        }
    }
    return true
}

/// Approximates `Object.keys(part).length === 0` from TS.
private func isEmptyPart(_ part: Part) -> Bool {
    guard let data = try? JSONEncoder().encode(part),
          let json = try? JSONDecoder().decode(JSONValue.self, from: data),
          case .object(let obj) = json else {
        return true
    }
    // Filter out null / undefined-equivalent fields.
    for (_, v) in obj {
        if case .null = v { continue }
        return false
    }
    return true
}

/// Validates the history contains the correct roles.
///
/// - Throws: `GenAIError.runtime` if the history contains an invalid role.
private func validateHistory(_ history: [Content]) throws {
    // Empty history is valid.
    if history.isEmpty { return }
    for content in history {
        let role = content.role
        if role != "user" && role != "model" {
            throw GenAIError.runtime("Role must be user or model, but got \(role ?? "nil").")
        }
    }
}

/// Extracts the curated (valid) history from a comprehensive history.
///
/// The model may sometimes generate invalid or empty contents (e.g., due to safety
/// filters or recitation). Extracting valid turns from the history ensures that
/// subsequent requests could be accepted by the model.
private func extractCuratedHistory(_ comprehensiveHistory: [Content]) -> [Content] {
    if comprehensiveHistory.isEmpty { return [] }
    var curatedHistory: [Content] = []
    let length = comprehensiveHistory.count
    var i = 0
    while i < length {
        if comprehensiveHistory[i].role == "user" {
            curatedHistory.append(comprehensiveHistory[i])
            i += 1
        } else {
            var modelOutput: [Content] = []
            var isValid = true
            while i < length && comprehensiveHistory[i].role == "model" {
                modelOutput.append(comprehensiveHistory[i])
                if isValid && !isValidContent(comprehensiveHistory[i]) {
                    isValid = false
                }
                i += 1
            }
            if isValid {
                curatedHistory.append(contentsOf: modelOutput)
            } else {
                // Remove the last user input when model content is invalid.
                if !curatedHistory.isEmpty {
                    curatedHistory.removeLast()
                }
            }
        }
    }
    return curatedHistory
}

// MARK: - Deep copy helpers

private func deepCopyContents(_ history: [Content]) -> [Content] {
    guard let data = try? JSONEncoder().encode(history),
          let copy = try? JSONDecoder().decode([Content].self, from: data) else {
        return history
    }
    return copy
}

// MARK: - Chats

/// A utility class to create a chat session.
public final class Chats: BaseModule, @unchecked Sendable {
    private let modelsModule: Models
    private let apiClient: ApiClient

    public init(modelsModule: Models, apiClient: ApiClient) {
        self.modelsModule = modelsModule
        self.apiClient = apiClient
        super.init()
    }

    /// Creates a new chat session.
    public func create(_ params: CreateChatParameters) -> Chat {
        return Chat(
            apiClient: self.apiClient,
            modelsModule: self.modelsModule,
            model: params.model,
            config: params.config ?? GenerateContentConfig(),
            // Deep copy the history to avoid mutating the history outside of the chat session.
            history: deepCopyContents(params.history ?? [])
        )
    }
}

/// Chat session that enables sending messages to the model with previous
/// conversation context.
///
/// The session maintains all the turns between user and model.
public final class Chat: @unchecked Sendable {
    private let apiClient: ApiClient
    private let modelsModule: Models
    private let model: String
    private let config: GenerateContentConfig

    // Mutable state guarded by `lock`.
    private let lock = NSLock()
    private var history: [Content]
    /// Mirror of TS `sendPromise` — used to serialize `sendMessage`/`sendMessageStream` calls.
    private var sendTask: Task<Void, Never>? = nil

    public init(
        apiClient: ApiClient,
        modelsModule: Models,
        model: String,
        config: GenerateContentConfig = GenerateContentConfig(),
        history: [Content] = []
    ) {
        self.apiClient = apiClient
        self.modelsModule = modelsModule
        self.model = model
        self.config = config
        self.history = history
        try? validateHistory(history)
    }

    /// Sends a message to the model and returns the response.
    ///
    /// This method will wait for the previous message to be processed before
    /// sending the next message.
    public func sendMessage(
        _ params: SendMessageParameters
    ) async throws -> GenerateContentResponse {
        // Wait for previous send to settle.
        await self.awaitPendingSend()

        let inputContent = try tContent(partListUnionToContentUnion(params.message))
        let contentsToSend = self.getHistory(curated: true) + [inputContent]
        let response = try await self.modelsModule.generateContent(
            GenerateContentParameters(
                model: self.model,
                contents: .contents(contentsToSend),
                config: params.config ?? self.config
            )
        )

        // Truncate AFC history to deduplicate the existing chat history.
        let fullAutomaticFunctionCallingHistory = response.automaticFunctionCallingHistory
        let index = self.getHistory(curated: true).count
        var automaticFunctionCallingHistory: [Content] = []
        if let full = fullAutomaticFunctionCallingHistory, full.count > index {
            automaticFunctionCallingHistory = Array(full[index...])
        }
        let modelOutput: [Content]
        if let outputContent = response.candidates?.first?.content {
            modelOutput = [outputContent]
        } else {
            modelOutput = []
        }
        self.recordHistory(
            userInput: inputContent,
            modelOutput: modelOutput,
            automaticFunctionCallingHistory: automaticFunctionCallingHistory
        )
        return response
    }

    /// Sends a message to the model and returns the response in chunks.
    ///
    /// This method will wait for the previous message to be processed before
    /// sending the next message.
    public func sendMessageStream(
        _ params: SendMessageParameters
    ) async throws -> AsyncThrowingStream<GenerateContentResponse, Error> {
        await self.awaitPendingSend()
        let inputContent = try tContent(partListUnionToContentUnion(params.message))
        let contentsToSend = self.getHistory(curated: true) + [inputContent]
        let streamResponse = try await self.modelsModule.generateContentStream(
            GenerateContentParameters(
                model: self.model,
                contents: .contents(contentsToSend),
                config: params.config ?? self.config
            )
        )
        return self.processStreamResponse(streamResponse: streamResponse, inputContent: inputContent)
    }

    /// Returns the chat history.
    ///
    /// - Parameter curated: Whether to return the curated history or the comprehensive history.
    /// - Returns: History contents alternating between user and model for the entire chat session.
    public func getHistory(curated: Bool = false) -> [Content] {
        lock.lock()
        let snapshot = self.history
        lock.unlock()
        let history = curated ? extractCuratedHistory(snapshot) : snapshot
        return deepCopyContents(history)
    }

    private func processStreamResponse(
        streamResponse: AsyncThrowingStream<GenerateContentResponse, Error>,
        inputContent: Content
    ) -> AsyncThrowingStream<GenerateContentResponse, Error> {
        return AsyncThrowingStream<GenerateContentResponse, Error> { continuation in
            let recorder = self
            let task = Task {
                var outputContent: [Content] = []
                do {
                    for try await chunk in streamResponse {
                        if isValidResponse(chunk) {
                            if let content = chunk.candidates?.first?.content {
                                outputContent.append(content)
                            }
                        }
                        continuation.yield(chunk)
                    }
                    recorder.recordHistory(
                        userInput: inputContent,
                        modelOutput: outputContent,
                        automaticFunctionCallingHistory: nil
                    )
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private func recordHistory(
        userInput: Content,
        modelOutput: [Content],
        automaticFunctionCallingHistory: [Content]?
    ) {
        var outputContents: [Content] = []
        if !modelOutput.isEmpty && modelOutput.allSatisfy({ $0.role != nil }) {
            outputContents = modelOutput
        } else {
            // Appends an empty content when model returns empty response, so that the
            // history is always alternating between user and model.
            outputContents.append(Content(parts: [], role: "model"))
        }
        lock.lock()
        if let afc = automaticFunctionCallingHistory, !afc.isEmpty {
            self.history.append(contentsOf: extractCuratedHistory(afc))
        } else {
            self.history.append(userInput)
        }
        self.history.append(contentsOf: outputContents)
        lock.unlock()
    }

    /// Mirrors TS `sendPromise` serialization — awaits the previous send before proceeding.
    private func awaitPendingSend() async {
        let pending = readPendingSendTask()
        if let p = pending {
            _ = await p.value
        }
    }

    private func readPendingSendTask() -> Task<Void, Never>? {
        lock.lock(); defer { lock.unlock() }
        return sendTask
    }
}

// MARK: - Internal helpers

/// Converts a `PartListUnion` to a `ContentUnion`. Mirrors TS `t.tContent(params.message)` plumbing.
private func partListUnionToContentUnion(_ message: PartListUnion) -> ContentUnion {
    switch message {
    case .single(let p):
        return .part(p)
    case .many(let arr):
        return .parts(arr)
    }
}
