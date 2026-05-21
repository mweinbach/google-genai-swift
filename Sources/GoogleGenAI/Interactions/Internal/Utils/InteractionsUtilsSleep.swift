// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Sleep for `ms` milliseconds. Mirrors `internal/utils/sleep.ts`.
public func interactionsSleep(ms: Double) async {
    let nanos = UInt64(max(0, ms) * 1_000_000)
    try? await Task.sleep(nanoseconds: nanos)
}
