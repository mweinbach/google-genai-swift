// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Constants

private let FUNCTION_RESPONSE_REQUIRES_ID =
    "FunctionResponse request must have an `id` field from the response of a ToolCall.FunctionalCalls in Google AI."

// MARK: - Live class

/// Live class encapsulates the configuration for live interaction with the
/// Generative Language API. Ports `Live` from `src/live.ts`.
///
/// Concurrency: holds a websocket task, so it is `@unchecked Sendable`.
public final class Live: BaseModule, @unchecked Sendable {
    private let apiClient: ApiClient
    private let auth: Auth
    private let webSocketFactory: WebSocketFactory

    public init(
        apiClient: ApiClient,
        auth: Auth,
        webSocketFactory: WebSocketFactory = URLSessionWebSocketFactory()
    ) {
        self.apiClient = apiClient
        self.auth = auth
        self.webSocketFactory = webSocketFactory
        super.init()
    }

    /// Establishes a connection to the specified model with the given configuration and returns
    /// a `Session` object representing that connection. Ports `Live.connect` in `src/live.ts`.
    public func connect(_ params: LiveConnectParameters) async throws -> Session {
        // TODO: b/404946746 - Support per request HTTP options.
        if params.config?.httpOptions != nil {
            throw GenAIError.invalidArgument(
                "The Live module does not support httpOptions at request-level in" +
                " LiveConnectConfig yet. Please use the client-level httpOptions" +
                " configuration instead."
            )
        }

        let websocketBaseUrl = try self.apiClient.getWebsocketBaseUrl()
        let apiVersion = try self.apiClient.getApiVersion()
        let clientHeaders = try self.apiClient.getHeaders()

        // MCP-tool detection: not yet ported (Wave 5 — mcp/_mcp.ts).
        // When that lands, call hasMcpToolUsage/setMcpUsageHeader here.

        var headers: [String: String] = clientHeaders
        let url: String

        if self.apiClient.isVertexAI() {
            let project = self.apiClient.getProject()
            let location = self.apiClient.getLocation()
            let apiKey = self.apiClient.getApiKey()
            let hasStandardAuth = ((project != nil) && (location != nil)) || (apiKey != nil)

            if self.apiClient.getCustomBaseUrl() != nil && !hasStandardAuth {
                // Custom base URL without standard auth (e.g., proxy).
                url = websocketBaseUrl
            } else {
                url = "\(websocketBaseUrl)/ws/google.cloud.aiplatform.\(apiVersion).LlmBidiService/BidiGenerateContent"
                try await self.auth.addAuthHeaders(&headers, url: url)
            }
        } else {
            let apiKey = self.apiClient.getApiKey()
            var method = "BidiGenerateContent"
            var keyName = "key"
            if let apiKey = apiKey, apiKey.hasPrefix("auth_tokens/") {
                print("Warning: Ephemeral token support is experimental and may change in future versions.")
                if apiVersion != "v1alpha" {
                    print("Warning: The SDK's ephemeral token support is in v1alpha only. Please use GoogleGenAIOptions(apiKey: token.name, httpOptions: HttpOptions(apiVersion: \"v1alpha\")) before session connection.")
                }
                method = "BidiGenerateContentConstrained"
                keyName = "access_token"
            }
            url = "\(websocketBaseUrl)/ws/google.ai.generativelanguage.\(apiVersion).GenerativeService.\(method)?\(keyName)=\(apiKey ?? "")"
        }

        // Translate `tools` callable resolution before constructing the setup message.
        // Mirrors TS: `await callableTool.tool()` for any CallableTool entries.
        var convertedTools: [Tool] = []
        if let inputTools = params.config?.tools {
            for tool in inputTools {
                switch tool {
                case .callable(let callable):
                    convertedTools.append(try await callable.tool())
                case .tool(let t):
                    convertedTools.append(t)
                }
            }
        }

        // Bridge transport-layer callbacks (WebSocketCallbacks) to user-supplied LiveCallbacks.
        let callbacks = params.callbacks
        let apiClient = self.apiClient

        // Continuation used to await `onopen` before sending the setup message.
        let onOpenStream = AsyncThrowingStream<Void, Error>.makeStream()

        let wsCallbacks = WebSocketCallbacks(
            onOpen: { @Sendable in
                callbacks.onOpen?()
                onOpenStream.continuation.yield(())
                onOpenStream.continuation.finish()
            },
            onMessage: { @Sendable rawMessage in
                Self.handleIncomingMessage(
                    rawMessage,
                    apiClient: apiClient,
                    onMessage: callbacks.onMessage
                )
            },
            onError: { @Sendable err in
                callbacks.onError?(err)
            },
            onClose: { @Sendable _, _ in
                callbacks.onClose?(nil)
            }
        )

        let conn = self.webSocketFactory.create(url: url, headers: headers, callbacks: wsCallbacks)
        conn.connect()
        // Wait for the websocket to open before sending requests.
        for try await _ in onOpenStream.stream { break }

        // Resolve the model name (with Vertex projects/locations prefixing).
        var transformedModel = try tModel(apiClient: self.apiClient, model: params.model)
        if self.apiClient.isVertexAI() && transformedModel.hasPrefix("publishers/") {
            if let project = self.apiClient.getProject(), let location = self.apiClient.getLocation() {
                transformedModel = "projects/\(project)/locations/\(location)/" + transformedModel
            }
        }

        // Apply Vertex-default `responseModalities = [AUDIO]` if missing, deprecation-warn
        // on generationConfig, and substitute the resolved tools list.
        var liveConfig = params.config
        if self.apiClient.isVertexAI() && liveConfig?.responseModalities == nil {
            if liveConfig == nil {
                liveConfig = LiveConnectConfig(responseModalities: [.audio])
            } else {
                liveConfig?.responseModalities = [.audio]
            }
        }
        if liveConfig?.generationConfig != nil {
            print("Setting `LiveConnectConfig.generation_config` is deprecated, please set the fields on `LiveConnectConfig` directly. This will become an error in a future version (not before Q3 2025).")
        }
        if !convertedTools.isEmpty {
            liveConfig?.tools = convertedTools.map { ToolUnion.tool($0) }
        }

        let liveConnectParameters = LiveConnectParameters(
            model: transformedModel,
            callbacks: params.callbacks,
            config: liveConfig
        )

        // Build the on-the-wire setup message via the Wave-5 converters.
        let paramsJson = try Self.liveConnectParametersToJson(liveConnectParameters)
        var clientMessage: [String: JSONValue]
        var parent: [String: JSONValue] = [:]
        if self.apiClient.isVertexAI() {
            clientMessage = try liveConnectParametersToVertex(
                apiClient: self.apiClient,
                fromObject: paramsJson,
                parentObject: &parent
            )
        } else {
            clientMessage = try liveConnectParametersToMldev(
                apiClient: self.apiClient,
                fromObject: paramsJson,
                parentObject: &parent
            )
        }
        clientMessage.removeValue(forKey: "config")

        let payload = try JSONEncoder().encode(JSONValue.object(clientMessage))
        let payloadString = String(data: payload, encoding: .utf8) ?? "{}"
        try conn.send(payloadString)

        return Session(conn: conn, apiClient: self.apiClient)
    }

    // MARK: - Incoming message handling

    private static func handleIncomingMessage(
        _ raw: String,
        apiClient: ApiClient,
        onMessage: @escaping @Sendable (LiveServerMessage) -> Void
    ) {
        guard let data = raw.data(using: .utf8) else { return }

        let serverMessage = LiveServerMessage()
        if apiClient.isVertexAI() {
            // Run the Vertex translator (Wave 5) and decode the resulting JSON shape.
            if let raw = try? JSONDecoder().decode([String: JSONValue].self, from: data) {
                var parent: [String: JSONValue] = [:]
                if let mapped = try? liveServerMessageFromVertex(
                    apiClient: apiClient,
                    fromObject: raw,
                    parentObject: &parent
                ) {
                    if let decoded = Self.tryDecodeServerMessage(mapped) {
                        Self.copy(serverMessage, from: decoded)
                    }
                }
            }
        } else {
            if let decoded = try? JSONDecoder().decode(LiveServerMessage.self, from: data) {
                Self.copy(serverMessage, from: decoded)
            }
        }
        onMessage(serverMessage)
    }

    private static func tryDecodeServerMessage(_ json: [String: JSONValue]) -> LiveServerMessage? {
        guard let data = try? JSONEncoder().encode(JSONValue.object(json)) else { return nil }
        return try? JSONDecoder().decode(LiveServerMessage.self, from: data)
    }

    private static func copy(_ dest: LiveServerMessage, from src: LiveServerMessage) {
        dest.setupComplete = src.setupComplete
        dest.serverContent = src.serverContent
        dest.toolCall = src.toolCall
        dest.toolCallCancellation = src.toolCallCancellation
        dest.usageMetadata = src.usageMetadata
        dest.goAway = src.goAway
        dest.sessionResumptionUpdate = src.sessionResumptionUpdate
        dest.voiceActivityDetectionSignal = src.voiceActivityDetectionSignal
        dest.voiceActivity = src.voiceActivity
    }

    // MARK: - JSON encoding helpers for LiveConnectParameters

    /// `LiveConnectParameters` and `LiveConnectConfig` are not Codable (their nested
    /// fields contain `LiveCallbacks` / `AbortSignal`). To feed them through the
    /// `liveConnectParametersTo{Mldev,Vertex}` converters (which work on JSON) we
    /// hand-roll a JSON projection.
    fileprivate static func liveConnectParametersToJson(_ params: LiveConnectParameters) throws -> [String: JSONValue] {
        var obj: [String: JSONValue] = ["model": .string(params.model)]
        if let config = params.config {
            obj["config"] = .object(try liveConnectConfigToJson(config))
        }
        return obj
    }

    fileprivate static func liveConnectConfigToJson(_ config: LiveConnectConfig) throws -> [String: JSONValue] {
        var out: [String: JSONValue] = [:]
        if let v = config.generationConfig { out["generationConfig"] = try roundTrip(v) }
        if let v = config.responseModalities { out["responseModalities"] = try roundTrip(v) }
        if let v = config.temperature { out["temperature"] = .double(v) }
        if let v = config.topP { out["topP"] = .double(v) }
        if let v = config.topK { out["topK"] = .double(v) }
        if let v = config.maxOutputTokens { out["maxOutputTokens"] = .double(v) }
        if let v = config.mediaResolution { out["mediaResolution"] = try roundTrip(v) }
        if let v = config.seed { out["seed"] = .double(v) }
        if let v = config.speechConfig { out["speechConfig"] = try roundTrip(v) }
        if let v = config.thinkingConfig { out["thinkingConfig"] = try roundTrip(v) }
        if let v = config.enableAffectiveDialog { out["enableAffectiveDialog"] = .bool(v) }
        if let v = config.systemInstruction { out["systemInstruction"] = try roundTrip(v) }
        if let v = config.tools { out["tools"] = try roundTrip(v) }
        if let v = config.sessionResumption { out["sessionResumption"] = try roundTrip(v) }
        if let v = config.inputAudioTranscription { out["inputAudioTranscription"] = try roundTrip(v) }
        if let v = config.outputAudioTranscription { out["outputAudioTranscription"] = try roundTrip(v) }
        if let v = config.realtimeInputConfig { out["realtimeInputConfig"] = try roundTrip(v) }
        if let v = config.contextWindowCompression { out["contextWindowCompression"] = try roundTrip(v) }
        if let v = config.proactivity { out["proactivity"] = try roundTrip(v) }
        if let v = config.explicitVadSignal { out["explicitVadSignal"] = .bool(v) }
        if let v = config.avatarConfig { out["avatarConfig"] = try roundTrip(v) }
        if let v = config.safetySettings { out["safetySettings"] = try roundTrip(v) }
        if let v = config.streamTranslationConfig { out["streamTranslationConfig"] = try roundTrip(v) }
        return out
    }

    fileprivate static func roundTrip<T: Encodable>(_ value: T) throws -> JSONValue {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(JSONValue.self, from: data)
    }
}

// MARK: - Session

/// Represents an established connection to the live API. Ports `Session` in `src/live.ts`.
public final class Session: @unchecked Sendable {
    /// Public read-only access to the underlying websocket connection.
    public let conn: WebSocketClient
    private let apiClient: ApiClient

    public init(conn: WebSocketClient, apiClient: ApiClient) {
        self.conn = conn
        self.apiClient = apiClient
    }

    // MARK: - sendClientContent

    /// Send a message over the established connection. Mirrors `sendClientContent` in TS.
    public func sendClientContent(_ params: LiveSendClientContentParameters) throws {
        // Default to turnComplete=true to match the TS default.
        var resolved = params
        if resolved.turnComplete == nil {
            resolved.turnComplete = true
        }
        let clientMessage = try self.tLiveClientContent(apiClient: self.apiClient, params: resolved)
        let encoded = try Self.encode(clientMessage)
        try self.conn.send(encoded)
    }

    // MARK: - sendRealtimeInput

    /// Send a realtime input over the established connection. Mirrors `sendRealtimeInput` in TS.
    public func sendRealtimeInput(_ params: LiveSendRealtimeInputParameters) throws {
        let json = try Self.realtimeInputParametersToJson(params)
        var parent: [String: JSONValue] = [:]
        let realtime: [String: JSONValue]
        if self.apiClient.isVertexAI() {
            realtime = try liveSendRealtimeInputParametersToVertex(
                apiClient: self.apiClient,
                fromObject: json,
                parentObject: &parent
            )
        } else {
            realtime = try liveSendRealtimeInputParametersToMldev(
                apiClient: self.apiClient,
                fromObject: json,
                parentObject: &parent
            )
        }
        let clientMessage: [String: JSONValue] = ["realtimeInput": .object(realtime)]
        let data = try JSONEncoder().encode(JSONValue.object(clientMessage))
        let encoded = String(data: data, encoding: .utf8) ?? "{}"
        try self.conn.send(encoded)
    }

    // MARK: - sendToolResponse

    /// Send a function response message over the established connection. Mirrors
    /// `sendToolResponse` in TS.
    public func sendToolResponse(_ params: LiveSendToolResponseParameters) throws {
        if params.functionResponses.isEmpty {
            throw GenAIError.invalidArgument("Tool response parameters are required.")
        }
        let clientMessage = try self.tLiveClientToolResponse(apiClient: self.apiClient, params: params)
        let encoded = try Self.encode(clientMessage)
        try self.conn.send(encoded)
    }

    /// Terminates the WebSocket connection. Mirrors `Session.close()` in TS.
    public func close() {
        self.conn.close()
    }

    // MARK: - tLiveClientContent (private)

    private func tLiveClientContent(
        apiClient: ApiClient,
        params: LiveSendClientContentParameters
    ) throws -> LiveClientMessage {
        if let turnsUnion = params.turns {
            var contents: [Content]
            do {
                contents = try tContents(turnsUnion)
                if !apiClient.isVertexAI() {
                    contents = try contents.map {
                        try Self.contentThroughMldev(apiClient: apiClient, content: $0)
                    }
                }
            } catch {
                let typeName = String(describing: type(of: turnsUnion))
                throw GenAIError.invalidArgument(
                    "Failed to parse client content \"turns\", type: '\(typeName)'"
                )
            }
            return LiveClientMessage(
                clientContent: LiveClientContent(turns: contents, turnComplete: params.turnComplete)
            )
        }
        return LiveClientMessage(
            clientContent: LiveClientContent(turnComplete: params.turnComplete)
        )
    }

    /// Wraps `CachesConverters.contentToMldev` — the only `contentToMldev` we have today.
    private static func contentThroughMldev(apiClient: ApiClient, content: Content) throws -> Content {
        let asData = try JSONEncoder().encode(content)
        guard let asValue = try? JSONDecoder().decode(JSONValue.self, from: asData),
              case .object(let obj) = asValue else {
            return content
        }
        var parent: [String: JSONValue] = [:]
        let converted = try contentToMldev(
            apiClient: apiClient, fromObject: obj, parentObject: &parent
        )
        let outData = try JSONEncoder().encode(JSONValue.object(converted))
        return try JSONDecoder().decode(Content.self, from: outData)
    }

    // MARK: - tLiveClientToolResponse (private)

    private func tLiveClientToolResponse(
        apiClient: ApiClient,
        params: LiveSendToolResponseParameters
    ) throws -> LiveClientMessage {
        let functionResponses = params.functionResponses
        if functionResponses.isEmpty {
            throw GenAIError.invalidArgument("functionResponses is required.")
        }
        for fr in functionResponses {
            if fr.name == nil || fr.response == nil {
                throw GenAIError.invalidArgument("Could not parse function response.")
            }
            if !apiClient.isVertexAI() && fr.id == nil {
                throw GenAIError.invalidArgument(FUNCTION_RESPONSE_REQUIRES_ID)
            }
        }
        return LiveClientMessage(
            toolResponse: LiveClientToolResponse(functionResponses: functionResponses)
        )
    }

    // MARK: - LiveClientMessage encoding

    /// Hand-rolled JSON encoder for `LiveClientMessage`. The struct's `setup` field carries
    /// non-Codable types (CallableTool), so we serialise only the populated wire branches
    /// the caller exercises (clientContent / realtimeInput / toolResponse).
    private static func encode(_ msg: LiveClientMessage) throws -> String {
        var root: [String: JSONValue] = [:]
        if let content = msg.clientContent {
            let data = try JSONEncoder().encode(content)
            if let v = try? JSONDecoder().decode(JSONValue.self, from: data) {
                root["clientContent"] = v
            }
        }
        if let realtime = msg.realtimeInput {
            let data = try JSONEncoder().encode(realtime)
            if let v = try? JSONDecoder().decode(JSONValue.self, from: data) {
                root["realtimeInput"] = v
            }
        }
        if let toolResponse = msg.toolResponse {
            let data = try JSONEncoder().encode(toolResponse)
            if let v = try? JSONDecoder().decode(JSONValue.self, from: data) {
                root["toolResponse"] = v
            }
        }
        let data = try JSONEncoder().encode(JSONValue.object(root))
        return String(data: data, encoding: .utf8) ?? "{}"
    }

    // MARK: - JSON projection of LiveSendRealtimeInputParameters

    fileprivate static func realtimeInputParametersToJson(
        _ params: LiveSendRealtimeInputParameters
    ) throws -> [String: JSONValue] {
        var out: [String: JSONValue] = [:]
        if let v = params.media { out["media"] = try Live.roundTrip(v) }
        if let v = params.audio { out["audio"] = try Live.roundTrip(v) }
        if let v = params.audioStreamEnd { out["audioStreamEnd"] = .bool(v) }
        if let v = params.video { out["video"] = try Live.roundTrip(v) }
        if let v = params.text { out["text"] = .string(v) }
        if let v = params.activityStart { out["activityStart"] = try Live.roundTrip(v) }
        if let v = params.activityEnd { out["activityEnd"] = try Live.roundTrip(v) }
        return out
    }
}

// MARK: - AsyncThrowingStream.makeStream backport

#if compiler(<5.9)
extension AsyncThrowingStream {
    static func makeStream(
        of elementType: Element.Type = Element.self,
        throwing failureType: Failure.Type = Failure.self,
        bufferingPolicy limit: Continuation.BufferingPolicy = .unbounded
    ) -> (stream: AsyncThrowingStream<Element, Failure>, continuation: AsyncThrowingStream<Element, Failure>.Continuation) {
        var continuation: AsyncThrowingStream<Element, Failure>.Continuation!
        let stream = AsyncThrowingStream(elementType, bufferingPolicy: limit) { continuation = $0 }
        return (stream, continuation)
    }
}
#endif
