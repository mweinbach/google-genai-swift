// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// SentencePiece model type — mirrors `TrainerSpec.ModelType` from `sentencepiece_model.proto`.
public enum ModelType: Int32, Sendable {
    case unigram = 1
    case bpe = 2
    case word = 3
    case char = 4
}

/// SentencePiece piece type — mirrors `SentencePiece.Type`.
public enum SentencePieceType: Int32, Sendable {
    case normal = 1
    case unknown = 2
    case control = 3
    case userDefined = 4
    case byte = 6
    case unused = 5
}

/// Subset of `TrainerSpec` actually consumed by `SentencePieceProcessor`.
public struct TrainerSpec: Sendable {
    public var modelType: ModelType?
    public var vocabSize: Int32?
    public var characterCoverage: Float?
    public var byteFallback: Bool?
    public var unkSurface: String?

    public init(
        modelType: ModelType? = nil,
        vocabSize: Int32? = nil,
        characterCoverage: Float? = nil,
        byteFallback: Bool? = nil,
        unkSurface: String? = nil
    ) {
        self.modelType = modelType
        self.vocabSize = vocabSize
        self.characterCoverage = characterCoverage
        self.byteFallback = byteFallback
        self.unkSurface = unkSurface
    }
}

/// Subset of `NormalizerSpec` actually consumed by `SentencePieceProcessor`.
public struct NormalizerSpec: Sendable {
    public var name: String?
    public var precompiledCharsmap: Data?
    public var addDummyPrefix: Bool?
    public var removeExtraWhitespaces: Bool?
    public var escapeWhitespaces: Bool?
    public var normalizationRuleTsv: String?

    public init(
        name: String? = nil,
        precompiledCharsmap: Data? = nil,
        addDummyPrefix: Bool? = nil,
        removeExtraWhitespaces: Bool? = nil,
        escapeWhitespaces: Bool? = nil,
        normalizationRuleTsv: String? = nil
    ) {
        self.name = name
        self.precompiledCharsmap = precompiledCharsmap
        self.addDummyPrefix = addDummyPrefix
        self.removeExtraWhitespaces = removeExtraWhitespaces
        self.escapeWhitespaces = escapeWhitespaces
        self.normalizationRuleTsv = normalizationRuleTsv
    }
}

/// A single SentencePiece vocabulary entry.
public struct SentencePiece: Sendable {
    public var piece: String?
    public var score: Float?
    public var type: SentencePieceType?

    public init(piece: String? = nil, score: Float? = nil, type: SentencePieceType? = nil) {
        self.piece = piece
        self.score = score
        self.type = type
    }
}

/// Top-level decoded SentencePiece model.
public struct ModelProto: Sendable {
    public var pieces: [SentencePiece]?
    public var trainerSpec: TrainerSpec?
    public var normalizerSpec: NormalizerSpec?

    public init(
        pieces: [SentencePiece]? = nil,
        trainerSpec: TrainerSpec? = nil,
        normalizerSpec: NormalizerSpec? = nil
    ) {
        self.pieces = pieces
        self.trainerSpec = trainerSpec
        self.normalizerSpec = normalizerSpec
    }
}

// MARK: - Proto wire format decoder

/// Minimal proto wire-format error.
enum ProtoDecodeError: Error, CustomStringConvertible {
    case truncated
    case malformedVarint
    case malformedUTF8
    case unsupportedWireType(Int)

    var description: String {
        switch self {
        case .truncated: return "Truncated protobuf input"
        case .malformedVarint: return "Malformed varint"
        case .malformedUTF8: return "Malformed UTF-8 in proto string field"
        case .unsupportedWireType(let w): return "Unsupported wire type: \(w)"
        }
    }
}

/// Wire types used by the SentencePiece model.
private enum WireType: Int {
    case varint = 0
    case fixed64 = 1
    case lengthDelimited = 2
    case fixed32 = 5
}

/// A protobuf wire-format reader operating over a `Data` buffer.
///
/// Only implements the surface area needed to decode `sentencepiece_model.proto`:
///   * `varint` (used for int32, enum, bool)
///   * `fixed32` (used for `float`)
///   * `fixed64` (used for `double`, skipped here)
///   * `length-delimited` (used for strings, bytes, sub-messages, packed fields)
struct ProtoReader {
    let data: Data
    var pos: Int

    init(_ data: Data) {
        self.data = data
        self.pos = data.startIndex
    }

    var isAtEnd: Bool { pos >= data.endIndex }

    mutating func readVarint() throws -> UInt64 {
        var result: UInt64 = 0
        var shift: UInt64 = 0
        while pos < data.endIndex {
            let byte = data[pos]
            pos += 1
            result |= UInt64(byte & 0x7F) << shift
            if (byte & 0x80) == 0 {
                return result
            }
            shift += 7
            if shift >= 64 {
                throw ProtoDecodeError.malformedVarint
            }
        }
        throw ProtoDecodeError.truncated
    }

    mutating func readTag() throws -> (fieldNumber: Int, wireType: Int) {
        let tag = try readVarint()
        let fieldNumber = Int(tag >> 3)
        let wireType = Int(tag & 0x7)
        return (fieldNumber, wireType)
    }

    mutating func readFixed32() throws -> UInt32 {
        guard data.endIndex - pos >= 4 else { throw ProtoDecodeError.truncated }
        var value: UInt32 = 0
        for i in 0..<4 {
            value |= UInt32(data[pos + i]) << (8 * UInt32(i))
        }
        pos += 4
        return value
    }

    mutating func readFixed64() throws -> UInt64 {
        guard data.endIndex - pos >= 8 else { throw ProtoDecodeError.truncated }
        var value: UInt64 = 0
        for i in 0..<8 {
            value |= UInt64(data[pos + i]) << (8 * UInt64(i))
        }
        pos += 8
        return value
    }

    mutating func readFloat() throws -> Float {
        let bits = try readFixed32()
        return Float(bitPattern: bits)
    }

    mutating func readLengthDelimited() throws -> Data {
        let length = Int(try readVarint())
        guard data.endIndex - pos >= length else { throw ProtoDecodeError.truncated }
        let sub = data.subdata(in: pos..<(pos + length))
        pos += length
        return sub
    }

    mutating func readString() throws -> String {
        let bytes = try readLengthDelimited()
        guard let s = String(data: bytes, encoding: .utf8) else {
            throw ProtoDecodeError.malformedUTF8
        }
        return s
    }

    mutating func skipField(wireType: Int) throws {
        switch wireType {
        case WireType.varint.rawValue:
            _ = try readVarint()
        case WireType.fixed64.rawValue:
            _ = try readFixed64()
        case WireType.lengthDelimited.rawValue:
            _ = try readLengthDelimited()
        case WireType.fixed32.rawValue:
            _ = try readFixed32()
        default:
            throw ProtoDecodeError.unsupportedWireType(wireType)
        }
    }
}

/// Decodes a SentencePiece `ModelProto` from raw bytes.
///
/// Only the subset of fields actually consumed by `SentencePieceProcessor`
/// is decoded — other fields are skipped per the proto wire-format rules.
func decodeModelProto(from bytes: Data) throws -> ModelProto {
    // ModelProto field numbers (from sentencepiece_model.proto):
    //   1 -> repeated SentencePiece pieces
    //   2 -> TrainerSpec trainer_spec
    //   3 -> NormalizerSpec normalizer_spec
    var pieces: [SentencePiece] = []
    var trainerSpec: TrainerSpec?
    var normalizerSpec: NormalizerSpec?

    var reader = ProtoReader(bytes)
    while !reader.isAtEnd {
        let (field, wire) = try reader.readTag()
        switch field {
        case 1 where wire == WireType.lengthDelimited.rawValue:
            let sub = try reader.readLengthDelimited()
            pieces.append(try decodeSentencePiece(from: sub))
        case 2 where wire == WireType.lengthDelimited.rawValue:
            let sub = try reader.readLengthDelimited()
            trainerSpec = try decodeTrainerSpec(from: sub)
        case 3 where wire == WireType.lengthDelimited.rawValue:
            let sub = try reader.readLengthDelimited()
            normalizerSpec = try decodeNormalizerSpec(from: sub)
        default:
            try reader.skipField(wireType: wire)
        }
    }

    return ModelProto(
        pieces: pieces.isEmpty ? nil : pieces,
        trainerSpec: trainerSpec,
        normalizerSpec: normalizerSpec
    )
}

private func decodeSentencePiece(from bytes: Data) throws -> SentencePiece {
    // SentencePiece field numbers:
    //   1 -> string piece
    //   2 -> float score
    //   3 -> Type type
    var piece: String?
    var score: Float?
    var type: SentencePieceType?

    var reader = ProtoReader(bytes)
    while !reader.isAtEnd {
        let (field, wire) = try reader.readTag()
        switch field {
        case 1 where wire == WireType.lengthDelimited.rawValue:
            piece = try reader.readString()
        case 2 where wire == WireType.fixed32.rawValue:
            score = try reader.readFloat()
        case 3 where wire == WireType.varint.rawValue:
            let raw = Int32(truncatingIfNeeded: try reader.readVarint())
            type = SentencePieceType(rawValue: raw)
        default:
            try reader.skipField(wireType: wire)
        }
    }

    return SentencePiece(piece: piece, score: score, type: type)
}

private func decodeTrainerSpec(from bytes: Data) throws -> TrainerSpec {
    // TrainerSpec field numbers (subset used here, per sentencepiece_model.proto):
    //   3  -> ModelType model_type
    //   4  -> int32   vocab_size
    //   10 -> float   character_coverage
    //   35 -> bool    byte_fallback
    //   44 -> string  unk_surface
    var modelType: ModelType?
    var vocabSize: Int32?
    var characterCoverage: Float?
    var byteFallback: Bool?
    var unkSurface: String?

    var reader = ProtoReader(bytes)
    while !reader.isAtEnd {
        let (field, wire) = try reader.readTag()
        switch (field, wire) {
        case (3, WireType.varint.rawValue):
            let raw = Int32(truncatingIfNeeded: try reader.readVarint())
            modelType = ModelType(rawValue: raw)
        case (4, WireType.varint.rawValue):
            vocabSize = Int32(truncatingIfNeeded: try reader.readVarint())
        case (10, WireType.fixed32.rawValue):
            characterCoverage = try reader.readFloat()
        case (35, WireType.varint.rawValue):
            byteFallback = (try reader.readVarint()) != 0
        case (44, WireType.lengthDelimited.rawValue):
            unkSurface = try reader.readString()
        default:
            try reader.skipField(wireType: wire)
        }
    }

    return TrainerSpec(
        modelType: modelType,
        vocabSize: vocabSize,
        characterCoverage: characterCoverage,
        byteFallback: byteFallback,
        unkSurface: unkSurface
    )
}

private func decodeNormalizerSpec(from bytes: Data) throws -> NormalizerSpec {
    // NormalizerSpec field numbers:
    //   1 -> string name
    //   2 -> bytes precompiled_charsmap
    //   3 -> bool add_dummy_prefix
    //   4 -> bool remove_extra_whitespaces
    //   5 -> bool escape_whitespaces
    //   6 -> string normalization_rule_tsv
    var name: String?
    var precompiledCharsmap: Data?
    var addDummyPrefix: Bool?
    var removeExtraWhitespaces: Bool?
    var escapeWhitespaces: Bool?
    var normalizationRuleTsv: String?

    var reader = ProtoReader(bytes)
    while !reader.isAtEnd {
        let (field, wire) = try reader.readTag()
        switch (field, wire) {
        case (1, WireType.lengthDelimited.rawValue):
            name = try reader.readString()
        case (2, WireType.lengthDelimited.rawValue):
            precompiledCharsmap = try reader.readLengthDelimited()
        case (3, WireType.varint.rawValue):
            addDummyPrefix = (try reader.readVarint()) != 0
        case (4, WireType.varint.rawValue):
            removeExtraWhitespaces = (try reader.readVarint()) != 0
        case (5, WireType.varint.rawValue):
            escapeWhitespaces = (try reader.readVarint()) != 0
        case (6, WireType.lengthDelimited.rawValue):
            normalizationRuleTsv = try reader.readString()
        default:
            try reader.skipField(wireType: wire)
        }
    }

    return NormalizerSpec(
        name: name,
        precompiledCharsmap: precompiledCharsmap,
        addDummyPrefix: addDummyPrefix,
        removeExtraWhitespaces: removeExtraWhitespaces,
        escapeWhitespaces: escapeWhitespaces,
        normalizationRuleTsv: normalizationRuleTsv
    )
}
