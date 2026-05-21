// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Whether the given error indicates an aborted request. Mirrors `isAbortError` in
/// `internal/errors.ts`.
public func isAbortError(_ err: Error) -> Bool {
    if err is CancellationError { return true }
    let s = String(describing: err)
    if s.contains("AbortError") || s.contains("FetchRequestCanceledException") { return true }
    return false
}

/// Coerces any error-like value into a Swift `Error`. Mirrors `castToError` in
/// `internal/errors.ts`.
public func castToError(_ err: Any?) -> Error {
    if let err = err as? Error { return err }
    if let s = err as? String {
        return GeminiNextGenAPIClientError.message(s)
    }
    return GeminiNextGenAPIClientError.message(String(describing: err ?? "unknown error"))
}
