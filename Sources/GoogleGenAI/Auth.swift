// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Header name used for the Google API key on every request.
public let GOOGLE_API_KEY_HEADER = "x-goog-api-key"

/// OAuth scope required when authenticating to Vertex AI with Application Default Credentials.
public let GENAI_REQUIRED_VERTEX_SCOPE = "https://www.googleapis.com/auth/cloud-platform"

/// The `Auth` protocol is used to authenticate with the API service.
///
/// Ports `_auth.ts`. The TS interface accepts a `Headers` mutable object — Swift uses
/// an `inout` dictionary so the implementation can append additional headers.
public protocol Auth: Sendable {
    /// Sets the headers needed to authenticate with the API service.
    ///
    /// - Parameters:
    ///   - headers: A mutable header dictionary that will be updated with authentication headers.
    ///   - url: The URL of the request (used when minting per-URL credentials).
    func addAuthHeaders(_ headers: inout [String: String], url: String?) async throws
}

/// Options for constructing a `DefaultAuth`. Ports `NodeAuthOptions` from `node/_node_auth.ts`.
public struct DefaultAuthOptions: Sendable {
    /// The API Key. Required for Gemini API users.
    public var apiKey: String?
    /// Optional. Authentication options used when authenticating with Vertex AI service accounts.
    public var googleAuthOptions: GoogleAuthOptions?

    public init(apiKey: String? = nil, googleAuthOptions: GoogleAuthOptions? = nil) {
        self.apiKey = apiKey
        self.googleAuthOptions = googleAuthOptions
    }
}

/// Foundation-native equivalent of the `google-auth-library` `GoogleAuthOptions` interface.
///
/// When `credentialsJSON` or `keyFile` is provided, the SDK uses `Security.framework` to
/// sign a JWT (RS256) and exchange it for an OAuth2 access token via the keyfile's
/// `token_uri`. Tokens are cached and refreshed automatically.
public struct GoogleAuthOptions: Sendable {
    /// OAuth scopes to request when minting credentials.
    public var scopes: [String]?
    /// Inline service-account JSON keyfile contents.
    public var credentialsJSON: Data?
    /// Path on disk to a service-account JSON keyfile.
    public var keyFile: String?

    public init(scopes: [String]? = nil, credentialsJSON: Data? = nil, keyFile: String? = nil) {
        self.scopes = scopes
        self.credentialsJSON = credentialsJSON
        self.keyFile = keyFile
    }
}

/// Concrete `Auth` implementation that collapses `NodeAuth` (Node runtime) and `WebAuth`
/// (browser runtime) from the JS SDK into a single Foundation-native class.
///
/// API-key auth is fully supported. Vertex AI ADC / service-account auth uses
/// `Security.framework` for RS256 JWT signing and automatic token caching/refresh.
public final class DefaultAuth: Auth, @unchecked Sendable {
    private let apiKey: String?
    private let googleAuthOptions: GoogleAuthOptions?
    private let credential: ServiceAccountCredential?

    public init(options: DefaultAuthOptions) {
        if let key = options.apiKey {
            self.apiKey = key
            self.googleAuthOptions = nil
            self.credential = nil
        } else {
            self.apiKey = nil
            let authOptions = (try? buildGoogleAuthOptions(options.googleAuthOptions))
                ?? GoogleAuthOptions(scopes: [GENAI_REQUIRED_VERTEX_SCOPE])
            self.googleAuthOptions = authOptions
            self.credential = Self.makeCredential(from: authOptions)
        }
    }

    /// Convenience initializer for API-key auth (mirrors `WebAuth(apiKey)`).
    public convenience init(apiKey: String?) {
        self.init(options: DefaultAuthOptions(apiKey: apiKey))
    }

    /// Convenience initializer for Vertex AI ADC auth.
    public convenience init(googleAuthOptions: GoogleAuthOptions?) {
        self.init(options: DefaultAuthOptions(googleAuthOptions: googleAuthOptions))
    }

    public func addAuthHeaders(_ headers: inout [String: String], url: String?) async throws {
        if let apiKey = apiKey {
            if apiKey.hasPrefix("auth_tokens/") {
                throw GenAIError.invalidArgument("Ephemeral tokens are only supported by the live API.")
            }
            try addKeyHeader(&headers, apiKey: apiKey)
            return
        }
        try await addGoogleAuthHeaders(&headers, url: url)
    }

    private func addKeyHeader(_ headers: inout [String: String], apiKey: String) throws {
        if headers[GOOGLE_API_KEY_HEADER] != nil {
            return
        }
        if apiKey.isEmpty {
            throw GenAIError.invalidArgument("API key is missing. Please provide a valid API key.")
        }
        headers[GOOGLE_API_KEY_HEADER] = apiKey
    }

    private func addGoogleAuthHeaders(_ headers: inout [String: String], url: String?) async throws {
        guard let credential = credential else {
            throw GenAIError.unsupported(
                "No service-account credentials available; provide GoogleAuthOptions with credentialsJSON or keyFile"
            )
        }
        let token = try await credential.getAccessToken()
        if headers["Authorization"] == nil {
            headers["Authorization"] = "Bearer \(token)"
        }
    }

    private static func makeCredential(from options: GoogleAuthOptions) -> ServiceAccountCredential? {
        let scopes = options.scopes ?? [GENAI_REQUIRED_VERTEX_SCOPE]
        if let jsonData = options.credentialsJSON {
            return try? ServiceAccountCredential(credentialsJSON: jsonData, scopes: scopes)
        }
        if let path = options.keyFile {
            return try? ServiceAccountCredential(keyFilePath: path, scopes: scopes)
        }
        return nil
    }
}

/// Ports `buildGoogleAuthOptions` from `node/_node_auth.ts`. Ensures the required Vertex AI
/// scope is present and throws if the caller supplied a conflicting scope list.
public func buildGoogleAuthOptions(_ googleAuthOptions: GoogleAuthOptions?) throws -> GoogleAuthOptions {
    guard var authOptions = googleAuthOptions else {
        return GoogleAuthOptions(scopes: [GENAI_REQUIRED_VERTEX_SCOPE])
    }
    guard let scopes = authOptions.scopes, !scopes.isEmpty else {
        authOptions.scopes = [GENAI_REQUIRED_VERTEX_SCOPE]
        return authOptions
    }
    if !scopes.contains(GENAI_REQUIRED_VERTEX_SCOPE) {
        throw GenAIError.invalidArgument(
            "Invalid auth scopes. Scopes must include: \(GENAI_REQUIRED_VERTEX_SCOPE)"
        )
    }
    return authOptions
}
