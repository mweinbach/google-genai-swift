// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// A "Promise"-like helper that wraps a pending API call and lets the caller
/// choose between getting the parsed response or the raw HTTPURLResponse.
/// Mirrors `APIPromise<T>` from `core/api-promise.ts`.
///
/// Swift has no `Promise` superclass; we model the equivalent as an actor-shaped
/// class with `value()` (parsed) and `asResponse()` (raw) async accessors.
public final class APIPromise<T: Sendable>: @unchecked Sendable {
    public typealias ParseFn = @Sendable (_ client: BaseGeminiNextGenAPIClient, _ props: APIResponseProps) async throws -> T

    private let client: BaseGeminiNextGenAPIClient
    private let responseFactory: @Sendable () async throws -> APIResponseProps
    private let parseResponse: ParseFn

    public init(
        client: BaseGeminiNextGenAPIClient,
        responseFactory: @escaping @Sendable () async throws -> APIResponseProps,
        parseResponse: @escaping ParseFn
    ) {
        self.client = client
        self.responseFactory = responseFactory
        self.parseResponse = parseResponse
    }

    /// Returns a new `APIPromise` whose value is the result of applying `transform`
    /// to the resolved value. Mirrors `_thenUnwrap`.
    public func thenUnwrap<U: Sendable>(_ transform: @escaping @Sendable (T, APIResponseProps) async throws -> U) -> APIPromise<U> {
        let inner = self
        return APIPromise<U>(
            client: client,
            responseFactory: inner.responseFactory,
            parseResponse: { client, props in
                let value = try await inner.parseResponse(client, props)
                return try await transform(value, props)
            }
        )
    }

    /// Returns the raw HTTPURLResponse without parsing the body.
    public func asResponse() async throws -> HTTPURLResponse {
        let props = try await responseFactory()
        return props.response
    }

    /// Returns both the parsed body and the raw HTTPURLResponse.
    public func withResponse() async throws -> (data: T, response: HTTPURLResponse) {
        let props = try await responseFactory()
        let value = try await parseResponse(client, props)
        return (value, props.response)
    }

    /// Awaits and returns the parsed value.
    public func value() async throws -> T {
        let props = try await responseFactory()
        return try await parseResponse(client, props)
    }
}
