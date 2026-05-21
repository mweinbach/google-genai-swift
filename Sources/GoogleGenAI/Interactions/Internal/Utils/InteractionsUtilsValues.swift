// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Whether `url` starts with a scheme like `https:` (matches RFC3986 url-scheme-string).
/// Mirrors `isAbsoluteURL` in `internal/utils/values.ts`.
public func isAbsoluteURL(_ url: String) -> Bool {
    let pattern = "^[a-z][a-z0-9+.\\-]*:"
    return url.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
}

/// Returns an empty object if the given value isn't an object, otherwise returns as-is.
public func maybeObj(_ x: JSONValue?) -> [String: JSONValue] {
    if let x = x, case .object(let obj) = x {
        return obj
    }
    return [:]
}

/// Returns true if `obj` is null or has no enumerable keys.
public func isEmptyObj(_ obj: [String: JSONValue]?) -> Bool {
    guard let obj = obj else { return true }
    return obj.isEmpty
}

/// Returns true if `obj` has its own property at `key`.
public func hasOwn<V>(_ obj: [String: V], _ key: String) -> Bool {
    return obj[key] != nil
}

/// Validates that `n` is a non-negative integer.
public func validatePositiveInteger(_ name: String, _ n: Int) throws -> Int {
    guard n >= 0 else {
        throw GeminiNextGenAPIClientError.message("\(name) must be a positive integer")
    }
    return n
}

public func coerceInteger(_ value: JSONValue) throws -> Int {
    switch value {
    case .int(let i): return Int(i)
    case .double(let d): return Int(d.rounded())
    case .string(let s):
        if let i = Int(s) { return i }
        throw GeminiNextGenAPIClientError.message("Could not coerce \(s) into a number")
    default:
        throw GeminiNextGenAPIClientError.message("Could not coerce value into a number")
    }
}

public func coerceFloat(_ value: JSONValue) throws -> Double {
    switch value {
    case .int(let i): return Double(i)
    case .double(let d): return d
    case .string(let s):
        if let d = Double(s) { return d }
        throw GeminiNextGenAPIClientError.message("Could not coerce \(s) into a number")
    default:
        throw GeminiNextGenAPIClientError.message("Could not coerce value into a number")
    }
}

public func coerceBoolean(_ value: JSONValue) -> Bool {
    switch value {
    case .bool(let b): return b
    case .string(let s): return s == "true"
    case .null: return false
    case .int(let i): return i != 0
    case .double(let d): return d != 0
    default: return true
    }
}

public func maybeCoerceInteger(_ value: JSONValue?) throws -> Int? {
    guard let value = value, case .null = value else {
        if let value = value { return try coerceInteger(value) }
        return nil
    }
    return nil
}

public func maybeCoerceFloat(_ value: JSONValue?) throws -> Double? {
    guard let value = value, case .null = value else {
        if let value = value { return try coerceFloat(value) }
        return nil
    }
    return nil
}

public func maybeCoerceBoolean(_ value: JSONValue?) -> Bool? {
    guard let value = value else { return nil }
    if case .null = value { return nil }
    return coerceBoolean(value)
}

/// Parses JSON without throwing. Returns nil for invalid JSON.
public func safeJSON(_ text: String) -> JSONValue? {
    guard let data = text.data(using: .utf8) else { return nil }
    return try? JSONDecoder().decode(JSONValue.self, from: data)
}

/// Throws if `value` is nil; otherwise returns the unwrapped value.
public func ensurePresent<T>(_ value: T?) throws -> T {
    guard let v = value else {
        throw GeminiNextGenAPIClientError.message("Expected a value to be given but received nil instead.")
    }
    return v
}
