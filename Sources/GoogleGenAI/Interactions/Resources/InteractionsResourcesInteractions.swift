// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// The Interactions resource. Mirrors `resources/interactions.ts`.
///
/// The TS file is ~2,900 lines and defines a deeply-nested set of overloaded
/// interface types (Step, StepDelta variants, Tool variants, Usage breakdowns…).
/// The Swift port keeps the runtime behavior — `create`, `delete`, `cancel`,
/// `get`, the `addOutputProperties` post-processor, and the legacy-lyria shim —
/// and exposes the data types as `JSONValue` typealiases. Concrete payloads use
/// `JSONValue` directly so callers can roundtrip through `JSONDecoder` into
/// their own types if desired.
open class BaseInteractions: APIResource, @unchecked Sendable {
    public override class var _key: [String] { return ["interactions"] }

    /// Creates a new interaction. Mirrors `BaseInteractions.create`.
    ///
    /// Pass `stream: true` in `params` to receive an `InteractionsStream` of SSE events;
    /// otherwise the returned promise resolves to a parsed `Interaction` JSON tree.
    public func create(_ params: InteractionCreateParams, options: RequestOptions = RequestOptions()) throws -> APIPromise<JSONValue> {
        let apiVersion = params.api_version ?? _client.apiVersion

        let body = params.toBody()
        // Validate exclusive fields, matching TS guards.
        if case .object(let obj) = body {
            if obj["model"] != nil && obj["agent_config"] != nil {
                throw GeminiNextGenAPIClientError.message(
                    "Invalid request: specified `model` and `agent_config`. If specifying `model`, use `generation_config`."
                )
            }
            if obj["agent"] != nil && obj["generation_config"] != nil {
                throw GeminiNextGenAPIClientError.message(
                    "Invalid request: specified `agent` and `generation_config`. If specifying `agent`, use `agent_config`."
                )
            }
        }

        let needsLegacyLyriaShim = isLegacyLyriaRequest(
            isVertex: isVertexClient(_client),
            model: { if case .object(let o) = body { return o["model"] } else { return nil } }()
        )
        let isStreaming = params.stream ?? false
        let path = try pathTag(statics: ["/", "/interactions"], params: [apiVersion])
        var opts = options
        opts.body = body
        opts.stream = isStreaming
        if needsLegacyLyriaShim && isStreaming {
            opts.streamClass = "LegacyLyriaStream"
        }

        let promise = _client.post(path, options: opts)
        if isStreaming {
            return promise
        }
        return promise.thenUnwrap { data, _ in
            var transformed = needsLegacyLyriaShim ? coerceLegacyInteractionResponse(data) : data
            transformed = addOutputProperties(transformed)
            return transformed
        }
    }

    /// Deletes the interaction by id.
    public func delete(_ id: String, params: InteractionDeleteParams? = nil, options: RequestOptions = RequestOptions()) throws -> APIPromise<JSONValue> {
        let apiVersion = params?.api_version ?? _client.apiVersion
        let path = try pathTag(statics: ["/", "/interactions/", ""], params: [apiVersion, id])
        return _client.delete(path, options: options)
    }

    /// Cancels an interaction by id. Only applies to background interactions still running.
    public func cancel(_ id: String, params: InteractionCancelParams? = nil, options: RequestOptions = RequestOptions()) throws -> APIPromise<JSONValue> {
        let apiVersion = params?.api_version ?? _client.apiVersion
        let path = try pathTag(statics: ["/", "/interactions/", "/cancel"], params: [apiVersion, id])
        return _client.post(path, options: options).thenUnwrap { data, _ in addOutputProperties(data) }
    }

    /// Retrieves the full details of a single interaction.
    public func get(_ id: String, params: InteractionGetParams? = nil, options: RequestOptions = RequestOptions()) throws -> APIPromise<JSONValue> {
        let apiVersion = params?.api_version ?? _client.apiVersion
        var query: [String: JSONValue] = [:]
        if let v = params?.include_input { query["include_input"] = .bool(v) }
        if let v = params?.last_event_id { query["last_event_id"] = .string(v) }
        if let v = params?.stream { query["stream"] = .bool(v) }

        let path = try pathTag(statics: ["/", "/interactions/", ""], params: [apiVersion, id])
        var opts = options
        opts.query = query
        opts.stream = params?.stream ?? false

        let promise = _client.get(path, options: opts)
        if params?.stream == true {
            return promise
        }
        return promise.thenUnwrap { data, _ in addOutputProperties(data) }
    }
}

public final class Interactions: BaseInteractions, @unchecked Sendable {}

/// Scans the steps array on an Interaction and synthesizes
/// `output_text`, `output_image`, `output_audio`, `output_video` properties.
/// Mirrors the file-scope `addOutputProperties` function.
public func addOutputProperties(_ interactionJSON: JSONValue) -> JSONValue {
    guard case .object(var obj) = interactionJSON else { return interactionJSON }
    guard case .array(let steps) = obj["steps"] ?? .null else { return interactionJSON }

    // output_text: scan backwards across all steps (stop at user_input);
    // skip non-text content until the first text item is found, then collect.
    var textParts: [String] = []
    var collecting = false

    outer: for i in stride(from: steps.count - 1, through: 0, by: -1) {
        guard case .object(let step) = steps[i] else { continue }
        if case .string(let t) = step["type"] ?? .null, t == "user_input" { break }
        guard case .string(let t) = step["type"] ?? .null, t == "model_output",
              case .array(let content) = step["content"] ?? .null else {
            if collecting { break outer }
            continue
        }
        for j in stride(from: content.count - 1, through: 0, by: -1) {
            guard case .object(let item) = content[j] else { continue }
            if case .string(let t) = item["type"] ?? .null, t == "text" {
                collecting = true
                if case .string(let s) = item["text"] ?? .null {
                    textParts.append(s)
                } else {
                    textParts.append("")
                }
            } else if collecting {
                break outer
            }
        }
    }
    let outputText = textParts.reversed().joined()

    var outputImage: JSONValue?
    var outputAudio: JSONValue?
    var outputVideo: JSONValue?

    for i in stride(from: steps.count - 1, through: 0, by: -1) {
        guard case .object(let step) = steps[i] else { continue }
        if case .string(let t) = step["type"] ?? .null, t == "user_input" { break }
        guard case .string(let t) = step["type"] ?? .null, t == "model_output",
              case .array(let content) = step["content"] ?? .null else { continue }
        for j in stride(from: content.count - 1, through: 0, by: -1) {
            guard case .object(let item) = content[j] else { continue }
            if case .string(let t) = item["type"] ?? .null {
                if t == "image" && outputImage == nil { outputImage = content[j] }
                if t == "audio" && outputAudio == nil { outputAudio = content[j] }
                if t == "video" && outputVideo == nil { outputVideo = content[j] }
            }
        }
    }

    if !outputText.isEmpty { obj["output_text"] = .string(outputText) }
    if let v = outputImage { obj["output_image"] = v }
    if let v = outputAudio { obj["output_audio"] = v }
    if let v = outputVideo { obj["output_video"] = v }
    return .object(obj)
}

// MARK: - Data types (JSONValue aliases)
//
// The TS file defines ~80 interfaces and unions: AllowedTools, Annotation,
// AudioContent, AudioResponseFormat, CodeExecutionCallArguments,
// CodeExecutionCallStep, CodeExecutionResultStep, Content, DeepResearchAgentConfig,
// DocumentContent, DynamicAgentConfig, Environment, ErrorEvent, FileCitation,
// FileSearchCallStep, FileSearchResultStep, Function, FunctionCallStep,
// FunctionResultStep, GenerationConfig, GoogleMapsCallArguments, GoogleMapsCallStep,
// GoogleMapsResult, GoogleMapsResultStep, GoogleSearchCallArguments,
// GoogleSearchCallStep, GoogleSearchResult, GoogleSearchResultStep, ImageConfig,
// ImageContent, ImageResponseFormat, Interaction, InteractionCompletedEvent,
// InteractionCreatedEvent, InteractionSSEEvent, InteractionStatusUpdate,
// MCPServerToolCallStep, MCPServerToolResultStep, Model, ModelOutputStep,
// PlaceCitation, SpeechConfig, Step, StepDelta (+ ~25 nested variants), StepStart,
// StepStop, TextContent, TextResponseFormat, ThinkingLevel, ThoughtStep, Tool
// (+ 6 nested), ToolChoiceConfig, ToolChoiceType, URLCitation,
// URLContextCallArguments, URLContextCallStep, URLContextResult,
// URLContextResultStep, Usage (+ nested token-by-modality variants),
// UserInputStep, VideoContent, WebhookConfig.
//
// All are exposed as `JSONValue` typealiases. Callers either inspect the JSON
// shape directly or roundtrip through `JSONDecoder` into their own struct.

public typealias AllowedTools = JSONValue
public typealias Annotation = JSONValue
public typealias AudioContent = JSONValue
public typealias AudioResponseFormat = JSONValue
public typealias CodeExecutionCallArguments = JSONValue
public typealias CodeExecutionCallStep = JSONValue
public typealias CodeExecutionResultStep = JSONValue
public typealias InteractionContent = JSONValue
public typealias DeepResearchAgentConfig = JSONValue
public typealias DocumentContent = JSONValue
public typealias DynamicAgentConfig = JSONValue
public typealias InteractionEnvironment = JSONValue
public typealias InteractionErrorEvent = JSONValue
public typealias InteractionFileCitation = JSONValue
public typealias InteractionFileSearchCallStep = JSONValue
public typealias InteractionFileSearchResultStep = JSONValue
public typealias InteractionFunction = JSONValue
public typealias InteractionFunctionCallStep = JSONValue
public typealias InteractionFunctionResultStep = JSONValue
public typealias InteractionGenerationConfig = JSONValue
public typealias InteractionGoogleMapsCallArguments = JSONValue
public typealias InteractionGoogleMapsCallStep = JSONValue
public typealias InteractionGoogleMapsResult = JSONValue
public typealias InteractionGoogleMapsResultStep = JSONValue
public typealias InteractionGoogleSearchCallArguments = JSONValue
public typealias InteractionGoogleSearchCallStep = JSONValue
public typealias InteractionGoogleSearchResult = JSONValue
public typealias InteractionGoogleSearchResultStep = JSONValue
public typealias InteractionImageConfig = JSONValue
public typealias InteractionImageContent = JSONValue
public typealias InteractionImageResponseFormat = JSONValue
public typealias Interaction = JSONValue
public typealias InteractionCompletedEvent = JSONValue
public typealias InteractionCreatedEvent = JSONValue
public typealias InteractionSSEEvent = JSONValue
public typealias InteractionStatusUpdate = JSONValue
public typealias InteractionMCPServerToolCallStep = JSONValue
public typealias InteractionMCPServerToolResultStep = JSONValue

/// Model name. The TS type is a string literal union with an open `string & {}` escape
/// hatch. In Swift this is just a string.
public typealias InteractionModel = String

public typealias InteractionModelOutputStep = JSONValue
public typealias InteractionPlaceCitation = JSONValue
public typealias InteractionSpeechConfig = JSONValue
public typealias InteractionStep = JSONValue
public typealias InteractionStepDelta = JSONValue
public typealias InteractionStepStart = JSONValue
public typealias InteractionStepStop = JSONValue
public typealias InteractionTextContent = JSONValue
public typealias InteractionTextResponseFormat = JSONValue

/// Thinking level.
public enum InteractionThinkingLevel: String, Sendable, Codable { case minimal, low, medium, high }

public typealias InteractionThoughtStep = JSONValue
public typealias InteractionTool = JSONValue
public typealias InteractionToolChoiceConfig = JSONValue
public typealias InteractionToolChoiceType = String  // "auto" | "any" | "none" | "validated"
public typealias InteractionURLCitation = JSONValue
public typealias InteractionURLContextCallArguments = JSONValue
public typealias InteractionURLContextCallStep = JSONValue
public typealias InteractionURLContextResult = JSONValue
public typealias InteractionURLContextResultStep = JSONValue
public typealias InteractionUsage = JSONValue
public typealias InteractionUserInputStep = JSONValue
public typealias InteractionVideoContent = JSONValue
public typealias InteractionWebhookConfig = JSONValue

public typealias InteractionDeleteResponse = JSONValue

// MARK: - Param types

/// Union of all interaction create params. Mirrors `InteractionCreateParams`.
public struct InteractionCreateParams: Sendable {
    public var api_version: String?
    /// The model name (mutually exclusive with `agent`).
    public var model: String?
    /// The agent name (mutually exclusive with `model`).
    public var agent: String?
    /// The input — string, list of steps/content, or single content block.
    public var input: JSONValue
    /// Whether to stream the response.
    public var stream: Bool?
    /// Whether to run in the background.
    public var background: Bool?
    public var environment: JSONValue?
    public var generation_config: JSONValue?
    public var agent_config: JSONValue?
    public var previous_interaction_id: String?
    public var response_format: JSONValue?
    public var response_mime_type: String?
    public var response_modalities: [String]?
    public var service_tier: String?
    public var store: Bool?
    public var system_instruction: String?
    public var tools: [JSONValue]?
    public var webhook_config: JSONValue?
    /// Free-form additional fields to merge into the request body.
    public var extra: [String: JSONValue]?

    public init(
        api_version: String? = nil,
        model: String? = nil,
        agent: String? = nil,
        input: JSONValue,
        stream: Bool? = nil,
        background: Bool? = nil,
        environment: JSONValue? = nil,
        generation_config: JSONValue? = nil,
        agent_config: JSONValue? = nil,
        previous_interaction_id: String? = nil,
        response_format: JSONValue? = nil,
        response_mime_type: String? = nil,
        response_modalities: [String]? = nil,
        service_tier: String? = nil,
        store: Bool? = nil,
        system_instruction: String? = nil,
        tools: [JSONValue]? = nil,
        webhook_config: JSONValue? = nil,
        extra: [String: JSONValue]? = nil
    ) {
        self.api_version = api_version
        self.model = model
        self.agent = agent
        self.input = input
        self.stream = stream
        self.background = background
        self.environment = environment
        self.generation_config = generation_config
        self.agent_config = agent_config
        self.previous_interaction_id = previous_interaction_id
        self.response_format = response_format
        self.response_mime_type = response_mime_type
        self.response_modalities = response_modalities
        self.service_tier = service_tier
        self.store = store
        self.system_instruction = system_instruction
        self.tools = tools
        self.webhook_config = webhook_config
        self.extra = extra
    }

    func toBody() -> JSONValue {
        var obj: [String: JSONValue] = [:]
        if let m = model { obj["model"] = .string(m) }
        if let a = agent { obj["agent"] = .string(a) }
        obj["input"] = input
        if let v = stream { obj["stream"] = .bool(v) }
        if let v = background { obj["background"] = .bool(v) }
        if let v = environment { obj["environment"] = v }
        if let v = generation_config { obj["generation_config"] = v }
        if let v = agent_config { obj["agent_config"] = v }
        if let v = previous_interaction_id { obj["previous_interaction_id"] = .string(v) }
        if let v = response_format { obj["response_format"] = v }
        if let v = response_mime_type { obj["response_mime_type"] = .string(v) }
        if let v = response_modalities { obj["response_modalities"] = .array(v.map { .string($0) }) }
        if let v = service_tier { obj["service_tier"] = .string(v) }
        if let v = store { obj["store"] = .bool(v) }
        if let v = system_instruction { obj["system_instruction"] = .string(v) }
        if let v = tools { obj["tools"] = .array(v) }
        if let v = webhook_config { obj["webhook_config"] = v }
        if let extra = extra {
            for (k, v) in extra { obj[k] = v }
        }
        return .object(obj)
    }
}

public typealias BaseCreateModelInteractionParams = InteractionCreateParams
public typealias BaseCreateAgentInteractionParams = InteractionCreateParams
public typealias CreateModelInteractionParamsNonStreaming = InteractionCreateParams
public typealias CreateModelInteractionParamsStreaming = InteractionCreateParams
public typealias CreateAgentInteractionParamsNonStreaming = InteractionCreateParams
public typealias CreateAgentInteractionParamsStreaming = InteractionCreateParams

public struct InteractionDeleteParams: Sendable {
    public var api_version: String?
    public init(api_version: String? = nil) { self.api_version = api_version }
}

public struct InteractionCancelParams: Sendable {
    public var api_version: String?
    public init(api_version: String? = nil) { self.api_version = api_version }
}

public struct InteractionGetParams: Sendable {
    public var api_version: String?
    public var include_input: Bool?
    public var last_event_id: String?
    public var stream: Bool?
    public init(api_version: String? = nil, include_input: Bool? = nil, last_event_id: String? = nil, stream: Bool? = nil) {
        self.api_version = api_version
        self.include_input = include_input
        self.last_event_id = last_event_id
        self.stream = stream
    }
}

public typealias InteractionGetParamsBase = InteractionGetParams
public typealias InteractionGetParamsNonStreaming = InteractionGetParams
public typealias InteractionGetParamsStreaming = InteractionGetParams
