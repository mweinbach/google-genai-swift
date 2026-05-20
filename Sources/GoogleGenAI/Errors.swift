// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

public struct ApiErrorInfo: Sendable {
    public let message: String
    public let status: Int

    public init(message: String, status: Int) {
        self.message = message
        self.status = status
    }
}

public struct ApiError: Error, Sendable, CustomStringConvertible {
    public let message: String
    public let status: Int

    public init(_ info: ApiErrorInfo) {
        self.message = info.message
        self.status = info.status
    }

    public init(message: String, status: Int) {
        self.message = message
        self.status = status
    }

    public var description: String { message }
}
