// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// A re-implementation of httpx's `LineDecoder` in Python that handles incrementally
/// reading lines from text. Mirrors `internal/decoders/line.ts`.
public final class LineDecoder: @unchecked Sendable {
    public static let NEWLINE_CHARS: Set<Character> = ["\n", "\r"]

    private var buffer: Data
    private var carriageReturnIndex: Int?
    private var searchIndex: Int

    public init() {
        self.buffer = Data()
        self.carriageReturnIndex = nil
        self.searchIndex = 0
    }

    /// Feeds the given chunk into the decoder and returns any complete lines decoded.
    public func decode(_ chunk: Data?) -> [String] {
        guard let chunk = chunk else { return [] }

        buffer.append(chunk)

        var lines: [String] = []
        while let patternIndex = findNewlineIndex(buffer, startIndex: carriageReturnIndex ?? searchIndex) {
            if patternIndex.carriage && carriageReturnIndex == nil {
                carriageReturnIndex = patternIndex.index
                continue
            }

            if let cri = carriageReturnIndex,
               (patternIndex.index != cri + 1 || patternIndex.carriage) {
                let endIndex = max(0, cri - 1)
                lines.append(decodeUTF8(buffer.subdata(in: 0..<endIndex)))
                buffer = buffer.subdata(in: cri..<buffer.count)
                carriageReturnIndex = nil
                searchIndex = 0
                continue
            }

            let endIndex = carriageReturnIndex != nil ? patternIndex.preceding - 1 : patternIndex.preceding
            let line = decodeUTF8(buffer.subdata(in: 0..<max(0, endIndex)))
            lines.append(line)
            buffer = buffer.subdata(in: patternIndex.index..<buffer.count)
            carriageReturnIndex = nil
            searchIndex = 0
        }

        searchIndex = max(0, buffer.count - 1)
        return lines
    }

    /// Feeds a chunk of UTF-8 text into the decoder.
    public func decode(_ chunk: String?) -> [String] {
        guard let chunk = chunk else { return [] }
        return decode(Data(chunk.utf8))
    }

    /// Flushes any buffered data as a trailing line.
    public func flush() -> [String] {
        if buffer.isEmpty { return [] }
        return decode("\n")
    }
}

private struct NewlineIndex {
    let preceding: Int
    let index: Int
    let carriage: Bool
}

/// Searches `buffer` for `\r` or `\n` starting at `startIndex`. Returns `nil` if
/// neither byte is found.
private func findNewlineIndex(_ buffer: Data, startIndex: Int?) -> NewlineIndex? {
    let newline: UInt8 = 0x0a
    let carriage: UInt8 = 0x0d
    let start = startIndex ?? 0
    if start >= buffer.count { return nil }

    var nextNewline = -1
    var nextCarriage = -1
    for i in start..<buffer.count {
        let byte = buffer[i]
        if byte == newline && nextNewline == -1 { nextNewline = i }
        if byte == carriage && nextCarriage == -1 { nextCarriage = i }
        if nextNewline != -1 && nextCarriage != -1 { break }
    }

    if nextNewline == -1 && nextCarriage == -1 { return nil }
    let i: Int
    if nextNewline != -1 && nextCarriage != -1 {
        i = min(nextNewline, nextCarriage)
    } else {
        i = nextNewline != -1 ? nextNewline : nextCarriage
    }
    if buffer[i] == newline {
        return NewlineIndex(preceding: i, index: i + 1, carriage: false)
    }
    return NewlineIndex(preceding: i, index: i + 1, carriage: true)
}

/// Searches `buffer` for `\r\r`, `\n\n`, or `\r\n\r\n` and returns the index right
/// after the first occurrence. Mirrors `findDoubleNewlineIndex` in `line.ts`.
public func findDoubleNewlineIndex(_ buffer: Data, startIndex: Int = 0) -> Int {
    let newline: UInt8 = 0x0a
    let carriage: UInt8 = 0x0d

    var i = startIndex
    while i < buffer.count - 1 {
        var nextNewline = -1
        var nextCarriage = -1
        for j in i..<buffer.count {
            if buffer[j] == newline && nextNewline == -1 { nextNewline = j }
            if buffer[j] == carriage && nextCarriage == -1 { nextCarriage = j }
            if nextNewline != -1 && nextCarriage != -1 { break }
        }

        if nextNewline == -1 && nextCarriage == -1 { return -1 }

        let index: Int
        if nextNewline != -1 && nextCarriage != -1 {
            index = min(nextNewline, nextCarriage)
        } else {
            index = nextNewline != -1 ? nextNewline : nextCarriage
        }

        if index >= buffer.count - 1 { return -1 }

        if buffer[index] == newline && buffer[index + 1] == newline { return index + 2 }
        if buffer[index] == carriage && buffer[index + 1] == carriage { return index + 2 }
        if buffer[index] == carriage &&
            buffer[index + 1] == newline &&
            index + 3 < buffer.count &&
            buffer[index + 2] == carriage &&
            buffer[index + 3] == newline {
            return index + 4
        }
        i = index + 1
    }
    return -1
}
