// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Platform-specific cache for tokenizer models.
public protocol TokenizerCache: Sendable {
    /// Returns cached model bytes if they exist and the SHA-256 matches `expectedHash`, else `nil`.
    func load(cacheKey: String, expectedHash: String) async throws -> Data?

    /// Persists `data` under `cacheKey`. Implementations should treat failures as best-effort.
    func save(cacheKey: String, data: Data) async throws
}

/// Platform-specific file system / network operations for tokenizer loading.
public protocol TokenizerFileSystem: Sendable {
    /// Downloads bytes from `url`.
    func fetchFromUrl(_ url: String) async throws -> Data

    /// Returns `true` iff `SHA-256(data)` matches `expectedHash` (lowercase hex).
    func validateHash(_ data: Data, expectedHash: String) async throws -> Bool

    /// Computes the lowercase-hex SHA-1 of `text` for use as a cache key.
    func computeSha1(_ text: Data) async throws -> String
}

/// Bundle of platform-specific dependencies for the tokenizer.
public struct TokenizerPlatform: Sendable {
    public var cache: TokenizerCache
    public var fileSystem: TokenizerFileSystem

    public init(cache: TokenizerCache, fileSystem: TokenizerFileSystem) {
        self.cache = cache
        self.fileSystem = fileSystem
    }
}

/// Configuration for a specific tokenizer model.
public struct TokenizerConfig: Sendable, Equatable {
    public var modelUrl: String
    public var modelHash: String

    public init(modelUrl: String, modelHash: String) {
        self.modelUrl = modelUrl
        self.modelHash = modelHash
    }
}

/// Public surface area of the local tokenizer.
public protocol ILocalTokenizer: Sendable {
    /// Counts the number of tokens in `contents`.
    func countTokens(
        contents: ContentListUnion,
        config: CountTokensConfig?
    ) async throws -> CountTokensResult

    /// Computes detailed token information for `contents`.
    func computeTokens(contents: ContentListUnion) async throws -> ComputeTokensResult
}
