// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - WebSocket placeholder protocols (TODO Wave 6)

/// Placeholder WebSocket protocol — replaced once `_websocket.ts` lands.
public protocol GenAIWebSocket: Sendable {
    func connect()
    func send(_ message: String)
    func close()
}

/// Placeholder WebSocket callback bundle — replaced once `_websocket.ts` lands.
public struct GenAIWebSocketCallbacks: Sendable {
    public var onOpen: @Sendable () -> Void
    public var onMessage: @Sendable (Data) -> Void
    public var onError: @Sendable (Error) -> Void
    public var onClose: @Sendable (Error?) -> Void

    public init(
        onOpen: @escaping @Sendable () -> Void,
        onMessage: @escaping @Sendable (Data) -> Void,
        onError: @escaping @Sendable (Error) -> Void,
        onClose: @escaping @Sendable (Error?) -> Void
    ) {
        self.onOpen = onOpen
        self.onMessage = onMessage
        self.onError = onError
        self.onClose = onClose
    }
}

/// Placeholder WebSocket factory — replaced once `_websocket.ts` lands.
public protocol GenAIWebSocketFactory: Sendable {
    func create(
        url: String,
        headers: [String: String],
        callbacks: GenAIWebSocketCallbacks
    ) -> GenAIWebSocket
}

// MARK: - Music

/// LiveMusic class encapsulates the configuration for live music
/// generation via Lyria Live models.
///
/// @experimental
public final class Music: BaseModule, @unchecked Sendable {
    private let apiClient: ApiClient
    private let auth: Auth
    private let webSocketFactory: GenAIWebSocketFactory

    public init(
        apiClient: ApiClient,
        auth: Auth,
        webSocketFactory: GenAIWebSocketFactory
    ) {
        self.apiClient = apiClient
        self.auth = auth
        self.webSocketFactory = webSocketFactory
        super.init()
    }

    /// Establishes a connection to the specified model and returns a
    /// MusicSession object representing that connection.
    ///
    /// @experimental
    public func connect(
        _ params: LiveMusicConnectParameters
    ) async throws -> MusicSession {
        if self.apiClient.isVertexAI() {
            throw GenAIError.unsupported("Live music is not supported for Vertex AI.")
        }
        print("Live music generation is experimental and may change in future versions.")

        let websocketBaseUrl = try self.apiClient.getWebsocketBaseUrl()
        let apiVersion = try self.apiClient.getApiVersion()
        let headers = self.apiClient.getDefaultHeaders()
        let apiKey = self.apiClient.getApiKey() ?? ""
        let url = "\(websocketBaseUrl)/ws/google.ai.generativelanguage.\(apiVersion).GenerativeService.BidiGenerateMusic?key=\(apiKey)"

        let callbacks = params.callbacks

        // Open handshake — capture the resolved continuation.
        let openSignal = AsyncOpenSignal()
        let userOnError = callbacks.onError
        let userOnClose = callbacks.onClose
        let apiClient = self.apiClient

        let websocketCallbacks = GenAIWebSocketCallbacks(
            onOpen: {
                openSignal.resolve()
            },
            onMessage: { data in
                Task {
                    await handleWebSocketMessage(
                        apiClient: apiClient,
                        onMessage: callbacks.onMessage,
                        eventData: data
                    )
                }
            },
            onError: { err in
                userOnError?(err)
            },
            onClose: { err in
                userOnClose?(err)
            }
        )

        let conn = self.webSocketFactory.create(
            url: url,
            headers: headers,
            callbacks: websocketCallbacks
        )
        conn.connect()
        // Wait for the websocket to open before sending requests.
        await openSignal.wait()

        let model = try tModel(apiClient: self.apiClient, model: params.model)
        let setup: [String: JSONValue] = ["model": .string(model)]
        let clientMessage: [String: JSONValue] = ["setup": .object(setup)]
        conn.send(jsonValueObjectToString(clientMessage))

        return MusicSession(conn: conn, apiClient: self.apiClient)
    }
}

/// Represents a connection to the API.
///
/// @experimental
public final class MusicSession: @unchecked Sendable {
    public let conn: GenAIWebSocket
    private let apiClient: ApiClient

    public init(conn: GenAIWebSocket, apiClient: ApiClient) {
        self.conn = conn
        self.apiClient = apiClient
    }

    /// Sets inputs to steer music generation. Updates the session's current
    /// weighted prompts.
    public func setWeightedPrompts(
        _ params: LiveMusicSetWeightedPromptsParameters
    ) async throws {
        if params.weightedPrompts.isEmpty {
            throw GenAIError.invalidArgument(
                "Weighted prompts must be set and contain at least one entry."
            )
        }
        let paramsDict = try jsonObject(params)
        var parent: [String: JSONValue] = [:]
        let clientContent = try liveMusicSetWeightedPromptsParametersToMldev(
            apiClient: self.apiClient, fromObject: paramsDict, parentObject: &parent
        )
        let message: [String: JSONValue] = ["clientContent": .object(clientContent)]
        self.conn.send(jsonValueObjectToString(message))
    }

    /// Sets a configuration to the model. Updates the session's current
    /// music generation config.
    public func setMusicGenerationConfig(
        _ params: LiveMusicSetConfigParameters
    ) async throws {
        let paramsDict = try jsonObject(params)
        var parent: [String: JSONValue] = [:]
        let setConfigParameters = try liveMusicSetConfigParametersToMldev(
            apiClient: self.apiClient, fromObject: paramsDict, parentObject: &parent
        )
        self.conn.send(jsonValueObjectToString(setConfigParameters))
    }

    private func sendPlaybackControl(_ playbackControl: LiveMusicPlaybackControl) {
        let message: [String: JSONValue] = [
            "playbackControl": .string(playbackControl.rawValue)
        ]
        self.conn.send(jsonValueObjectToString(message))
    }

    /// Start the music stream.
    ///
    /// @experimental
    public func play() {
        self.sendPlaybackControl(LiveMusicPlaybackControl.play)
    }

    /// Temporarily halt the music stream. Use `play` to resume from the current position.
    ///
    /// @experimental
    public func pause() {
        self.sendPlaybackControl(LiveMusicPlaybackControl.pause)
    }

    /// Stop the music stream and reset the state. Retains the current prompts and config.
    ///
    /// @experimental
    public func stop() {
        self.sendPlaybackControl(LiveMusicPlaybackControl.stop)
    }

    /// Resets the context of the music generation without stopping it.
    /// Retains the current prompts and config.
    ///
    /// @experimental
    public func resetContext() {
        self.sendPlaybackControl(LiveMusicPlaybackControl.resetContext)
    }

    /// Terminates the WebSocket connection.
    ///
    /// @experimental
    public func close() {
        self.conn.close()
    }
}

// MARK: - Internal helpers

/// Handles incoming messages from the WebSocket.
///
/// This function is responsible for parsing incoming messages, transforming them
/// into LiveMusicServerMessage, and then calling the onmessage callback.
private func handleWebSocketMessage(
    apiClient: ApiClient,
    onMessage: @Sendable (LiveMusicServerMessage) -> Void,
    eventData: Data
) async {
    let serverMessage = LiveMusicServerMessage()
    if let decoded = try? JSONDecoder().decode(LiveMusicServerMessage.self, from: eventData) {
        serverMessage.setupComplete = decoded.setupComplete
        serverMessage.serverContent = decoded.serverContent
        serverMessage.filteredPrompt = decoded.filteredPrompt
    }
    onMessage(serverMessage)
}

/// Awaitable one-shot signal used to mirror the JS `Promise` pattern for `onopen`.
private final class AsyncOpenSignal: @unchecked Sendable {
    private let lock = NSLock()
    private var resolved = false
    private var continuations: [CheckedContinuation<Void, Never>] = []

    func resolve() {
        lock.lock()
        let toResume = continuations
        continuations.removeAll()
        resolved = true
        lock.unlock()
        for c in toResume { c.resume() }
    }

    func wait() async {
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            lock.lock()
            if resolved {
                lock.unlock()
                cont.resume()
            } else {
                continuations.append(cont)
                lock.unlock()
            }
        }
    }
}
