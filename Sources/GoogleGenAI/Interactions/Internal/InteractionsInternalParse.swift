// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// The raw response context handed to `defaultParseResponse`. Mirrors `APIResponseProps`
/// in `internal/parse.ts`.
public struct APIResponseProps: Sendable {
    /// Raw HTTP response metadata + body bytes.
    public var response: HTTPURLResponse
    public var bodyData: Data
    public var bodyStream: InteractionsReadableStream?
    public var options: FinalRequestOptions
    /// Cancellation handle for the in-flight request (for SSE early termination).
    public var controller: AbortController
    public var requestLogID: String
    public var retryOfRequestLogID: String?
    public var startTime: Date

    public init(
        response: HTTPURLResponse,
        bodyData: Data,
        bodyStream: InteractionsReadableStream? = nil,
        options: FinalRequestOptions,
        controller: AbortController,
        requestLogID: String,
        retryOfRequestLogID: String? = nil,
        startTime: Date
    ) {
        self.response = response
        self.bodyData = bodyData
        self.bodyStream = bodyStream
        self.options = options
        self.controller = controller
        self.requestLogID = requestLogID
        self.retryOfRequestLogID = retryOfRequestLogID
        self.startTime = startTime
    }
}

/// A simple cancellation token. Mirrors `AbortController` from the Fetch API.
public final class AbortController: @unchecked Sendable {
    private var aborted: Bool = false
    private let lock = NSLock()

    public init() {}

    public var signal: AbortSignalToken {
        return AbortSignalToken(controller: self)
    }

    public func abort() {
        lock.lock(); defer { lock.unlock() }
        aborted = true
    }

    public var isAborted: Bool {
        lock.lock(); defer { lock.unlock() }
        return aborted
    }
}

public struct AbortSignalToken: Sendable {
    weak var controller: AbortController?
    public var aborted: Bool { controller?.isAborted ?? false }
}

/// Default parser: handles streaming responses, 204 No Content, JSON bodies and text.
/// Mirrors `defaultParseResponse` in `internal/parse.ts`. Returns `JSONValue` so the
/// caller can decode further into a concrete type.
public func defaultParseResponse(
    client: BaseGeminiNextGenAPIClient,
    props: APIResponseProps
) async throws -> JSONValue {
    if props.options.stream == true {
        // Streaming is unwrapped by the caller (`APIPromise.parse()` short-circuits
        // for stream=true and hands the consumer a Stream<T> directly).
        return .null
    }
    if props.response.statusCode == 204 {
        return .null
    }
    if props.options.binaryResponse == true {
        return .string(props.bodyData.base64EncodedString())
    }
    let contentType = (props.response.value(forHTTPHeaderField: "content-type") ?? "").lowercased()
    let mediaType = contentType.split(separator: ";").first.map { String($0).trimmingCharacters(in: .whitespaces) } ?? ""
    let isJSON = mediaType.contains("application/json") || mediaType.hasSuffix("+json")
    if isJSON {
        if let cl = props.response.value(forHTTPHeaderField: "content-length"), cl == "0" {
            return .null
        }
        if props.bodyData.isEmpty { return .null }
        return try JSONDecoder().decode(JSONValue.self, from: props.bodyData)
    }
    let text = String(data: props.bodyData, encoding: .utf8) ?? ""
    return .string(text)
}
