// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Represents one source of header input — either a key/value map (with optional null
/// values to denote unset) or pre-parsed `NullableHeaders`. Mirrors `HeadersLike` in
/// `internal/headers.ts`.
public enum HeadersLike: Sendable {
    case none
    case map([String: String?])
    case nullable(NullableHeaders)
    case pairs([(String, String?)])
}

/// Parsed headers carrying the active values plus the set of keys that were explicitly
/// nulled out. Mirrors `NullableHeaders` in `internal/headers.ts`.
public struct NullableHeaders: Sendable {
    public var values: [String: String]
    public var nulls: Set<String>

    public init(values: [String: String] = [:], nulls: Set<String> = []) {
        self.values = values
        self.nulls = nulls
    }
}

private func iterateHeaders(_ headers: HeadersLike) -> [(String, String?)] {
    switch headers {
    case .none:
        return []
    case .nullable(let nh):
        var out: [(String, String?)] = []
        for (k, v) in nh.values { out.append((k, v)) }
        for n in nh.nulls { out.append((n, nil)) }
        return out
    case .pairs(let pairs):
        return pairs
    case .map(let map):
        // Object keys always overwrite older headers.
        var out: [(String, String?)] = []
        for (k, v) in map {
            out.append((k, nil)) // clear marker
            if let v = v {
                out.append((k, v))
            }
        }
        return out
    }
}

/// Merges several header sources into one `NullableHeaders`. Mirrors `buildHeaders`.
public func buildHeaders(_ newHeaders: [HeadersLike]) -> NullableHeaders {
    var target: [String: String] = [:]
    var nulls: Set<String> = []

    // Lower-cased key → original key, to preserve case but allow case-insensitive matching.
    var keyForLower: [String: String] = [:]

    for headers in newHeaders {
        var seen: Set<String> = []
        for (name, value) in iterateHeaders(headers) {
            let lower = name.lowercased()
            if !seen.contains(lower) {
                if let originalKey = keyForLower[lower] {
                    target.removeValue(forKey: originalKey)
                }
                seen.insert(lower)
            }
            if let value = value {
                target[name] = value
                keyForLower[lower] = name
                nulls.remove(lower)
            } else {
                if let originalKey = keyForLower[lower] {
                    target.removeValue(forKey: originalKey)
                }
                nulls.insert(lower)
            }
        }
    }
    return NullableHeaders(values: target, nulls: nulls)
}

/// Returns true if `headers` has no entries.
public func isEmptyHeaders(_ headers: HeadersLike) -> Bool {
    return iterateHeaders(headers).isEmpty
}
