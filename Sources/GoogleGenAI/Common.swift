// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// JSON value type used wherever the TS source uses `unknown` / `any` / `Record<string, unknown>`.
public indirect enum JSONValue: Sendable, Hashable, Codable {
    case null
    case bool(Bool)
    case int(Int64)
    case double(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() {
            self = .null
        } else if let v = try? c.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? c.decode(Int64.self) {
            self = .int(v)
        } else if let v = try? c.decode(Double.self) {
            self = .double(v)
        } else if let v = try? c.decode(String.self) {
            self = .string(v)
        } else if let v = try? c.decode([JSONValue].self) {
            self = .array(v)
        } else if let v = try? c.decode([String: JSONValue].self) {
            self = .object(v)
        } else {
            throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unsupported JSON value")
        }
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .null: try c.encodeNil()
        case .bool(let v): try c.encode(v)
        case .int(let v): try c.encode(v)
        case .double(let v): try c.encode(v)
        case .string(let v): try c.encode(v)
        case .array(let v): try c.encode(v)
        case .object(let v): try c.encode(v)
        }
    }
}

/// Base class for SDK modules.
open class BaseModule: @unchecked Sendable {
    public init() {}
}

/// Replaces `{key}` placeholders in `template` with corresponding values from `valueMap`.
/// Throws if a placeholder has no corresponding key.
public func formatMap(_ template: String, _ valueMap: [String: JSONValue]) throws -> String {
    var result = ""
    var remaining = Substring(template)
    while let openIdx = remaining.firstIndex(of: "{") {
        result.append(contentsOf: remaining[..<openIdx])
        guard let closeIdx = remaining[openIdx...].firstIndex(of: "}") else {
            result.append(contentsOf: remaining[openIdx...])
            return result
        }
        let key = String(remaining[remaining.index(after: openIdx)..<closeIdx])
        guard let value = valueMap[key] else {
            throw GenAIError.runtime("Key '\(key)' not found in valueMap.")
        }
        result.append(jsonValueToString(value))
        remaining = remaining[remaining.index(after: closeIdx)...]
    }
    result.append(contentsOf: remaining)
    return result
}

private func jsonValueToString(_ value: JSONValue) -> String {
    switch value {
    case .null: return ""
    case .bool(let b): return b ? "true" : "false"
    case .int(let i): return String(i)
    case .double(let d): return String(d)
    case .string(let s): return s
    case .array, .object:
        let data = (try? JSONEncoder().encode(value)) ?? Data()
        return String(data: data, encoding: .utf8) ?? ""
    }
}

/// Runtime errors raised by internal SDK plumbing (distinct from `ApiError` which is server-returned).
public enum GenAIError: Error, Sendable, CustomStringConvertible {
    case runtime(String)
    case invalidArgument(String)
    case unsupported(String)

    public var description: String {
        switch self {
        case .runtime(let m), .invalidArgument(let m), .unsupported(let m): return m
        }
    }
}

/// Navigates a nested JSON tree and sets `value` at the given key path.
/// Supports `key[]` (array fan-out) and `key[0]` (first-element) segments matching the TS implementation.
public func setValueByPath(
    _ data: inout [String: JSONValue],
    _ keys: [String],
    _ value: JSONValue
) throws {
    try _setValueByPath(&data, keys, value)
}

private func _setValueByPath(
    _ data: inout [String: JSONValue],
    _ keys: [String],
    _ value: JSONValue
) throws {
    guard !keys.isEmpty else { return }

    if keys.count == 1 {
        let keyToSet = keys[0]
        if let existing = data[keyToSet] {
            if case .null = value { return }
            if case .object(let obj) = value, obj.isEmpty { return }
            if existing == value { return }
            if case .object(var existingObj) = existing, case .object(let newObj) = value {
                for (k, v) in newObj { existingObj[k] = v }
                data[keyToSet] = .object(existingObj)
            } else {
                throw GenAIError.runtime("Cannot set value for an existing key. Key: \(keyToSet)")
            }
        } else if keyToSet == "_self", case .object(let obj) = value {
            for (k, v) in obj { data[k] = v }
        } else {
            data[keyToSet] = value
        }
        return
    }

    let key = keys[0]
    let rest = Array(keys.dropFirst())

    if key.hasSuffix("[]") {
        let keyName = String(key.dropLast(2))
        if data[keyName] == nil {
            if case .array(let arr) = value {
                data[keyName] = .array(Array(repeating: .object([:]), count: arr.count))
            } else {
                throw GenAIError.runtime("Value must be a list given an array path \(key)")
            }
        }
        guard case .array(var arr) = data[keyName] else { return }
        if case .array(let valueArr) = value {
            for j in arr.indices where j < valueArr.count {
                if case .object(var entry) = arr[j] {
                    try _setValueByPath(&entry, rest, valueArr[j])
                    arr[j] = .object(entry)
                }
            }
        } else {
            for j in arr.indices {
                if case .object(var entry) = arr[j] {
                    try _setValueByPath(&entry, rest, value)
                    arr[j] = .object(entry)
                }
            }
        }
        data[keyName] = .array(arr)
        return
    } else if key.hasSuffix("[0]") {
        let keyName = String(key.dropLast(3))
        if data[keyName] == nil {
            data[keyName] = .array([.object([:])])
        }
        guard case .array(var arr) = data[keyName], !arr.isEmpty else { return }
        if case .object(var entry) = arr[0] {
            try _setValueByPath(&entry, rest, value)
            arr[0] = .object(entry)
            data[keyName] = .array(arr)
        }
        return
    }

    if case .object(var nested) = data[key] {
        try _setValueByPath(&nested, rest, value)
        data[key] = .object(nested)
    } else {
        var nested: [String: JSONValue] = [:]
        try _setValueByPath(&nested, rest, value)
        data[key] = .object(nested)
    }
}

/// Reads a nested JSON tree by key path with optional default. Mirrors `getValueByPath` in `_common.ts`.
public func getValueByPath(
    _ data: JSONValue,
    _ keys: [String],
    defaultValue: JSONValue = .null
) -> JSONValue {
    if keys.count == 1 && keys[0] == "_self" {
        return data
    }

    var current = data
    for i in 0..<keys.count {
        let key = keys[i]
        guard case .object(let obj) = current else {
            return defaultValue
        }
        if key.hasSuffix("[]") {
            let keyName = String(key.dropLast(2))
            guard case .array(let arr) = obj[keyName] else {
                return defaultValue
            }
            let rest = Array(keys.dropFirst(i + 1))
            return .array(arr.map { getValueByPath($0, rest, defaultValue: defaultValue) })
        }
        guard let next = obj[key] else {
            return defaultValue
        }
        current = next
    }
    return current
}

/// Moves values from source paths to destination paths in a JSON tree.
/// Mirrors `moveValueByPath` in `_common.ts`.
public func moveValueByPath(
    _ data: inout JSONValue,
    _ paths: [String: String]
) throws {
    for (sourcePath, destPath) in paths {
        let sourceKeys = sourcePath.split(separator: ".").map(String.init)
        let destKeys = destPath.split(separator: ".").map(String.init)

        var excludeKeys = Set<String>()
        var wildcardIdx = -1
        for i in sourceKeys.indices where sourceKeys[i] == "*" {
            wildcardIdx = i
            break
        }
        if wildcardIdx != -1 && destKeys.count > wildcardIdx {
            for i in wildcardIdx..<destKeys.count {
                let k = destKeys[i]
                if k != "*" && !k.hasSuffix("[]") && !k.hasSuffix("[0]") {
                    excludeKeys.insert(k)
                }
            }
        }
        try _moveValueRecursive(&data, sourceKeys, destKeys, 0, excludeKeys)
    }
}

private func _moveValueRecursive(
    _ data: inout JSONValue,
    _ sourceKeys: [String],
    _ destKeys: [String],
    _ keyIdx: Int,
    _ excludeKeys: Set<String>
) throws {
    guard keyIdx < sourceKeys.count else { return }
    guard case .object(var obj) = data else { return }
    let key = sourceKeys[keyIdx]

    if key.hasSuffix("[]") {
        let keyName = String(key.dropLast(2))
        guard case .array(var arr) = obj[keyName] else { return }
        for i in arr.indices {
            try _moveValueRecursive(&arr[i], sourceKeys, destKeys, keyIdx + 1, excludeKeys)
        }
        obj[keyName] = .array(arr)
        data = .object(obj)
    } else if key == "*" {
        let keysToMove = obj.keys.filter { !$0.hasPrefix("_") && !excludeKeys.contains($0) }
        var valuesToMove: [String: JSONValue] = [:]
        for k in keysToMove { valuesToMove[k] = obj[k] }

        for (k, v) in valuesToMove {
            var newDestKeys: [String] = []
            for dk in destKeys.dropFirst(keyIdx) {
                newDestKeys.append(dk == "*" ? k : dk)
            }
            try setValueByPath(&obj, newDestKeys, v)
        }
        for k in keysToMove { obj.removeValue(forKey: k) }
        data = .object(obj)
    } else {
        guard var next = obj[key] else { return }
        try _moveValueRecursive(&next, sourceKeys, destKeys, keyIdx + 1, excludeKeys)
        obj[key] = next
        data = .object(obj)
    }
}
