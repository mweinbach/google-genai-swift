// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// `LocalTokenizer` provides text-only local tokenization for Gemini models.
///
/// LIMITATIONS:
/// - Only supports text-based tokenization (no multimodal)
/// - Forward compatibility depends on open-source tokenizer models
/// - For tools/schemas, only supports `Tool` and `Schema` objects
public actor LocalTokenizerImpl: ILocalTokenizer {
    private let modelName: String
    private let tokenizerName: String
    private let platform: TokenizerPlatform
    private var processor: SentencePieceProcessor?

    public init(modelName: String, platform: TokenizerPlatform) throws {
        self.modelName = modelName
        self.tokenizerName = try getTokenizerName(modelName)
        self.platform = platform
    }

    private func ensureProcessor() async throws -> SentencePieceProcessor {
        if let processor { return processor }
        let modelBytes = try await loadModelProtoBytes(
            tokenizerName: tokenizerName,
            platform: platform
        )
        let processor = try SentencePieceProcessor(modelProtoBytes: modelBytes)
        self.processor = processor
        return processor
    }

    /// Counts the number of tokens in the given content.
    public func countTokens(
        contents: ContentListUnion,
        config: CountTokensConfig? = nil
    ) async throws -> CountTokensResult {
        let processor = try await ensureProcessor()
        let processedContents = try tContents(contents)

        let accumulator = TextsAccumulator()
        try accumulator.addContents(processedContents)

        if let systemInstruction = config?.systemInstruction {
            let systemContent = try tContent(systemInstruction)
            try accumulator.addContents([systemContent])
        }

        if let tools = config?.tools {
            accumulator.addTools(tools)
        }

        if let responseSchema = config?.generationConfig?.responseSchema {
            accumulator.addSchema(responseSchema)
        }

        var totalTokens = 0
        for text in accumulator.getTexts() {
            totalTokens += processor.encode(text).count
        }

        return CountTokensResult(totalTokens: Double(totalTokens))
    }

    /// Computes detailed token information for the given content.
    public func computeTokens(contents: ContentListUnion) async throws -> ComputeTokensResult {
        let processor = try await ensureProcessor()
        let processedContents = try tContents(contents)

        var tokensInfo: [TokensInfo] = []
        for content in processedContents {
            let accumulator = TextsAccumulator()
            try accumulator.addContent(content)

            var allTokenIds: [Int] = []
            var allTokens: [String] = []
            for text in accumulator.getTexts() {
                let tokens = processor.encode(text)
                for t in tokens {
                    allTokenIds.append(t.id)
                    allTokens.append(tokenTextToBase64(t.text))
                }
            }

            if !allTokenIds.isEmpty {
                tokensInfo.append(TokensInfo(
                    role: content.role,
                    tokenIds: allTokenIds.map { String($0) },
                    tokens: allTokens
                ))
            }
        }

        return ComputeTokensResult(tokensInfo: tokensInfo)
    }

    /// Converts a piece's display text to base64, mirroring the TS implementation
    /// which replaces SentencePiece's "▁" separator with a space first.
    private nonisolated func tokenTextToBase64(_ text: String) -> String {
        var replaced = ""
        replaced.reserveCapacity(text.count)
        for ch in text {
            if ch == "\u{2581}" {
                replaced.append(" ")
            } else {
                replaced.append(ch)
            }
        }
        return Data(replaced.utf8).base64EncodedString()
    }
}
