// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Converter stubs (Wave 5)

// TODO Wave 5: Port from ./converters/_operations_converters.js
internal func getOperationParametersToVertex(
    _ fromObject: GetOperationParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (getOperationParametersToVertex)")
}

// TODO Wave 5: Port from ./converters/_operations_converters.js
internal func getOperationParametersToMldev(
    _ fromObject: GetOperationParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (getOperationParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_operations_converters.js
internal func fetchPredictOperationParametersToVertex(
    _ fromObject: FetchPredictOperationParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (fetchPredictOperationParametersToVertex)")
}

// MARK: - Operations

public final class Operations: BaseModule, @unchecked Sendable {
    private let apiClient: ApiClient

    public init(apiClient: ApiClient) {
        self.apiClient = apiClient
        super.init()
    }

    /// Gets the status of a long-running operation.
    public func getVideosOperation(
        _ parameters: OperationGetParameters<GenerateVideosOperation>
    ) async throws -> GenerateVideosOperation {
        let operation = parameters.operation
        let config = parameters.config

        guard let opName = operation.name, !opName.isEmpty else {
            throw GenAIError.invalidArgument("Operation name is required.")
        }

        if self.apiClient.isVertexAI() {
            let resourceName = opName.components(separatedBy: "/operations/").first ?? opName
            let httpOptions: HttpOptions? = config?.httpOptions

            let rawOperation = try await self.fetchPredictVideosOperationInternal(
                FetchPredictOperationParameters(
                    operationName: opName,
                    resourceName: resourceName,
                    config: FetchPredictOperationConfig(httpOptions: httpOptions)
                )
            )
            return GenerateVideosOperation.fromAPIResponse(
                apiClient: self.apiClient,
                apiResponse: rawOperation,
                isVertexAI: true
            )
        } else {
            let rawOperation = try await self.getVideosOperationInternal(
                GetOperationParameters(
                    operationName: opName,
                    config: config
                )
            )
            return GenerateVideosOperation.fromAPIResponse(
                apiClient: self.apiClient,
                apiResponse: rawOperation,
                isVertexAI: false
            )
        }
    }

    /// Gets the status of a long-running operation.
    public func get<T: Codable & Sendable>(
        _ parameters: OperationGetParameters<Operation<T>>
    ) async throws -> Operation<T> {
        let operation = parameters.operation
        let config = parameters.config

        guard let opName = operation.name, !opName.isEmpty else {
            throw GenAIError.invalidArgument("Operation name is required.")
        }

        if self.apiClient.isVertexAI() {
            let resourceName = opName.components(separatedBy: "/operations/").first ?? opName
            let httpOptions: HttpOptions? = config?.httpOptions

            let rawOperation = try await self.fetchPredictVideosOperationInternal(
                FetchPredictOperationParameters(
                    operationName: opName,
                    resourceName: resourceName,
                    config: FetchPredictOperationConfig(httpOptions: httpOptions)
                )
            )
            return try Operations.decodeOperation(rawOperation)
        } else {
            let rawOperation = try await self.getVideosOperationInternal(
                GetOperationParameters(
                    operationName: opName,
                    config: config
                )
            )
            return try Operations.decodeOperation(rawOperation)
        }
    }

    private static func decodeOperation<T: Codable & Sendable>(
        _ raw: [String: JSONValue]
    ) throws -> Operation<T> {
        let data = try JSONEncoder().encode(JSONValue.object(raw))
        return try JSONDecoder().decode(Operation<T>.self, from: data)
    }

    private func getVideosOperationInternal(
        _ params: GetOperationParameters
    ) async throws -> [String: JSONValue] {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            var body = getOperationParametersToVertex(params)
            guard case .object(let urlMap) = body["_url"] ?? .null else {
                throw GenAIError.runtime("Missing _url in body.")
            }
            path = try formatMap("{operationName}", urlMap)
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
            let json = try httpResponse.json()
            if case .object(let obj) = json { return obj }
            return [:]
        } else {
            var body = getOperationParametersToMldev(params)
            guard case .object(let urlMap) = body["_url"] ?? .null else {
                throw GenAIError.runtime("Missing _url in body.")
            }
            path = try formatMap("{operationName}", urlMap)
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
            let json = try httpResponse.json()
            if case .object(let obj) = json { return obj }
            return [:]
        }
    }

    private func fetchPredictVideosOperationInternal(
        _ params: FetchPredictOperationParameters
    ) async throws -> [String: JSONValue] {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            var body = fetchPredictOperationParametersToVertex(params)
            guard case .object(let urlMap) = body["_url"] ?? .null else {
                throw GenAIError.runtime("Missing _url in body.")
            }
            path = try formatMap("{resourceName}:fetchPredictOperation", urlMap)
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
            let json = try httpResponse.json()
            if case .object(let obj) = json { return obj }
            return [:]
        } else {
            throw GenAIError.unsupported(
                "This method is only supported by the Gemini Enterprise Agent Platform (previously known as Vertex AI)."
            )
        }
    }
}
