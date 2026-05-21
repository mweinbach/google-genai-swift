// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Caches

public final class Caches: BaseModule, @unchecked Sendable {
    private let apiClient: ApiClient

    public init(apiClient: ApiClient) {
        self.apiClient = apiClient
        super.init()
    }

    /// Lists cached contents.
    public func list(
        _ params: ListCachedContentsParameters = ListCachedContentsParameters()
    ) async throws -> Pager<CachedContent> {
        let initial = try await self.listInternal(params)
        return Pager<CachedContent>(
            PagedItem.cachedContents,
            { x in
                guard let p = x as? ListCachedContentsParameters else {
                    throw GenAIError.invalidArgument("Expected ListCachedContentsParameters")
                }
                return try await self.listInternal(p)
            },
            initial,
            params
        )
    }

    /// Creates a cached contents resource.
    public func create(
        _ params: CreateCachedContentParameters
    ) async throws -> CachedContent {
        var path = ""
        var queryParams: [String: String] = [:]
        let paramsDict = try jsonObject(params)
        if self.apiClient.isVertexAI() {
            var parent: [String: JSONValue] = [:]
            var body = try createCachedContentParametersToVertex(
                apiClient: self.apiClient,
                fromObject: paramsDict,
                parentObject: &parent
            )
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("cachedContents", urlMap)
            } else {
                path = try formatMap("cachedContents", [:])
            }
            queryParams = extractStringMap(body["_query"])
            body.removeValue(forKey: "_url")
            body.removeValue(forKey: "_query")

            let bodyString = jsonValueObjectToString(body)
            let httpResponse = try await self.apiClient.request(HttpRequest(
                path: path,
                queryParams: queryParams,
                body: .string(bodyString),
                httpMethod: .POST,
                httpOptions: params.config?.httpOptions,
                abortSignal: params.config?.abortSignal
            ))
            let apiResponse = try httpResponse.json()
            return try decodeFromJSONValue(CachedContent.self, apiResponse)
        } else {
            var parent: [String: JSONValue] = [:]
            var body = try createCachedContentParametersToMldev(
                apiClient: self.apiClient,
                fromObject: paramsDict,
                parentObject: &parent
            )
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("cachedContents", urlMap)
            } else {
                path = try formatMap("cachedContents", [:])
            }
            queryParams = extractStringMap(body["_query"])
            body.removeValue(forKey: "_url")
            body.removeValue(forKey: "_query")

            let bodyString = jsonValueObjectToString(body)
            let httpResponse = try await self.apiClient.request(HttpRequest(
                path: path,
                queryParams: queryParams,
                body: .string(bodyString),
                httpMethod: .POST,
                httpOptions: params.config?.httpOptions,
                abortSignal: params.config?.abortSignal
            ))
            let apiResponse = try httpResponse.json()
            return try decodeFromJSONValue(CachedContent.self, apiResponse)
        }
    }

    /// Gets cached content configurations.
    public func get(
        _ params: GetCachedContentParameters
    ) async throws -> CachedContent {
        var path = ""
        var queryParams: [String: String] = [:]
        let paramsDict = try jsonObject(params)
        if self.apiClient.isVertexAI() {
            var parent: [String: JSONValue] = [:]
            var body = try getCachedContentParametersToVertex(
                apiClient: self.apiClient,
                fromObject: paramsDict,
                parentObject: &parent
            )
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
            return try decodeFromJSONValue(CachedContent.self, apiResponse)
        } else {
            var parent: [String: JSONValue] = [:]
            var body = try getCachedContentParametersToMldev(
                apiClient: self.apiClient,
                fromObject: paramsDict,
                parentObject: &parent
            )
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
            return try decodeFromJSONValue(CachedContent.self, apiResponse)
        }
    }

    /// Deletes cached content.
    public func delete(
        _ params: DeleteCachedContentParameters
    ) async throws -> DeleteCachedContentResponse {
        var path = ""
        var queryParams: [String: String] = [:]
        let paramsDict = try jsonObject(params)
        if self.apiClient.isVertexAI() {
            var parent: [String: JSONValue] = [:]
            var body = try deleteCachedContentParametersToVertex(
                apiClient: self.apiClient,
                fromObject: paramsDict,
                parentObject: &parent
            )
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
                httpMethod: .DELETE,
                httpOptions: params.config?.httpOptions,
                abortSignal: params.config?.abortSignal
            ))
            let apiResponse = try httpResponse.json()
            let apiDict = jsonValueAsDict(apiResponse)
            var respParent: [String: JSONValue] = [:]
            let resp = try deleteCachedContentResponseFromVertex(
                apiClient: self.apiClient,
                fromObject: apiDict,
                parentObject: &respParent
            )
            let typed = try decodeFromJSONObject(DeleteCachedContentResponse.self, resp)
            typed.sdkHttpResponse = HttpResponse(headers: httpResponse.headers, bodyData: nil)
            return typed
        } else {
            var parent: [String: JSONValue] = [:]
            var body = try deleteCachedContentParametersToMldev(
                apiClient: self.apiClient,
                fromObject: paramsDict,
                parentObject: &parent
            )
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
                httpMethod: .DELETE,
                httpOptions: params.config?.httpOptions,
                abortSignal: params.config?.abortSignal
            ))
            let apiResponse = try httpResponse.json()
            let apiDict = jsonValueAsDict(apiResponse)
            var respParent: [String: JSONValue] = [:]
            let resp = try deleteCachedContentResponseFromMldev(
                apiClient: self.apiClient,
                fromObject: apiDict,
                parentObject: &respParent
            )
            let typed = try decodeFromJSONObject(DeleteCachedContentResponse.self, resp)
            typed.sdkHttpResponse = HttpResponse(headers: httpResponse.headers, bodyData: nil)
            return typed
        }
    }

    /// Updates cached content configurations.
    public func update(
        _ params: UpdateCachedContentParameters
    ) async throws -> CachedContent {
        var path = ""
        var queryParams: [String: String] = [:]
        let paramsDict = try jsonObject(params)
        if self.apiClient.isVertexAI() {
            var parent: [String: JSONValue] = [:]
            var body = try updateCachedContentParametersToVertex(
                apiClient: self.apiClient,
                fromObject: paramsDict,
                parentObject: &parent
            )
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
                httpMethod: .PATCH,
                httpOptions: params.config?.httpOptions,
                abortSignal: params.config?.abortSignal
            ))
            let apiResponse = try httpResponse.json()
            return try decodeFromJSONValue(CachedContent.self, apiResponse)
        } else {
            var parent: [String: JSONValue] = [:]
            var body = try updateCachedContentParametersToMldev(
                apiClient: self.apiClient,
                fromObject: paramsDict,
                parentObject: &parent
            )
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
                httpMethod: .PATCH,
                httpOptions: params.config?.httpOptions,
                abortSignal: params.config?.abortSignal
            ))
            let apiResponse = try httpResponse.json()
            return try decodeFromJSONValue(CachedContent.self, apiResponse)
        }
    }

    private func listInternal(
        _ params: ListCachedContentsParameters
    ) async throws -> ListCachedContentsResponse {
        var path = ""
        var queryParams: [String: String] = [:]
        let paramsDict = try jsonObject(params)
        if self.apiClient.isVertexAI() {
            var parent: [String: JSONValue] = [:]
            var body = try listCachedContentsParametersToVertex(
                apiClient: self.apiClient,
                fromObject: paramsDict,
                parentObject: &parent
            )
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("cachedContents", urlMap)
            } else {
                path = try formatMap("cachedContents", [:])
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
            let apiDict = jsonValueAsDict(apiResponse)
            var respParent: [String: JSONValue] = [:]
            let resp = try listCachedContentsResponseFromVertex(
                apiClient: self.apiClient,
                fromObject: apiDict,
                parentObject: &respParent
            )
            let typed = try decodeFromJSONObject(ListCachedContentsResponse.self, resp)
            typed.sdkHttpResponse = HttpResponse(headers: httpResponse.headers, bodyData: nil)
            return typed
        } else {
            var parent: [String: JSONValue] = [:]
            var body = try listCachedContentsParametersToMldev(
                apiClient: self.apiClient,
                fromObject: paramsDict,
                parentObject: &parent
            )
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("cachedContents", urlMap)
            } else {
                path = try formatMap("cachedContents", [:])
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
            let apiDict = jsonValueAsDict(apiResponse)
            var respParent: [String: JSONValue] = [:]
            let resp = try listCachedContentsResponseFromMldev(
                apiClient: self.apiClient,
                fromObject: apiDict,
                parentObject: &respParent
            )
            let typed = try decodeFromJSONObject(ListCachedContentsResponse.self, resp)
            typed.sdkHttpResponse = HttpResponse(headers: httpResponse.headers, bodyData: nil)
            return typed
        }
    }
}

// MARK: - Helpers

/// Decodes any `JSONValue` into a Codable type.
internal func decodeFromJSONValue<T: Decodable>(_ type: T.Type, _ value: JSONValue) throws -> T {
    let data = try JSONEncoder().encode(value)
    return try JSONDecoder().decode(T.self, from: data)
}
