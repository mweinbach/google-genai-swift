// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

// Mirrors `internal/builtin-types.ts`.
//
// The TS file re-exports the browser/node Fetch/RequestInit/Response/Headers types
// so they can be imported under aliased names. In Swift we use Foundation types
// directly (`URLSession`, `URLRequest`, `HTTPURLResponse`, `[String: String]`),
// so this file exists purely to document the mapping.

/// The Fetch function signature: takes a request and optionally a per-call init,
/// returns the response. In Swift we use URLSession directly; this is a typealias
/// for documentation only.
public typealias InteractionsFetch = @Sendable (URLRequest) async throws -> (Data, URLResponse)

/// Mirrors `BlobPropertyBag` — options for constructing a Blob/File. Swift uses
/// `Data` plus separate mime-type/filename, so this struct is kept for parity.
public struct BlobPropertyBag: Sendable {
    public enum EndingType: String, Sendable { case native, transparent }
    public var endings: EndingType?
    public var type: String?
    public init(endings: EndingType? = nil, type: String? = nil) {
        self.endings = endings
        self.type = type
    }
}

/// Mirrors `FilePropertyBag` — extends `BlobPropertyBag` with `lastModified`.
public struct FilePropertyBag: Sendable {
    public var endings: BlobPropertyBag.EndingType?
    public var type: String?
    public var lastModified: Int?
    public init(endings: BlobPropertyBag.EndingType? = nil, type: String? = nil, lastModified: Int? = nil) {
        self.endings = endings
        self.type = type
        self.lastModified = lastModified
    }
}
