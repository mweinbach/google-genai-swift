// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// `type BlobImageUnion = Blob;` — direct alias.
public typealias BlobImageUnion = Blob

// `PartUnion` and `PartListUnion` are declared in `Content.swift`.

/// `type ContentUnion = Content | PartUnion[] | PartUnion;`
public enum ContentUnion: Codable, Sendable {
    case content(Content)
    case parts([PartUnion])
    case part(PartUnion)

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(Content.self) { self = .content(v); return }
        if let v = try? c.decode([PartUnion].self) { self = .parts(v); return }
        if let v = try? c.decode(PartUnion.self) { self = .part(v); return }
        throw DecodingError.typeMismatch(
            ContentUnion.self,
            .init(codingPath: decoder.codingPath, debugDescription: "Cannot decode ContentUnion")
        )
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .content(let v): try c.encode(v)
        case .parts(let v): try c.encode(v)
        case .part(let v): try c.encode(v)
        }
    }
}

/// `type ContentListUnion = Content | Content[] | PartUnion | PartUnion[];`
public enum ContentListUnion: Codable, Sendable {
    case content(Content)
    case contents([Content])
    case part(PartUnion)
    case parts([PartUnion])

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode([Content].self) { self = .contents(v); return }
        if let v = try? c.decode(Content.self) { self = .content(v); return }
        if let v = try? c.decode([PartUnion].self) { self = .parts(v); return }
        if let v = try? c.decode(PartUnion.self) { self = .part(v); return }
        throw DecodingError.typeMismatch(
            ContentListUnion.self,
            .init(codingPath: decoder.codingPath, debugDescription: "Cannot decode ContentListUnion")
        )
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .content(let v): try c.encode(v)
        case .contents(let v): try c.encode(v)
        case .part(let v): try c.encode(v)
        case .parts(let v): try c.encode(v)
        }
    }
}

/// `type SchemaUnion = Schema | unknown;`
public indirect enum SchemaUnion: Codable, Sendable {
    case schema(Schema)
    case unknown(JSONValue)

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(Schema.self) { self = .schema(v); return }
        let v = try c.decode(JSONValue.self)
        self = .unknown(v)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .schema(let v): try c.encode(v)
        case .unknown(let v): try c.encode(v)
        }
    }
}

/// `type SpeechConfigUnion = SpeechConfig | string;`
public enum SpeechConfigUnion: Codable, Sendable {
    case config(SpeechConfig)
    case string(String)

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(String.self) { self = .string(v); return }
        let v = try c.decode(SpeechConfig.self)
        self = .config(v)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .config(let v): try c.encode(v)
        case .string(let v): try c.encode(v)
        }
    }
}

/// `type ToolUnion = Tool | CallableTool;`
///
/// `CallableTool` is a protocol with async methods, so it cannot be encoded directly.
/// The SDK is expected to resolve callables to plain `Tool` values via
/// `await callable.tool()` before serialization. Attempting to encode a `.callable`
/// case directly throws `EncodingError.invalidValue`.
public enum ToolUnion: Codable, Sendable {
    case tool(Tool)
    case callable(any CallableTool)

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let v = try c.decode(Tool.self)
        self = .tool(v)
    }

    public func encode(to encoder: Encoder) throws {
        switch self {
        case .tool(let v):
            var c = encoder.singleValueContainer()
            try c.encode(v)
        case .callable:
            throw EncodingError.invalidValue(
                self,
                .init(
                    codingPath: encoder.codingPath,
                    debugDescription: "CallableTool must be resolved to Tool before encoding"
                )
            )
        }
    }
}

/// `type ToolListUnion = ToolUnion[];`
public typealias ToolListUnion = [ToolUnion]

/// `type DownloadableFileUnion = string | File | GeneratedVideo | Video;`
public enum DownloadableFileUnion: Codable, Sendable {
    case string(String)
    case file(File)
    case generatedVideo(GeneratedVideo)
    case video(Video)

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(String.self) { self = .string(v); return }
        if let v = try? c.decode(File.self) { self = .file(v); return }
        if let v = try? c.decode(GeneratedVideo.self) { self = .generatedVideo(v); return }
        let v = try c.decode(Video.self)
        self = .video(v)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .string(let v): try c.encode(v)
        case .file(let v): try c.encode(v)
        case .generatedVideo(let v): try c.encode(v)
        case .video(let v): try c.encode(v)
        }
    }
}

/// `type BatchJobSourceUnion = BatchJobSource | InlinedRequest[] | string;`
public enum BatchJobSourceUnion: Codable, Sendable {
    case source(BatchJobSource)
    case inlined([InlinedRequest])
    case string(String)

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(String.self) { self = .string(v); return }
        if let v = try? c.decode([InlinedRequest].self) { self = .inlined(v); return }
        let v = try c.decode(BatchJobSource.self)
        self = .source(v)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .source(let v): try c.encode(v)
        case .inlined(let v): try c.encode(v)
        case .string(let v): try c.encode(v)
        }
    }
}

/// `type BatchJobDestinationUnion = BatchJobDestination | string;`
public enum BatchJobDestinationUnion: Codable, Sendable {
    case destination(BatchJobDestination)
    case string(String)

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(String.self) { self = .string(v); return }
        let v = try c.decode(BatchJobDestination.self)
        self = .destination(v)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .destination(let v): try c.encode(v)
        case .string(let v): try c.encode(v)
        }
    }
}
