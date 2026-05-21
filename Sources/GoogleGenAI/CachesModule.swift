// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Converter stubs (Wave 5)

// TODO Wave 5: Port from ./converters/_caches_converters.js
internal func createCachedContentParametersToMldev(
    _ apiClient: ApiClient,
    _ fromObject: CreateCachedContentParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (createCachedContentParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_caches_converters.js
internal func createCachedContentParametersToVertex(
    _ apiClient: ApiClient,
    _ fromObject: CreateCachedContentParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (createCachedContentParametersToVertex)")
}

// TODO Wave 5: Port from ./converters/_caches_converters.js
internal func getCachedContentParametersToMldev(
    _ apiClient: ApiClient,
    _ fromObject: GetCachedContentParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (getCachedContentParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_caches_converters.js
internal func getCachedContentParametersToVertex(
    _ apiClient: ApiClient,
    _ fromObject: GetCachedContentParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (getCachedContentParametersToVertex)")
}

// TODO Wave 5: Port from ./converters/_caches_converters.js
internal func deleteCachedContentParametersToMldev(
    _ apiClient: ApiClient,
    _ fromObject: DeleteCachedContentParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (deleteCachedContentParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_caches_converters.js
internal func deleteCachedContentParametersToVertex(
    _ apiClient: ApiClient,
    _ fromObject: DeleteCachedContentParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (deleteCachedContentParametersToVertex)")
}

// TODO Wave 5: Port from ./converters/_caches_converters.js
internal func updateCachedContentParametersToMldev(
    _ apiClient: ApiClient,
    _ fromObject: UpdateCachedContentParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (updateCachedContentParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_caches_converters.js
internal func updateCachedContentParametersToVertex(
    _ apiClient: ApiClient,
    _ fromObject: UpdateCachedContentParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (updateCachedContentParametersToVertex)")
}

// TODO Wave 5: Port from ./converters/_caches_converters.js
internal func listCachedContentsParametersToMldev(
    _ fromObject: ListCachedContentsParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (listCachedContentsParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_caches_converters.js
internal func listCachedContentsParametersToVertex(
    _ fromObject: ListCachedContentsParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (listCachedContentsParametersToVertex)")
}

// TODO Wave 5: Port from ./converters/_caches_converters.js
internal func deleteCachedContentResponseFromMldev(
    _ fromObject: JSONValue
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (deleteCachedContentResponseFromMldev)")
}

// TODO Wave 5: Port from ./converters/_caches_converters.js
internal func deleteCachedContentResponseFromVertex(
    _ fromObject: JSONValue
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (deleteCachedContentResponseFromVertex)")
}

// TODO Wave 5: Port from ./converters/_caches_converters.js
internal func listCachedContentsResponseFromMldev(
    _ fromObject: JSONValue
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (listCachedContentsResponseFromMldev)")
}

// TODO Wave 5: Port from ./converters/_caches_converters.js
internal func listCachedContentsResponseFromVertex(
    _ fromObject: JSONValue
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (listCachedContentsResponseFromVertex)")
}

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
        if self.apiClient.isVertexAI() {
            var body = createCachedContentParametersToVertex(self.apiClient, params)
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
            var body = createCachedContentParametersToMldev(self.apiClient, params)
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
        if self.apiClient.isVertexAI() {
            var body = getCachedContentParametersToVertex(self.apiClient, params)
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
            var body = getCachedContentParametersToMldev(self.apiClient, params)
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
        if self.apiClient.isVertexAI() {
            var body = deleteCachedContentParametersToVertex(self.apiClient, params)
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
            let resp = deleteCachedContentResponseFromVertex(apiResponse)
            let typed = try decodeFromJSONObject(DeleteCachedContentResponse.self, resp)
            typed.sdkHttpResponse = HttpResponse(headers: httpResponse.headers, bodyData: nil)
            return typed
        } else {
            var body = deleteCachedContentParametersToMldev(self.apiClient, params)
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
            let resp = deleteCachedContentResponseFromMldev(apiResponse)
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
        if self.apiClient.isVertexAI() {
            var body = updateCachedContentParametersToVertex(self.apiClient, params)
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
            var body = updateCachedContentParametersToMldev(self.apiClient, params)
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
        if self.apiClient.isVertexAI() {
            var body = listCachedContentsParametersToVertex(params)
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
            let resp = listCachedContentsResponseFromVertex(apiResponse)
            let typed = try decodeFromJSONObject(ListCachedContentsResponse.self, resp)
            typed.sdkHttpResponse = HttpResponse(headers: httpResponse.headers, bodyData: nil)
            return typed
        } else {
            var body = listCachedContentsParametersToMldev(params)
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
            let resp = listCachedContentsResponseFromMldev(apiResponse)
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
