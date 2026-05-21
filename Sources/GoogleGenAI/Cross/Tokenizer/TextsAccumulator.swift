// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Accumulates countable text from `Content`, `Tool`, and `Schema` objects.
///
/// Translated from `src/cross/tokenizer/_texts_accumulator.ts`. Text fields are
/// collected verbatim and returned via `getTexts()` for downstream tokenization.
/// Non-text content (binary blobs, file data) is rejected.
public final class TextsAccumulator {
    private var texts: [String] = []

    public init() {}

    /// Returns the accumulated texts in insertion order.
    public func getTexts() -> [String] { texts }

    /// Adds multiple `Content` objects.
    public func addContents(_ contents: [Content]) throws {
        for c in contents {
            try addContent(c)
        }
    }

    /// Adds a single `Content` object, traversing its parts.
    public func addContent(_ content: Content) throws {
        if let parts = content.parts {
            for part in parts {
                if part.fileData != nil || part.inlineData != nil {
                    throw GenAIError.unsupported(
                        "LocalTokenizers do not support non-text content types."
                    )
                }

                if let functionCall = part.functionCall {
                    addFunctionCall(functionCall)
                }

                if let functionResponse = part.functionResponse {
                    addFunctionResponse(functionResponse)
                }

                if let text = part.text {
                    texts.append(text)
                }
            }
        }
    }

    public func addFunctionCall(_ functionCall: FunctionCall) {
        if let name = functionCall.name {
            texts.append(name)
        }
        if let args = functionCall.args {
            dictTraverse(args)
        }
    }

    public func addTools(_ tools: [Tool]) {
        for tool in tools {
            addTool(tool)
        }
    }

    public func addTool(_ tool: Tool) {
        if let decls = tool.functionDeclarations {
            for d in decls {
                functionDeclarationTraverse(d)
            }
        }
    }

    public func addFunctionResponses(_ functionResponses: [FunctionResponse]) {
        for r in functionResponses {
            addFunctionResponse(r)
        }
    }

    public func addFunctionResponse(_ functionResponse: FunctionResponse) {
        if let name = functionResponse.name {
            texts.append(name)
        }
        if let response = functionResponse.response {
            dictTraverse(response)
        }
    }

    private func functionDeclarationTraverse(_ functionDeclaration: FunctionDeclaration) {
        if let name = functionDeclaration.name {
            texts.append(name)
        }
        if let description = functionDeclaration.description {
            texts.append(description)
        }
        if let parameters = functionDeclaration.parameters {
            addSchema(parameters)
        }
        if let response = functionDeclaration.response {
            addSchema(response)
        }
    }

    public func addSchema(_ schema: Schema) {
        if let format = schema.format {
            texts.append(format)
        }
        if let description = schema.description {
            texts.append(description)
        }
        if let e = schema.enum {
            texts.append(contentsOf: e)
        }
        if let required = schema.required {
            texts.append(contentsOf: required)
        }
        if let items = schema.items {
            addSchema(items.value)
        }
        if let properties = schema.properties {
            for (key, value) in properties {
                texts.append(key)
                addSchema(value)
            }
        }
        if let example = schema.example, case .null = example {
            // Treat explicit null example as absent — matches the TS guard.
        } else if let example = schema.example {
            anyTraverse(example)
        }
    }

    private func dictTraverse(_ obj: [String: JSONValue]) {
        texts.append(contentsOf: obj.keys)
        for value in obj.values {
            anyTraverse(value)
        }
    }

    private func anyTraverse(_ value: JSONValue) {
        switch value {
        case .string(let s):
            texts.append(s)
        case .array(let arr):
            for item in arr {
                anyTraverse(item)
            }
        case .object(let obj):
            dictTraverse(obj)
        case .null, .bool, .int, .double:
            break
        }
    }
}
