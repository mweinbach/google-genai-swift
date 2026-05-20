// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

public func tBytes(_ fromBytes: JSONValue) throws -> String {
    guard case .string(let s) = fromBytes else {
        throw GenAIError.invalidArgument("fromImageBytes must be a string")
    }
    // TODO(b/389133914): Remove dummy bytes converter.
    return s
}

public func tBytes(_ fromBytes: String) -> String {
    fromBytes
}
