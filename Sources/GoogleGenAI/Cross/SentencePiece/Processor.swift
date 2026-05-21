// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Whitespace separator used by SentencePiece (▁, U+2581).
private let whitespaceSeparator: Character = "\u{2581}"

private let symbolBOS = "<bos>"
private let symbolEOS = "<eos>"
private let symbolPAD = "<pad>"

/// A single token produced or consumed by the tokenizer.
public struct Token: Sendable, Equatable {
    public var id: Int
    public var text: String
    public init(id: Int, text: String) {
        self.id = id
        self.text = text
    }
}

/// Summary information about a loaded SentencePiece model.
public struct ModelInfo: Sendable, Equatable {
    public var vocabularySize: Int
    public var beginningOfSentenceID: Int
    public var endOfSentenceID: Int
    public var unknownID: Int
    public var padID: Int

    public init(
        vocabularySize: Int,
        beginningOfSentenceID: Int,
        endOfSentenceID: Int,
        unknownID: Int,
        padID: Int
    ) {
        self.vocabularySize = vocabularySize
        self.beginningOfSentenceID = beginningOfSentenceID
        self.endOfSentenceID = endOfSentenceID
        self.unknownID = unknownID
        self.padID = padID
    }
}

/// Pure-Swift SentencePiece BPE tokenizer.
///
/// Translated from the TypeScript implementation in
/// `src/cross/sentencepiece/_processor.ts`, which is itself a port of
/// `github.com/eliben/go-sentencepiece`.
public final class SentencePieceProcessor: @unchecked Sendable {
    private let model: ModelProto
    private let pieces: [String: Int]
    private let reserved: [String: Int]
    private let unknownID: Int
    private let userDefinedMatcher: PrefixMatcher
    private let byte2Token: [Int: Token]
    private let idToByte: [Int: Int]
    private let maxPieceLength: Int

    /// Creates a new `SentencePieceProcessor` from the serialized model bytes.
    public init(modelProtoBytes: Data) throws {
        self.model = try decodeModelProto(from: modelProtoBytes)

        guard let tspec = model.trainerSpec, tspec.modelType == .bpe else {
            let actual = String(describing: model.trainerSpec?.modelType)
            throw GenAIError.unsupported(
                "Model type \(actual) not supported, only BPE is supported"
            )
        }

        if let nspec = model.normalizerSpec,
           nspec.addDummyPrefix == true || nspec.removeExtraWhitespaces == true {
            throw GenAIError.unsupported(
                "Normalizer spec options not supported: addDummyPrefix=\(String(describing: nspec.addDummyPrefix)) removeExtraWhitespaces=\(String(describing: nspec.removeExtraWhitespaces))"
            )
        }

        guard let modelPieces = model.pieces else {
            throw GenAIError.runtime("Model has no pieces")
        }

        var userDefined = Set<String>()
        var pieces: [String: Int] = [:]
        var reserved: [String: Int] = [:]
        var byte2Token: [Int: Token] = [:]
        var idToByte: [Int: Int] = [:]
        var unknownID = -1
        var maxPieceLength = 0

        for i in 0..<modelPieces.count {
            let p = modelPieces[i]
            let pieceText = p.piece ?? ""
            let pieceType = p.type ?? .normal

            let isNormalPiece =
                pieceType == .normal
                || pieceType == .userDefined
                || pieceType == .unused

            if isNormalPiece {
                pieces[pieceText] = i
                if pieceText.count > maxPieceLength {
                    maxPieceLength = pieceText.count
                }
            } else {
                reserved[pieceText] = i
            }

            switch pieceType {
            case .userDefined:
                userDefined.insert(pieceText)
            case .unknown:
                if unknownID >= 0 {
                    throw GenAIError.runtime("unk redefined")
                }
                unknownID = i
            case .byte:
                if tspec.byteFallback != true {
                    throw GenAIError.runtime(
                        "byte piece \"\(pieceText)\" found although byte_fallback=false"
                    )
                }
                let bv = convertHexValue(pieceText)
                if bv >= 0 && bv < 256 {
                    byte2Token[bv] = Token(id: i, text: pieceText)
                    idToByte[i] = bv
                }
            default:
                break
            }
        }

        if unknownID < 0 {
            throw GenAIError.runtime("unk symbol is not defined")
        }

        if tspec.byteFallback == true {
            for i in 0..<256 {
                if byte2Token[i] == nil {
                    let hex = String(i, radix: 16, uppercase: false)
                    let padded = hex.count < 2 ? String(repeating: "0", count: 2 - hex.count) + hex : hex
                    throw GenAIError.runtime("byte value 0x\(padded) not found")
                }
            }
        }

        self.pieces = pieces
        self.reserved = reserved
        self.byte2Token = byte2Token
        self.idToByte = idToByte
        self.unknownID = unknownID
        self.maxPieceLength = maxPieceLength
        self.userDefinedMatcher = PrefixMatcher(vocab: userDefined)
    }

    // MARK: - Public API

    /// Encodes `text` into a list of tokens.
    public func encode(_ text: String) -> [Token] {
        let normalized = normalize(text)

        // Symbol list element type — stored as a struct, manipulated via index.
        struct SymListElem {
            var prev: Int
            var next: Int
            var noMerge: Bool
            var symbol: String
        }

        var symList: [SymListElem] = []

        // Walk the normalized text character-by-character (or by user-defined
        // prefix match when present).
        var remaining = Substring(normalized)
        while !remaining.isEmpty {
            let (slen, found) = symbolMatch(String(remaining))
            // Take `slen` characters from `remaining`.
            let prefix = String(remaining.prefix(slen))
            let sym = SymListElem(
                prev: symList.count - 1,
                next: symList.count + 1,
                noMerge: found,
                symbol: prefix
            )
            symList.append(sym)
            remaining = remaining.dropFirst(slen)
        }

        if symList.isEmpty {
            return []
        }

        symList[symList.count - 1].next = -1

        struct MergeCandidate {
            var left: Int
            var right: Int
            var length: Int
            var score: Float
        }

        let mergeQueue = PriorityQueue<MergeCandidate>(
            sizeHint: symList.count,
            cmp: { a, b in
                if a.score > b.score || (a.score == b.score && a.left < b.left) {
                    return 1
                }
                return -1
            }
        )

        let modelPieces = model.pieces ?? []

        func findMerged(_ x: SymListElem, _ y: SymListElem) -> (String, Int, Bool) {
            let merged = x.symbol + y.symbol
            if let id = pieces[merged] {
                return (modelPieces[id].piece ?? "", id, true)
            }
            return ("", 0, false)
        }

        func suggestNewMergePair(_ left: Int, _ right: Int) {
            if left == -1 || right == -1 || symList[left].noMerge || symList[right].noMerge {
                return
            }
            let (mergedSymbol, id, ok) = findMerged(symList[left], symList[right])
            if ok {
                mergeQueue.insert(MergeCandidate(
                    left: left,
                    right: right,
                    length: mergedSymbol.count,
                    score: modelPieces[id].score ?? 0
                ))
            }
        }

        for i in 1..<symList.count {
            suggestNewMergePair(i - 1, i)
        }

        let candidateIsDead: (MergeCandidate) -> Bool = { candidate in
            let leftSymbol = symList[candidate.left].symbol
            let rightSymbol = symList[candidate.right].symbol
            return leftSymbol.isEmpty
                || rightSymbol.isEmpty
                || (leftSymbol.count + rightSymbol.count) != candidate.length
        }

        var mergeQueueDead = 0
        while mergeQueue.len() > 0 {
            let candidate = mergeQueue.popMax()
            let leftSymbol = symList[candidate.left]
            let rightSymbol = symList[candidate.right]

            if candidateIsDead(candidate) {
                mergeQueueDead -= 1
                continue
            }

            if mergeQueueDead * 3 > mergeQueue.len() {
                mergeQueue.removeFunc(candidateIsDead)
                mergeQueueDead = 0
            }

            let (mergedSymbol, _, ok) = findMerged(leftSymbol, rightSymbol)
            if !ok {
                // Mirrors the TS Error path; this should be unreachable when
                // the queue is consistent.
                continue
            }
            symList[candidate.left].symbol = mergedSymbol
            symList[candidate.left].next = rightSymbol.next
            if rightSymbol.next >= 0 {
                symList[rightSymbol.next].prev = candidate.left
            }
            symList[candidate.right].symbol = ""
            mergeQueueDead += 1

            suggestNewMergePair(leftSymbol.prev, candidate.left)
            suggestNewMergePair(candidate.left, rightSymbol.next)
        }

        var tokens: [Token] = []
        var i = 0
        while i >= 0 {
            let symbol = symList[i].symbol
            let id = symbolToID(symbol)
            if id == unknownID && model.trainerSpec?.byteFallback == true {
                // Fall back to UTF-8 byte tokens.
                let bytes = Array(symbol.utf8)
                for b in bytes {
                    if let byteToken = byte2Token[Int(b)] {
                        tokens.append(byteToken)
                    }
                }
            } else {
                tokens.append(Token(id: id, text: symbol))
            }
            i = symList[i].next
        }

        return tokens
    }

    /// Decodes a list of token IDs back into text.
    public func decode(_ ids: [Int]) -> String {
        var parts: [String] = []
        var i = 0
        let modelPieces = model.pieces ?? []

        while i < ids.count {
            var nextNonByte = i
            while nextNonByte < ids.count && isByteID(ids[nextNonByte]) {
                nextNonByte += 1
            }
            let numBytes = nextNonByte - i
            if numBytes > 0 {
                var bytes: [UInt8] = []
                bytes.reserveCapacity(numBytes)
                for bi in i..<nextNonByte {
                    if let b = idToByte[ids[bi]] {
                        bytes.append(UInt8(b))
                    }
                }
                // UTF-8 decode, replacing malformed sequences (non-fatal).
                let decoded = String(decoding: bytes, as: UTF8.self)
                parts.append(decoded)
            }

            if nextNonByte >= ids.count {
                break
            }

            let id = ids[nextNonByte]
            if isControlID(id) {
                // Skip.
            } else if id == unknownID {
                parts.append(model.trainerSpec?.unkSurface ?? "")
            } else if id >= 0 && id < modelPieces.count {
                let piece = modelPieces[id].piece ?? ""
                parts.append(replaceSeparatorsBySpace(piece))
            }
            i = nextNonByte + 1
        }

        return parts.joined()
    }

    /// Decodes a list of tokens back into text.
    public func decodeTokens(_ tokens: [Token]) -> String {
        return decode(tokens.map { $0.id })
    }

    /// Returns information about the loaded model.
    public func modelInfo() -> ModelInfo {
        let getControlID: (String) -> Int = { symbol in
            let id = self.symbolToID(symbol)
            return self.isControlID(id) ? id : -1
        }

        return ModelInfo(
            vocabularySize: model.pieces?.count ?? 0,
            beginningOfSentenceID: getControlID(symbolBOS),
            endOfSentenceID: getControlID(symbolEOS),
            unknownID: unknownID,
            padID: getControlID(symbolPAD)
        )
    }

    // MARK: - Internals

    private func normalize(_ text: String) -> String {
        // Replace ASCII spaces with the SentencePiece whitespace marker.
        var out = ""
        out.reserveCapacity(text.count)
        for ch in text {
            if ch == " " {
                out.append(whitespaceSeparator)
            } else {
                out.append(ch)
            }
        }
        return out
    }

    private func replaceSeparatorsBySpace(_ text: String) -> String {
        var out = ""
        out.reserveCapacity(text.count)
        for ch in text {
            if ch == whitespaceSeparator {
                out.append(" ")
            } else {
                out.append(ch)
            }
        }
        return out
    }

    private func symbolMatch(_ text: String) -> (Int, Bool) {
        let prefixLen = userDefinedMatcher.findPrefixLen(text)
        if prefixLen > 0 {
            return (prefixLen, true)
        }
        // Advance by one character (not one UTF-16 unit / one byte).
        return (1, false)
    }

    private func symbolToID(_ symbol: String) -> Int {
        if let r = reserved[symbol] {
            return r
        }
        if let p = pieces[symbol] {
            return p
        }
        return unknownID
    }

    private func isByteID(_ id: Int) -> Bool {
        guard let pieces = model.pieces, id >= 0, id < pieces.count else {
            return false
        }
        return pieces[id].type == .byte
    }

    private func isControlID(_ id: Int) -> Bool {
        guard let pieces = model.pieces, id >= 0, id < pieces.count else {
            return false
        }
        return pieces[id].type == .control
    }
}

/// Parses a byte-piece literal of the form `<0xNN>` into its numeric byte
/// value, or returns -1 if the input does not match.
private func convertHexValue(_ bv: String) -> Int {
    // Match `^<0x([0-9A-Fa-f]{2})>$`
    let chars = Array(bv)
    guard chars.count == 6,
          chars[0] == "<",
          chars[1] == "0",
          (chars[2] == "x" || chars[2] == "X"),
          chars[5] == ">"
    else {
        return -1
    }
    let hi = chars[3]
    let lo = chars[4]
    guard let h = hi.hexDigitValue, let l = lo.hexDigitValue else {
        return -1
    }
    return h * 16 + l
}
