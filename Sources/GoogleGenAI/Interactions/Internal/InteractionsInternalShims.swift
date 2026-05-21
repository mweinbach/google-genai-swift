// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Returns the default fetch implementation — a URLSession-backed function.
/// Mirrors `getDefaultFetch` in `internal/shims.ts`.
public func getDefaultFetch() -> InteractionsFetch {
    return { request in
        return try await URLSession.shared.data(for: request)
    }
}

/// Build a `ReadableStream` from an `AsyncSequence` of `Data` chunks.
/// Mirrors `ReadableStreamFrom` in `internal/shims.ts`.
public func readableStreamFrom<S: AsyncSequence & Sendable>(
    _ iterable: S
) -> InteractionsReadableStream where S.Element == Data {
    return AsyncThrowingStream { continuation in
        let task = Task {
            do {
                for try await chunk in iterable {
                    continuation.yield(chunk)
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        continuation.onTermination = { _ in task.cancel() }
    }
}

/// Make a `ReadableStream` from an `AsyncIterator`. The TS version takes a
/// "start/pull/cancel" controller; this Swift version simply returns the input
/// stream since `AsyncThrowingStream` already provides backpressure via
/// `continuation.yield(_:)`.
public func makeReadableStream(_ stream: InteractionsReadableStream) -> InteractionsReadableStream {
    return stream
}

/// Convert a `ReadableStream` into an `AsyncIteratorProtocol`-like sequence.
/// In Swift the stream is already an `AsyncSequence` so this is a passthrough.
/// Mirrors `ReadableStreamToAsyncIterable`.
public func readableStreamToAsyncIterable(
    _ stream: InteractionsReadableStream
) -> InteractionsReadableStream {
    return stream
}

/// Cancels a readable byte stream we don't need to consume. Swift's
/// `AsyncThrowingStream` cancels via `Task.cancel()`, so this is a no-op
/// taking the canceller closure as a parameter.
public func cancelReadableStream(_ task: Task<Void, Never>?) {
    task?.cancel()
}
