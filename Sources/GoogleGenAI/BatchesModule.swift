// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Converter stubs (Wave 5)

// TODO Wave 5: Port from ./converters/_batches_converters.js
internal func createBatchJobParametersToMldev(
    _ apiClient: ApiClient,
    _ fromObject: CreateBatchJobParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (createBatchJobParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_batches_converters.js
internal func createBatchJobParametersToVertex(
    _ apiClient: ApiClient,
    _ fromObject: CreateBatchJobParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (createBatchJobParametersToVertex)")
}

// TODO Wave 5: Port from ./converters/_batches_converters.js
internal func createEmbeddingsBatchJobParametersToMldev(
    _ apiClient: ApiClient,
    _ fromObject: CreateEmbeddingsBatchJobParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (createEmbeddingsBatchJobParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_batches_converters.js
internal func getBatchJobParametersToMldev(
    _ apiClient: ApiClient,
    _ fromObject: GetBatchJobParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (getBatchJobParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_batches_converters.js
internal func getBatchJobParametersToVertex(
    _ apiClient: ApiClient,
    _ fromObject: GetBatchJobParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (getBatchJobParametersToVertex)")
}

// TODO Wave 5: Port from ./converters/_batches_converters.js
internal func cancelBatchJobParametersToMldev(
    _ apiClient: ApiClient,
    _ fromObject: CancelBatchJobParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (cancelBatchJobParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_batches_converters.js
internal func cancelBatchJobParametersToVertex(
    _ apiClient: ApiClient,
    _ fromObject: CancelBatchJobParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (cancelBatchJobParametersToVertex)")
}

// TODO Wave 5: Port from ./converters/_batches_converters.js
internal func listBatchJobsParametersToMldev(
    _ fromObject: ListBatchJobsParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (listBatchJobsParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_batches_converters.js
internal func listBatchJobsParametersToVertex(
    _ fromObject: ListBatchJobsParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (listBatchJobsParametersToVertex)")
}

// TODO Wave 5: Port from ./converters/_batches_converters.js
internal func deleteBatchJobParametersToMldev(
    _ apiClient: ApiClient,
    _ fromObject: DeleteBatchJobParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (deleteBatchJobParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_batches_converters.js
internal func deleteBatchJobParametersToVertex(
    _ apiClient: ApiClient,
    _ fromObject: DeleteBatchJobParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (deleteBatchJobParametersToVertex)")
}

// TODO Wave 5: Port from ./converters/_batches_converters.js
internal func batchJobFromMldev(_ fromObject: JSONValue) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (batchJobFromMldev)")
}

// TODO Wave 5: Port from ./converters/_batches_converters.js
internal func batchJobFromVertex(_ fromObject: JSONValue) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (batchJobFromVertex)")
}

// TODO Wave 5: Port from ./converters/_batches_converters.js
internal func listBatchJobsResponseFromMldev(_ fromObject: JSONValue) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (listBatchJobsResponseFromMldev)")
}

// TODO Wave 5: Port from ./converters/_batches_converters.js
internal func listBatchJobsResponseFromVertex(_ fromObject: JSONValue) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (listBatchJobsResponseFromVertex)")
}

// TODO Wave 5: Port from ./converters/_batches_converters.js
internal func deleteResourceJobFromMldev(_ fromObject: JSONValue) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (deleteResourceJobFromMldev)")
}

// TODO Wave 5: Port from ./converters/_batches_converters.js
internal func deleteResourceJobFromVertex(_ fromObject: JSONValue) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (deleteResourceJobFromVertex)")
}

// MARK: - Batches

public final class Batches: BaseModule, @unchecked Sendable {
    private let apiClient: ApiClient

    public init(apiClient: ApiClient) {
        self.apiClient = apiClient
        super.init()
    }

    /// Lists batch jobs.
    public func list(
        _ params: ListBatchJobsParameters = ListBatchJobsParameters()
    ) async throws -> Pager<BatchJob> {
        let initial = try await self.listInternal(params)
        return Pager<BatchJob>(
            PagedItem.batchJobs,
            { x in
                guard let p = x as? ListBatchJobsParameters else {
                    throw GenAIError.invalidArgument("Expected ListBatchJobsParameters")
                }
                return try await self.listInternal(p)
            },
            initial,
            params
        )
    }

    /// Create batch job.
    public func create(_ params: CreateBatchJobParameters) async throws -> BatchJob {
        var params = params
        if self.apiClient.isVertexAI() {
            // Format destination if not provided
            params.config = self.formatDestination(params.src, params.config)
        }
        return try await self.createInternal(params)
    }

    /// **Experimental** Creates an embedding batch job.
    public func createEmbeddings(
        _ params: CreateEmbeddingsBatchJobParameters
    ) async throws -> BatchJob {
        print("batches.createEmbeddings() is experimental and may change without notice.")

        if self.apiClient.isVertexAI() {
            throw ApiError(
                message: "Gemini Enterprise Agent Platform (previously known as Vertex AI) does not support batches.createEmbeddings.",
                status: 400
            )
        }
        return try await self.createEmbeddingsInternal(params)
    }

    // Helper function to handle inlined generate content requests
    private func createInlinedGenerateContentRequest(
        _ params: CreateBatchJobParameters
    ) throws -> (path: String, body: [String: JSONValue]) {
        var body = createBatchJobParametersToMldev(self.apiClient, params)

        guard case .object(let urlParams) = body["_url"] ?? .null else {
            throw GenAIError.runtime("Missing _url in createInlinedGenerateContentRequest body.")
        }
        let path = try formatMap("{model}:batchGenerateContent", urlParams)

        guard case .object(var batch) = body["batch"] ?? .null else {
            throw GenAIError.runtime("Missing batch in createInlinedGenerateContentRequest body.")
        }
        guard case .object(var inputConfig) = batch["inputConfig"] ?? .null else {
            throw GenAIError.runtime("Missing inputConfig in createInlinedGenerateContentRequest body.")
        }
        guard case .object(var requestsWrapper) = inputConfig["requests"] ?? .null else {
            throw GenAIError.runtime("Missing requests wrapper in createInlinedGenerateContentRequest body.")
        }
        guard case .array(let requests) = requestsWrapper["requests"] ?? .null else {
            throw GenAIError.runtime("Missing requests array in createInlinedGenerateContentRequest body.")
        }

        var newRequests: [JSONValue] = []
        for request in requests {
            guard case .object(var requestDict) = request else {
                newRequests.append(request)
                continue
            }
            if let systemInstructionValue = requestDict["systemInstruction"] {
                requestDict.removeValue(forKey: "systemInstruction")
                if case .object(var requestContent) = requestDict["request"] ?? .null {
                    requestContent["systemInstruction"] = systemInstructionValue
                    requestDict["request"] = .object(requestContent)
                }
            }
            newRequests.append(.object(requestDict))
        }
        requestsWrapper["requests"] = .array(newRequests)
        inputConfig["requests"] = .object(requestsWrapper)
        batch["inputConfig"] = .object(inputConfig)
        body["batch"] = .object(batch)

        body.removeValue(forKey: "config")
        body.removeValue(forKey: "_url")
        body.removeValue(forKey: "_query")

        return (path, body)
    }

    // Helper function to get the first GCS URI
    private func getGcsUri(_ src: BatchJobSourceUnion) -> String? {
        switch src {
        case .string(let s):
            return s.hasPrefix("gs://") ? s : nil
        case .source(let source):
            if let uris = source.gcsUri, !uris.isEmpty {
                return uris[0]
            }
            return nil
        case .inlined:
            return nil
        }
    }

    // Helper function to get the BigQuery URI
    private func getBigqueryUri(_ src: BatchJobSourceUnion) -> String? {
        switch src {
        case .string(let s):
            return s.hasPrefix("bq://") ? s : nil
        case .source(let source):
            return source.bigqueryUri
        case .inlined:
            return nil
        }
    }

    // Function to format the destination configuration for Vertex AI
    private func formatDestination(
        _ src: BatchJobSourceUnion,
        _ config: CreateBatchJobConfig?
    ) -> CreateBatchJobConfig {
        var newConfig = config ?? CreateBatchJobConfig()
        let timestampStr = String(Int(Date().timeIntervalSince1970 * 1000))

        if newConfig.displayName == nil {
            newConfig.displayName = "genaiBatchJob_\(timestampStr)"
        }

        if newConfig.dest == nil {
            let gcsUri = self.getGcsUri(src)
            let bigqueryUri = self.getBigqueryUri(src)

            if let gcsUri = gcsUri {
                if gcsUri.hasSuffix(".jsonl") {
                    newConfig.dest = .string(String(gcsUri.dropLast(6)) + "/dest")
                } else {
                    newConfig.dest = .string("\(gcsUri)_dest_\(timestampStr)")
                }
            } else if let bigqueryUri = bigqueryUri {
                newConfig.dest = .string("\(bigqueryUri)_dest_\(timestampStr)")
            } else {
                // Mirror TS: throw Error. We cannot throw from here without changing signature;
                // Swift port mirrors by setting a sentinel and crashing later. Match TS behavior:
                // throw via fatalError to surface the misconfiguration.
                // Note: TS throws a new Error; mirror with a runtime trap to preserve semantics.
                preconditionFailure(
                    "Unsupported source for Gemini Enterprise Agent Platform (previously known as Vertex AI): No GCS or BigQuery URI found."
                )
            }
        }
        return newConfig
    }

    /// Internal method to create batch job.
    private func createInternal(
        _ params: CreateBatchJobParameters
    ) async throws -> BatchJob {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            var body = createBatchJobParametersToVertex(self.apiClient, params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("batchPredictionJobs", urlMap)
            } else {
                path = try formatMap("batchPredictionJobs", [:])
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
            let resp = batchJobFromVertex(apiResponse)
            return try decodeFromJSONObject(BatchJob.self, resp)
        } else {
            var body = createBatchJobParametersToMldev(self.apiClient, params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("{model}:batchGenerateContent", urlMap)
            } else {
                path = try formatMap("{model}:batchGenerateContent", [:])
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
            let resp = batchJobFromMldev(apiResponse)
            return try decodeFromJSONObject(BatchJob.self, resp)
        }
    }

    /// Internal method to create an embedding batch job.
    private func createEmbeddingsInternal(
        _ params: CreateEmbeddingsBatchJobParameters
    ) async throws -> BatchJob {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            throw ApiError(
                message: "This method is only supported by the Gemini Developer API.",
                status: 400
            )
        } else {
            var body = createEmbeddingsBatchJobParametersToMldev(self.apiClient, params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("{model}:asyncBatchEmbedContent", urlMap)
            } else {
                path = try formatMap("{model}:asyncBatchEmbedContent", [:])
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
            let resp = batchJobFromMldev(apiResponse)
            return try decodeFromJSONObject(BatchJob.self, resp)
        }
    }

    /// Gets batch job configurations.
    public func get(_ params: GetBatchJobParameters) async throws -> BatchJob {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            var body = getBatchJobParametersToVertex(self.apiClient, params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("batchPredictionJobs/{name}", urlMap)
            } else {
                path = try formatMap("batchPredictionJobs/{name}", [:])
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
            let resp = batchJobFromVertex(apiResponse)
            return try decodeFromJSONObject(BatchJob.self, resp)
        } else {
            var body = getBatchJobParametersToMldev(self.apiClient, params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("batches/{name}", urlMap)
            } else {
                path = try formatMap("batches/{name}", [:])
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
            let resp = batchJobFromMldev(apiResponse)
            return try decodeFromJSONObject(BatchJob.self, resp)
        }
    }

    /// Cancels a batch job.
    public func cancel(_ params: CancelBatchJobParameters) async throws {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            var body = cancelBatchJobParametersToVertex(self.apiClient, params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("batchPredictionJobs/{name}:cancel", urlMap)
            } else {
                path = try formatMap("batchPredictionJobs/{name}:cancel", [:])
            }
            queryParams = extractStringMap(body["_query"])
            body.removeValue(forKey: "_url")
            body.removeValue(forKey: "_query")

            let bodyString = jsonValueObjectToString(body)
            _ = try await self.apiClient.request(HttpRequest(
                path: path,
                queryParams: queryParams,
                body: .string(bodyString),
                httpMethod: .POST,
                httpOptions: params.config?.httpOptions,
                abortSignal: params.config?.abortSignal
            ))
        } else {
            var body = cancelBatchJobParametersToMldev(self.apiClient, params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("batches/{name}:cancel", urlMap)
            } else {
                path = try formatMap("batches/{name}:cancel", [:])
            }
            queryParams = extractStringMap(body["_query"])
            body.removeValue(forKey: "_url")
            body.removeValue(forKey: "_query")

            let bodyString = jsonValueObjectToString(body)
            _ = try await self.apiClient.request(HttpRequest(
                path: path,
                queryParams: queryParams,
                body: .string(bodyString),
                httpMethod: .POST,
                httpOptions: params.config?.httpOptions,
                abortSignal: params.config?.abortSignal
            ))
        }
    }

    private func listInternal(
        _ params: ListBatchJobsParameters
    ) async throws -> ListBatchJobsResponse {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            var body = listBatchJobsParametersToVertex(params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("batchPredictionJobs", urlMap)
            } else {
                path = try formatMap("batchPredictionJobs", [:])
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
            let resp = listBatchJobsResponseFromVertex(apiResponse)
            let typed = try decodeFromJSONObject(ListBatchJobsResponse.self, resp)
            typed.sdkHttpResponse = HttpResponse(headers: httpResponse.headers, bodyData: nil)
            return typed
        } else {
            var body = listBatchJobsParametersToMldev(params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("batches", urlMap)
            } else {
                path = try formatMap("batches", [:])
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
            let resp = listBatchJobsResponseFromMldev(apiResponse)
            let typed = try decodeFromJSONObject(ListBatchJobsResponse.self, resp)
            typed.sdkHttpResponse = HttpResponse(headers: httpResponse.headers, bodyData: nil)
            return typed
        }
    }

    /// Deletes a batch job.
    public func delete(
        _ params: DeleteBatchJobParameters
    ) async throws -> DeleteResourceJob {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            var body = deleteBatchJobParametersToVertex(self.apiClient, params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("batchPredictionJobs/{name}", urlMap)
            } else {
                path = try formatMap("batchPredictionJobs/{name}", [:])
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
            let resp = deleteResourceJobFromVertex(apiResponse)
            return try decodeFromJSONObject(DeleteResourceJob.self, resp)
        } else {
            var body = deleteBatchJobParametersToMldev(self.apiClient, params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("batches/{name}", urlMap)
            } else {
                path = try formatMap("batches/{name}", [:])
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
            let resp = deleteResourceJobFromMldev(apiResponse)
            return try decodeFromJSONObject(DeleteResourceJob.self, resp)
        }
    }
}

// MARK: - Helpers

/// Encodes a `[String: JSONValue]` body into a JSON string.
internal func jsonValueObjectToString(_ obj: [String: JSONValue]) -> String {
    guard let data = try? JSONEncoder().encode(JSONValue.object(obj)) else { return "{}" }
    return String(data: data, encoding: .utf8) ?? "{}"
}

/// Extracts a `[String: String]` from a `JSONValue` (treating non-string values as string-coerced or empty).
internal func extractStringMap(_ value: JSONValue?) -> [String: String] {
    guard let value = value, case .object(let obj) = value else { return [:] }
    var out: [String: String] = [:]
    for (k, v) in obj {
        switch v {
        case .string(let s): out[k] = s
        case .int(let i): out[k] = String(i)
        case .double(let d): out[k] = String(d)
        case .bool(let b): out[k] = String(b)
        case .null: continue
        default: continue
        }
    }
    return out
}

/// Decodes a JSON object dictionary into a Codable type.
internal func decodeFromJSONObject<T: Decodable>(_ type: T.Type, _ obj: [String: JSONValue]) throws -> T {
    let data = try JSONEncoder().encode(JSONValue.object(obj))
    return try JSONDecoder().decode(T.self, from: data)
}
