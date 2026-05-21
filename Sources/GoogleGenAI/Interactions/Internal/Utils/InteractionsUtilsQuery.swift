// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Basic re-implementation of `qs.stringify` for primitive types.
/// Mirrors `internal/utils/query.ts`.
public func stringifyQuery(_ query: [String: JSONValue]) throws -> String {
    var pairs: [String] = []
    for (key, value) in query {
        switch value {
        case .null:
            pairs.append("\(percentEncode(key))=")
        case .bool(let b):
            pairs.append("\(percentEncode(key))=\(percentEncode(b ? "true" : "false"))")
        case .int(let i):
            pairs.append("\(percentEncode(key))=\(percentEncode(String(i)))")
        case .double(let d):
            pairs.append("\(percentEncode(key))=\(percentEncode(String(d)))")
        case .string(let s):
            pairs.append("\(percentEncode(key))=\(percentEncode(s))")
        case .array, .object:
            throw GeminiNextGenAPIClientError.message(
                "Cannot stringify nested value; Expected string, number, boolean, or null."
            )
        }
    }
    return pairs.joined(separator: "&")
}

private func percentEncode(_ s: String) -> String {
    return s.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? s
}

extension CharacterSet {
    static let urlQueryValueAllowed: CharacterSet = {
        var set = CharacterSet.urlQueryAllowed
        set.remove(charactersIn: "&=+?#")
        return set
    }()
}
