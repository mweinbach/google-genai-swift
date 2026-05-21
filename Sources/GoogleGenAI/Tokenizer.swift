// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation
#if canImport(CryptoKit)
import CryptoKit
#elseif canImport(Crypto)
import Crypto
#endif

/// Foundation-based `TokenizerCache` backed by the system temporary directory.
///
/// Collapses the original `node/_node_tokenizer_platform.ts` / `web/...`
/// platform implementations: Apple platforms share Foundation for filesystem
/// access (`FileManager`) and `URLSession` for network.
public final class FoundationTokenizerCache: TokenizerCache, @unchecked Sendable {
    private let cacheDir: URL

    public init() {
        let tmp = FileManager.default.temporaryDirectory
        self.cacheDir = tmp.appendingPathComponent("vertexai_tokenizer_model", isDirectory: true)
    }

    public func load(cacheKey: String, expectedHash: String) async throws -> Data? {
        let filePath = cacheDir.appendingPathComponent(cacheKey)
        guard let data = try? Data(contentsOf: filePath) else {
            return nil
        }
        let hash = sha256Hex(data)
        if hash == expectedHash {
            return data
        }
        try? FileManager.default.removeItem(at: filePath)
        return nil
    }

    public func save(cacheKey: String, data: Data) async throws {
        do {
            try FileManager.default.createDirectory(
                at: cacheDir, withIntermediateDirectories: true
            )
            let filePath = cacheDir.appendingPathComponent(cacheKey)
            let tmpPath = cacheDir.appendingPathComponent("\(cacheKey).\(UUID().uuidString).tmp")
            try data.write(to: tmpPath, options: .atomic)
            // Replace any existing file.
            if FileManager.default.fileExists(atPath: filePath.path) {
                try? FileManager.default.removeItem(at: filePath)
            }
            try FileManager.default.moveItem(at: tmpPath, to: filePath)
        } catch {
            // Cache is optional — silently ignore failures.
        }
    }
}

/// Foundation-based `TokenizerFileSystem` using `URLSession` and CryptoKit.
public final class FoundationTokenizerFileSystem: TokenizerFileSystem, @unchecked Sendable {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchFromUrl(_ url: String) async throws -> Data {
        guard let parsedURL = URL(string: url) else {
            throw GenAIError.invalidArgument("Invalid tokenizer model URL: \(url)")
        }
        let (data, response) = try await session.data(from: parsedURL)
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw GenAIError.runtime(
                "Failed to fetch tokenizer model from \(url): HTTP \(http.statusCode)"
            )
        }
        return data
    }

    public func validateHash(_ data: Data, expectedHash: String) async throws -> Bool {
        return sha256Hex(data) == expectedHash
    }

    public func computeSha1(_ text: Data) async throws -> String {
        return sha1Hex(text)
    }
}

/// SHA-256 hex digest of `data`.
private func sha256Hex(_ data: Data) -> String {
    #if canImport(CryptoKit) || canImport(Crypto)
    let digest = SHA256.hash(data: data)
    return digest.map { String(format: "%02x", $0) }.joined()
    #else
    // Fallback: returning empty disables cache validation; should never trigger on Apple platforms.
    return ""
    #endif
}

/// SHA-1 hex digest of `data`.
private func sha1Hex(_ data: Data) -> String {
    #if canImport(CryptoKit) || canImport(Crypto)
    let digest = Insecure.SHA1.hash(data: data)
    return digest.map { String(format: "%02x", $0) }.joined()
    #else
    return ""
    #endif
}

/// Public-facing local tokenizer entry point, wiring up the Foundation platform.
///
/// Mirrors the user-facing surface of `tokenizer/node.ts` and `tokenizer/web.ts`,
/// collapsed into a single Apple-platforms implementation.
///
/// Example:
/// ```swift
/// let tokenizer = try LocalTokenizer(modelName: "gemini-2.0-flash-001")
/// let result = try await tokenizer.countTokens(contents: .part(.text("What is your name?")))
/// print(result.totalTokens ?? 0)
/// ```
public final class LocalTokenizer: Sendable {
    private let base: LocalTokenizerImpl

    /// Creates a new `LocalTokenizer` for the given Gemini `modelName`,
    /// using the default Foundation-backed tokenizer platform.
    public convenience init(modelName: String) throws {
        let platform = TokenizerPlatform(
            cache: FoundationTokenizerCache(),
            fileSystem: FoundationTokenizerFileSystem()
        )
        try self.init(modelName: modelName, platform: platform)
    }

    /// Creates a new `LocalTokenizer` with an explicit `TokenizerPlatform`,
    /// useful for tests or custom caching/network implementations.
    public init(modelName: String, platform: TokenizerPlatform) throws {
        self.base = try LocalTokenizerImpl(modelName: modelName, platform: platform)
    }

    /// Counts the number of tokens in the given content.
    public func countTokens(
        contents: ContentListUnion,
        config: CountTokensConfig? = nil
    ) async throws -> CountTokensResult {
        return try await base.countTokens(contents: contents, config: config)
    }

    /// Computes detailed token information for the given content.
    public func computeTokens(contents: ContentListUnion) async throws -> ComputeTokensResult {
        return try await base.computeTokens(contents: contents)
    }
}
