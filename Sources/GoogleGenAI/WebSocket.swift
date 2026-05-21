// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - WebSocket callbacks

/// Mirrors `WebSocketCallbacks` from `_websocket.ts`. Each callback is `@Sendable` so the
/// receiving websocket implementation can hop between actors freely.
public struct WebSocketCallbacks: Sendable {
    public var onOpen: @Sendable () -> Void
    public var onMessage: @Sendable (String) -> Void
    public var onError: @Sendable (Error) -> Void
    public var onClose: @Sendable (Int, String) -> Void

    public init(
        onOpen: @escaping @Sendable () -> Void,
        onMessage: @escaping @Sendable (String) -> Void,
        onError: @escaping @Sendable (Error) -> Void,
        onClose: @escaping @Sendable (Int, String) -> Void
    ) {
        self.onOpen = onOpen
        self.onMessage = onMessage
        self.onError = onError
        self.onClose = onClose
    }
}

// MARK: - WebSocketClient protocol

/// Foundation-native equivalent of TS `WebSocket` interface (`_websocket.ts`).
public protocol WebSocketClient: Sendable {
    /// Connects the socket to the server.
    func connect()
    /// Sends a message to the server.
    func send(_ message: String) throws
    /// Closes the socket connection.
    func close()
}

/// Mirrors `WebSocketFactory` from `_websocket.ts`. Collapses node/browser variants into a
/// single Foundation factory backed by `URLSessionWebSocketTask`.
public protocol WebSocketFactory: Sendable {
    func create(
        url: String,
        headers: [String: String],
        callbacks: WebSocketCallbacks
    ) -> WebSocketClient
}

// MARK: - URLSession-backed implementation

/// Foundation implementation backed by `URLSessionWebSocketTask`. Collapses
/// `NodeWebSocket` (Node `ws` package) and `BrowserWebSocket` (browser native) into one type.
public final class URLSessionWebSocket: WebSocketClient, @unchecked Sendable {
    private let url: String
    private let headers: [String: String]
    private let callbacks: WebSocketCallbacks
    private let session: URLSession
    private var task: URLSessionWebSocketTask?
    private let lock = NSLock()
    private var closed = false

    public init(
        url: String,
        headers: [String: String],
        callbacks: WebSocketCallbacks,
        session: URLSession = .shared
    ) {
        self.url = url
        self.headers = headers
        self.callbacks = callbacks
        self.session = session
    }

    public func connect() {
        guard let parsed = URL(string: url) else {
            self.callbacks.onError(GenAIError.invalidArgument("Invalid websocket URL: \(url)"))
            return
        }
        var request = URLRequest(url: parsed)
        for (k, v) in headers {
            request.setValue(v, forHTTPHeaderField: k)
        }
        let task = session.webSocketTask(with: request)
        lock.lock(); self.task = task; lock.unlock()
        task.resume()
        // URLSessionWebSocketTask connects on resume; receive() will report errors via the
        // recursive receive loop. We fire onOpen immediately to match TS WebSocket semantics
        // (Node/browser emit `open` once the task is ready to send).
        self.callbacks.onOpen()
        self.startReceiving()
    }

    public func send(_ message: String) throws {
        lock.lock()
        let task = self.task
        lock.unlock()
        guard let task = task else {
            throw GenAIError.runtime("WebSocket is not connected")
        }
        let callbacks = self.callbacks
        // Send is async — fire-and-forget but surface failures through onError.
        task.send(.string(message)) { error in
            if let error = error {
                callbacks.onError(error)
            }
        }
    }

    public func close() {
        lock.lock()
        let task = self.task
        let alreadyClosed = self.closed
        self.closed = true
        lock.unlock()
        guard !alreadyClosed, let task = task else { return }
        task.cancel(with: .normalClosure, reason: nil)
        self.callbacks.onClose(Int(URLSessionWebSocketTask.CloseCode.normalClosure.rawValue), "")
    }

    private func startReceiving() {
        lock.lock()
        let task = self.task
        lock.unlock()
        guard let task = task else { return }
        let callbacks = self.callbacks
        task.receive { [weak self] result in
            switch result {
            case .failure(let error):
                callbacks.onError(error)
                self?.handleClose(code: -1, reason: error.localizedDescription)
            case .success(let message):
                switch message {
                case .string(let s):
                    callbacks.onMessage(s)
                case .data(let d):
                    if let s = String(data: d, encoding: .utf8) {
                        callbacks.onMessage(s)
                    } else {
                        callbacks.onError(GenAIError.runtime("WebSocket frame was not UTF-8 decodable"))
                    }
                @unknown default:
                    break
                }
                // Recursively chain another receive() — `URLSessionWebSocketTask` only delivers
                // one frame per call.
                self?.startReceiving()
            }
        }
    }

    private func handleClose(code: Int, reason: String) {
        lock.lock()
        let alreadyClosed = self.closed
        self.closed = true
        lock.unlock()
        if !alreadyClosed {
            self.callbacks.onClose(code, reason)
        }
    }
}

/// Default factory that produces `URLSessionWebSocket` instances. Used by `Live`.
public struct URLSessionWebSocketFactory: WebSocketFactory {
    public init() {}
    public func create(
        url: String,
        headers: [String: String],
        callbacks: WebSocketCallbacks
    ) -> WebSocketClient {
        return URLSessionWebSocket(url: url, headers: headers, callbacks: callbacks)
    }
}
