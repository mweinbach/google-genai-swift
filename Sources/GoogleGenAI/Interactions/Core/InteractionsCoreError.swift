// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Base error type for the Interactions subsystem. Mirrors `GeminiNextGenAPIClientError`
/// from `core/error.ts`.
public enum GeminiNextGenAPIClientError: Error, Sendable, CustomStringConvertible {
    case message(String)

    public var description: String {
        switch self {
        case .message(let m): return m
        }
    }
}

/// Generic API error. Mirrors `APIError` from `core/error.ts`. The TS generics
/// (`TStatus`, `THeaders`, `TError`) are erased to optionals here.
public struct InteractionsAPIError: Error, Sendable, CustomStringConvertible {
    public let status: Int?
    public let headers: [String: String]?
    public let error: JSONValue?
    public let messageText: String

    public init(status: Int?, error: JSONValue?, message: String?, headers: [String: String]?) {
        self.status = status
        self.error = error
        self.headers = headers
        self.messageText = InteractionsAPIError.makeMessage(status: status, error: error, message: message)
    }

    public var description: String { messageText }

    private static func makeMessage(status: Int?, error: JSONValue?, message: String?) -> String {
        var msg: String? = nil
        if let error = error {
            if case .object(let obj) = error, let m = obj["message"] {
                if case .string(let s) = m {
                    msg = s
                } else {
                    let data = (try? JSONEncoder().encode(m)) ?? Data()
                    msg = String(data: data, encoding: .utf8)
                }
            } else {
                let data = (try? JSONEncoder().encode(error)) ?? Data()
                msg = String(data: data, encoding: .utf8)
            }
        } else if let m = message {
            msg = m
        }
        if let status = status, let msg = msg { return "\(status) \(msg)" }
        if let status = status { return "\(status) status code (no body)" }
        if let msg = msg { return msg }
        return "(no status code or body)"
    }

    /// Mirrors `APIError.generate` — promotes generic API errors into specific
    /// subclasses by status code.
    public static func generate(
        status: Int?,
        errorResponse: JSONValue?,
        message: String?,
        headers: [String: String]?
    ) -> InteractionsAPIError {
        guard let status = status, let headers = headers else {
            return APIConnectionError(message: message, cause: nil).asAPIError()
        }

        switch status {
        case 400: return BadRequestError(status: status, error: errorResponse, message: message, headers: headers).asAPIError()
        case 401: return AuthenticationError(status: status, error: errorResponse, message: message, headers: headers).asAPIError()
        case 403: return PermissionDeniedError(status: status, error: errorResponse, message: message, headers: headers).asAPIError()
        case 404: return NotFoundError(status: status, error: errorResponse, message: message, headers: headers).asAPIError()
        case 409: return ConflictError(status: status, error: errorResponse, message: message, headers: headers).asAPIError()
        case 422: return UnprocessableEntityError(status: status, error: errorResponse, message: message, headers: headers).asAPIError()
        case 429: return RateLimitError(status: status, error: errorResponse, message: message, headers: headers).asAPIError()
        default:
            if status >= 500 {
                return InternalServerError(status: status, error: errorResponse, message: message, headers: headers).asAPIError()
            }
            return InteractionsAPIError(status: status, error: errorResponse, message: message, headers: headers)
        }
    }
}

/// Aborted-by-user error. Mirrors `APIUserAbortError`.
public struct APIUserAbortError: Error, Sendable, CustomStringConvertible {
    public let messageText: String
    public init(message: String? = nil) {
        self.messageText = message ?? "Request was aborted."
    }
    public var description: String { messageText }
    public func asAPIError() -> InteractionsAPIError {
        return InteractionsAPIError(status: nil, error: nil, message: messageText, headers: nil)
    }
}

/// Connection error. Mirrors `APIConnectionError`.
public struct APIConnectionError: Error, Sendable, CustomStringConvertible {
    public let messageText: String
    public let cause: String?
    public init(message: String? = nil, cause: Error? = nil) {
        self.messageText = message ?? "Connection error."
        self.cause = cause.map { String(describing: $0) }
    }
    public var description: String { messageText }
    public func asAPIError() -> InteractionsAPIError {
        return InteractionsAPIError(status: nil, error: nil, message: messageText, headers: nil)
    }
}

/// Connection timeout. Mirrors `APIConnectionTimeoutError`.
public struct APIConnectionTimeoutError: Error, Sendable, CustomStringConvertible {
    public let messageText: String
    public init(message: String? = nil) {
        self.messageText = message ?? "Request timed out. This is a client-side timeout. You can increase the timeout by setting the `timeout` argument in your request or client http options."
    }
    public var description: String { messageText }
}

/// Specific status-code error wrappers. Each carries a fixed expected status code.
public struct BadRequestError: Error, Sendable {
    public let status: Int; public let error: JSONValue?; public let message: String?; public let headers: [String: String]
    public init(status: Int, error: JSONValue?, message: String?, headers: [String: String]) {
        self.status = status; self.error = error; self.message = message; self.headers = headers
    }
    public func asAPIError() -> InteractionsAPIError {
        InteractionsAPIError(status: status, error: error, message: message, headers: headers)
    }
}
public struct AuthenticationError: Error, Sendable {
    public let status: Int; public let error: JSONValue?; public let message: String?; public let headers: [String: String]
    public init(status: Int, error: JSONValue?, message: String?, headers: [String: String]) {
        self.status = status; self.error = error; self.message = message; self.headers = headers
    }
    public func asAPIError() -> InteractionsAPIError {
        InteractionsAPIError(status: status, error: error, message: message, headers: headers)
    }
}
public struct PermissionDeniedError: Error, Sendable {
    public let status: Int; public let error: JSONValue?; public let message: String?; public let headers: [String: String]
    public init(status: Int, error: JSONValue?, message: String?, headers: [String: String]) {
        self.status = status; self.error = error; self.message = message; self.headers = headers
    }
    public func asAPIError() -> InteractionsAPIError {
        InteractionsAPIError(status: status, error: error, message: message, headers: headers)
    }
}
public struct NotFoundError: Error, Sendable {
    public let status: Int; public let error: JSONValue?; public let message: String?; public let headers: [String: String]
    public init(status: Int, error: JSONValue?, message: String?, headers: [String: String]) {
        self.status = status; self.error = error; self.message = message; self.headers = headers
    }
    public func asAPIError() -> InteractionsAPIError {
        InteractionsAPIError(status: status, error: error, message: message, headers: headers)
    }
}
public struct ConflictError: Error, Sendable {
    public let status: Int; public let error: JSONValue?; public let message: String?; public let headers: [String: String]
    public init(status: Int, error: JSONValue?, message: String?, headers: [String: String]) {
        self.status = status; self.error = error; self.message = message; self.headers = headers
    }
    public func asAPIError() -> InteractionsAPIError {
        InteractionsAPIError(status: status, error: error, message: message, headers: headers)
    }
}
public struct UnprocessableEntityError: Error, Sendable {
    public let status: Int; public let error: JSONValue?; public let message: String?; public let headers: [String: String]
    public init(status: Int, error: JSONValue?, message: String?, headers: [String: String]) {
        self.status = status; self.error = error; self.message = message; self.headers = headers
    }
    public func asAPIError() -> InteractionsAPIError {
        InteractionsAPIError(status: status, error: error, message: message, headers: headers)
    }
}
public struct RateLimitError: Error, Sendable {
    public let status: Int; public let error: JSONValue?; public let message: String?; public let headers: [String: String]
    public init(status: Int, error: JSONValue?, message: String?, headers: [String: String]) {
        self.status = status; self.error = error; self.message = message; self.headers = headers
    }
    public func asAPIError() -> InteractionsAPIError {
        InteractionsAPIError(status: status, error: error, message: message, headers: headers)
    }
}
public struct InternalServerError: Error, Sendable {
    public let status: Int; public let error: JSONValue?; public let message: String?; public let headers: [String: String]
    public init(status: Int, error: JSONValue?, message: String?, headers: [String: String]) {
        self.status = status; self.error = error; self.message = message; self.headers = headers
    }
    public func asAPIError() -> InteractionsAPIError {
        InteractionsAPIError(status: status, error: error, message: message, headers: headers)
    }
}
