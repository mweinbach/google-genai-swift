// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// File input that may be a local path or a raw `Data` blob.
public enum FileInput: Sendable {
    case path(String)
    case data(Data)
}

/// Parameters for the upload file method.
public struct UploadFileParameters: Sendable {
    /// The string path to the file to be uploaded or a `Data` object.
    public var file: FileInput
    /// Configuration that contains optional parameters.
    public var config: UploadFileConfig?

    public init(file: FileInput, config: UploadFileConfig? = nil) {
        self.file = file
        self.config = config
    }
}

// `UploadToFileSearchStoreParameters` is declared in `DocsAndFileSearch.swift` by a sibling slice.

/// CallableTool is an invokable tool that can be executed with external application
/// (e.g., via Model Context Protocol) or local functions with function calling.
public protocol CallableTool: Sendable {
    /// Returns the tool that can be called by Gemini.
    func tool() async throws -> Tool
    /// Executes the callable tool with the given function call arguments and
    /// returns the response parts from the tool execution.
    func callTool(functionCalls: [FunctionCall]) async throws -> [Part]
}

/// CallableToolConfig is the configuration for a callable tool.
public struct CallableToolConfig: Sendable {
    /// Specifies the model's behavior after invoking this tool.
    public var behavior: Behavior?
    /// Timeout for remote calls in milliseconds.
    public var timeout: Double?

    public init(behavior: Behavior? = nil, timeout: Double? = nil) {
        self.behavior = behavior
        self.timeout = timeout
    }
}

/// Parameters for connecting to the live music API.
public struct LiveMusicConnectParameters: Sendable {
    /// The model's resource name.
    public var model: String
    /// Callbacks invoked on server events.
    public var callbacks: LiveMusicCallbacks

    public init(model: String, callbacks: LiveMusicCallbacks) {
        self.model = model
        self.callbacks = callbacks
    }
}

/// Parameters for setting config for the live music API.
public struct LiveMusicSetConfigParameters: Sendable {
    /// Configuration for music generation.
    public var musicGenerationConfig: LiveMusicGenerationConfig

    public init(musicGenerationConfig: LiveMusicGenerationConfig) {
        self.musicGenerationConfig = musicGenerationConfig
    }
}

/// Parameters for setting weighted prompts for the live music API.
public struct LiveMusicSetWeightedPromptsParameters: Sendable {
    /// A map of text prompts to weights to use for the generation request.
    public var weightedPrompts: [WeightedPrompt]

    public init(weightedPrompts: [WeightedPrompt]) {
        self.weightedPrompts = weightedPrompts
    }
}

/// Config for auth_tokens.create parameters.
public struct AuthToken: Codable, Sendable {
    /// The name of the auth token.
    public var name: String?

    public init(name: String? = nil) {
        self.name = name
    }
}

/// Config for LiveConnectConstraints for Auth Token creation.
public struct LiveConnectConstraints: Sendable {
    /// ID of the model to configure in the ephemeral token for Live API.
    public var model: String?
    /// Configuration specific to Live API connections created using this token.
    public var config: LiveConnectConfig?

    public init(model: String? = nil, config: LiveConnectConfig? = nil) {
        self.model = model
        self.config = config
    }
}

/// Optional parameters for creating an auth token.
public struct CreateAuthTokenConfig: Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    public var abortSignal: AbortSignal?
    /// An optional time after which messages in Live API sessions will be rejected.
    public var expireTime: String?
    /// The time after which new Live API sessions using the token resulting from this request will be rejected.
    public var newSessionExpireTime: String?
    /// The number of times the token can be used.
    public var uses: Double?
    /// Configuration specific to Live API connections created using this token.
    public var liveConnectConstraints: LiveConnectConstraints?
    /// Additional fields to lock in the effective LiveConnectParameters.
    public var lockAdditionalFields: [String]?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        expireTime: String? = nil,
        newSessionExpireTime: String? = nil,
        uses: Double? = nil,
        liveConnectConstraints: LiveConnectConstraints? = nil,
        lockAdditionalFields: [String]? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.expireTime = expireTime
        self.newSessionExpireTime = newSessionExpireTime
        self.uses = uses
        self.liveConnectConstraints = liveConnectConstraints
        self.lockAdditionalFields = lockAdditionalFields
    }
}

/// Config for auth_tokens.create parameters.
public struct CreateAuthTokenParameters: Sendable {
    /// Optional parameters for the request.
    public var config: CreateAuthTokenConfig?

    public init(config: CreateAuthTokenConfig? = nil) {
        self.config = config
    }
}

/// Parameters for the get method of the operations module.
public struct OperationGetParameters<U: Sendable>: Sendable {
    /// Used to override the default configuration.
    public var config: GetOperationConfig?
    /// The operation to be retrieved.
    public var operation: U

    public init(config: GetOperationConfig? = nil, operation: U) {
        self.config = config
        self.operation = operation
    }
}

/// Local tokenizer count tokens result.
public struct CountTokensResult: Codable, Sendable {
    /// The total number of tokens.
    public var totalTokens: Double?

    public init(totalTokens: Double? = nil) {
        self.totalTokens = totalTokens
    }
}

/// Local tokenizer compute tokens result.
public struct ComputeTokensResult: Codable, Sendable {
    /// Lists of tokens info from the input.
    public var tokensInfo: [TokensInfo]?

    public init(tokensInfo: [TokensInfo]? = nil) {
        self.tokensInfo = tokensInfo
    }
}

/// Fine-tuning job creation parameters - optional fields.
public struct CreateTuningJobParameters: Sendable {
    /// The base model that is being tuned, e.g., "gemini-2.5-flash".
    public var baseModel: String
    /// Cloud Storage path to file containing training dataset for tuning.
    public var trainingDataset: TuningDataset
    /// Configuration for the tuning job.
    public var config: CreateTuningJobConfig?

    public init(
        baseModel: String,
        trainingDataset: TuningDataset,
        config: CreateTuningJobConfig? = nil
    ) {
        self.baseModel = baseModel
        self.trainingDataset = trainingDataset
        self.config = config
    }
}

/// Parameters for the embed_content method.
public struct EmbedContentParameters: Sendable {
    /// ID of the model to use.
    public var model: String
    /// The content to embed. Only the `parts.text` fields will be counted.
    public var contents: ContentListUnion
    /// Configuration that contains optional parameters.
    public var config: EmbedContentConfig?

    public init(
        model: String,
        contents: ContentListUnion,
        config: EmbedContentConfig? = nil
    ) {
        self.model = model
        self.contents = contents
        self.config = config
    }
}

/// The response when long-running operation for uploading a file to a FileSearchStore complete.
public final class UploadToFileSearchStoreResponse: Codable, @unchecked Sendable {
    /// Used to retain the full HTTP response.
    public var sdkHttpResponse: HttpResponse?
    /// The name of the FileSearchStore containing Documents.
    public var parent: String?
    /// The identifier for the Document imported.
    public var documentName: String?

    public init(
        sdkHttpResponse: HttpResponse? = nil,
        parent: String? = nil,
        documentName: String? = nil
    ) {
        self.sdkHttpResponse = sdkHttpResponse
        self.parent = parent
        self.documentName = documentName
    }
}

/// Long-running operation for uploading a file to a FileSearchStore.
public final class UploadToFileSearchStoreOperation: Codable, @unchecked Sendable {
    /// The server-assigned name.
    public var name: String?
    /// Service-specific metadata associated with the operation.
    public var metadata: [String: JSONValue]?
    /// If the value is `false`, the operation is still in progress.
    public var done: Bool?
    /// The error result of the operation in case of failure or cancellation.
    public var error: [String: JSONValue]?
    /// The result of the UploadToFileSearchStore operation, available when the operation is done.
    public var response: UploadToFileSearchStoreResponse?
    /// The full HTTP response.
    public var sdkHttpResponse: HttpResponse?

    public init(
        name: String? = nil,
        metadata: [String: JSONValue]? = nil,
        done: Bool? = nil,
        error: [String: JSONValue]? = nil,
        response: UploadToFileSearchStoreResponse? = nil,
        sdkHttpResponse: HttpResponse? = nil
    ) {
        self.name = name
        self.metadata = metadata
        self.done = done
        self.error = error
        self.response = response
        self.sdkHttpResponse = sdkHttpResponse
    }

    /// Instantiates an Operation of the same type as the one being called with the fields set from the API response.
    public func _fromAPIResponse(_ parameters: OperationFromAPIResponseParameters) -> UploadToFileSearchStoreOperation {
        let operation = UploadToFileSearchStoreOperation()
        let mapped: [String: JSONValue]
        do {
            var parent: [String: JSONValue] = [:]
            mapped = try uploadToFileSearchStoreOperationFromMldev(apiClient: parameters.apiClient, fromObject: parameters.apiResponse, parentObject: &parent)
        } catch {
            return operation
        }
        if let data = try? JSONEncoder().encode(JSONValue.object(mapped)),
           let decoded = try? JSONDecoder().decode(UploadToFileSearchStoreOperation.self, from: data) {
            operation.name = decoded.name
            operation.metadata = decoded.metadata
            operation.done = decoded.done
            operation.error = decoded.error
            operation.response = decoded.response
            operation.sdkHttpResponse = decoded.sdkHttpResponse
        }
        return operation
    }
}

/// Used to override the default configuration.
public struct DownloadMediaConfig: Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    public var abortSignal: AbortSignal?

    public init(httpOptions: HttpOptions? = nil, abortSignal: AbortSignal? = nil) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}
