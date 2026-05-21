// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Returns a UUID4 string. Mirrors `internal/utils/uuid.ts`.
public func uuid4() -> String {
    return UUID().uuidString.lowercased()
}
