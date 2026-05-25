// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

private let LANGUAGE_LABEL_PREFIX = "gl-swift/"

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

/// The Google GenAI SDK — entry-point class.
///
/// Provides access to the GenAI features through either the Gemini API or the
/// Vertex AI / Gemini Enterprise Agent Platform API. Mirrors `new GoogleGenAI(...)`
/// from the JavaScript SDK.
///
/// ```swift
/// // Gemini API with explicit API key
/// let ai = try GoogleGenAI(apiKey: "GEMINI_API_KEY")
/// let response = try await ai.models.generateContent(
///     GenerateContentParameters(
///         model: "gemini-2.5-flash",
///         contents: .part(.text("Why is the sky blue?"))
///     )
/// )
/// print(response.text ?? "")
///
/// // Vertex AI / Enterprise
/// let ai = try GoogleGenAI(
///     enterprise: true,
///     project: "your-project",
///     location: "us-central1"
/// )
///
/// // Read from environment variables
/// // (GOOGLE_API_KEY / GEMINI_API_KEY, GOOGLE_GENAI_USE_VERTEXAI / _USE_ENTERPRISE,
/// //  GOOGLE_CLOUD_PROJECT, GOOGLE_CLOUD_LOCATION)
/// let ai = try GoogleGenAI()
/// ```
public final class GoogleGenAI: @unchecked Sendable {
    public let apiClient: ApiClient
    public let vertexai: Bool
    public let apiVersion: String?
    private let apiKey: String?
    private let httpOptions: HttpOptions?

    // Module surface — matches js-genai's `client.ts` public properties 1:1.
    public let models: Models
    public let live: Live
    public let batches: Batches
    public let chats: Chats
    public let caches: Caches
    public let files: Files
    public let operations: Operations
    public let authTokens: Tokens
    public let tunings: Tunings
    public let fileSearchStores: FileSearchStores

    /// Primary initializer.
    public init(options: GoogleGenAIOptions) throws {
        let env = ProcessInfo.processInfo.environment
        let envApiKey = env["GOOGLE_API_KEY"] ?? env["GEMINI_API_KEY"]
        let envProject = env["GOOGLE_CLOUD_PROJECT"]
        let envLocation = env["GOOGLE_CLOUD_LOCATION"]
        let envEnterprise = env["GOOGLE_GENAI_USE_ENTERPRISE"].flatMap(parseBool)
        let envVertexai = env["GOOGLE_GENAI_USE_VERTEXAI"].flatMap(parseBool)
        let envCredentialsPath = env["GOOGLE_APPLICATION_CREDENTIALS"]

        // Enterprise vs vertexai precedence: explicit option > env var > default false.
        if let e = options.enterprise, let v = options.vertexai, e != v {
            throw GenAIError.invalidArgument(
                "enterprise and vertexai flags have conflicting values, please set enterprise value only."
            )
        }
        let useVertex = options.enterprise
            ?? options.vertexai
            ?? envEnterprise
            ?? envVertexai
            ?? false

        let apiKey = options.apiKey ?? envApiKey
        let project = options.project ?? envProject
        let location = options.location ?? envLocation

        // Resolve auth: API key (Gemini API) takes precedence; Vertex requires project+location.
        let auth: Auth
        if let apiKey {
            auth = DefaultAuth(apiKey: apiKey)
        } else if useVertex {
            if project == nil || location == nil {
                throw GenAIError.invalidArgument(
                    "Vertex AI / Enterprise requires either an API key or both project and location."
                )
            }
            var resolvedAuthOptions = options.googleAuthOptions
            if resolvedAuthOptions == nil, let credPath = envCredentialsPath {
                resolvedAuthOptions = GoogleAuthOptions(keyFile: credPath)
            }
            auth = DefaultAuth(googleAuthOptions: resolvedAuthOptions)
        } else {
            throw GenAIError.invalidArgument(
                "An API key must be set for the Gemini API. Provide options.apiKey or set GOOGLE_API_KEY / GEMINI_API_KEY in the environment."
            )
        }

        self.vertexai = useVertex
        self.apiKey = apiKey
        self.apiVersion = options.apiVersion
        self.httpOptions = options.httpOptions

        self.apiClient = try ApiClient(ApiClientInitOptions(
            auth: auth,
            uploader: URLSessionUploader(),
            downloader: URLSessionDownloader(),
            project: project,
            location: location,
            apiKey: apiKey,
            vertexai: useVertex,
            apiVersion: options.apiVersion,
            httpOptions: options.httpOptions,
            userAgentExtra: LANGUAGE_LABEL_PREFIX + "cross"
        ))

        // Wire the real resource modules from Wave 4 / 6.
        self.models = Models(apiClient: self.apiClient)
        self.live = Live(apiClient: self.apiClient, auth: auth)
        self.batches = Batches(apiClient: self.apiClient)
        self.chats = Chats(modelsModule: self.models, apiClient: self.apiClient)
        self.caches = Caches(apiClient: self.apiClient)
        self.files = Files(apiClient: self.apiClient)
        self.operations = Operations(apiClient: self.apiClient)
        self.authTokens = Tokens(apiClient: self.apiClient)
        self.tunings = Tunings(apiClient: self.apiClient)
        self.fileSearchStores = FileSearchStores(apiClient: self.apiClient)
    }

    /// JS-style convenience: `GoogleGenAI(apiKey: "X")`.
    public convenience init(
        apiKey: String? = nil,
        enterprise: Bool? = nil,
        vertexai: Bool? = nil,
        project: String? = nil,
        location: String? = nil,
        apiVersion: String? = nil,
        googleAuthOptions: GoogleAuthOptions? = nil,
        httpOptions: HttpOptions? = nil
    ) throws {
        try self.init(options: GoogleGenAIOptions(
            enterprise: enterprise,
            vertexai: vertexai,
            project: project,
            location: location,
            apiKey: apiKey,
            apiVersion: apiVersion,
            googleAuthOptions: googleAuthOptions,
            httpOptions: httpOptions
        ))
    }
}

private func parseBool(_ s: String) -> Bool? {
    switch s.lowercased() {
    case "true", "1", "yes": return true
    case "false", "0", "no", "": return false
    default: return nil
    }
}

// Real Uploader / Downloader live in `Uploader.swift` and `Downloader.swift`.
