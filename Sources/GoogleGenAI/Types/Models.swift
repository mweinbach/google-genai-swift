// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Optional parameters for models.get method.
public struct GetModelConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    public var abortSignal: AbortSignal?

    public init(httpOptions: HttpOptions? = nil, abortSignal: AbortSignal? = nil) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

public struct GetModelParameters: Codable, Sendable {
    public var model: String
    /// Optional parameters for the request.
    public var config: GetModelConfig?

    public init(model: String, config: GetModelConfig? = nil) {
        self.model = model
        self.config = config
    }
}

/// An endpoint where you deploy models.
public struct Endpoint: Codable, Sendable {
    /// Resource name of the endpoint.
    public var name: String?
    /// ID of the model that's deployed to the endpoint.
    public var deployedModelId: String?

    public init(name: String? = nil, deployedModelId: String? = nil) {
        self.name = name
        self.deployedModelId = deployedModelId
    }
}

/// A tuned machine learning model.
public struct TunedModelInfo: Codable, Sendable {
    /// ID of the base model that you want to tune.
    public var baseModel: String?
    /// Date and time when the base model was created.
    public var createTime: String?
    /// Date and time when the base model was last updated.
    public var updateTime: String?

    public init(
        baseModel: String? = nil,
        createTime: String? = nil,
        updateTime: String? = nil
    ) {
        self.baseModel = baseModel
        self.createTime = createTime
        self.updateTime = updateTime
    }
}

/// Describes the machine learning model version checkpoint.
public struct Checkpoint: Codable, Sendable {
    /// The ID of the checkpoint.
    public var checkpointId: String?
    /// The epoch of the checkpoint.
    public var epoch: String?
    /// The step of the checkpoint.
    public var step: String?

    public init(checkpointId: String? = nil, epoch: String? = nil, step: String? = nil) {
        self.checkpointId = checkpointId
        self.epoch = epoch
        self.step = step
    }
}

/// A trained machine learning model.
public struct Model: Codable, Sendable {
    /// Resource name of the model.
    public var name: String?
    /// Display name of the model.
    public var displayName: String?
    /// Description of the model.
    public var description: String?
    /// Version ID of the model.
    public var version: String?
    /// List of deployed models created from this base model.
    public var endpoints: [Endpoint]?
    /// Labels with user-defined metadata to organize your models.
    public var labels: [String: String]?
    /// Information about the tuned model from the base model.
    public var tunedModelInfo: TunedModelInfo?
    /// The maximum number of input tokens that the model can handle.
    public var inputTokenLimit: Double?
    /// The maximum number of output tokens that the model can generate.
    public var outputTokenLimit: Double?
    /// List of actions that are supported by the model.
    public var supportedActions: [String]?
    /// The default checkpoint id of a model version.
    public var defaultCheckpointId: String?
    /// The checkpoints of the model.
    public var checkpoints: [Checkpoint]?
    /// Temperature value used for sampling set when the dataset was saved.
    public var temperature: Double?
    /// The maximum temperature value used for sampling set when the dataset was saved.
    public var maxTemperature: Double?
    /// Optional. Specifies the nucleus sampling threshold.
    public var topP: Double?
    /// Optional. Specifies the top-k sampling threshold.
    public var topK: Double?
    /// Whether the model supports thinking features.
    public var thinking: Bool?

    public init(
        name: String? = nil,
        displayName: String? = nil,
        description: String? = nil,
        version: String? = nil,
        endpoints: [Endpoint]? = nil,
        labels: [String: String]? = nil,
        tunedModelInfo: TunedModelInfo? = nil,
        inputTokenLimit: Double? = nil,
        outputTokenLimit: Double? = nil,
        supportedActions: [String]? = nil,
        defaultCheckpointId: String? = nil,
        checkpoints: [Checkpoint]? = nil,
        temperature: Double? = nil,
        maxTemperature: Double? = nil,
        topP: Double? = nil,
        topK: Double? = nil,
        thinking: Bool? = nil
    ) {
        self.name = name
        self.displayName = displayName
        self.description = description
        self.version = version
        self.endpoints = endpoints
        self.labels = labels
        self.tunedModelInfo = tunedModelInfo
        self.inputTokenLimit = inputTokenLimit
        self.outputTokenLimit = outputTokenLimit
        self.supportedActions = supportedActions
        self.defaultCheckpointId = defaultCheckpointId
        self.checkpoints = checkpoints
        self.temperature = temperature
        self.maxTemperature = maxTemperature
        self.topP = topP
        self.topK = topK
        self.thinking = thinking
    }
}

public struct ListModelsConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    public var abortSignal: AbortSignal?
    public var pageSize: Double?
    public var pageToken: String?
    public var filter: String?
    /// Set true to list base models, false to list tuned models.
    public var queryBase: Bool?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        pageSize: Double? = nil,
        pageToken: String? = nil,
        filter: String? = nil,
        queryBase: Bool? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.pageSize = pageSize
        self.pageToken = pageToken
        self.filter = filter
        self.queryBase = queryBase
    }
}

public struct ListModelsParameters: Codable, Sendable {
    public var config: ListModelsConfig?

    public init(config: ListModelsConfig? = nil) {
        self.config = config
    }
}

public final class ListModelsResponse: Codable, @unchecked Sendable {
    /// Used to retain the full HTTP response.
    public var sdkHttpResponse: HttpResponse?
    public var nextPageToken: String?
    public var models: [Model]?

    public init(
        sdkHttpResponse: HttpResponse? = nil,
        nextPageToken: String? = nil,
        models: [Model]? = nil
    ) {
        self.sdkHttpResponse = sdkHttpResponse
        self.nextPageToken = nextPageToken
        self.models = models
    }
}

/// Configuration for updating a tuned model.
public struct UpdateModelConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    public var abortSignal: AbortSignal?
    public var displayName: String?
    public var description: String?
    public var defaultCheckpointId: String?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        displayName: String? = nil,
        description: String? = nil,
        defaultCheckpointId: String? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.displayName = displayName
        self.description = description
        self.defaultCheckpointId = defaultCheckpointId
    }
}

/// Configuration for updating a tuned model.
public struct UpdateModelParameters: Codable, Sendable {
    public var model: String
    public var config: UpdateModelConfig?

    public init(model: String, config: UpdateModelConfig? = nil) {
        self.model = model
        self.config = config
    }
}

/// Configuration for deleting a tuned model.
public struct DeleteModelConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    public var abortSignal: AbortSignal?

    public init(httpOptions: HttpOptions? = nil, abortSignal: AbortSignal? = nil) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

/// Parameters for deleting a tuned model.
public struct DeleteModelParameters: Codable, Sendable {
    public var model: String
    /// Optional parameters for the request.
    public var config: DeleteModelConfig?

    public init(model: String, config: DeleteModelConfig? = nil) {
        self.model = model
        self.config = config
    }
}

public final class DeleteModelResponse: Codable, @unchecked Sendable {
    /// Used to retain the full HTTP response.
    public var sdkHttpResponse: HttpResponse?

    public init(sdkHttpResponse: HttpResponse? = nil) {
        self.sdkHttpResponse = sdkHttpResponse
    }
}

/// Generation config.
public struct GenerationConfig: Codable, Sendable {
    /// Optional. Config for model selection.
    public var modelSelectionConfig: ModelSelectionConfig?
    /// Output schema of the generated response.
    public var responseJsonSchema: JSONValue?
    /// Optional. If enabled, audio timestamps will be included in the request to the model.
    public var audioTimestamp: Bool?
    /// Optional. The number of candidate responses to generate.
    public var candidateCount: Double?
    /// Optional. If enabled, the model will detect emotions and adapt its responses accordingly.
    public var enableAffectiveDialog: Bool?
    /// Optional. Penalizes tokens based on their frequency in the generated text.
    public var frequencyPenalty: Double?
    /// Optional. The number of top log probabilities to return for each token.
    public var logprobs: Double?
    /// Optional. The maximum number of tokens to generate in the response.
    public var maxOutputTokens: Double?
    /// Optional. The token resolution at which input media content is sampled.
    public var mediaResolution: MediaResolution?
    /// Optional. Penalizes tokens that have already appeared in the generated text.
    public var presencePenalty: Double?
    /// Optional. If set to true, the log probabilities of the output tokens are returned.
    public var responseLogprobs: Bool?
    /// Optional. The IANA standard MIME type of the response.
    public var responseMimeType: String?
    /// Optional. The modalities of the response.
    public var responseModalities: [Modality]?
    /// Optional. Lets you specify a schema for the model's response.
    public var responseSchema: Schema?
    /// Optional. Routing configuration.
    public var routingConfig: GenerationConfigRoutingConfig?
    /// Optional. A seed for the random number generator.
    public var seed: Double?
    /// Optional. The speech generation config.
    public var speechConfig: SpeechConfig?
    /// Optional. A list of character sequences that will stop the model from generating further tokens.
    public var stopSequences: [String]?
    /// Optional. Controls the randomness of the output.
    public var temperature: Double?
    /// Optional. Configuration for thinking features.
    public var thinkingConfig: ThinkingConfig?
    /// Optional. Specifies the top-k sampling threshold.
    public var topK: Double?
    /// Optional. Specifies the nucleus sampling threshold.
    public var topP: Double?
    /// Optional. Enables enhanced civic answers.
    public var enableEnhancedCivicAnswers: Bool?

    public init(
        modelSelectionConfig: ModelSelectionConfig? = nil,
        responseJsonSchema: JSONValue? = nil,
        audioTimestamp: Bool? = nil,
        candidateCount: Double? = nil,
        enableAffectiveDialog: Bool? = nil,
        frequencyPenalty: Double? = nil,
        logprobs: Double? = nil,
        maxOutputTokens: Double? = nil,
        mediaResolution: MediaResolution? = nil,
        presencePenalty: Double? = nil,
        responseLogprobs: Bool? = nil,
        responseMimeType: String? = nil,
        responseModalities: [Modality]? = nil,
        responseSchema: Schema? = nil,
        routingConfig: GenerationConfigRoutingConfig? = nil,
        seed: Double? = nil,
        speechConfig: SpeechConfig? = nil,
        stopSequences: [String]? = nil,
        temperature: Double? = nil,
        thinkingConfig: ThinkingConfig? = nil,
        topK: Double? = nil,
        topP: Double? = nil,
        enableEnhancedCivicAnswers: Bool? = nil
    ) {
        self.modelSelectionConfig = modelSelectionConfig
        self.responseJsonSchema = responseJsonSchema
        self.audioTimestamp = audioTimestamp
        self.candidateCount = candidateCount
        self.enableAffectiveDialog = enableAffectiveDialog
        self.frequencyPenalty = frequencyPenalty
        self.logprobs = logprobs
        self.maxOutputTokens = maxOutputTokens
        self.mediaResolution = mediaResolution
        self.presencePenalty = presencePenalty
        self.responseLogprobs = responseLogprobs
        self.responseMimeType = responseMimeType
        self.responseModalities = responseModalities
        self.responseSchema = responseSchema
        self.routingConfig = routingConfig
        self.seed = seed
        self.speechConfig = speechConfig
        self.stopSequences = stopSequences
        self.temperature = temperature
        self.thinkingConfig = thinkingConfig
        self.topK = topK
        self.topP = topP
        self.enableEnhancedCivicAnswers = enableEnhancedCivicAnswers
    }
}

/// Config for the count_tokens method.
public struct CountTokensConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    public var abortSignal: AbortSignal?
    /// Instructions for the model to steer it toward better performance.
    public var systemInstruction: ContentUnion?
    /// Code that enables the system to interact with external systems to perform an action outside of the knowledge and scope of the model.
    public var tools: [Tool]?
    /// Configuration that the model uses to generate the response. Not supported by the Gemini Developer API.
    public var generationConfig: GenerationConfig?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        systemInstruction: ContentUnion? = nil,
        tools: [Tool]? = nil,
        generationConfig: GenerationConfig? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.systemInstruction = systemInstruction
        self.tools = tools
        self.generationConfig = generationConfig
    }
}

/// Parameters for counting tokens.
public struct CountTokensParameters: Codable, Sendable {
    /// ID of the model to use.
    public var model: String
    /// Input content.
    public var contents: ContentListUnion
    /// Configuration for counting tokens.
    public var config: CountTokensConfig?

    public init(
        model: String,
        contents: ContentListUnion,
        config: CountTokensConfig? = nil
    ) {
        self.model = model
        self.contents = contents
        self.config = config
    }
}

/// Response for counting tokens.
public final class CountTokensResponse: Codable, @unchecked Sendable {
    /// Used to retain the full HTTP response.
    public var sdkHttpResponse: HttpResponse?
    /// Total number of tokens.
    public var totalTokens: Double?
    /// Number of tokens in the cached part of the prompt (the cached content).
    public var cachedContentTokenCount: Double?

    public init(
        sdkHttpResponse: HttpResponse? = nil,
        totalTokens: Double? = nil,
        cachedContentTokenCount: Double? = nil
    ) {
        self.sdkHttpResponse = sdkHttpResponse
        self.totalTokens = totalTokens
        self.cachedContentTokenCount = cachedContentTokenCount
    }
}

/// Optional parameters for computing tokens.
public struct ComputeTokensConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    public var abortSignal: AbortSignal?

    public init(httpOptions: HttpOptions? = nil, abortSignal: AbortSignal? = nil) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

/// Parameters for computing tokens.
public struct ComputeTokensParameters: Codable, Sendable {
    /// ID of the model to use.
    public var model: String
    /// Input content.
    public var contents: ContentListUnion
    /// Optional parameters for the request.
    public var config: ComputeTokensConfig?

    public init(
        model: String,
        contents: ContentListUnion,
        config: ComputeTokensConfig? = nil
    ) {
        self.model = model
        self.contents = contents
        self.config = config
    }
}

/// Tokens info with a list of tokens and the corresponding list of token ids.
public struct TokensInfo: Codable, Sendable {
    /// Optional fields for the role from the corresponding Content.
    public var role: String?
    /// A list of token ids from the input.
    public var tokenIds: [String]?
    /// A list of tokens from the input. Encoded as base64 string.
    public var tokens: [String]?

    public init(role: String? = nil, tokenIds: [String]? = nil, tokens: [String]? = nil) {
        self.role = role
        self.tokenIds = tokenIds
        self.tokens = tokens
    }
}

/// Response for computing tokens.
public final class ComputeTokensResponse: Codable, @unchecked Sendable {
    /// Used to retain the full HTTP response.
    public var sdkHttpResponse: HttpResponse?
    /// Lists of tokens info from the input.
    public var tokensInfo: [TokensInfo]?

    public init(
        sdkHttpResponse: HttpResponse? = nil,
        tokensInfo: [TokensInfo]? = nil
    ) {
        self.sdkHttpResponse = sdkHttpResponse
        self.tokensInfo = tokensInfo
    }
}
