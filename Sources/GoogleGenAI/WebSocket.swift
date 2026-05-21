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
///
/// `onOpen` is fired from `URLSessionWebSocketDelegate.urlSession(_:webSocketTask:didOpenWithProtocol:)`
/// — i.e. only after the HTTP-Upgrade handshake actually completes — so callers
/// can safely send messages from the `onOpen` callback.
public final class URLSessionWebSocket: NSObject, WebSocketClient, URLSessionWebSocketDelegate, @unchecked Sendable {
    private let url: String
    private let headers: [String: String]
    private let callbacks: WebSocketCallbacks
    private var session: URLSession!
    private var task: URLSessionWebSocketTask?
    private let lock = NSLock()
    private var closed = false
    private var opened = false
    private var pendingSends: [String] = []

    public init(
        url: String,
        headers: [String: String],
        callbacks: WebSocketCallbacks
    ) {
        self.url = url
        self.headers = headers
        self.callbacks = callbacks
        super.init()
        self.session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
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
        // `startReceiving()` is intentionally NOT called here — it runs from
        // `didOpenWithProtocol` once the WebSocket handshake actually completes,
        // otherwise `task.receive` immediately fails with NSPOSIXErrorDomain 57.
    }

    public func send(_ message: String) throws {
        lock.lock()
        let task = self.task
        let isOpen = self.opened
        if !isOpen {
            // Queue until handshake completes — protects against the race where a caller
            // sends from `onOpen` but the delegate hasn't fired yet on this thread.
            self.pendingSends.append(message)
        }
        lock.unlock()
        guard let task = task else {
            throw GenAIError.runtime("WebSocket is not connected")
        }
        guard isOpen else { return }
        let callbacks = self.callbacks
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

    // MARK: - URLSessionWebSocketDelegate

    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didOpenWithProtocol protocol: String?
    ) {
        lock.lock()
        self.opened = true
        let drain = self.pendingSends
        self.pendingSends.removeAll()
        lock.unlock()
        self.callbacks.onOpen()
        let callbacks = self.callbacks
        // Start the receive loop now that the handshake has completed.
        self.startReceiving()
        for queued in drain {
            webSocketTask.send(.string(queued)) { error in
                if let error = error { callbacks.onError(error) }
            }
        }
    }

    public func urlSession(
        _ session: URLSession,
        webSocketTask: URLSessionWebSocketTask,
        didCloseWith closeCode: URLSessionWebSocketTask.CloseCode,
        reason: Data?
    ) {
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? ""
        self.handleClose(code: Int(closeCode.rawValue), reason: reasonString)
    }

    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        if let error = error {
            self.callbacks.onError(error)
            self.handleClose(code: -1, reason: error.localizedDescription)
        }
    }

    // MARK: - Receive loop

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
