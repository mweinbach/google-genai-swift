// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// A streaming UTF-8 decoder that mirrors the behavior of the Web API's
/// `TextDecoder('utf-8', {stream: true})`. Unlike `String(data:encoding:.utf8)`,
/// which is all-or-nothing, this decoder returns as much decoded text as possible
/// from each chunk and only buffers the incomplete trailing multi-byte sequence.
///
/// This is critical for SSE streaming where a complete event like `data: {"text":"hi"}\n\n`
/// should not be held hostage because the TCP chunk boundary splits a trailing emoji.
final class StreamingUTF8Decoder: @unchecked Sendable {
    private var pendingIncomplete: Data = Data()

    /// Feeds raw bytes and returns the decoded string for all complete
    /// UTF-8 characters. Incomplete trailing bytes are buffered internally
    /// and prepended to the next call.
    func decode(_ chunk: Data) -> String {
        if chunk.isEmpty { return "" }

        var combined = pendingIncomplete
        combined.append(chunk)

        let boundary = lastCompleteUTF8Boundary(combined)
        if boundary == 0 {
            pendingIncomplete = combined
            return ""
        }

        let validPrefix = combined.subdata(in: 0..<boundary)
        if boundary < combined.count {
            pendingIncomplete = combined.subdata(in: boundary..<combined.count)
        } else {
            pendingIncomplete.removeAll(keepingCapacity: true)
        }

        return String(data: validPrefix, encoding: .utf8) ?? ""
    }

    /// Flushes any remaining buffered bytes. Call at end of stream.
    /// Returns the decoded string for any remaining bytes, or nil if nothing was buffered.
    func flush() -> String? {
        if pendingIncomplete.isEmpty { return nil }
        let result = String(data: pendingIncomplete, encoding: .utf8) ?? ""
        pendingIncomplete.removeAll()
        return result.isEmpty ? nil : result
    }

    /// Returns the index of the last byte that completes a valid UTF-8
    /// character. If the data ends with an incomplete multi-byte sequence,
    /// returns the index before that sequence begins.
    private func lastCompleteUTF8Boundary(_ data: Data) -> Int {
        if data.isEmpty { return 0 }
        let count = data.count

        let lastByte = data[count - 1]
        if lastByte < 0x80 { return count }

        var i = count - 1
        while i >= 0 && data[i] & 0xC0 == 0x80 {
            i -= 1
        }

        if i < 0 { return 0 }

        let leadByte = data[i]
        if leadByte < 0x80 { return i + 1 }

        let expectedLength: Int
        if leadByte >= 0xF0 { expectedLength = 4 }
        else if leadByte >= 0xE0 { expectedLength = 3 }
        else { expectedLength = 2 }

        let actualLength = count - i
        return actualLength >= expectedLength ? count : i
    }
}
