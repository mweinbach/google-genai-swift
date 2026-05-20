// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Client-side cancellation token. Mirrors TypeScript's `AbortSignal` for parameter
/// compatibility. Callers should use Swift structured-concurrency cancellation
/// (`Task.cancel()` / `withTaskCancellationHandler`) — this struct is a marker
/// carried through public configs.
public struct AbortSignal: Codable, Sendable, Hashable {
    public var isAborted: Bool
    public init(isAborted: Bool = false) {
        self.isAborted = isAborted
    }
}

/// Required. The code to be executed.
public struct ExecutableCode: Codable, Sendable {
    public var code: String?
    public var language: Language?
    public var id: String?
    public init(code: String? = nil, language: Language? = nil, id: String? = nil) {
        self.code = code
        self.language = language
        self.id = id
    }
}

/// Result of executing the `ExecutableCode`.
public struct CodeExecutionResult: Codable, Sendable {
    public var outcome: Outcome?
    public var output: String?
    public var id: String?
    public init(outcome: Outcome? = nil, output: String? = nil, id: String? = nil) {
        self.outcome = outcome
        self.output = output
        self.id = id
    }
}

/// Media resolution for the input media.
public struct PartMediaResolution: Codable, Sendable {
    public var level: PartMediaResolutionLevel?
    public var numTokens: Double?
    public init(level: PartMediaResolutionLevel? = nil, numTokens: Double? = nil) {
        self.level = level
        self.numTokens = numTokens
    }
}

/// A predicted server-side `ToolCall` returned from the model.
public struct ToolCall: Codable, Sendable {
    public var id: String?
    public var toolType: ToolType?
    public var args: [String: JSONValue]?
    public init(id: String? = nil, toolType: ToolType? = nil, args: [String: JSONValue]? = nil) {
        self.id = id
        self.toolType = toolType
        self.args = args
    }
}

/// The output from a server-side `ToolCall` execution.
public final class ToolResponse: Codable, @unchecked Sendable {
    public var id: String?
    public var toolType: ToolType?
    public var response: [String: JSONValue]?
    public init(id: String? = nil, toolType: ToolType? = nil, response: [String: JSONValue]? = nil) {
        self.id = id
        self.toolType = toolType
        self.response = response
    }
}

/// URI-based data.
public struct FileData: Codable, Sendable {
    public var displayName: String?
    public var fileUri: String?
    public var mimeType: String?
    public init(displayName: String? = nil, fileUri: String? = nil, mimeType: String? = nil) {
        self.displayName = displayName
        self.fileUri = fileUri
        self.mimeType = mimeType
    }
}

/// Partial argument value of the function call. This data type is not supported in Gemini API.
public struct PartialArg: Codable, Sendable {
    public var boolValue: Bool?
    public var jsonPath: String?
    public var nullValue: String?
    public var numberValue: Double?
    public var stringValue: String?
    public var willContinue: Bool?
    public init(
        boolValue: Bool? = nil,
        jsonPath: String? = nil,
        nullValue: String? = nil,
        numberValue: Double? = nil,
        stringValue: String? = nil,
        willContinue: Bool? = nil
    ) {
        self.boolValue = boolValue
        self.jsonPath = jsonPath
        self.nullValue = nullValue
        self.numberValue = numberValue
        self.stringValue = stringValue
        self.willContinue = willContinue
    }
}

/// A function call.
public struct FunctionCall: Codable, Sendable {
    public var id: String?
    public var args: [String: JSONValue]?
    public var name: String?
    public var partialArgs: [PartialArg]?
    public var willContinue: Bool?
    public init(
        id: String? = nil,
        args: [String: JSONValue]? = nil,
        name: String? = nil,
        partialArgs: [PartialArg]? = nil,
        willContinue: Bool? = nil
    ) {
        self.id = id
        self.args = args
        self.name = name
        self.partialArgs = partialArgs
        self.willContinue = willContinue
    }
}

/// Raw media bytes for function response.
public final class FunctionResponseBlob: Codable, @unchecked Sendable {
    public var mimeType: String?
    public var data: String?
    public var displayName: String?
    public init(mimeType: String? = nil, data: String? = nil, displayName: String? = nil) {
        self.mimeType = mimeType
        self.data = data
        self.displayName = displayName
    }
}

/// URI based data for function response.
public final class FunctionResponseFileData: Codable, @unchecked Sendable {
    public var fileUri: String?
    public var mimeType: String?
    public var displayName: String?
    public init(fileUri: String? = nil, mimeType: String? = nil, displayName: String? = nil) {
        self.fileUri = fileUri
        self.mimeType = mimeType
        self.displayName = displayName
    }
}

/// A datatype containing media that is part of a `FunctionResponse` message.
public final class FunctionResponsePart: Codable, @unchecked Sendable {
    public var inlineData: FunctionResponseBlob?
    public var fileData: FunctionResponseFileData?
    public init(inlineData: FunctionResponseBlob? = nil, fileData: FunctionResponseFileData? = nil) {
        self.inlineData = inlineData
        self.fileData = fileData
    }
}

/// Creates a `FunctionResponsePart` object from a `base64` encoded `string`.
public func createFunctionResponsePartFromBase64(
    data: String,
    mimeType: String
) -> FunctionResponsePart {
    return FunctionResponsePart(
        inlineData: FunctionResponseBlob(mimeType: mimeType, data: data)
    )
}

/// Creates a `FunctionResponsePart` object from a `URI` string.
public func createFunctionResponsePartFromUri(
    uri: String,
    mimeType: String
) -> FunctionResponsePart {
    return FunctionResponsePart(
        fileData: FunctionResponseFileData(fileUri: uri, mimeType: mimeType)
    )
}

/// A function response.
public final class FunctionResponse: Codable, @unchecked Sendable {
    public var willContinue: Bool?
    public var scheduling: FunctionResponseScheduling?
    public var parts: [FunctionResponsePart]?
    public var id: String?
    public var name: String?
    public var response: [String: JSONValue]?
    public init(
        willContinue: Bool? = nil,
        scheduling: FunctionResponseScheduling? = nil,
        parts: [FunctionResponsePart]? = nil,
        id: String? = nil,
        name: String? = nil,
        response: [String: JSONValue]? = nil
    ) {
        self.willContinue = willContinue
        self.scheduling = scheduling
        self.parts = parts
        self.id = id
        self.name = name
        self.response = response
    }
}

/// A content blob.
public struct Blob: Codable, Sendable {
    public var data: String?
    public var displayName: String?
    public var mimeType: String?
    public init(data: String? = nil, displayName: String? = nil, mimeType: String? = nil) {
        self.data = data
        self.displayName = displayName
        self.mimeType = mimeType
    }
}

/// Provides metadata for a video.
public struct VideoMetadata: Codable, Sendable {
    public var endOffset: String?
    public var fps: Double?
    public var startOffset: String?
    public init(endOffset: String? = nil, fps: Double? = nil, startOffset: String? = nil) {
        self.endOffset = endOffset
        self.fps = fps
        self.startOffset = startOffset
    }
}

/// A datatype containing media content.
public struct Part: Codable, Sendable {
    public var mediaResolution: PartMediaResolution?
    public var codeExecutionResult: CodeExecutionResult?
    public var executableCode: ExecutableCode?
    public var fileData: FileData?
    public var functionCall: FunctionCall?
    public var functionResponse: FunctionResponse?
    public var inlineData: Blob?
    public var text: String?
    public var thought: Bool?
    public var thoughtSignature: String?
    public var videoMetadata: VideoMetadata?
    public var toolCall: ToolCall?
    public var toolResponse: ToolResponse?
    public var partMetadata: [String: JSONValue]?
    public init(
        mediaResolution: PartMediaResolution? = nil,
        codeExecutionResult: CodeExecutionResult? = nil,
        executableCode: ExecutableCode? = nil,
        fileData: FileData? = nil,
        functionCall: FunctionCall? = nil,
        functionResponse: FunctionResponse? = nil,
        inlineData: Blob? = nil,
        text: String? = nil,
        thought: Bool? = nil,
        thoughtSignature: String? = nil,
        videoMetadata: VideoMetadata? = nil,
        toolCall: ToolCall? = nil,
        toolResponse: ToolResponse? = nil,
        partMetadata: [String: JSONValue]? = nil
    ) {
        self.mediaResolution = mediaResolution
        self.codeExecutionResult = codeExecutionResult
        self.executableCode = executableCode
        self.fileData = fileData
        self.functionCall = functionCall
        self.functionResponse = functionResponse
        self.inlineData = inlineData
        self.text = text
        self.thought = thought
        self.thoughtSignature = thoughtSignature
        self.videoMetadata = videoMetadata
        self.toolCall = toolCall
        self.toolResponse = toolResponse
        self.partMetadata = partMetadata
    }
}

/// Creates a `Part` object from a `URI` string.
public func createPartFromUri(
    uri: String,
    mimeType: String,
    mediaResolution: PartMediaResolutionLevel? = nil
) -> Part {
    var part = Part(fileData: FileData(fileUri: uri, mimeType: mimeType))
    if let mediaResolution {
        part.mediaResolution = PartMediaResolution(level: mediaResolution)
    }
    return part
}

/// Creates a `Part` object from a `text` string.
public func createPartFromText(_ text: String) -> Part {
    return Part(text: text)
}

/// Creates a `Part` object from a `FunctionCall` object.
public func createPartFromFunctionCall(
    name: String,
    args: [String: JSONValue]
) -> Part {
    return Part(functionCall: FunctionCall(args: args, name: name))
}

/// Creates a `Part` object from a `FunctionResponse` object.
public func createPartFromFunctionResponse(
    id: String,
    name: String,
    response: [String: JSONValue],
    parts: [FunctionResponsePart] = []
) -> Part {
    let fr = FunctionResponse(
        parts: parts.isEmpty ? nil : parts,
        id: id,
        name: name,
        response: response
    )
    return Part(functionResponse: fr)
}

/// Creates a `Part` object from a `base64` encoded `string`.
public func createPartFromBase64(
    data: String,
    mimeType: String,
    mediaResolution: PartMediaResolutionLevel? = nil
) -> Part {
    var part = Part(inlineData: Blob(data: data, mimeType: mimeType))
    if let mediaResolution {
        part.mediaResolution = PartMediaResolution(level: mediaResolution)
    }
    return part
}

/// Creates a `Part` object from the `outcome` and `output` of a `CodeExecutionResult` object.
public func createPartFromCodeExecutionResult(
    outcome: Outcome,
    output: String
) -> Part {
    return Part(codeExecutionResult: CodeExecutionResult(outcome: outcome, output: output))
}

/// Creates a `Part` object from the `code` and `language` of an `ExecutableCode` object.
public func createPartFromExecutableCode(
    code: String,
    language: Language
) -> Part {
    return Part(executableCode: ExecutableCode(code: code, language: language))
}

/// Contains the multi-part content of a message.
public struct Content: Codable, Sendable {
    public var parts: [Part]?
    public var role: String?
    public init(parts: [Part]? = nil, role: String? = nil) {
        self.parts = parts
        self.role = role
    }
}

/// A single Part or a String — mirrors TS `PartUnion = Part | string`.
public enum PartUnion: Codable, Sendable {
    case part(Part)
    case text(String)

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(String.self) { self = .text(v); return }
        let v = try c.decode(Part.self)
        self = .part(v)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .part(let v): try c.encode(v)
        case .text(let v): try c.encode(v)
        }
    }
}

/// One or more `PartUnion` values — mirrors TS `PartListUnion = PartUnion[] | PartUnion`.
public enum PartListUnion: Codable, Sendable {
    case single(PartUnion)
    case many([PartUnion])

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode([PartUnion].self) { self = .many(v); return }
        let v = try c.decode(PartUnion.self)
        self = .single(v)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .single(let v): try c.encode(v)
        case .many(let v): try c.encode(v)
        }
    }
}

internal func _toParts(_ partOrString: PartListUnion) throws -> [Part] {
    var parts: [Part] = []
    switch partOrString {
    case .single(let u):
        switch u {
        case .text(let s): parts.append(createPartFromText(s))
        case .part(let p): parts.append(p)
        }
    case .many(let arr):
        if arr.isEmpty {
            throw GenAIError.invalidArgument("partOrString cannot be an empty array")
        }
        for u in arr {
            switch u {
            case .text(let s): parts.append(createPartFromText(s))
            case .part(let p): parts.append(p)
            }
        }
    }
    return parts
}

/// Creates a `Content` object with a user role from a `PartListUnion` object or `string`.
public func createUserContent(_ partOrString: PartListUnion) throws -> Content {
    return Content(parts: try _toParts(partOrString), role: "user")
}

/// Creates a `Content` object with a user role from a string.
public func createUserContent(_ text: String) -> Content {
    return Content(parts: [createPartFromText(text)], role: "user")
}

/// Creates a `Content` object with a model role from a `PartListUnion` object or `string`.
public func createModelContent(_ partOrString: PartListUnion) throws -> Content {
    return Content(parts: try _toParts(partOrString), role: "model")
}

/// Creates a `Content` object with a model role from a string.
public func createModelContent(_ text: String) -> Content {
    return Content(parts: [createPartFromText(text)], role: "model")
}
