// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Converter stubs (Wave 5)

// TODO Wave 5: Port from ./converters/_documents_converters.js
internal func getDocumentParametersToMldev(
    _ fromObject: GetDocumentParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (getDocumentParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_documents_converters.js
internal func deleteDocumentParametersToMldev(
    _ fromObject: DeleteDocumentParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (deleteDocumentParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_documents_converters.js
internal func listDocumentsParametersToMldev(
    _ fromObject: ListDocumentsParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (listDocumentsParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_documents_converters.js
internal func listDocumentsResponseFromMldev(_ fromObject: JSONValue) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (listDocumentsResponseFromMldev)")
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
            var body = getDocumentParametersToMldev(params)
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
            var body = deleteDocumentParametersToMldev(params)
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
            var body = listDocumentsParametersToMldev(params)
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
            let resp = listDocumentsResponseFromMldev(apiResponse)
            return try decodeFromJSONObject(ListDocumentsResponse.self, resp)
        }
    }
}
