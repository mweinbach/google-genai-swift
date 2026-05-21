// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Encodes the given data to a base64 string. Mirrors `internal/utils/base64.ts`.
public func toBase64(_ data: Data?) -> String {
    guard let data = data, !data.isEmpty else { return "" }
    return data.base64EncodedString()
}

/// Encodes a UTF-8 string to base64.
public func toBase64(_ s: String?) -> String {
    guard let s = s, !s.isEmpty else { return "" }
    return Data(s.utf8).base64EncodedString()
}

/// Decodes the given base64 string to bytes. Mirrors `internal/utils/base64.ts`.
public func fromBase64(_ s: String) throws -> Data {
    guard let data = Data(base64Encoded: s) else {
        throw GeminiNextGenAPIClientError.message("Cannot decode base64 string")
    }
    return data
}
