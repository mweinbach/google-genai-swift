// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Models that use the legacy vertex+lyria response/event shape.
public let LEGACY_LYRIA_MODELS: Set<String> = [
    "lyria-3-pro-preview",
    "lyria-3-clip-preview",
]

/// Event-type renames from the legacy lyria SSE shape to the modern one.
public let LEGACY_EVENT_TYPE_RENAMES: [String: String] = [
    "interaction.start": "interaction.created",
    "content.start": "step.start",
    "content.delta": "step.delta",
    "content.stop": "step.stop",
    "interaction.complete": "interaction.completed",
]

/// Whether the given request needs the legacy lyria shim.
public func isLegacyLyriaRequest(isVertex: Bool, model: JSONValue?) -> Bool {
    guard isVertex else { return false }
    if case .string(let s) = model {
        return LEGACY_LYRIA_MODELS.contains(s)
    }
    return false
}

/// Detect whether a client is in vertex mode.
public func isVertexClient(_ client: BaseGeminiNextGenAPIClient) -> Bool {
    guard let adapter = client.clientAdapter else { return false }
    return adapter.isVertexAI()
}

private func isPlainObject(_ value: JSONValue) -> Bool {
    if case .object = value { return true }
    return false
}

/// Wrap `outputs` into `steps: [{type: 'model_output', content: outputs}]` if needed.
private func wrapOutputsAsSteps(_ data: [String: JSONValue]) -> [String: JSONValue] {
    if data["steps"] != nil { return data }
    guard let outputs = data["outputs"] else { return data }
    var out = data
    out.removeValue(forKey: "outputs")
    out["steps"] = .array([
        .object([
            "type": .string("model_output"),
            "content": outputs,
        ]),
    ])
    return out
}

/// Non-streaming: rewrite a legacy interaction response so consumers see the modern
/// `steps` shape. Mirrors `coerceLegacyInteractionResponse`.
public func coerceLegacyInteractionResponse(_ data: JSONValue) -> JSONValue {
    guard case .object(let obj) = data else { return data }
    return .object(wrapOutputsAsSteps(obj))
}

/// Streaming: translate one legacy SSE event to its modern equivalent.
/// Mirrors `maybeRemapLegacyStreamEvent`.
public func maybeRemapLegacyStreamEvent(_ data: JSONValue) -> JSONValue {
    guard case .object(var obj) = data else { return data }

    guard case .string(let eventType) = obj["event_type"] ?? .null,
          let renamed = LEGACY_EVENT_TYPE_RENAMES[eventType] else {
        return data
    }
    obj["event_type"] = .string(renamed)

    if eventType == "content.start" {
        let content = obj.removeValue(forKey: "content") ?? .null
        let stepContent: [JSONValue]
        switch content {
        case .null: stepContent = []
        case .array(let arr): stepContent = arr
        default: stepContent = [content]
        }
        obj["step"] = .object([
            "type": .string("model_output"),
            "content": .array(stepContent),
        ])
        return .object(obj)
    }

    if eventType == "interaction.start" || eventType == "interaction.complete" {
        if case .object(let inner) = obj["interaction"] ?? .null {
            obj["interaction"] = .object(wrapOutputsAsSteps(inner))
        }
    }
    return .object(obj)
}

/// A `Stream` subclass that runs each yielded SSE item through `maybeRemapLegacyStreamEvent`.
/// Mirrors `LegacyLyriaStream`.
public final class LegacyLyriaStream {
    public static func fromSSEResponse(
        bodyStream: InteractionsReadableStream,
        controller: AbortController,
        client: BaseGeminiNextGenAPIClient? = nil
    ) -> InteractionsStream {
        let base = InteractionsStream.fromSSEResponse(
            bodyStream: bodyStream,
            controller: controller,
            client: client
        )
        return InteractionsStream(controller: controller) {
            AsyncThrowingStream { continuation in
                let task = Task {
                    do {
                        for try await item in base {
                            continuation.yield(maybeRemapLegacyStreamEvent(item))
                        }
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
                continuation.onTermination = { _ in task.cancel() }
            }
        }
    }
}
