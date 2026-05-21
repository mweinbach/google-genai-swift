// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Options for constructing a Gemini Next Gen API client. Mirrors `ClientOptions`
/// from `client.ts`.
public struct InteractionsClientOptions: Sendable {
    public var apiKey: String?
    public var apiVersion: String?
    public var baseURL: String?
    public var timeout: TimeInterval?
    public var fetchOptions: MergedRequestInit?
    public var fetch: InteractionsFetch?
    public var maxRetries: Int?
    public var defaultHeaders: HeadersLike?
    public var defaultQuery: [String: String?]?
    public var logLevel: InteractionsLogLevel?
    public var logger: InteractionsLogger?
    public var clientAdapter: InteractionsClientAdapter?

    public init(
        apiKey: String? = nil,
        apiVersion: String? = nil,
        baseURL: String? = nil,
        timeout: TimeInterval? = nil,
        fetchOptions: MergedRequestInit? = nil,
        fetch: InteractionsFetch? = nil,
        maxRetries: Int? = nil,
        defaultHeaders: HeadersLike? = nil,
        defaultQuery: [String: String?]? = nil,
        logLevel: InteractionsLogLevel? = nil,
        logger: InteractionsLogger? = nil,
        clientAdapter: InteractionsClientAdapter? = nil
    ) {
        self.apiKey = apiKey
        self.apiVersion = apiVersion
        self.baseURL = baseURL
        self.timeout = timeout
        self.fetchOptions = fetchOptions
        self.fetch = fetch
        self.maxRetries = maxRetries
        self.defaultHeaders = defaultHeaders
        self.defaultQuery = defaultQuery
        self.logLevel = logLevel
        self.logger = logger
        self.clientAdapter = clientAdapter
    }
}

/// Base class for the Interactions client. Mirrors `BaseGeminiNextGenAPIClient`.
open class BaseGeminiNextGenAPIClient: @unchecked Sendable {
    public static let DEFAULT_TIMEOUT: TimeInterval = 60.0  // 60 seconds (TS: 60_000 ms)

    public var apiKey: String?
    public var apiVersion: String
    public var baseURL: String
    public var maxRetries: Int
    public var timeout: TimeInterval
    public var logger: InteractionsLogger
    public var logLevel: InteractionsLogLevel?
    public var fetchOptions: MergedRequestInit?

    var fetch: InteractionsFetch
    var encoder: RequestEncoder
    var idempotencyHeader: String?
    private var _options: InteractionsClientOptions
    public var clientAdapter: InteractionsClientAdapter?

    public required init(_ optsInput: InteractionsClientOptions) {
        let baseURL = optsInput.baseURL ?? readEnv("GEMINI_NEXT_GEN_API_BASE_URL") ?? "https://generativelanguage.googleapis.com"
        let apiKey = optsInput.apiKey ?? readEnv("GEMINI_API_KEY")
        let apiVersion = optsInput.apiVersion ?? "v1beta"

        var options = optsInput
        options.apiKey = apiKey
        options.apiVersion = apiVersion
        options.baseURL = baseURL

        self.baseURL = baseURL
        self.timeout = options.timeout ?? Self.DEFAULT_TIMEOUT
        self.logger = options.logger ?? ConsoleInteractionsLogger()
        let defaultLogLevel: InteractionsLogLevel = .warn
        self.logLevel = defaultLogLevel
        self.fetchOptions = options.fetchOptions
        self.maxRetries = options.maxRetries ?? 2
        self.fetch = options.fetch ?? getDefaultFetch()
        self.encoder = fallbackEncoder

        self._options = options
        self.apiKey = apiKey
        self.apiVersion = apiVersion
        self.clientAdapter = options.clientAdapter

        // Re-resolve log level now that `self` is fully initialized so warnings can be emitted.
        self.logLevel = parseLogLevel(options.logLevel?.rawValue, sourceName: "ClientOptions.logLevel", client: self)
            ?? parseLogLevel(readEnv("GEMINI_NEXT_GEN_API_LOG"), sourceName: "process.env['GEMINI_NEXT_GEN_API_LOG']", client: self)
            ?? defaultLogLevel
    }

    /// Create a new client instance re-using the same options with optional overrides.
    public func withOptions(_ options: InteractionsClientOptions) -> Self {
        var merged = _options
        if let v = options.apiKey { merged.apiKey = v }
        if let v = options.apiVersion { merged.apiVersion = v }
        if let v = options.baseURL { merged.baseURL = v }
        if let v = options.timeout { merged.timeout = v }
        if let v = options.fetchOptions { merged.fetchOptions = v }
        if let v = options.fetch { merged.fetch = v }
        if let v = options.maxRetries { merged.maxRetries = v }
        if let v = options.defaultHeaders { merged.defaultHeaders = v }
        if let v = options.defaultQuery { merged.defaultQuery = v }
        if let v = options.logLevel { merged.logLevel = v }
        if let v = options.logger { merged.logger = v }
        if let v = options.clientAdapter { merged.clientAdapter = v }
        return Self(merged)
    }


    // Check whether the base URL is set to its default.
    private func baseURLOverridden() -> Bool {
        return baseURL != "https://generativelanguage.googleapis.com"
    }

    open func defaultQuery() -> [String: String?]? {
        return _options.defaultQuery
    }

    /// Validate that required auth headers are present.
    open func validateHeaders(_ nh: NullableHeaders) throws {
        let lowerKeys = Set(nh.values.keys.map { $0.lowercased() })
        if lowerKeys.contains("authorization") || lowerKeys.contains("x-goog-api-key") {
            return
        }
        if apiKey != nil, nh.values["x-goog-api-key"] != nil {
            return
        }
        if nh.nulls.contains("x-goog-api-key") {
            return
        }
        throw GeminiNextGenAPIClientError.message(
            "Could not resolve authentication method. Expected the apiKey to be set. Or for the \"x-goog-api-key\" headers to be explicitly omitted"
        )
    }

    open func authHeaders(_ opts: FinalRequestOptions) async throws -> NullableHeaders? {
        let existingHeaders = buildHeaders([opts.headers ?? .none])
        let lower = Set(existingHeaders.values.keys.map { $0.lowercased() })
        if lower.contains("authorization") || lower.contains("x-goog-api-key") {
            return nil
        }
        if let apiKey = apiKey {
            return buildHeaders([.map(["x-goog-api-key": apiKey])])
        }
        if let adapter = clientAdapter, adapter.isVertexAI() {
            let headers = try await adapter.getAuthHeaders()
            return buildHeaders([.map(headers.mapValues { Optional($0) })])
        }
        return nil
    }

    open func stringifyQuery(_ query: [String: JSONValue]) throws -> String {
        return try Interactions_stringifyQueryWrapper(query)
    }

    private func getUserAgent() -> String {
        return "GeminiNextGenAPIClient/Swift \(INTERACTIONS_VERSION)"
    }

    open func defaultIdempotencyKey() -> String {
        return "stainless-swift-retry-\(uuid4())"
    }

    open func makeStatusError(
        status: Int,
        error: JSONValue?,
        message: String?,
        headers: [String: String]
    ) -> InteractionsAPIError {
        return InteractionsAPIError.generate(status: status, errorResponse: error, message: message, headers: headers)
    }

    /// Build the URL for a given path and query parameters.
    public func buildURL(
        path: String,
        query: [String: JSONValue]?,
        defaultBaseURL: String? = nil
    ) throws -> String {
        let chosen = (!baseURLOverridden() && defaultBaseURL != nil) ? defaultBaseURL! : baseURL
        var urlString: String
        if isAbsoluteURL(path) {
            urlString = path
        } else {
            let trimmed = (chosen.hasSuffix("/") && path.hasPrefix("/")) ? String(path.dropFirst()) : path
            urlString = chosen + trimmed
        }

        guard var comps = URLComponents(string: urlString) else {
            throw GeminiNextGenAPIClientError.message("Invalid URL: \(urlString)")
        }

        let defaultQueryDict = defaultQuery() ?? [:]
        var mergedQuery: [String: JSONValue] = [:]
        for item in comps.queryItems ?? [] {
            mergedQuery[item.name] = item.value.map { .string($0) } ?? .null
        }
        for (k, v) in defaultQueryDict {
            if let v = v { mergedQuery[k] = .string(v) }
        }
        if let q = query {
            for (k, v) in q { mergedQuery[k] = v }
        }

        if !mergedQuery.isEmpty {
            comps.percentEncodedQuery = try stringifyQuery(mergedQuery)
        }
        return comps.string ?? urlString
    }

    /// Mutate the request options before sending. Mirrors `prepareOptions`.
    open func prepareOptions(_ options: inout FinalRequestOptions) async throws {
        if let adapter = clientAdapter,
           adapter.isVertexAI(),
           !options.path.hasPrefix("/\(apiVersion)/projects/") {
            let prefix = "/\(apiVersion)"
            let oldPath = options.path.hasPrefix(prefix)
                ? String(options.path.dropFirst(prefix.count))
                : options.path
            let project = adapter.getProject() ?? ""
            let location = adapter.getLocation() ?? ""
            options.path = "/\(apiVersion)/projects/\(project)/locations/\(location)\(oldPath)"
        }
    }

    /// Mutate the underlying URLRequest after headers/body are built. Mirrors `prepareRequest`.
    open func prepareRequest(_ request: inout URLRequest, url: String, options: FinalRequestOptions) async throws {}

    // MARK: - HTTP verb helpers

    public func get(_ path: String, options: RequestOptions = RequestOptions()) -> APIPromise<JSONValue> {
        return methodRequest(.get, path: path, options: options)
    }
    public func post(_ path: String, options: RequestOptions = RequestOptions()) -> APIPromise<JSONValue> {
        return methodRequest(.post, path: path, options: options)
    }
    public func patch(_ path: String, options: RequestOptions = RequestOptions()) -> APIPromise<JSONValue> {
        return methodRequest(.patch, path: path, options: options)
    }
    public func put(_ path: String, options: RequestOptions = RequestOptions()) -> APIPromise<JSONValue> {
        return methodRequest(.put, path: path, options: options)
    }
    public func delete(_ path: String, options: RequestOptions = RequestOptions()) -> APIPromise<JSONValue> {
        return methodRequest(.delete, path: path, options: options)
    }

    private func methodRequest(_ method: InteractionsHTTPMethod, path: String, options: RequestOptions) -> APIPromise<JSONValue> {
        let final = FinalRequestOptions(method: method, path: path, options: options)
        return request(final)
    }

    public func request(_ options: FinalRequestOptions) -> APIPromise<JSONValue> {
        return APIPromise(
            client: self,
            responseFactory: { [weak self] in
                guard let self = self else {
                    throw GeminiNextGenAPIClientError.message("Client was deallocated.")
                }
                return try await self.makeRequest(options, retriesRemaining: nil, retryOfRequestLogID: nil)
            },
            parseResponse: { client, props in
                return try await defaultParseResponse(client: client, props: props)
            }
        )
    }

    private func makeRequest(
        _ optionsInput: FinalRequestOptions,
        retriesRemaining: Int?,
        retryOfRequestLogID: String?
    ) async throws -> APIResponseProps {
        var options = optionsInput
        let maxRetries = options.maxRetries ?? self.maxRetries
        let retriesRemaining = retriesRemaining ?? maxRetries

        try await prepareOptions(&options)

        let (req, url, timeout) = try await buildRequest(options, retryCount: maxRetries - retriesRemaining)
        var urlRequest = req.request
        try await prepareRequest(&urlRequest, url: url, options: options)

        let requestLogID = "log_" + String(format: "%06x", Int.random(in: 0..<(1 << 24)))
        let startTime = Date()

        if options.signal?.aborted == true {
            throw APIUserAbortError()
        }

        let controller = AbortController()
        do {
            let (data, response) = try await fetchWithTimeout(
                request: urlRequest,
                ms: timeout,
                controller: controller
            )
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeminiNextGenAPIClientError.message("Response was not an HTTPURLResponse.")
            }

            if !(200..<300).contains(httpResponse.statusCode) {
                let shouldRetry = self.shouldRetry(httpResponse)
                if retriesRemaining > 0 && shouldRetry {
                    var headers: [String: String] = [:]
                    for (k, v) in httpResponse.allHeaderFields {
                        if let k = k as? String, let v = v as? String { headers[k] = v }
                    }
                    return try await retryRequest(
                        options,
                        retriesRemaining: retriesRemaining,
                        requestLogID: retryOfRequestLogID ?? requestLogID,
                        responseHeaders: headers
                    )
                }
                let errText = String(data: data, encoding: .utf8) ?? ""
                let errJSON = safeJSON(errText)
                let errMessage: String? = (errJSON == nil) ? errText : nil
                var headersDict: [String: String] = [:]
                for (k, v) in httpResponse.allHeaderFields {
                    if let k = k as? String, let v = v as? String { headersDict[k] = v }
                }
                throw makeStatusError(
                    status: httpResponse.statusCode,
                    error: errJSON,
                    message: errMessage,
                    headers: headersDict
                )
            }

            return APIResponseProps(
                response: httpResponse,
                bodyData: data,
                options: options,
                controller: controller,
                requestLogID: requestLogID,
                retryOfRequestLogID: retryOfRequestLogID,
                startTime: startTime
            )
        } catch let err as InteractionsAPIError {
            throw err
        } catch {
            if options.signal?.aborted == true {
                throw APIUserAbortError()
            }
            let isTimeout = isAbortError(error) || String(describing: error).lowercased().contains("timed out")
            if retriesRemaining > 0 {
                return try await retryRequest(
                    options,
                    retriesRemaining: retriesRemaining,
                    requestLogID: retryOfRequestLogID ?? requestLogID,
                    responseHeaders: nil
                )
            }
            if isTimeout {
                throw APIConnectionTimeoutError()
            }
            throw APIConnectionError(cause: error)
        }
    }

    private func fetchWithTimeout(
        request: URLRequest,
        ms: TimeInterval,
        controller: AbortController
    ) async throws -> (Data, URLResponse) {
        var req = request
        if ms > 0 { req.timeoutInterval = ms }
        return try await fetch(req)
    }

    open func shouldRetry(_ response: HTTPURLResponse) -> Bool {
        let header = (response.value(forHTTPHeaderField: "x-should-retry") ?? "").lowercased()
        if header == "true" { return true }
        if header == "false" { return false }
        switch response.statusCode {
        case 408, 409, 429: return true
        case 500...: return true
        default: return false
        }
    }

    private func retryRequest(
        _ options: FinalRequestOptions,
        retriesRemaining: Int,
        requestLogID: String,
        responseHeaders: [String: String]?
    ) async throws -> APIResponseProps {
        var timeoutMillis: Double?
        if let v = responseHeaders?["retry-after-ms"], let n = Double(v) {
            timeoutMillis = n
        }
        if timeoutMillis == nil, let v = responseHeaders?["retry-after"] {
            if let seconds = Double(v) {
                timeoutMillis = seconds * 1000
            }
        }
        if timeoutMillis == nil {
            let maxRetries = options.maxRetries ?? self.maxRetries
            timeoutMillis = calculateDefaultRetryTimeoutMillis(retriesRemaining: retriesRemaining, maxRetries: maxRetries)
        }
        await interactionsSleep(ms: timeoutMillis ?? 0)
        return try await makeRequest(options, retriesRemaining: retriesRemaining - 1, retryOfRequestLogID: requestLogID)
    }

    private func calculateDefaultRetryTimeoutMillis(retriesRemaining: Int, maxRetries: Int) -> Double {
        let initialRetryDelay = 0.5
        let maxRetryDelay = 8.0
        let numRetries = Double(maxRetries - retriesRemaining)
        let sleepSeconds = min(initialRetryDelay * pow(2.0, numRetries), maxRetryDelay)
        let jitter = 1.0 - Double.random(in: 0..<0.25)
        return sleepSeconds * jitter * 1000.0
    }

    open func buildRequest(
        _ inputOptions: FinalRequestOptions,
        retryCount: Int = 0
    ) async throws -> (FinalizedRequestInit, String, TimeInterval) {
        var options = inputOptions
        let url = try buildURL(path: options.path, query: options.query, defaultBaseURL: options.defaultBaseURL)
        if let timeout = options.timeout {
            _ = try validatePositiveInteger("timeout", Int(timeout))
        }
        let timeout = options.timeout ?? self.timeout

        let (bodyHeaders, bodyBytes) = try buildBody(&options)
        let reqHeaders = try await assembleRequestHeaders(
            options: inputOptions,
            method: options.method,
            bodyHeaders: bodyHeaders,
            retryCount: retryCount
        )

        guard let urlObj = URL(string: url) else {
            throw GeminiNextGenAPIClientError.message("Invalid URL: \(url)")
        }
        var urlRequest = URLRequest(url: urlObj)
        urlRequest.httpMethod = options.method.uppercased
        for (k, v) in reqHeaders { urlRequest.setValue(v, forHTTPHeaderField: k) }
        if let body = bodyBytes { urlRequest.httpBody = body }
        if let fo = self.fetchOptions ?? options.fetchOptions {
            if let t = fo.timeoutInterval { urlRequest.timeoutInterval = t }
            if let cp = fo.cachePolicy { urlRequest.cachePolicy = cp }
            if let ac = fo.allowsCellularAccess { urlRequest.allowsCellularAccess = ac }
        }

        return (FinalizedRequestInit(request: urlRequest, headers: reqHeaders), url, timeout)
    }

    private func assembleRequestHeaders(
        options: FinalRequestOptions,
        method: InteractionsHTTPMethod,
        bodyHeaders: HeadersLike?,
        retryCount: Int
    ) async throws -> [String: String] {
        var idempotencyHeaders: HeadersLike = .none
        if let idHeader = idempotencyHeader, method != .get {
            var mut = options
            if mut.idempotencyKey == nil { mut.idempotencyKey = defaultIdempotencyKey() }
            idempotencyHeaders = .map([idHeader: mut.idempotencyKey])
        }
        let authHeaders = try await self.authHeaders(options)

        let headers = buildHeaders([
            idempotencyHeaders,
            .map([
                "Accept": "application/json",
                "User-Agent": getUserAgent(),
                "Api-Revision": "2026-05-20",
            ]),
            _options.defaultHeaders ?? .none,
            bodyHeaders ?? .none,
            options.headers ?? .none,
            authHeaders.map { .nullable($0) } ?? .none,
        ])

        try validateHeaders(headers)
        return headers.values
    }

    private func buildBody(_ options: inout FinalRequestOptions) throws -> (HeadersLike?, Data?) {
        guard let body = options.body else {
            return (nil, nil)
        }
        let headers = buildHeaders([options.headers ?? .none])
        if case .string(let s) = body, headers.values.contains(where: { $0.key.lowercased() == "content-type" }) {
            return (nil, Data(s.utf8))
        }
        // Default: use the JSON encoder.
        let encoded = try encoder(headers, body)
        return (encoded.bodyHeaders, encoded.body)
    }
}

/// Wrapper that forwards to the top-level `stringifyQuery(_:)` to disambiguate
/// the open-method call from the free function.
private func Interactions_stringifyQueryWrapper(_ query: [String: JSONValue]) throws -> String {
    return try stringifyQuery(query)
}

/// Top-level `GeminiNextGenAPIClient`. Mirrors `client.ts`'s leaf class.
public final class GeminiNextGenAPIClient: BaseGeminiNextGenAPIClient, @unchecked Sendable {
    public lazy var interactions: Interactions = Interactions(self)
    public lazy var webhooks: Webhooks = Webhooks(self)
    public lazy var agents: Agents = Agents(self)

    public required init(_ optsInput: InteractionsClientOptions) {
        super.init(optsInput)
    }
}
