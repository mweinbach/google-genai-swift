// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Accepted inputs to `toFile`. Mirrors `ToFileInput` in `internal/to-file.ts`.
public enum ToFileInput: Sendable {
    case data(Data)
    case string(String)
    case url(URL)
    case uploadable(Uploadable)
}

/// "BlobLikePart" placeholder. Mirrors `BlobLikePart` in `internal/to-file.ts`.
public typealias BlobLikePart = Data

/// Helper for creating an Uploadable to pass to an SDK upload method from a variety
/// of different inputs. Mirrors `toFile`.
public func toFile(
    _ value: ToFileInput,
    name: String? = nil,
    options: FilePropertyBag? = nil
) async throws -> Uploadable {
    checkFileSupport()

    switch value {
    case .uploadable(let u):
        return u
    case .data(let d):
        return makeFile(d, fileName: name, options: options)
    case .string(let s):
        return makeFile(Data(s.utf8), fileName: name, options: options)
    case .url(let url):
        let data = try Data(contentsOf: url)
        let finalName = name ?? url.lastPathComponent
        return makeFile(data, fileName: finalName, options: options)
    }
}
