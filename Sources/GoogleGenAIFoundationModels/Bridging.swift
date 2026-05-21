// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

#if canImport(FoundationModels)
import Foundation
import FoundationModels
import GoogleGenAI

// MARK: - GeneratedContent ↔ JSONValue

@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
internal func jsonValue(from generated: GeneratedContent) -> JSONValue {
    switch generated.kind {
    case .null:
        return .null
    case .bool(let b):
        return .bool(b)
    case .number(let n):
        // Preserve integers as integers when possible (cleaner wire format).
        if n.rounded() == n, abs(n) < 1e18 {
            return .int(Int64(n))
        }
        return .double(n)
    case .string(let s):
        return .string(s)
    case .array(let arr):
        return .array(arr.map(jsonValue(from:)))
    case .structure(let props, let orderedKeys):
        var obj: [String: JSONValue] = [:]
        for key in orderedKeys {
            if let v = props[key] { obj[key] = jsonValue(from: v) }
        }
        // Pick up any properties the orderedKeys list missed.
        for (k, v) in props where obj[k] == nil {
            obj[k] = jsonValue(from: v)
        }
        return .object(obj)
    @unknown default:
        return .null
    }
}

@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
internal func generatedContent(from json: JSONValue) -> GeneratedContent {
    switch json {
    case .null:
        return GeneratedContent(kind: .null)
    case .bool(let b):
        return GeneratedContent(kind: .bool(b))
    case .int(let i):
        return GeneratedContent(kind: .number(Double(i)))
    case .double(let d):
        return GeneratedContent(kind: .number(d))
    case .string(let s):
        return GeneratedContent(kind: .string(s))
    case .array(let arr):
        return GeneratedContent(kind: .array(arr.map(generatedContent(from:))))
    case .object(let obj):
        let orderedKeys = Array(obj.keys)
        let mapped = obj.mapValues(generatedContent(from:))
        return GeneratedContent(kind: .structure(properties: mapped, orderedKeys: orderedKeys))
    }
}

// MARK: - GenerationSchema → JSON Schema (for Gemini responseJsonSchema)

@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
internal func jsonSchema(from schema: GenerationSchema) throws -> JSONValue {
    // `GenerationSchema` is Encodable and serializes as JSON Schema.
    let data = try JSONEncoder().encode(schema)
    let value = try JSONDecoder().decode(JSONValue.self, from: data)
    return value
}

// MARK: - GenerationOptions → GenerateContentConfig

@available(macOS 26.0, iOS 26.0, visionOS 26.0, *)
internal func bridge(
    _ options: GenerationOptions?,
    into config: inout GenerateContentConfig
) {
    guard let options else { return }
    if let t = options.temperature {
        config.temperature = t
    }
    if let m = options.maximumResponseTokens {
        config.maxOutputTokens = m
    }
    // SamplingMode is not Encodable, so we use a String(describing:) shim to
    // recognize the common cases. Apple's debug description includes the
    // mode name + parameters; we extract topK / topP / seed when present.
    if let mode = options.sampling {
        let desc = String(describing: mode)
        // Extract numeric values by simple substring scan.
        if let top = _extractInt(after: "top:", from: desc) {
            config.topK = Double(top)
        }
        if let prob = _extractDouble(after: "probabilityThreshold:", from: desc) {
            config.topP = prob
        }
        if let seed = _extractInt(after: "seed:", from: desc) {
            config.seed = seed
        }
    }
}

private func _extractInt(after key: String, from text: String) -> Int? {
    guard let r = text.range(of: key) else { return nil }
    let rest = text[r.upperBound...].drop(while: { $0 == " " || $0 == "(" })
    let digits = rest.prefix(while: { $0.isNumber || $0 == "-" })
    return Int(digits)
}

private func _extractDouble(after key: String, from text: String) -> Double? {
    guard let r = text.range(of: key) else { return nil }
    let rest = text[r.upperBound...].drop(while: { $0 == " " || $0 == "(" })
    let body = rest.prefix(while: { $0.isNumber || $0 == "-" || $0 == "." })
    return Double(body)
}

// MARK: - Errors

/// Errors raised by the Foundation Models adapter.
public enum GeminiFoundationModelsError: Error, Sendable, CustomStringConvertible {
    case modelResponseEmpty
    case modelResponseNotJSON(text: String, underlying: Error?)
    case schemaConversionFailed(underlying: Error)
    case toolCallNotFound(name: String)

    public var description: String {
        switch self {
        case .modelResponseEmpty:
            return "The model returned an empty response."
        case .modelResponseNotJSON(let text, let underlying):
            return "Could not decode model response as JSON: \(underlying?.localizedDescription ?? "no underlying error"). Raw text: \(text)"
        case .schemaConversionFailed(let err):
            return "Failed to convert GenerationSchema → JSON Schema: \(err)"
        case .toolCallNotFound(let name):
            return "Model invoked unknown tool: \(name)"
        }
    }
}

#endif
