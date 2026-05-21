// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Concatenates an array of byte buffers. Mirrors `internal/utils/bytes.ts`.
public func concatBytes(_ buffers: [Data]) -> Data {
    var out = Data()
    var total = 0
    for b in buffers { total += b.count }
    out.reserveCapacity(total)
    for b in buffers { out.append(b) }
    return out
}

/// Encodes a string as UTF-8 bytes. Mirrors `encodeUTF8` in `internal/utils/bytes.ts`.
public func encodeUTF8(_ s: String) -> Data {
    return Data(s.utf8)
}

/// Decodes UTF-8 bytes to a string. Returns the empty string for invalid sequences.
/// Mirrors `decodeUTF8` in `internal/utils/bytes.ts`.
public func decodeUTF8(_ bytes: Data) -> String {
    return String(data: bytes, encoding: .utf8) ?? ""
}
