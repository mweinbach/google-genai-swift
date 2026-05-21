// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Converter stubs (Wave 5)

// TODO Wave 5: Port from ./converters/_tunings_converters.js
internal func getTuningJobParametersToVertex(
    _ fromObject: GetTuningJobParameters,
    _ parentObject: GetTuningJobParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (getTuningJobParametersToVertex)")
}

// TODO Wave 5: Port from ./converters/_tunings_converters.js
internal func getTuningJobParametersToMldev(
    _ fromObject: GetTuningJobParameters,
    _ parentObject: GetTuningJobParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (getTuningJobParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_tunings_converters.js
internal func tuningJobFromVertex(
    _ fromObject: JSONValue,
    _ parentObject: GetTuningJobParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (tuningJobFromVertex)")
}

// TODO Wave 5: Port from ./converters/_tunings_converters.js
internal func tuningJobFromMldev(
    _ fromObject: JSONValue,
    _ parentObject: GetTuningJobParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (tuningJobFromMldev)")
}

// TODO Wave 5: Port from ./converters/_tunings_converters.js
internal func tuningJobFromVertex(
    _ fromObject: JSONValue,
    _ parentObject: CreateTuningJobParametersPrivate
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (tuningJobFromVertex)")
}

// TODO Wave 5: Port from ./converters/_tunings_converters.js
internal func listTuningJobsParametersToVertex(
    _ fromObject: ListTuningJobsParameters,
    _ parentObject: ListTuningJobsParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (listTuningJobsParametersToVertex)")
}

// TODO Wave 5: Port from ./converters/_tunings_converters.js
internal func listTuningJobsResponseFromVertex(
    _ fromObject: JSONValue,
    _ parentObject: ListTuningJobsParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (listTuningJobsResponseFromVertex)")
}

// TODO Wave 5: Port from ./converters/_tunings_converters.js
internal func cancelTuningJobParametersToVertex(
    _ fromObject: CancelTuningJobParameters,
    _ parentObject: CancelTuningJobParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (cancelTuningJobParametersToVertex)")
}

// TODO Wave 5: Port from ./converters/_tunings_converters.js
internal func cancelTuningJobParametersToMldev(
    _ fromObject: CancelTuningJobParameters,
    _ parentObject: CancelTuningJobParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (cancelTuningJobParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_tunings_converters.js
internal func cancelTuningJobResponseFromVertex(
    _ fromObject: JSONValue,
    _ parentObject: CancelTuningJobParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (cancelTuningJobResponseFromVertex)")
}

// TODO Wave 5: Port from ./converters/_tunings_converters.js
internal func cancelTuningJobResponseFromMldev(
    _ fromObject: JSONValue,
    _ parentObject: CancelTuningJobParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (cancelTuningJobResponseFromMldev)")
}

// TODO Wave 5: Port from ./converters/_tunings_converters.js
internal func createTuningJobParametersPrivateToVertex(
    _ fromObject: CreateTuningJobParametersPrivate,
    _ parentObject: CreateTuningJobParametersPrivate
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (createTuningJobParametersPrivateToVertex)")
}

// TODO Wave 5: Port from ./converters/_tunings_converters.js
internal func createTuningJobParametersPrivateToMldev(
    _ fromObject: CreateTuningJobParametersPrivate,
    _ parentObject: CreateTuningJobParametersPrivate
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (createTuningJobParametersPrivateToMldev)")
}

// TODO Wave 5: Port from ./converters/_tunings_converters.js
internal func tuningOperationFromMldev(
    _ fromObject: JSONValue,
    _ parentObject: CreateTuningJobParametersPrivate
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (tuningOperationFromMldev)")
}

// MARK: - Tunings

public final class Tunings: BaseModule, @unchecked Sendable {
    private let apiClient: ApiClient

    public init(apiClient: ApiClient) {
        self.apiClient = apiClient
        super.init()
    }

    /// Lists tuning jobs.
    public func list(
        _ params: ListTuningJobsParameters = ListTuningJobsParameters()
    ) async throws -> Pager<TuningJob> {
        let initial = try await self.listInternal(params)
        return Pager<TuningJob>(
            PagedItem.tuningJobs,
            { x in
                guard let p = x as? ListTuningJobsParameters else {
                    throw GenAIError.invalidArgument("Expected ListTuningJobsParameters")
                }
                return try await self.listInternal(p)
            },
            initial,
            params
        )
    }

    /// Gets a TuningJob.
    public func get(
        _ params: GetTuningJobParameters
    ) async throws -> TuningJob {
        return try await self.getInternal(params)
    }

    /// Creates a supervised fine-tuning job.
    public func tune(
        _ params: CreateTuningJobParameters
    ) async throws -> TuningJob {
        if self.apiClient.isVertexAI() {
            if params.baseModel.hasPrefix("projects/") {
                var preTunedModel = PreTunedModel()
                preTunedModel.tunedModelName = params.baseModel
                if let checkpointId = params.config?.preTunedModelCheckpointId {
                    preTunedModel.checkpointId = checkpointId
                }
                var paramsPrivate = CreateTuningJobParametersPrivate(
                    trainingDataset: params.trainingDataset
                )
                paramsPrivate.preTunedModel = preTunedModel
                paramsPrivate.config = params.config
                paramsPrivate.baseModel = nil
                return try await self.tuneInternal(paramsPrivate)
            } else {
                var paramsPrivate = CreateTuningJobParametersPrivate(
                    baseModel: params.baseModel,
                    trainingDataset: params.trainingDataset,
                    config: params.config
                )
                return try await self.tuneInternal(paramsPrivate)
            }
        } else {
            let paramsPrivate = CreateTuningJobParametersPrivate(
                baseModel: params.baseModel,
                trainingDataset: params.trainingDataset,
                config: params.config
            )
            let operation = try await self.tuneMldevInternal(paramsPrivate)
            var tunedModelName = ""
            if let metadata = operation.metadata,
               case .string(let s) = metadata["tunedModel"] ?? .null {
                tunedModelName = s
            } else if let name = operation.name, name.contains("/operations/") {
                tunedModelName = name.components(separatedBy: "/operations/").first ?? ""
            }
            var tuningJob = TuningJob()
            tuningJob.name = tunedModelName
            tuningJob.state = JobState.jobStateQueued
            return tuningJob
        }
    }

    private func getInternal(
        _ params: GetTuningJobParameters
    ) async throws -> TuningJob {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            var body = getTuningJobParametersToVertex(params, params)
            guard case .object(let urlMap) = body["_url"] ?? .null else {
                throw GenAIError.runtime("Missing _url in body.")
            }
            path = try formatMap("{name}", urlMap)
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
            let resp = tuningJobFromVertex(apiResponse, params)
            var typedResp: TuningJob = try decodeFromJSONObject(TuningJob.self, resp)
            typedResp.sdkHttpResponse = HttpResponse(headers: httpResponse.headers)
            return typedResp
        } else {
            var body = getTuningJobParametersToMldev(params, params)
            guard case .object(let urlMap) = body["_url"] ?? .null else {
                throw GenAIError.runtime("Missing _url in body.")
            }
            path = try formatMap("{name}", urlMap)
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
            let resp = tuningJobFromMldev(apiResponse, params)
            var typedResp: TuningJob = try decodeFromJSONObject(TuningJob.self, resp)
            typedResp.sdkHttpResponse = HttpResponse(headers: httpResponse.headers)
            return typedResp
        }
    }

    private func listInternal(
        _ params: ListTuningJobsParameters
    ) async throws -> ListTuningJobsResponse {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            var body = listTuningJobsParametersToVertex(params, params)
            guard case .object(let urlMap) = body["_url"] ?? .null else {
                throw GenAIError.runtime("Missing _url in body.")
            }
            path = try formatMap("tuningJobs", urlMap)
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
            let resp = listTuningJobsResponseFromVertex(apiResponse, params)
            let typedResp = try decodeFromJSONObject(ListTuningJobsResponse.self, resp)
            typedResp.sdkHttpResponse = HttpResponse(headers: httpResponse.headers)
            return typedResp
        } else {
            throw GenAIError.unsupported(
                "This method is only supported by the Gemini Enterprise Agent Platform (previously known as Vertex AI)."
            )
        }
    }

    /// Cancels a tuning job.
    public func cancel(
        _ params: CancelTuningJobParameters
    ) async throws -> CancelTuningJobResponse {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            var body = cancelTuningJobParametersToVertex(params, params)
            guard case .object(let urlMap) = body["_url"] ?? .null else {
                throw GenAIError.runtime("Missing _url in body.")
            }
            path = try formatMap("{name}:cancel", urlMap)
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
            let resp = cancelTuningJobResponseFromVertex(apiResponse, params)
            let typedResp = try decodeFromJSONObject(CancelTuningJobResponse.self, resp)
            typedResp.sdkHttpResponse = HttpResponse(headers: httpResponse.headers)
            return typedResp
        } else {
            var body = cancelTuningJobParametersToMldev(params, params)
            guard case .object(let urlMap) = body["_url"] ?? .null else {
                throw GenAIError.runtime("Missing _url in body.")
            }
            path = try formatMap("{name}:cancel", urlMap)
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
            let resp = cancelTuningJobResponseFromMldev(apiResponse, params)
            let typedResp = try decodeFromJSONObject(CancelTuningJobResponse.self, resp)
            typedResp.sdkHttpResponse = HttpResponse(headers: httpResponse.headers)
            return typedResp
        }
    }

    private func tuneInternal(
        _ params: CreateTuningJobParametersPrivate
    ) async throws -> TuningJob {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            var body = createTuningJobParametersPrivateToVertex(params, params)
            guard case .object(let urlMap) = body["_url"] ?? .null else {
                throw GenAIError.runtime("Missing _url in body.")
            }
            path = try formatMap("tuningJobs", urlMap)
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
            let resp = tuningJobFromVertex(apiResponse, params)
            var typedResp: TuningJob = try decodeFromJSONObject(TuningJob.self, resp)
            typedResp.sdkHttpResponse = HttpResponse(headers: httpResponse.headers)
            return typedResp
        } else {
            throw GenAIError.unsupported(
                "This method is only supported by the Gemini Enterprise Agent Platform (previously known as Vertex AI)."
            )
        }
    }

    private func tuneMldevInternal(
        _ params: CreateTuningJobParametersPrivate
    ) async throws -> TuningOperation {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            throw GenAIError.unsupported(
                "This method is only supported by the Gemini Developer API."
            )
        } else {
            var body = createTuningJobParametersPrivateToMldev(params, params)
            guard case .object(let urlMap) = body["_url"] ?? .null else {
                throw GenAIError.runtime("Missing _url in body.")
            }
            path = try formatMap("tunedModels", urlMap)
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
            let resp = tuningOperationFromMldev(apiResponse, params)
            var typedResp: TuningOperation = try decodeFromJSONObject(TuningOperation.self, resp)
            typedResp.sdkHttpResponse = HttpResponse(headers: httpResponse.headers)
            return typedResp
        }
    }
}
