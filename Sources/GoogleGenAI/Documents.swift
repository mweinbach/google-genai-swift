// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Converter shims
//
// Local-typed wrappers that bridge strongly-typed parameter structs to the
// JSON-based converter functions in `Converters/DocumentsConverters.swift`.

private func _docObject<T: Encodable>(_ value: T) throws -> [String: JSONValue] {
    return try jsonObject(value)
}

private func _docAsObject(_ value: JSONValue) -> [String: JSONValue] {
    if case .object(let o) = value { return o }
    return [:]
}

private func _docMerge(_ dst: inout [String: JSONValue], _ src: [String: JSONValue]) {
    for (k, v) in src { dst[k] = v }
}

internal func getDocumentParametersToMldevShim(
    _ apiClient: ApiClient,
    _ fromObject: GetDocumentParameters
) throws -> [String: JSONValue] {
    let dict = try _docObject(fromObject)
    var parent: [String: JSONValue] = [:]
    let inner = try getDocumentParametersToMldev(
        apiClient: apiClient, fromObject: dict, parentObject: &parent
    )
    _docMerge(&parent, inner)
    return parent
}

internal func deleteDocumentParametersToMldevShim(
    _ apiClient: ApiClient,
    _ fromObject: DeleteDocumentParameters
) throws -> [String: JSONValue] {
    let dict = try _docObject(fromObject)
    var parent: [String: JSONValue] = [:]
    let inner = try deleteDocumentParametersToMldev(
        apiClient: apiClient, fromObject: dict, parentObject: &parent
    )
    _docMerge(&parent, inner)
    return parent
}

internal func listDocumentsParametersToMldevShim(
    _ apiClient: ApiClient,
    _ fromObject: ListDocumentsParameters
) throws -> [String: JSONValue] {
    let dict = try _docObject(fromObject)
    var parent: [String: JSONValue] = [:]
    let inner = try listDocumentsParametersToMldev(
        apiClient: apiClient, fromObject: dict, parentObject: &parent
    )
    _docMerge(&parent, inner)
    return parent
}

internal func listDocumentsResponseFromMldevShim(
    _ apiClient: ApiClient,
    _ fromObject: JSONValue
) throws -> [String: JSONValue] {
    let dict = _docAsObject(fromObject)
    var parent: [String: JSONValue] = [:]
    return try listDocumentsResponseFromMldev(
        apiClient: apiClient, fromObject: dict, parentObject: &parent
    )
}

// MARK: - Documents

public final class Documents: BaseModule, @unchecked Sendable {
    private let apiClient: ApiClient

    public init(apiClient: ApiClient) {
        self.apiClient = apiClient
        super.init()
    }

    /// Lists documents.
    public func list(
        _ params: ListDocumentsParameters
    ) async throws -> Pager<Document> {
        let initial = try await self.listInternal(params)
        let parent = params.parent
        return Pager<Document>(
            PagedItem.documents,
            { x in
                guard let cfg = x as? ListDocumentsConfig else {
                    // If the pager passes the original params object, accept it too.
                    if let p = x as? ListDocumentsParameters {
                        return try await self.listInternal(p)
                    }
                    throw GenAIError.invalidArgument("Expected ListDocumentsConfig or ListDocumentsParameters")
                }
                let next = ListDocumentsParameters(parent: parent, config: cfg)
                return try await self.listInternal(next)
            },
            initial,
            params
        )
    }

    /// Gets a Document.
    public func get(_ params: GetDocumentParameters) async throws -> Document {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            throw ApiError(
                message: "This method is only supported by the Gemini Developer API.",
                status: 400
            )
        } else {
            var body = try getDocumentParametersToMldevShim(self.apiClient, params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("{name}", urlMap)
            } else {
                path = try formatMap("{name}", [:])
            }
            queryParams = extractStringMap(body["_query"])
            body.removeValue(forKey: "_url")
            body.removeValue(forKey: "_query")

            let bodyString = jsonValueObjectToString(body)
            let httpResponse = try await self.apiClient.request(HttpRequest(
                path: path,
                queryParams: queryParams,
                body: .string(bodyString),
                httpMethod: .GET,
                httpOptions: params.config?.httpOptions,
                abortSignal: params.config?.abortSignal
            ))
            let apiResponse = try httpResponse.json()
            return try decodeFromJSONValue(Document.self, apiResponse)
        }
    }

    /// Deletes a Document.
    public func delete(_ params: DeleteDocumentParameters) async throws {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            throw ApiError(
                message: "This method is only supported by the Gemini Developer API.",
                status: 400
            )
        } else {
            var body = try deleteDocumentParametersToMldevShim(self.apiClient, params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("{name}", urlMap)
            } else {
                path = try formatMap("{name}", [:])
            }
            queryParams = extractStringMap(body["_query"])
            body.removeValue(forKey: "_url")
            body.removeValue(forKey: "_query")

            let bodyString = jsonValueObjectToString(body)
            _ = try await self.apiClient.request(HttpRequest(
                path: path,
                queryParams: queryParams,
                body: .string(bodyString),
                httpMethod: .DELETE,
                httpOptions: params.config?.httpOptions,
                abortSignal: params.config?.abortSignal
            ))
        }
    }

    private func listInternal(
        _ params: ListDocumentsParameters
    ) async throws -> ListDocumentsResponse {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            throw ApiError(
                message: "This method is only supported by the Gemini Developer API.",
                status: 400
            )
        } else {
            var body = try listDocumentsParametersToMldevShim(self.apiClient, params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("{parent}/documents", urlMap)
            } else {
                path = try formatMap("{parent}/documents", [:])
            }
            queryParams = extractStringMap(body["_query"])
            body.removeValue(forKey: "_url")
            body.removeValue(forKey: "_query")

            let bodyString = jsonValueObjectToString(body)
            let httpResponse = try await self.apiClient.request(HttpRequest(
                path: path,
                queryParams: queryParams,
                body: .string(bodyString),
                httpMethod: .GET,
                httpOptions: params.config?.httpOptions,
                abortSignal: params.config?.abortSignal
            ))
            let apiResponse = try httpResponse.json()
            let resp = try listDocumentsResponseFromMldevShim(self.apiClient, apiResponse)
            return try decodeFromJSONObject(ListDocumentsResponse.self, resp)
        }
    }
}
