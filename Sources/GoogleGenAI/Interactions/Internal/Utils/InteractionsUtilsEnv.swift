// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Read an environment variable. Trims beginning and trailing whitespace.
/// Returns `nil` if the environment variable doesn't exist or is empty after trimming.
/// Mirrors `internal/utils/env.ts`.
public func readEnv(_ env: String) -> String? {
    guard let value = ProcessInfo.processInfo.environment[env] else { return nil }
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
}
