// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Per-request options. Mirrors `RequestOptions` in `internal/request-options.ts`.
public struct RequestOptions: Sendable {
    public var method: InteractionsHTTPMethod?
    public var path: String?
    public var query: [String: JSONValue]?
    public var body: JSONValue?
    public var headers: HeadersLike?
    public var maxRetries: Int?
    public var stream: Bool?
    public var timeout: Double?
    public var fetchOptions: MergedRequestInit?
    public var signal: AbortSignalToken?
    public var idempotencyKey: String?
    public var defaultBaseURL: String?
    public var binaryResponse: Bool?
    /// The class name of an override stream subclass — e.g. `"LegacyLyriaStream"`.
    public var streamClass: String?

    public init(
        method: InteractionsHTTPMethod? = nil,
        path: String? = nil,
        query: [String: JSONValue]? = nil,
        body: JSONValue? = nil,
        headers: HeadersLike? = nil,
        maxRetries: Int? = nil,
        stream: Bool? = nil,
        timeout: Double? = nil,
        fetchOptions: MergedRequestInit? = nil,
        signal: AbortSignalToken? = nil,
        idempotencyKey: String? = nil,
        defaultBaseURL: String? = nil,
        binaryResponse: Bool? = nil,
        streamClass: String? = nil
    ) {
        self.method = method
        self.path = path
        self.query = query
        self.body = body
        self.headers = headers
        self.maxRetries = maxRetries
        self.stream = stream
        self.timeout = timeout
        self.fetchOptions = fetchOptions
        self.signal = signal
        self.idempotencyKey = idempotencyKey
        self.defaultBaseURL = defaultBaseURL
        self.binaryResponse = binaryResponse
        self.streamClass = streamClass
    }
}

/// `FinalRequestOptions` = `RequestOptions` with `method` and `path` required.
public struct FinalRequestOptions: Sendable {
    public var method: InteractionsHTTPMethod
    public var path: String
    public var query: [String: JSONValue]?
    public var body: JSONValue?
    public var headers: HeadersLike?
    public var maxRetries: Int?
    public var stream: Bool?
    public var timeout: Double?
    public var fetchOptions: MergedRequestInit?
    public var signal: AbortSignalToken?
    public var idempotencyKey: String?
    public var defaultBaseURL: String?
    public var binaryResponse: Bool?
    public var streamClass: String?

    public init(
        method: InteractionsHTTPMethod,
        path: String,
        options: RequestOptions = RequestOptions()
    ) {
        self.method = method
        self.path = path
        self.query = options.query
        self.body = options.body
        self.headers = options.headers
        self.maxRetries = options.maxRetries
        self.stream = options.stream
        self.timeout = options.timeout
        self.fetchOptions = options.fetchOptions
        self.signal = options.signal
        self.idempotencyKey = options.idempotencyKey
        self.defaultBaseURL = options.defaultBaseURL
        self.binaryResponse = options.binaryResponse
        self.streamClass = options.streamClass
    }
}

/// Output of a `RequestEncoder` — body bytes plus any header overrides required to
/// describe them (e.g. `content-type`).
public struct EncodedContent: Sendable {
    public var bodyHeaders: HeadersLike?
    public var body: Data
    public init(bodyHeaders: HeadersLike?, body: Data) {
        self.bodyHeaders = bodyHeaders
        self.body = body
    }
}

/// Encodes an in-memory request body into bytes. Mirrors `RequestEncoder`.
public typealias RequestEncoder = @Sendable (_ headers: NullableHeaders, _ body: JSONValue?) throws -> EncodedContent

/// Default fallback encoder — JSON-stringifies the body, sets `content-type: application/json`.
/// Mirrors `FallbackEncoder` in `internal/request-options.ts`.
public let fallbackEncoder: RequestEncoder = { _, body in
    let payload = body ?? .null
    let data = try JSONEncoder().encode(payload)
    return EncodedContent(
        bodyHeaders: .map(["content-type": "application/json"]),
        body: data
    )
}
