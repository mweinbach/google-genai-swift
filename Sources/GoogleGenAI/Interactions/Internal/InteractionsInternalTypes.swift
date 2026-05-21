// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

// Mirrors `internal/types.ts`.

/// HTTP methods supported by the SDK. Mirrors TS `HTTPMethod`.
public enum InteractionsHTTPMethod: String, Sendable {
    case get
    case post
    case put
    case patch
    case delete

    public var uppercased: String { rawValue.uppercased() }
}

/// `Promise<T> | T` becomes `async throws -> T` in Swift — there's no value-vs-promise
/// distinction. This alias is kept for documentation parity with `PromiseOrValue<T>`.
public typealias PromiseOrValue<T> = T

/// Merged `RequestInit`-like overrides. The TS form is a complex union of platform
/// dispatcher/agent options; in Swift we expose a small subset on `URLRequest`.
public struct MergedRequestInit: Sendable {
    public var timeoutInterval: TimeInterval?
    public var cachePolicy: URLRequest.CachePolicy?
    public var allowsCellularAccess: Bool?
    public init(
        timeoutInterval: TimeInterval? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil,
        allowsCellularAccess: Bool? = nil
    ) {
        self.timeoutInterval = timeoutInterval
        self.cachePolicy = cachePolicy
        self.allowsCellularAccess = allowsCellularAccess
    }
}

/// Mirrors TS `FinalizedRequestInit`. Pairs the underlying URLRequest with its
/// fully built header dictionary so downstream code can mutate either.
public struct FinalizedRequestInit: Sendable {
    public var request: URLRequest
    public var headers: [String: String]
    public init(request: URLRequest, headers: [String: String]) {
        self.request = request
        self.headers = headers
    }
}
