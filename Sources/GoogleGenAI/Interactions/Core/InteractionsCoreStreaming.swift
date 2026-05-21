// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// A single Server-Sent Event. Mirrors `ServerSentEvent` from `core/streaming.ts`.
public struct ServerSentEvent: Sendable {
    public var event: String?
    public var data: String
    public var raw: [String]

    public init(event: String?, data: String, raw: [String]) {
        self.event = event
        self.data = data
        self.raw = raw
    }
}

/// A stream of items decoded from a streaming HTTP response.
/// Mirrors `Stream<Item>` from `core/streaming.ts`. Items are typed as
/// `JSONValue` to mirror the JS dynamic-typing — concrete consumers can
/// decode each item into their own struct.
public final class InteractionsStream: @unchecked Sendable, AsyncSequence {
    public typealias Element = JSONValue

    public let controller: AbortController
    private let make: @Sendable () -> AsyncThrowingStream<JSONValue, Error>
    private let lock = NSLock()
    private var consumed = false

    public init(
        controller: AbortController,
        makeIterator: @escaping @Sendable () -> AsyncThrowingStream<JSONValue, Error>
    ) {
        self.controller = controller
        self.make = makeIterator
    }

    public func makeAsyncIterator() -> AsyncThrowingStream<JSONValue, Error>.AsyncIterator {
        lock.lock(); defer { lock.unlock() }
        if consumed {
            return AsyncThrowingStream<JSONValue, Error> { c in
                c.finish(throwing: GeminiNextGenAPIClientError.message(
                    "Cannot iterate over a consumed stream, use `.tee()` to split the stream."
                ))
            }.makeAsyncIterator()
        }
        consumed = true
        return make().makeAsyncIterator()
    }

    /// Decode SSE events from an HTTP response's byte stream into JSON items.
    /// Mirrors `Stream.fromSSEResponse`.
    public static func fromSSEResponse(
        bodyStream: InteractionsReadableStream,
        controller: AbortController,
        client: BaseGeminiNextGenAPIClient? = nil
    ) -> InteractionsStream {
        return InteractionsStream(controller: controller) {
            AsyncThrowingStream { continuation in
                let task = Task {
                    do {
                        var done = false
                        for try await sse in iterSSEMessages(bodyStream: bodyStream, controller: controller) {
                            if done { continue }
                            if sse.data.hasPrefix("[DONE]") {
                                done = true
                                continue
                            }
                            guard let data = sse.data.data(using: .utf8) else { continue }
                            do {
                                let value = try JSONDecoder().decode(JSONValue.self, from: data)
                                continuation.yield(value)
                            } catch {
                                if let logger = client.map(loggerFor) {
                                    logger.error("Could not parse message into JSON: \(sse.data)")
                                }
                                throw error
                            }
                        }
                        continuation.finish()
                    } catch {
                        if isAbortError(error) {
                            continuation.finish()
                        } else {
                            controller.abort()
                            continuation.finish(throwing: error)
                        }
                    }
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        }
    }

    /// Decode a newline-separated stream where each line is a JSON value.
    /// Mirrors `Stream.fromReadableStream`.
    public static func fromReadableStream(
        bodyStream: InteractionsReadableStream,
        controller: AbortController,
        client: BaseGeminiNextGenAPIClient? = nil
    ) -> InteractionsStream {
        return InteractionsStream(controller: controller) {
            AsyncThrowingStream { continuation in
                let task = Task {
                    let decoder = LineDecoder()
                    do {
                        for try await chunk in bodyStream {
                            for line in decoder.decode(chunk) {
                                if line.isEmpty { continue }
                                guard let data = line.data(using: .utf8) else { continue }
                                let value = try JSONDecoder().decode(JSONValue.self, from: data)
                                continuation.yield(value)
                            }
                        }
                        for line in decoder.flush() {
                            if line.isEmpty { continue }
                            guard let data = line.data(using: .utf8) else { continue }
                            let value = try JSONDecoder().decode(JSONValue.self, from: data)
                            continuation.yield(value)
                        }
                        continuation.finish()
                    } catch {
                        if isAbortError(error) {
                            continuation.finish()
                        } else {
                            controller.abort()
                            continuation.finish(throwing: error)
                        }
                    }
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        }
    }
}

/// Yields SSE messages from a stream of raw byte chunks. Mirrors `_iterSSEMessages`.
public func iterSSEMessages(
    bodyStream: InteractionsReadableStream,
    controller: AbortController
) -> AsyncThrowingStream<ServerSentEvent, Error> {
    return AsyncThrowingStream { continuation in
        let task = Task {
            let sseDecoder = SSEDecoder()
            let lineDecoder = LineDecoder()
            do {
                for try await chunk in bodyStream {
                    for line in lineDecoder.decode(chunk) {
                        if let event = sseDecoder.decode(line) {
                            continuation.yield(event)
                        }
                    }
                }
                for line in lineDecoder.flush() {
                    if let event = sseDecoder.decode(line) {
                        continuation.yield(event)
                    }
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        continuation.onTermination = { _ in task.cancel() }
    }
}

/// SSE protocol decoder. Mirrors the `SSEDecoder` class in `core/streaming.ts`.
final class SSEDecoder: @unchecked Sendable {
    private var data: [String] = []
    private var event: String? = nil
    private var chunks: [String] = []

    func decode(_ rawLine: String) -> ServerSentEvent? {
        var line = rawLine
        if line.hasSuffix("\r") {
            line = String(line.dropLast())
        }

        if line.isEmpty {
            if event == nil && data.isEmpty { return nil }
            let sse = ServerSentEvent(event: event, data: data.joined(separator: "\n"), raw: chunks)
            event = nil
            data.removeAll()
            chunks.removeAll()
            return sse
        }

        chunks.append(line)
        if line.hasPrefix(":") { return nil }

        let (fieldname, _, rawValue) = partition(line, delimiter: ":")
        var value = rawValue
        if value.hasPrefix(" ") {
            value = String(value.dropFirst())
        }

        if fieldname == "event" {
            event = value
        } else if fieldname == "data" {
            data.append(value)
        }
        return nil
    }
}

/// Returns `(prefix, delimiter, suffix)` for the first occurrence of `delimiter` in
/// `str`, or `(str, "", "")` when the delimiter is absent. Mirrors TS `partition`.
private func partition(_ str: String, delimiter: String) -> (String, String, String) {
    guard let r = str.range(of: delimiter) else {
        return (str, "", "")
    }
    return (String(str[..<r.lowerBound]), delimiter, String(str[r.upperBound...]))
}
