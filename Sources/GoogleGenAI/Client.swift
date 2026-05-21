// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

private let LANGUAGE_LABEL_PREFIX = "gl-swift/"

// MARK: - Module stubs (replaced in Wave 4)

// Each of these `final class FooModule` types is a placeholder so `GoogleGenAI` can hold
// references to them. The real implementations live in dedicated files in later waves.

/// TODO Wave 4: replace with real implementation.
public final class ModelsModule: @unchecked Sendable {
    public let apiClient: ApiClient
    public init(apiClient: ApiClient) { self.apiClient = apiClient }
}

/// TODO Wave 4: replace with real implementation.
public final class ChatsModule: @unchecked Sendable {
    public let apiClient: ApiClient
    public let models: ModelsModule
    public init(models: ModelsModule, apiClient: ApiClient) {
        self.models = models
        self.apiClient = apiClient
    }
}

/// TODO Wave 4: replace with real implementation.
public final class BatchesModule: @unchecked Sendable {
    public let apiClient: ApiClient
    public init(apiClient: ApiClient) { self.apiClient = apiClient }
}

/// TODO Wave 4: replace with real implementation.
public final class CachesModule: @unchecked Sendable {
    public let apiClient: ApiClient
    public init(apiClient: ApiClient) { self.apiClient = apiClient }
}

/// TODO Wave 4: replace with real implementation.
public final class FilesModule: @unchecked Sendable {
    public let apiClient: ApiClient
    public init(apiClient: ApiClient) { self.apiClient = apiClient }
}

/// TODO Wave 4: replace with real implementation.
public final class FileSearchStoresModule: @unchecked Sendable {
    public let apiClient: ApiClient
    public init(apiClient: ApiClient) { self.apiClient = apiClient }
}

/// TODO Wave 4: replace with real implementation.
public final class OperationsModule: @unchecked Sendable {
    public let apiClient: ApiClient
    public init(apiClient: ApiClient) { self.apiClient = apiClient }
}

/// TODO Wave 4: replace with real implementation.
public final class TokensModule: @unchecked Sendable {
    public let apiClient: ApiClient
    public init(apiClient: ApiClient) { self.apiClient = apiClient }
}

/// TODO Wave 4: replace with real implementation.
public final class TuningsModule: @unchecked Sendable {
    public let apiClient: ApiClient
    public init(apiClient: ApiClient) { self.apiClient = apiClient }
}

/// TODO Wave 4: replace with real implementation.
public final class LiveModule: @unchecked Sendable {
    public let apiClient: ApiClient
    public let auth: Auth
    public init(apiClient: ApiClient, auth: Auth) {
        self.apiClient = apiClient
        self.auth = auth
    }
}

/// TODO Wave 4: replace with real implementation.
public final class DocumentsModule: @unchecked Sendable {
    public let apiClient: ApiClient
    public init(apiClient: ApiClient) { self.apiClient = apiClient }
}

/// TODO Wave 4: replace with real implementation.
public final class MusicModule: @unchecked Sendable {
    public let apiClient: ApiClient
    public init(apiClient: ApiClient) { self.apiClient = apiClient }
}

// MARK: - GoogleGenAI

/// Google Gen AI SDK's configuration options.
public struct GoogleGenAIOptions: Sendable {
    /// Determines whether to use the Vertex AI / Gemini Enterprise Agent Platform or the Gemini API.
    public var enterprise: Bool?
    /// Determines whether to use Vertex AI or the Gemini API. The `enterprise` flag is recommended.
    public var vertexai: Bool?
    /// The Google Cloud project ID for Vertex AI clients.
    public var project: String?
    /// The Google Cloud project location for Vertex AI clients.
    public var location: String?
    /// The API Key, required for Gemini API clients.
    public var apiKey: String?
    /// The API version to use.
    public var apiVersion: String?
    /// Authentication options for Vertex AI clients.
    public var googleAuthOptions: GoogleAuthOptions?
    /// A set of customizable configuration for HTTP requests.
    public var httpOptions: HttpOptions?

    public init(
        enterprise: Bool? = nil,
        vertexai: Bool? = nil,
        project: String? = nil,
        location: String? = nil,
        apiKey: String? = nil,
        apiVersion: String? = nil,
        googleAuthOptions: GoogleAuthOptions? = nil,
        httpOptions: HttpOptions? = nil
    ) {
        self.enterprise = enterprise
        self.vertexai = vertexai
        self.project = project
        self.location = location
        self.apiKey = apiKey
        self.apiVersion = apiVersion
        self.googleAuthOptions = googleAuthOptions
        self.httpOptions = httpOptions
    }
}

/// The Google GenAI SDK.
///
/// Provides access to the GenAI features through either the Gemini API or the Vertex AI API.
public final class GoogleGenAI: @unchecked Sendable {
    public let apiClient: ApiClient
    private let apiKey: String?
    public let vertexai: Bool
    private let apiVersion: String?
    private let httpOptions: HttpOptions?

    public let models: ModelsModule
    public let live: LiveModule
    public let batches: BatchesModule
    public let chats: ChatsModule
    public let caches: CachesModule
    public let files: FilesModule
    public let operations: OperationsModule
    public let authTokens: TokensModule
    public let tunings: TuningsModule
    public let fileSearchStores: FileSearchStoresModule

    public init(options: GoogleGenAIOptions) throws {
        // The Swift port currently only supports API-key auth (the `cross`/`web` runtime path
        // from js-genai). Vertex ADC will be added once `DefaultAuth` learns to sign JWTs.
        guard let apiKey = options.apiKey else {
            throw GenAIError.invalidArgument(
                "An API Key must be set when running in an unspecified environment."
            )
        }
        if let enterprise = options.enterprise,
           let vertexai = options.vertexai,
           enterprise != vertexai {
            throw GenAIError.invalidArgument(
                "enterprise and vertexAI flags have conflicting values, please set enterprise value only."
            )
        }
        self.vertexai = options.enterprise ?? options.vertexai ?? false
        self.apiKey = apiKey
        self.apiVersion = options.apiVersion
        self.httpOptions = options.httpOptions
        let auth: Auth = DefaultAuth(apiKey: apiKey)
        // Wave 6: real Foundation-backed Uploader / Downloader.
        self.apiClient = try ApiClient(ApiClientInitOptions(
            auth: auth,
            uploader: URLSessionUploader(),
            downloader: URLSessionDownloader(),
            project: options.project,
            location: options.location,
            apiKey: apiKey,
            vertexai: self.vertexai,
            apiVersion: options.apiVersion,
            httpOptions: options.httpOptions,
            userAgentExtra: LANGUAGE_LABEL_PREFIX + "cross"
        ))
        self.models = ModelsModule(apiClient: self.apiClient)
        self.live = LiveModule(apiClient: self.apiClient, auth: auth)
        self.chats = ChatsModule(models: self.models, apiClient: self.apiClient)
        self.batches = BatchesModule(apiClient: self.apiClient)
        self.caches = CachesModule(apiClient: self.apiClient)
        self.files = FilesModule(apiClient: self.apiClient)
        self.operations = OperationsModule(apiClient: self.apiClient)
        self.authTokens = TokensModule(apiClient: self.apiClient)
        self.tunings = TuningsModule(apiClient: self.apiClient)
        self.fileSearchStores = FileSearchStoresModule(apiClient: self.apiClient)
    }
}

// Real Uploader / Downloader live in `Uploader.swift` and `Downloader.swift`.
