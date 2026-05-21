// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Source of truth:
/// https://cloud.google.com/vertex-ai/generative-ai/docs/learn/models
private let geminiModelsToTokenizerNames: [String: String] = [
    "gemini-2.5-pro": "gemma3",
    "gemini-2.5-flash": "gemma3",
    "gemini-2.5-flash-lite": "gemma3",
    "gemini-2.0-flash": "gemma3",
    "gemini-2.0-flash-lite": "gemma3",
]

private let geminiStableModelsToTokenizerNames: [String: String] = [
    "gemini-3-pro-preview": "gemma3",
    "gemini-2.5-pro-preview-06-05": "gemma3",
    "gemini-2.5-pro-preview-05-06": "gemma3",
    "gemini-2.5-pro-exp-03-25": "gemma3",
    "gemini-live-2.5-flash": "gemma3",
    "gemini-2.5-flash-preview-05-20": "gemma3",
    "gemini-2.5-flash-preview-04-17": "gemma3",
    "gemini-2.5-flash-lite-preview-06-17": "gemma3",
    "gemini-2.0-flash-001": "gemma3",
    "gemini-2.0-flash-lite-001": "gemma3",
]

private let tokenizers: [String: TokenizerConfig] = [
    "gemma2": TokenizerConfig(
        modelUrl:
            "https://raw.githubusercontent.com/google/gemma_pytorch/33b652c465537c6158f9a472ea5700e5e770ad3f/tokenizer/tokenizer.model",
        modelHash:
            "61a7b147390c64585d6c3543dd6fc636906c9af3865a5548f27f31aee1d4c8e2"
    ),
    "gemma3": TokenizerConfig(
        modelUrl:
            "https://raw.githubusercontent.com/google/gemma_pytorch/014acb7ac4563a5f77c76d7ff98f31b568c16508/tokenizer/gemma3_cleaned_262144_v2.spiece.model",
        modelHash:
            "1299c11d7cf632ef3b4e11937501358ada021bbdf7c47638d13c0ee982f2e79c"
    ),
]

/// Returns the tokenizer name to use for a given Gemini model name.
public func getTokenizerName(_ modelName: String) throws -> String {
    if let name = geminiModelsToTokenizerNames[modelName] {
        return name
    }
    if let name = geminiStableModelsToTokenizerNames[modelName] {
        return name
    }
    let supportedModels = (
        Array(geminiModelsToTokenizerNames.keys) +
        Array(geminiStableModelsToTokenizerNames.keys)
    ).joined(separator: ", ")
    throw GenAIError.unsupported(
        "Model \(modelName) is not supported for local tokenization. Supported models: \(supportedModels)."
    )
}

/// Returns the `TokenizerConfig` for a given tokenizer name (e.g. `"gemma3"`).
public func getTokenizerConfig(_ tokenizerName: String) throws -> TokenizerConfig {
    guard let cfg = tokenizers[tokenizerName] else {
        let names = Array(tokenizers.keys).joined(separator: ", ")
        throw GenAIError.unsupported(
            "Tokenizer \(tokenizerName) is not supported. Supported tokenizers: \(names)"
        )
    }
    return cfg
}

/// Loads tokenizer model bytes from cache or by downloading them.
public func loadModelProtoBytes(
    tokenizerName: String,
    platform: TokenizerPlatform
) async throws -> Data {
    let config = try getTokenizerConfig(tokenizerName)

    let urlBytes = Data(config.modelUrl.utf8)
    let cacheKey = try await platform.fileSystem.computeSha1(urlBytes)

    if let cached = try await platform.cache.load(cacheKey: cacheKey, expectedHash: config.modelHash) {
        return cached
    }

    let modelData = try await platform.fileSystem.fetchFromUrl(config.modelUrl)

    let isValid = try await platform.fileSystem.validateHash(modelData, expectedHash: config.modelHash)
    if !isValid {
        let actualHash = try await platform.fileSystem.computeSha1(modelData)
        throw GenAIError.runtime(
            "Downloaded model file is corrupted. Expected hash \(config.modelHash). Got file hash \(actualHash)."
        )
    }

    try await platform.cache.save(cacheKey: cacheKey, data: modelData)
    return modelData
}
