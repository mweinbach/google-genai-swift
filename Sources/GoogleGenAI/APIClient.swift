// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Constants

private let CONTENT_TYPE_HEADER = "Content-Type"
private let SERVER_TIMEOUT_HEADER = "X-Server-Timeout"
private let USER_AGENT_HEADER = "User-Agent"
public let GOOGLE_API_CLIENT_HEADER = "x-goog-api-client"
public let SDK_VERSION = "2.5.0" // x-release-please-version
private let LIBRARY_LABEL = "google-genai-sdk/\(SDK_VERSION)"
private let VERTEX_AI_API_DEFAULT_VERSION = "v1beta1"
private let GOOGLE_AI_API_DEFAULT_VERSION = "v1beta"

private let MULTI_REGIONAL_LOCATIONS: Set<String> = ["us", "eu"]

// Default retry options.
// The config is based on https://cloud.google.com/storage/docs/retry-strategy.
private let DEFAULT_RETRY_ATTEMPTS = 5 // Including the initial call
private let DEFAULT_RETRY_HTTP_STATUS_CODES: Set<Int> = [
    408, // Request timeout
    429, // Too many requests
    500, // Internal server error
    502, // Bad gateway
    503, // Service unavailable
    504, // Gateway timeout
]

// MARK: - Stubs — replaced in later waves

/// `Auth` is owned by sibling port (`Auth.swift`, `_auth.ts`).

/// Uploader abstraction — real implementation arrives in Wave 6 (`_uploader.ts`).
public protocol Uploader: Sendable {
    /// Returns size + inferred MIME type for the input file.
    func stat(_ file: FileInput) async throws -> FileStat
    /// Performs a resumable upload to the pre-fetched `uploadUrl` and returns the resulting `File`.
    func upload(_ file: FileInput, uploadUrl: String, apiClient: ApiClient) async throws -> File
    /// Uploads to a file search store, returning the long-running operation handle.
    func uploadToFileSearchStore(_ file: FileInput, uploadUrl: String, apiClient: ApiClient) async throws -> UploadToFileSearchStoreOperation
}

/// Stat info returned by an `Uploader`.
public struct FileStat: Sendable {
    public var size: Int64
    public var type: String?
    public init(size: Int64, type: String? = nil) {
        self.size = size
        self.type = type
    }
}

/// Downloader abstraction — real implementation arrives in Wave 6 (`_downloader.ts`).
public protocol Downloader: Sendable {
    func download(_ params: DownloadFileParameters, apiClient: ApiClient) async throws
}

/// Adapter protocol — concrete shape arrives in Wave 7 (`interactions/client-adapter.ts`).
/// Declared empty here so `ApiClient` can conform without coupling to unbuilt code.
public protocol GeminiNextGenAPIClientAdapter: Sendable {
}

/// Converter stub — real implementation arrives in Wave 5 (`converters/_filesearchstores_converters.ts`).
internal func uploadToFileSearchStoreConfigToMldev(
    _ fromObject: UploadToFileSearchStoreConfig,
    _ parentObject: inout [String: JSONValue]
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (uploadToFileSearchStoreConfigToMldev)")
}

// MARK: - ApiClientInitOptions

/// Options for initializing the ApiClient.
public struct ApiClientInitOptions: Sendable {
    public var auth: Auth
    public var uploader: Uploader
    public var downloader: Downloader
    public var project: String?
    public var location: String?
    public var apiKey: String?
    public var vertexai: Bool?
    public var apiVersion: String?
    public var httpOptions: HttpOptions?
    public var userAgentExtra: String?

    public init(
        auth: Auth,
        uploader: Uploader,
        downloader: Downloader,
        project: String? = nil,
        location: String? = nil,
        apiKey: String? = nil,
        vertexai: Bool? = nil,
        apiVersion: String? = nil,
        httpOptions: HttpOptions? = nil,
        userAgentExtra: String? = nil
    ) {
        self.auth = auth
        self.uploader = uploader
        self.downloader = downloader
        self.project = project
        self.location = location
        self.apiKey = apiKey
        self.vertexai = vertexai
        self.apiVersion = apiVersion
        self.httpOptions = httpOptions
        self.userAgentExtra = userAgentExtra
    }
}

// MARK: - HttpRequest

/// HTTP method enum used by `HttpRequest`.
public enum HttpMethod: String, Sendable {
    case GET
    case POST
    case PATCH
    case DELETE
}

/// Body payload for an `HttpRequest`. Mirrors TS `string | Blob`.
public enum HttpBody: Sendable {
    case string(String)
    case data(Data)

    public var isEmpty: Bool {
        switch self {
        case .string(let s): return s.isEmpty
        case .data(let d): return d.isEmpty
        }
    }
}

/// Represents the necessary information to send a request to an API endpoint.
public struct HttpRequest: Sendable {
    public var path: String
    public var queryParams: [String: String]?
    public var body: HttpBody?
    public var httpMethod: HttpMethod
    public var httpOptions: HttpOptions?
    public var abortSignal: AbortSignal?

    public init(
        path: String,
        queryParams: [String: String]? = nil,
        body: HttpBody? = nil,
        httpMethod: HttpMethod,
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil
    ) {
        self.path = path
        self.queryParams = queryParams
        self.body = body
        self.httpMethod = httpMethod
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

// MARK: - Internal request representation

/// Internal "RequestInit"-equivalent — collects everything URLSession needs.
private struct RequestInit {
    var body: HttpBody?
    var headers: [String: String] = [:]
    var timeoutMs: Double?
}

// MARK: - ApiClient

/// The ApiClient class is used to send requests to the Gemini API or Vertex AI endpoints.
///
/// WARNING: This is an internal API and may change without notice. Direct usage
/// is not supported and may break your application.
public final class ApiClient: GeminiNextGenAPIClientAdapter, @unchecked Sendable {
    public private(set) var clientOptions: ApiClientInitOptions
    private let customBaseUrl: String?

    public init(_ opts: ApiClientInitOptions) throws {
        self.clientOptions = opts
        self.customBaseUrl = opts.httpOptions?.baseUrl

        if self.clientOptions.vertexai == true {
            if self.clientOptions.project != nil && self.clientOptions.location != nil {
                self.clientOptions.apiKey = nil
            } else if self.clientOptions.apiKey != nil {
                self.clientOptions.project = nil
                self.clientOptions.location = nil
            }
        }

        var initHttpOptions = HttpOptions()

        if self.clientOptions.vertexai == true {
            if self.clientOptions.location == nil
                && self.clientOptions.apiKey == nil
                && self.customBaseUrl == nil {
                self.clientOptions.location = "global"
            }

            let hasSufficientAuth =
                (self.clientOptions.project != nil && self.clientOptions.location != nil)
                || self.clientOptions.apiKey != nil

            if !hasSufficientAuth && self.customBaseUrl == nil {
                throw GenAIError.invalidArgument(
                    "Authentication is not set up. Please provide either a project and location, or an API key, or a custom base URL."
                )
            }

            let hasConstructorAuth =
                (opts.project != nil && opts.location != nil) || (opts.apiKey != nil)

            if let customBaseUrl = self.customBaseUrl, !hasConstructorAuth {
                initHttpOptions.baseUrl = customBaseUrl
                self.clientOptions.project = nil
                self.clientOptions.location = nil
            } else if self.clientOptions.apiKey != nil
                || self.clientOptions.location == "global" {
                // Vertex Express or global endpoint case.
                initHttpOptions.baseUrl = "https://aiplatform.googleapis.com/"
            } else if let project = self.clientOptions.project,
                      let location = self.clientOptions.location,
                      !project.isEmpty,
                      MULTI_REGIONAL_LOCATIONS.contains(location) {
                initHttpOptions.baseUrl = "https://aiplatform.\(location).rep.googleapis.com/"
            } else if let project = self.clientOptions.project,
                      let location = self.clientOptions.location,
                      !project.isEmpty,
                      !location.isEmpty {
                initHttpOptions.baseUrl = "https://\(location)-aiplatform.googleapis.com/"
            }

            initHttpOptions.apiVersion =
                self.clientOptions.apiVersion ?? VERTEX_AI_API_DEFAULT_VERSION
        } else {
            // Gemini API
            if self.clientOptions.apiKey == nil {
                print("API key should be set when using the Gemini API.")
            }
            initHttpOptions.apiVersion =
                self.clientOptions.apiVersion ?? GOOGLE_AI_API_DEFAULT_VERSION
            initHttpOptions.baseUrl = "https://generativelanguage.googleapis.com/"
        }

        initHttpOptions.headers = ApiClient.getDefaultHeadersStatic(
            userAgentExtra: self.clientOptions.userAgentExtra
        )

        self.clientOptions.httpOptions = initHttpOptions

        if let userHttpOptions = opts.httpOptions {
            self.clientOptions.httpOptions = ApiClient.patchHttpOptions(
                base: initHttpOptions,
                patch: userHttpOptions
            )
        }
    }

    // MARK: - Accessors

    public func isVertexAI() -> Bool {
        return self.clientOptions.vertexai ?? false
    }

    public func getProject() -> String? {
        return self.clientOptions.project
    }

    public func getLocation() -> String? {
        return self.clientOptions.location
    }

    public func getCustomBaseUrl() -> String? {
        return self.customBaseUrl
    }

    public func getAuthHeaders() async throws -> [String: String] {
        var headers: [String: String] = [:]
        try await self.clientOptions.auth.addAuthHeaders(&headers, url: nil)
        return headers
    }

    public func getApiVersion() throws -> String {
        if let opts = self.clientOptions.httpOptions, let v = opts.apiVersion {
            return v
        }
        throw GenAIError.runtime("API version is not set.")
    }

    public func getBaseUrl() throws -> String {
        if let opts = self.clientOptions.httpOptions, let b = opts.baseUrl {
            return b
        }
        throw GenAIError.runtime("Base URL is not set.")
    }

    public func getRequestUrl() throws -> String {
        return try ApiClient.getRequestUrlInternal(self.clientOptions.httpOptions)
    }

    public func getHeaders() throws -> [String: String] {
        if let opts = self.clientOptions.httpOptions, let h = opts.headers {
            return h
        }
        throw GenAIError.runtime("Headers are not set.")
    }

    private static func getRequestUrlInternal(_ httpOptions: HttpOptions?) throws -> String {
        guard let httpOptions = httpOptions,
              let baseUrlRaw = httpOptions.baseUrl,
              let apiVersionRaw = httpOptions.apiVersion else {
            throw GenAIError.runtime("HTTP options are not correctly set.")
        }
        let baseUrl = baseUrlRaw.hasSuffix("/") ? String(baseUrlRaw.dropLast()) : baseUrlRaw
        var elements: [String] = [baseUrl]
        if !apiVersionRaw.isEmpty {
            elements.append(apiVersionRaw)
        }
        return elements.joined(separator: "/")
    }

    public func getBaseResourcePath() -> String {
        return "projects/\(self.clientOptions.project ?? "")/locations/\(self.clientOptions.location ?? "")"
    }

    public func getApiKey() -> String? {
        return self.clientOptions.apiKey
    }

    public func getWebsocketBaseUrl() throws -> String {
        let baseUrl = try self.getBaseUrl()
        guard var components = URLComponents(string: baseUrl) else {
            throw GenAIError.runtime("Invalid base URL: \(baseUrl)")
        }
        components.scheme = (components.scheme == "http") ? "ws" : "wss"
        return components.string ?? baseUrl
    }

    public func setBaseUrl(_ url: String) throws {
        if self.clientOptions.httpOptions != nil {
            self.clientOptions.httpOptions?.baseUrl = url
        } else {
            throw GenAIError.runtime("HTTP options are not correctly set.")
        }
    }

    // MARK: - URL construction

    private func constructUrl(
        path: String,
        httpOptions: HttpOptions,
        prependProjectLocation: Bool
    ) throws -> URLComponents {
        var elements: [String] = [try ApiClient.getRequestUrlInternal(httpOptions)]
        if prependProjectLocation {
            elements.append(self.getBaseResourcePath())
        }
        if !path.isEmpty {
            elements.append(path)
        }
        let joined = elements.joined(separator: "/")
        guard let comps = URLComponents(string: joined) else {
            throw GenAIError.runtime("Invalid URL: \(joined)")
        }
        return comps
    }

    private func shouldPrependVertexProjectPath(
        request: HttpRequest,
        httpOptions: HttpOptions
    ) -> Bool {
        if httpOptions.baseUrl != nil
            && httpOptions.baseUrlResourceScope == .collection {
            return false
        }
        if self.clientOptions.apiKey != nil {
            return false
        }
        if self.clientOptions.vertexai != true {
            return false
        }
        if request.path.hasPrefix("projects/") {
            return false
        }
        if request.httpMethod == .GET && request.path.hasPrefix("publishers/google/models") {
            return false
        }
        return true
    }

    // MARK: - request / requestStream

    public func request(_ request: HttpRequest) async throws -> HttpResponse {
        var patchedHttpOptions = self.clientOptions.httpOptions ?? HttpOptions()
        if let reqOpts = request.httpOptions {
            patchedHttpOptions = ApiClient.patchHttpOptions(
                base: self.clientOptions.httpOptions ?? HttpOptions(),
                patch: reqOpts
            )
        }

        let prependProjectLocation = self.shouldPrependVertexProjectPath(
            request: request,
            httpOptions: patchedHttpOptions
        )
        var urlComps = try self.constructUrl(
            path: request.path,
            httpOptions: patchedHttpOptions,
            prependProjectLocation: prependProjectLocation
        )
        if let queryParams = request.queryParams {
            var items = urlComps.queryItems ?? []
            for (k, v) in queryParams {
                items.append(URLQueryItem(name: k, value: v))
            }
            urlComps.queryItems = items
        }

        var requestInit = RequestInit()
        if request.httpMethod == .GET {
            if let body = request.body, !body.isEmpty {
                if case .string(let s) = body, s == "{}" {
                    // allowed
                } else {
                    throw GenAIError.invalidArgument(
                        "Request body should be empty for GET request, but got non empty request body"
                    )
                }
            }
        } else {
            requestInit.body = request.body
        }

        let finalUrlString = urlComps.string ?? ""
        try await self.includeExtraHttpOptionsToRequestInit(
            &requestInit,
            httpOptions: patchedHttpOptions,
            url: finalUrlString,
            abortSignal: request.abortSignal
        )

        guard let url = urlComps.url else {
            throw GenAIError.runtime("Invalid URL: \(finalUrlString)")
        }
        return try await self.unaryApiCall(
            url: url,
            requestInit: requestInit,
            httpMethod: request.httpMethod
        )
    }

    public func requestStream(_ request: HttpRequest) async throws -> AsyncThrowingStream<HttpResponse, Error> {
        var patchedHttpOptions = self.clientOptions.httpOptions ?? HttpOptions()
        if let reqOpts = request.httpOptions {
            patchedHttpOptions = ApiClient.patchHttpOptions(
                base: self.clientOptions.httpOptions ?? HttpOptions(),
                patch: reqOpts
            )
        }

        let prependProjectLocation = self.shouldPrependVertexProjectPath(
            request: request,
            httpOptions: patchedHttpOptions
        )
        var urlComps = try self.constructUrl(
            path: request.path,
            httpOptions: patchedHttpOptions,
            prependProjectLocation: prependProjectLocation
        )
        var items = urlComps.queryItems ?? []
        let altValue = items.first(where: { $0.name == "alt" })?.value
        if altValue != "sse" {
            items.removeAll(where: { $0.name == "alt" })
            items.append(URLQueryItem(name: "alt", value: "sse"))
        }
        urlComps.queryItems = items

        var requestInit = RequestInit()
        requestInit.body = request.body
        let finalUrlString = urlComps.string ?? ""
        try await self.includeExtraHttpOptionsToRequestInit(
            &requestInit,
            httpOptions: patchedHttpOptions,
            url: finalUrlString,
            abortSignal: request.abortSignal
        )

        guard let url = urlComps.url else {
            throw GenAIError.runtime("Invalid URL: \(finalUrlString)")
        }
        return try await self.streamApiCall(
            url: url,
            requestInit: requestInit,
            httpMethod: request.httpMethod
        )
    }

    // MARK: - HttpOptions patching

    /// Mirrors the TS `patchHttpOptions`: shallow merges, with one level of object
    /// merging for object-typed sub-fields (headers, retryOptions, extraBody).
    private static func patchHttpOptions(base: HttpOptions, patch: HttpOptions) -> HttpOptions {
        var out = base

        if let baseUrl = patch.baseUrl {
            out.baseUrl = baseUrl
        }
        if let scope = patch.baseUrlResourceScope {
            out.baseUrlResourceScope = scope
        }
        if let apiVersion = patch.apiVersion {
            out.apiVersion = apiVersion
        }
        if let timeout = patch.timeout {
            out.timeout = timeout
        }

        // Object fields — shallow merge.
        if let patchHeaders = patch.headers {
            var merged = out.headers ?? [:]
            for (k, v) in patchHeaders { merged[k] = v }
            out.headers = merged
        }
        if let patchExtra = patch.extraBody {
            var merged = out.extraBody ?? [:]
            for (k, v) in patchExtra { merged[k] = v }
            out.extraBody = merged
        }
        if let patchRetry = patch.retryOptions {
            var merged = out.retryOptions ?? HttpRetryOptions()
            if let a = patchRetry.attempts { merged.attempts = a }
            out.retryOptions = merged
        }

        return out
    }

    // MARK: - includeExtraHttpOptionsToRequestInit

    private func includeExtraHttpOptionsToRequestInit(
        _ requestInit: inout RequestInit,
        httpOptions: HttpOptions,
        url: String,
        abortSignal: AbortSignal?
    ) async throws {
        // Timeout is enforced inside `apiCall` via Task.sleep + cancellation.
        if let timeout = httpOptions.timeout, timeout > 0 {
            requestInit.timeoutMs = timeout
        }
        // AbortSignal is a marker type in Swift — actual cancellation is via Task.cancel().
        // We honor `isAborted == true` by pre-emptively throwing.
        if let abortSignal = abortSignal, abortSignal.isAborted {
            throw CancellationError()
        }

        if let extraBody = httpOptions.extraBody {
            ApiClient.includeExtraBodyToRequestInit(&requestInit, extraBody: extraBody)
        }

        requestInit.headers = try await self.getHeadersInternal(
            httpOptions: httpOptions,
            url: url
        )
    }

    // MARK: - unary / stream API call

    private func unaryApiCall(
        url: URL,
        requestInit: RequestInit,
        httpMethod: HttpMethod
    ) async throws -> HttpResponse {
        let (data, httpResponse) = try await self.apiCall(
            url: url,
            requestInit: requestInit,
            httpMethod: httpMethod
        )
        try ApiClient.throwErrorIfNotOK(response: httpResponse, bodyData: data)
        return HttpResponse(httpResponse, bodyData: data)
    }

    private func streamApiCall(
        url: URL,
        requestInit: RequestInit,
        httpMethod: HttpMethod
    ) async throws -> AsyncThrowingStream<HttpResponse, Error> {
        let (byteStream, httpResponse) = try await self.apiCallStream(
            url: url,
            requestInit: requestInit,
            httpMethod: httpMethod
        )
        try ApiClient.throwErrorIfNotOK(response: httpResponse, bodyData: nil)
        return self.processStreamResponse(byteStream: byteStream, response: httpResponse)
    }

    /// Parses a Server-Sent-Events byte stream into `HttpResponse` chunks. Each event's
    /// `data:` payload becomes one yielded HttpResponse with the original headers/status.
    public func processStreamResponse(
        byteStream: URLSession.AsyncBytes,
        response: HTTPURLResponse
    ) -> AsyncThrowingStream<HttpResponse, Error> {
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    var buffer = ""
                    let dataPrefix = "data:"
                    let delimiters = ["\n\n", "\r\r", "\r\n\r\n"]
                    var pendingBytes = Data()

                    for try await byte in byteStream {
                        try Task.checkCancellation()
                        pendingBytes.append(byte)
                        // Try to decode as UTF-8 incrementally — flush full chunks when they
                        // contain a delimiter.
                        if let chunkString = String(data: pendingBytes, encoding: .utf8) {
                            pendingBytes.removeAll(keepingCapacity: true)
                            // Detect inline server-side error JSON (rare — usually arrives mid-stream
                            // before any SSE delimiter on auth/quota failures).
                            if let errJson = try? JSONDecoder().decode(JSONValue.self, from: Data(chunkString.utf8)),
                               case .object(let obj) = errJson,
                               case .object(let errorObj) = obj["error"] ?? .null {
                                if case .int(let code) = errorObj["code"] ?? .null,
                                   code >= 400 && code < 600 {
                                    let statusStr: String
                                    if case .string(let s) = errorObj["status"] ?? .null { statusStr = s } else { statusStr = "" }
                                    let errorMessage = "got status: \(statusStr). \(chunkString)"
                                    throw ApiError(message: errorMessage, status: Int(code))
                                }
                            }
                            buffer.append(chunkString)

                            // Drain complete events from the buffer.
                            while true {
                                var delimiterIndex: String.Index? = nil
                                var delimiterLength = 0
                                for delimiter in delimiters {
                                    if let r = buffer.range(of: delimiter) {
                                        if delimiterIndex == nil || r.lowerBound < delimiterIndex! {
                                            delimiterIndex = r.lowerBound
                                            delimiterLength = delimiter.count
                                        }
                                    }
                                }
                                guard let idx = delimiterIndex else { break }

                                let eventString = String(buffer[..<idx])
                                let afterDelim = buffer.index(idx, offsetBy: delimiterLength)
                                buffer = String(buffer[afterDelim...])

                                let trimmedEvent = eventString.trimmingCharacters(in: .whitespacesAndNewlines)
                                if trimmedEvent.hasPrefix(dataPrefix) {
                                    let processed = String(trimmedEvent.dropFirst(dataPrefix.count))
                                        .trimmingCharacters(in: .whitespacesAndNewlines)
                                    var headers: [String: String] = [:]
                                    for (k, v) in response.allHeaderFields {
                                        if let ks = k as? String, let vs = v as? String {
                                            headers[ks] = vs
                                        }
                                    }
                                    let partial = HttpResponse(
                                        headers: headers,
                                        bodyData: Data(processed.utf8)
                                    )
                                    continuation.yield(partial)
                                }
                            }
                        }
                    }
                    // End of stream — verify no leftover data.
                    if !buffer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        throw GenAIError.runtime("Incomplete JSON segment at the end")
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - apiCall (URLSession + retry)

    private func apiCall(
        url: URL,
        requestInit: RequestInit,
        httpMethod: HttpMethod
    ) async throws -> (Data, HTTPURLResponse) {
        let urlRequest = ApiClient.buildURLRequest(
            url: url,
            requestInit: requestInit,
            httpMethod: httpMethod
        )

        let retryOptions = self.clientOptions.httpOptions?.retryOptions
        let attempts = retryOptions?.attempts ?? DEFAULT_RETRY_ATTEMPTS

        if retryOptions == nil {
            // No retry — single fetch.
            return try await ApiClient.performRequest(
                urlRequest,
                timeoutMs: requestInit.timeoutMs
            )
        }

        return try await Self.withRetry(attempts: attempts) {
            let (data, response) = try await ApiClient.performRequest(
                urlRequest,
                timeoutMs: requestInit.timeoutMs
            )
            let status = response.statusCode
            if (200..<300).contains(status) {
                return (data, response)
            }
            if DEFAULT_RETRY_HTTP_STATUS_CODES.contains(status) {
                throw RetryableError(message: "Retryable HTTP Error: \(HTTPURLResponse.localizedString(forStatusCode: status))")
            }
            throw AbortError(message: "Non-retryable exception \(HTTPURLResponse.localizedString(forStatusCode: status)) sending request")
        }
    }

    /// Streaming variant — uses URLSession.bytes(for:) to expose an `AsyncBytes` stream.
    private func apiCallStream(
        url: URL,
        requestInit: RequestInit,
        httpMethod: HttpMethod
    ) async throws -> (URLSession.AsyncBytes, HTTPURLResponse) {
        let urlRequest = ApiClient.buildURLRequest(
            url: url,
            requestInit: requestInit,
            httpMethod: httpMethod
        )
        let session = URLSession.shared
        let (bytes, response) = try await session.bytes(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GenAIError.runtime("Response was not an HTTPURLResponse")
        }
        return (bytes, httpResponse)
    }

    private static func buildURLRequest(
        url: URL,
        requestInit: RequestInit,
        httpMethod: HttpMethod
    ) -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod.rawValue
        for (k, v) in requestInit.headers {
            urlRequest.setValue(v, forHTTPHeaderField: k)
        }
        if let body = requestInit.body {
            switch body {
            case .string(let s):
                urlRequest.httpBody = Data(s.utf8)
            case .data(let d):
                urlRequest.httpBody = d
            }
        }
        if let timeoutMs = requestInit.timeoutMs, timeoutMs > 0 {
            urlRequest.timeoutInterval = timeoutMs / 1000.0
        }
        return urlRequest
    }

    private static func performRequest(
        _ urlRequest: URLRequest,
        timeoutMs: Double?
    ) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GenAIError.runtime("Response was not an HTTPURLResponse")
        }
        return (data, httpResponse)
    }

    // MARK: - Retry helper

    private struct RetryableError: Error {
        let message: String
    }
    private struct AbortError: Error {
        let message: String
    }

    /// Hand-rolled `p-retry` equivalent. Retries `work` up to `attempts` total times
    /// (so the call count = `attempts`), with exponential backoff + jitter, except
    /// when an `AbortError` is thrown (which short-circuits).
    static func withRetry<T: Sendable>(
        attempts: Int = DEFAULT_RETRY_ATTEMPTS,
        _ work: @Sendable () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        let totalAttempts = max(1, attempts)
        for attempt in 0..<totalAttempts {
            do {
                return try await work()
            } catch let err as AbortError {
                throw GenAIError.runtime(err.message)
            } catch {
                lastError = error
                if attempt == totalAttempts - 1 { break }
                // Exponential backoff: 1s, 2s, 4s, 8s ... capped at 30s, with small jitter.
                let baseDelaySec = min(pow(2.0, Double(attempt)), 30.0)
                let jitter = Double.random(in: 0...0.5)
                let totalNs = UInt64((baseDelaySec + jitter) * 1_000_000_000)
                try await Task.sleep(nanoseconds: totalNs)
            }
        }
        throw lastError ?? GenAIError.runtime("withRetry exhausted with no error captured")
    }

    // MARK: - Default / per-request headers

    public func getDefaultHeaders() -> [String: String] {
        return ApiClient.getDefaultHeadersStatic(userAgentExtra: self.clientOptions.userAgentExtra)
    }

    private static func getDefaultHeadersStatic(userAgentExtra: String?) -> [String: String] {
        var headers: [String: String] = [:]
        let suffix = userAgentExtra ?? ""
        // Mirror TS template-literal: `${LIBRARY_LABEL} ${userAgentExtra}` — TS prints "undefined" if missing.
        let versionHeaderValue = LIBRARY_LABEL + " " + (userAgentExtra == nil ? "undefined" : suffix)
        headers[USER_AGENT_HEADER] = versionHeaderValue
        headers[GOOGLE_API_CLIENT_HEADER] = versionHeaderValue
        headers[CONTENT_TYPE_HEADER] = "application/json"
        return headers
    }

    private func getHeadersInternal(
        httpOptions: HttpOptions?,
        url: String
    ) async throws -> [String: String] {
        var headers: [String: String] = [:]
        if let optHeaders = httpOptions?.headers {
            for (k, v) in optHeaders {
                headers[k] = v
            }
        }
        // X-Server-Timeout is set whenever a timeout is configured — even without other custom headers.
        if let timeout = httpOptions?.timeout, timeout > 0 {
            let seconds = Int((timeout / 1000.0).rounded(.up))
            headers[SERVER_TIMEOUT_HEADER] = String(seconds)
        }
        try await self.clientOptions.auth.addAuthHeaders(&headers, url: url)
        return headers
    }

    // MARK: - File name utility

    private func getFileName(_ file: FileInput) -> String {
        switch file {
        case .path(let p):
            // Strip trailing slashes/backslashes then take last component.
            var path = p
            while path.hasSuffix("/") || path.hasSuffix("\\") {
                path = String(path.dropLast())
            }
            // Split on / or \
            let components = path.split(whereSeparator: { $0 == "/" || $0 == "\\" })
            return components.last.map(String.init) ?? ""
        case .data:
            return ""
        }
    }

    // MARK: - uploadFile

    /// Uploads a file asynchronously using Gemini API only.
    public func uploadFile(
        _ file: FileInput,
        config: UploadFileConfig? = nil
    ) async throws -> File {
        var fileToUpload = File()
        if let config = config {
            fileToUpload.mimeType = config.mimeType
            fileToUpload.name = config.name
            fileToUpload.displayName = config.displayName
        }

        if let n = fileToUpload.name, !n.hasPrefix("files/") {
            fileToUpload.name = "files/\(n)"
        }

        let uploader = self.clientOptions.uploader
        let fileStat = try await uploader.stat(file)
        fileToUpload.sizeBytes = String(fileStat.size)
        let mimeType = config?.mimeType ?? fileStat.type
        guard let resolvedMime = mimeType, !resolvedMime.isEmpty else {
            throw GenAIError.invalidArgument(
                "Can not determine mimeType. Please provide mimeType in the config."
            )
        }
        fileToUpload.mimeType = resolvedMime

        // Body for the resumable-upload start request. The TS implementation passes
        // `{ file: fileToUpload }` and then resolves `body['_url']` via formatMap;
        // there is no `_url` placeholder in the path, so the formatted path equals
        // the input. We preserve that behavior.
        let bodyDict: [String: JSONValue] = [
            "file": ApiClient.fileToJSONValue(fileToUpload)
        ]
        let fileName = self.getFileName(file)
        let path = try formatMap("upload/v1beta/files", [:])
        let uploadUrl = try await self.fetchUploadUrl(
            path: path,
            sizeBytes: fileToUpload.sizeBytes ?? "0",
            mimeType: resolvedMime,
            fileName: fileName,
            body: bodyDict,
            configHttpOptions: config?.httpOptions
        )
        return try await uploader.upload(file, uploadUrl: uploadUrl, apiClient: self)
    }

    /// Uploads a file to a given file search store. Gemini API only.
    public func uploadFileToFileSearchStore(
        fileSearchStoreName: String,
        file: FileInput,
        config: UploadToFileSearchStoreConfig? = nil
    ) async throws -> UploadToFileSearchStoreOperation {
        let uploader = self.clientOptions.uploader
        let fileStat = try await uploader.stat(file)
        let sizeBytes = String(fileStat.size)
        let mimeType = config?.mimeType ?? fileStat.type
        guard let resolvedMime = mimeType, !resolvedMime.isEmpty else {
            throw GenAIError.invalidArgument(
                "Can not determine mimeType. Please provide mimeType in the config."
            )
        }
        let path = "upload/v1beta/\(fileSearchStoreName):uploadToFileSearchStore"
        let fileName = self.getFileName(file)
        var body: [String: JSONValue] = [:]
        if let config = config {
            _ = uploadToFileSearchStoreConfigToMldev(config, &body)
        }
        let uploadUrl = try await self.fetchUploadUrl(
            path: path,
            sizeBytes: sizeBytes,
            mimeType: resolvedMime,
            fileName: fileName,
            body: body,
            configHttpOptions: config?.httpOptions
        )
        return try await uploader.uploadToFileSearchStore(file, uploadUrl: uploadUrl, apiClient: self)
    }

    // MARK: - downloadFile

    public func downloadFile(_ params: DownloadFileParameters) async throws {
        let downloader = self.clientOptions.downloader
        try await downloader.download(params, apiClient: self)
    }

    // MARK: - fetchUploadUrl

    private func fetchUploadUrl(
        path: String,
        sizeBytes: String,
        mimeType: String,
        fileName: String,
        body: [String: JSONValue],
        configHttpOptions: HttpOptions?
    ) async throws -> String {
        var httpOptions: HttpOptions
        if let configHttpOptions = configHttpOptions {
            httpOptions = configHttpOptions
        } else {
            var headers: [String: String] = [
                "Content-Type": "application/json",
                "X-Goog-Upload-Protocol": "resumable",
                "X-Goog-Upload-Command": "start",
                "X-Goog-Upload-Header-Content-Length": "\(sizeBytes)",
                "X-Goog-Upload-Header-Content-Type": "\(mimeType)",
            ]
            if !fileName.isEmpty {
                headers["X-Goog-Upload-File-Name"] = fileName
            }
            httpOptions = HttpOptions(
                apiVersion: "", // api-version is set in the path.
                headers: headers
            )
        }

        let bodyData = try JSONEncoder().encode(JSONValue.object(body))
        let bodyString = String(data: bodyData, encoding: .utf8) ?? "{}"
        let httpResponse = try await self.request(HttpRequest(
            path: path,
            body: .string(bodyString),
            httpMethod: .POST,
            httpOptions: httpOptions
        ))

        guard let headers = httpResponse.headers else {
            throw GenAIError.runtime(
                "Server did not return an HttpResponse or the returned HttpResponse did not have headers."
            )
        }
        // Header lookup is case-insensitive — Foundation may title-case keys.
        let uploadUrl = headers.first(where: { $0.key.lowercased() == "x-goog-upload-url" })?.value
        guard let uploadUrl = uploadUrl else {
            throw GenAIError.runtime(
                "Failed to get upload url. Server did not return the x-google-upload-url in the headers"
            )
        }
        return uploadUrl
    }

    // MARK: - Error mapping

    private static func throwErrorIfNotOK(response: HTTPURLResponse, bodyData: Data?) throws {
        let status = response.statusCode
        if (200..<300).contains(status) {
            return
        }
        // Mirror TS: if JSON, parse it; else wrap text.
        let contentType = (response.value(forHTTPHeaderField: "content-type") ?? "").lowercased()
        let errorBody: [String: JSONValue]
        if contentType.contains("application/json"), let data = bodyData,
           let decoded = try? JSONDecoder().decode(JSONValue.self, from: data),
           case .object(let obj) = decoded {
            errorBody = obj
        } else {
            let text = bodyData.flatMap { String(data: $0, encoding: .utf8) } ?? ""
            errorBody = [
                "error": .object([
                    "message": .string(text),
                    "code": .int(Int64(status)),
                    "status": .string(HTTPURLResponse.localizedString(forStatusCode: status)),
                ])
            ]
        }
        let data = (try? JSONEncoder().encode(JSONValue.object(errorBody))) ?? Data()
        let errorMessage = String(data: data, encoding: .utf8) ?? ""
        if (400..<600).contains(status) {
            throw ApiError(message: errorMessage, status: status)
        }
        throw GenAIError.runtime(errorMessage)
    }

    // MARK: - File → JSONValue serialization helper

    private static func fileToJSONValue(_ file: File) -> JSONValue {
        guard let data = try? JSONEncoder().encode(file),
              let decoded = try? JSONDecoder().decode(JSONValue.self, from: data) else {
            return .object([:])
        }
        return decoded
    }

    // MARK: - includeExtraBodyToRequestInit

    /// Recursively merges `extraBody` into the JSON-encoded `requestInit.body`.
    /// If body is `Data`/Blob, the merge is skipped (matches TS warning behavior).
    fileprivate static func includeExtraBodyToRequestInit(
        _ requestInit: inout RequestInit,
        extraBody: [String: JSONValue]
    ) {
        if extraBody.isEmpty { return }

        // Blob equivalent — skip with warning.
        if case .data = requestInit.body {
            print("includeExtraBodyToRequestInit: extraBody provided but current request body is a Blob. extraBody will be ignored as merging is not supported for Blob bodies.")
            return
        }

        var currentBodyObject: [String: JSONValue] = [:]
        if case .string(let s) = requestInit.body, !s.isEmpty {
            guard let data = s.data(using: .utf8),
                  let parsed = try? JSONDecoder().decode(JSONValue.self, from: data) else {
                print("includeExtraBodyToRequestInit: Original request body is not valid JSON. Skip applying extraBody to the request body.")
                return
            }
            if case .object(let obj) = parsed {
                currentBodyObject = obj
            } else {
                print("includeExtraBodyToRequestInit: Original request body is valid JSON but not a non-array object. Skip applying extraBody to the request body.")
                return
            }
        }

        let merged = deepMergeJSON(currentBodyObject, extraBody)
        if let data = try? JSONEncoder().encode(JSONValue.object(merged)),
           let str = String(data: data, encoding: .utf8) {
            requestInit.body = .string(str)
        }
    }

    /// Public-ish overload that accepts a mutable `HttpBody` directly — used by
    /// future callers that want extraBody merging without crafting a `RequestInit`.
    internal static func includeExtraBody(
        body: inout HttpBody?,
        extraBody: [String: JSONValue]
    ) {
        var ri = RequestInit()
        ri.body = body
        includeExtraBodyToRequestInit(&ri, extraBody: extraBody)
        body = ri.body
    }
}

// MARK: - JSON deep merge (file-scope helper)

private func deepMergeJSON(
    _ target: [String: JSONValue],
    _ source: [String: JSONValue]
) -> [String: JSONValue] {
    var output = target
    for (key, sourceValue) in source {
        let targetValue = output[key]
        if case .object(let sObj) = sourceValue,
           case .object(let tObj) = (targetValue ?? .null) {
            output[key] = .object(deepMergeJSON(tObj, sObj))
        } else {
            if let tv = targetValue, !typesEqual(tv, sourceValue) {
                print("includeExtraBodyToRequestInit:deepMerge: Type mismatch for key \"\(key)\". Overwriting.")
            }
            output[key] = sourceValue
        }
    }
    return output
}

private func typesEqual(_ a: JSONValue, _ b: JSONValue) -> Bool {
    switch (a, b) {
    case (.null, .null), (.bool, .bool), (.int, .int), (.double, .double),
         (.string, .string), (.array, .array), (.object, .object):
        return true
    // Treat int / double as the same numeric "type" for warning purposes.
    case (.int, .double), (.double, .int):
        return true
    default:
        return false
    }
}
