// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

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
                let paramsPrivate = CreateTuningJobParametersPrivate(
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
        let paramsDict = try jsonObject(params)
        if self.apiClient.isVertexAI() {
            var parent: [String: JSONValue] = [:]
            var body = try getTuningJobParametersToVertex(
                apiClient: self.apiClient,
                fromObject: paramsDict,
                parentObject: &parent
            )
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
            let apiDict = jsonValueAsDict(apiResponse)
            var respParent: [String: JSONValue] = [:]
            let resp = try tuningJobFromVertex(
                apiClient: self.apiClient,
                fromObject: apiDict,
                parentObject: &respParent
            )
            var typedResp: TuningJob = try decodeFromJSONObject(TuningJob.self, resp)
            typedResp.sdkHttpResponse = HttpResponse(headers: httpResponse.headers)
            return typedResp
        } else {
            var parent: [String: JSONValue] = [:]
            var body = try getTuningJobParametersToMldev(
                apiClient: self.apiClient,
                fromObject: paramsDict,
                parentObject: &parent
            )
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
            let apiDict = jsonValueAsDict(apiResponse)
            var respParent: [String: JSONValue] = [:]
            let resp = try tuningJobFromMldev(
                apiClient: self.apiClient,
                fromObject: apiDict,
                parentObject: &respParent
            )
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
            let paramsDict = try jsonObject(params)
            var parent: [String: JSONValue] = [:]
            var body = try listTuningJobsParametersToVertex(
                apiClient: self.apiClient,
                fromObject: paramsDict,
                parentObject: &parent
            )
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
            let apiDict = jsonValueAsDict(apiResponse)
            var respParent: [String: JSONValue] = [:]
            let resp = try listTuningJobsResponseFromVertex(
                apiClient: self.apiClient,
                fromObject: apiDict,
                parentObject: &respParent
            )
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
        let paramsDict = try jsonObject(params)
        if self.apiClient.isVertexAI() {
            var parent: [String: JSONValue] = [:]
            var body = try cancelTuningJobParametersToVertex(
                apiClient: self.apiClient,
                fromObject: paramsDict,
                parentObject: &parent
            )
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
            let apiDict = jsonValueAsDict(apiResponse)
            var respParent: [String: JSONValue] = [:]
            let resp = try cancelTuningJobResponseFromVertex(
                apiClient: self.apiClient,
                fromObject: apiDict,
                parentObject: &respParent
            )
            let typedResp = try decodeFromJSONObject(CancelTuningJobResponse.self, resp)
            typedResp.sdkHttpResponse = HttpResponse(headers: httpResponse.headers)
            return typedResp
        } else {
            var parent: [String: JSONValue] = [:]
            var body = try cancelTuningJobParametersToMldev(
                apiClient: self.apiClient,
                fromObject: paramsDict,
                parentObject: &parent
            )
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
            let apiDict = jsonValueAsDict(apiResponse)
            var respParent: [String: JSONValue] = [:]
            let resp = try cancelTuningJobResponseFromMldev(
                apiClient: self.apiClient,
                fromObject: apiDict,
                parentObject: &respParent
            )
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
            let paramsDict = try jsonObject(params)
            var parent: [String: JSONValue] = [:]
            var body = try createTuningJobParametersPrivateToVertex(
                apiClient: self.apiClient,
                fromObject: paramsDict,
                parentObject: &parent
            )
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
            let apiDict = jsonValueAsDict(apiResponse)
            var respParent: [String: JSONValue] = [:]
            let resp = try tuningJobFromVertex(
                apiClient: self.apiClient,
                fromObject: apiDict,
                parentObject: &respParent
            )
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
            let paramsDict = try jsonObject(params)
            var parent: [String: JSONValue] = [:]
            var body = try createTuningJobParametersPrivateToMldev(
                apiClient: self.apiClient,
                fromObject: paramsDict,
                parentObject: &parent
            )
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
            let apiDict = jsonValueAsDict(apiResponse)
            var respParent: [String: JSONValue] = [:]
            let resp = try tuningOperationFromMldev(
                apiClient: self.apiClient,
                fromObject: apiDict,
                parentObject: &respParent
            )
            var typedResp: TuningOperation = try decodeFromJSONObject(TuningOperation.self, resp)
            typedResp.sdkHttpResponse = HttpResponse(headers: httpResponse.headers)
            return typedResp
        }
    }
}
