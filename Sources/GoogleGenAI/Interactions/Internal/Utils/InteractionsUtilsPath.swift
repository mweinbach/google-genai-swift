// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Percent-encode everything that isn't safe to have in a path without encoding safe chars.
/// Mirrors `encodeURIPath` in `internal/utils/path.ts`.
public func encodeURIPath(_ s: String) -> String {
    let safe = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~!$&'()*+,;=:@"
    var allowed = CharacterSet()
    allowed.insert(charactersIn: safe)
    return s.addingPercentEncoding(withAllowedCharacters: allowed) ?? s
}

private let invalidSegmentRegex: NSRegularExpression = {
    return try! NSRegularExpression(
        pattern: "(^|/)(?:\\.|%2e){1,2}(?=/|$)",
        options: [.caseInsensitive]
    )
}()

/// Build a path from interleaved static segments and parameter values.
/// Mirrors the `path` tagged template function in `internal/utils/path.ts`.
/// Use as `pathTag(statics: ["/", "/agents/", ""], params: ["v1", agentId])`.
public func pathTag(statics: [String], params: [Any?]) throws -> String {
    if statics.count == 1 {
        return statics[0]
    }

    var postPath = false
    var invalidSegments: [(start: Int, length: Int, error: String)] = []
    var result = ""

    for index in 0..<statics.count {
        let currentValue = statics[index]
        if currentValue.range(of: "[?#]", options: .regularExpression) != nil {
            postPath = true
        }
        let pathSoFarLen = result.count + currentValue.count
        result += currentValue

        if index < params.count {
            let value = params[index]
            let stringValue: String
            if let v = value {
                stringValue = String(describing: v)
            } else {
                stringValue = "null"
            }
            let encoded = postPath
                ? (stringValue.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? stringValue)
                : encodeURIPath(stringValue)

            if value == nil {
                invalidSegments.append((pathSoFarLen, encoded.count, "Value of type null is not a valid path parameter"))
            }
            result += encoded
        }
    }

    let pathOnly = result.split(whereSeparator: { $0 == "?" || $0 == "#" }).first.map(String.init) ?? result
    let nsPath = pathOnly as NSString
    let matches = invalidSegmentRegex.matches(in: pathOnly, range: NSRange(location: 0, length: nsPath.length))
    for m in matches {
        let matchText = nsPath.substring(with: m.range)
        let hasLeadingSlash = matchText.hasPrefix("/")
        let offset = hasLeadingSlash ? 1 : 0
        let cleanMatch = hasLeadingSlash ? String(matchText.dropFirst()) : matchText
        invalidSegments.append((m.range.location + offset, cleanMatch.count, "Value \"\(cleanMatch)\" can't be safely passed as a path parameter"))
    }

    if !invalidSegments.isEmpty {
        let errors = invalidSegments.map { $0.error }.joined(separator: "\n")
        throw GeminiNextGenAPIClientError.message(
            "Path parameters result in path with invalid segments:\n\(errors)\n\(result)"
        )
    }

    return result
}
