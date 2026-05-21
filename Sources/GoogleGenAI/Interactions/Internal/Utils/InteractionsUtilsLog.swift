// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Log level. Mirrors `LogLevel` in `internal/utils/log.ts`.
public enum InteractionsLogLevel: String, Sendable, CaseIterable {
    case off
    case error
    case warn
    case info
    case debug

    var rank: Int {
        switch self {
        case .off: return 0
        case .error: return 200
        case .warn: return 300
        case .info: return 400
        case .debug: return 500
        }
    }
}

/// Logger interface. Mirrors `Logger` in `internal/utils/log.ts`.
public protocol InteractionsLogger: Sendable {
    func error(_ message: String, _ rest: [Any])
    func warn(_ message: String, _ rest: [Any])
    func info(_ message: String, _ rest: [Any])
    func debug(_ message: String, _ rest: [Any])
}

public extension InteractionsLogger {
    func error(_ message: String) { error(message, []) }
    func warn(_ message: String) { warn(message, []) }
    func info(_ message: String) { info(message, []) }
    func debug(_ message: String) { debug(message, []) }
}

/// No-op logger.
public struct NoopInteractionsLogger: InteractionsLogger {
    public init() {}
    public func error(_ message: String, _ rest: [Any]) {}
    public func warn(_ message: String, _ rest: [Any]) {}
    public func info(_ message: String, _ rest: [Any]) {}
    public func debug(_ message: String, _ rest: [Any]) {}
}

/// Default console logger that writes to stderr.
public struct ConsoleInteractionsLogger: InteractionsLogger {
    public init() {}
    public func error(_ message: String, _ rest: [Any]) { FileHandle.standardError.write(Data("[error] \(message)\n".utf8)) }
    public func warn(_ message: String, _ rest: [Any]) { FileHandle.standardError.write(Data("[warn] \(message)\n".utf8)) }
    public func info(_ message: String, _ rest: [Any]) { FileHandle.standardError.write(Data("[info] \(message)\n".utf8)) }
    public func debug(_ message: String, _ rest: [Any]) { FileHandle.standardError.write(Data("[debug] \(message)\n".utf8)) }
}

/// Parses a log level. Mirrors `parseLogLevel` in `internal/utils/log.ts`.
public func parseLogLevel(
    _ maybeLevel: String?,
    sourceName: String,
    client: BaseGeminiNextGenAPIClient
) -> InteractionsLogLevel? {
    guard let maybeLevel = maybeLevel else { return nil }
    if let level = InteractionsLogLevel(rawValue: maybeLevel) {
        return level
    }
    loggerFor(client).warn(
        "\(sourceName) was set to \"\(maybeLevel)\", expected one of \(InteractionsLogLevel.allCases.map { $0.rawValue })"
    )
    return nil
}

/// Wraps a client's logger with level filtering. Mirrors `loggerFor` in `internal/utils/log.ts`.
public func loggerFor(_ client: BaseGeminiNextGenAPIClient) -> InteractionsLogger {
    let level = client.logLevel ?? .off
    return LevelFilteredLogger(inner: client.logger, level: level)
}

private struct LevelFilteredLogger: InteractionsLogger {
    let inner: InteractionsLogger
    let level: InteractionsLogLevel

    func shouldLog(_ fnLevel: InteractionsLogLevel) -> Bool {
        return fnLevel.rank <= level.rank
    }
    func error(_ message: String, _ rest: [Any]) { if shouldLog(.error) { inner.error(message, rest) } }
    func warn(_ message: String, _ rest: [Any]) { if shouldLog(.warn) { inner.warn(message, rest) } }
    func info(_ message: String, _ rest: [Any]) { if shouldLog(.info) { inner.info(message, rest) } }
    func debug(_ message: String, _ rest: [Any]) { if shouldLog(.debug) { inner.debug(message, rest) } }
}

/// Format request details for safe logging. Strips sensitive headers and removes
/// internal options. Mirrors `formatRequestDetails` in `internal/utils/log.ts`.
public func formatRequestDetails(
    options: RequestOptions? = nil,
    headers: [String: String]? = nil,
    retryOfRequestLogID: String? = nil,
    url: String? = nil,
    status: Int? = nil,
    method: String? = nil,
    durationMs: Int? = nil,
    message: Any? = nil,
    body: Any? = nil
) -> [String: Any] {
    var details: [String: Any] = [:]
    if let options = options {
        var sanitizedOptions = options
        sanitizedOptions.headers = nil
        details["options"] = sanitizedOptions
    }
    if let headers = headers {
        var redacted: [String: String] = [:]
        for (name, value) in headers {
            let l = name.lowercased()
            if l == "x-goog-api-key" || l == "authorization" || l == "cookie" || l == "set-cookie" {
                redacted[name] = "***"
            } else {
                redacted[name] = value
            }
        }
        details["headers"] = redacted
    }
    if let retryOfRequestLogID = retryOfRequestLogID {
        details["retryOf"] = retryOfRequestLogID
    }
    if let url = url { details["url"] = url }
    if let status = status { details["status"] = status }
    if let method = method { details["method"] = method }
    if let durationMs = durationMs { details["durationMs"] = durationMs }
    if let message = message { details["message"] = message }
    if let body = body { details["body"] = body }
    return details
}
