// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Models

/// Models module surfaces `generateContent`, `generateContentStream`,
/// `embedContent`, `countTokens`, `computeTokens`, `get`, `list`, `update`,
/// `delete`, `editImage`, `upscaleImage`, `recontextImage`, `segmentImage`,
/// `generateImages`, and `generateVideos`.
public final class Models: BaseModule, @unchecked Sendable {
    private let apiClient: ApiClient

    public init(apiClient: ApiClient) {
        self.apiClient = apiClient
        super.init()
    }

    // MARK: - embedContent

    /// Calculates embeddings for the given contents.
    public func embedContent(
        _ params: EmbedContentParameters
    ) async throws -> EmbedContentResponse {
        if !apiClient.isVertexAI() {
            var params = params
            let isGeminiEmbedding2Model = params.model.contains("gemini-embedding-2")
            if isGeminiEmbedding2Model {
                // tContents normalizes the contents — re-wrap as ContentListUnion.
                let normalized = try tContents(params.contents)
                params.contents = .contents(normalized)
            }
            let paramsPrivate = EmbedContentParametersPrivate(
                model: params.model,
                contents: params.contents,
                content: nil,
                embeddingApiType: nil,
                config: params.config
            )
            return try await embedContentInternal(paramsPrivate)
        }
        let isVertexEmbedContentModel =
            (params.model.contains("gemini") && params.model != "gemini-embedding-001")
            || params.model.contains("maas")

        if isVertexEmbedContentModel {
            let contents = try tContents(params.contents)
            if contents.count > 1 {
                throw GenAIError.invalidArgument(
                    "The embedContent API for this model only supports one content at a time."
                )
            }
            let paramsPrivate = EmbedContentParametersPrivate(
                model: params.model,
                contents: params.contents,
                content: .content(contents[0]),
                embeddingApiType: .embedContent,
                config: params.config
            )
            return try await embedContentInternal(paramsPrivate)
        } else {
            let paramsPrivate = EmbedContentParametersPrivate(
                model: params.model,
                contents: params.contents,
                content: nil,
                embeddingApiType: .predict,
                config: params.config
            )
            return try await embedContentInternal(paramsPrivate)
        }
    }

    // MARK: - generateContent

    /// Makes an API request to generate content with a given model.
    public func generateContent(
        _ params: GenerateContentParameters
    ) async throws -> GenerateContentResponse {
        var params = params
        let transformedParams = try await processParamsMaybeAddMcpUsage(params)
        maybeMoveToResponseJsonSchem(&params)
        if !hasCallableTools(params) || shouldDisableAfc(params.config) {
            return try await generateContentInternal(transformedParams)
        }

        let incompatibleToolIndexes = findAfcIncompatibleToolIndexes(params)
        if !incompatibleToolIndexes.isEmpty {
            let formattedIndexes = incompatibleToolIndexes
                .map { "tools[\($0)]" }
                .joined(separator: ", ")
            throw GenAIError.invalidArgument(
                "Automatic function calling with CallableTools (or MCP objects) and basic FunctionDeclarations is not yet supported. Incompatible tools found at \(formattedIndexes)."
            )
        }

        var transformedParams2 = transformedParams
        var response: GenerateContentResponse? = nil
        var automaticFunctionCallingHistory: [Content] = try tContents(transformedParams2.contents)
        let maxRemoteCalls =
            transformedParams2.config?.automaticFunctionCalling?.maximumRemoteCalls
            ?? DEFAULT_MAX_REMOTE_CALLS
        var remoteCalls = 0
        while remoteCalls < maxRemoteCalls {
            let r = try await generateContentInternal(transformedParams2)
            response = r
            if r.functionCalls == nil || (r.functionCalls?.isEmpty ?? true) {
                break
            }
            guard let responseContent = r.candidates?.first?.content else { break }
            var functionResponseParts: [Part] = []
            for tool in params.config?.tools ?? [] {
                if isCallableTool(tool) {
                    if case .callable(let callableTool) = tool {
                        let parts = try await callableTool.callTool(functionCalls: r.functionCalls ?? [])
                        functionResponseParts.append(contentsOf: parts)
                    }
                }
            }

            remoteCalls += 1

            let functionResponseContent = Content(
                parts: functionResponseParts,
                role: "user"
            )

            var contents = try tContents(transformedParams2.contents)
            contents.append(responseContent)
            contents.append(functionResponseContent)
            transformedParams2.contents = .contents(contents)

            if shouldAppendAfcHistory(transformedParams2.config) {
                automaticFunctionCallingHistory.append(responseContent)
                automaticFunctionCallingHistory.append(functionResponseContent)
            }
        }
        guard let finalResponse = response else {
            throw GenAIError.runtime("generateContent loop produced no response")
        }
        if shouldAppendAfcHistory(transformedParams2.config) {
            finalResponse.automaticFunctionCallingHistory = automaticFunctionCallingHistory
        }
        return finalResponse
    }

    /// This logic is needed for GenerateContentConfig only. Moves a `responseSchema`
    /// that carries `$schema` to `responseJsonSchema` for backward compatibility.
    private func maybeMoveToResponseJsonSchem(_ params: inout GenerateContentParameters) {
        guard var config = params.config else { return }
        guard case .unknown(let schemaValue) = config.responseSchema ?? .unknown(.null) else {
            // Either no responseSchema or it's a typed Schema — nothing to migrate.
            return
        }
        if config.responseJsonSchema != nil { return }
        if case .object(let obj) = schemaValue, obj["$schema"] != nil {
            config.responseJsonSchema = schemaValue
            config.responseSchema = nil
            params.config = config
        }
    }

    // MARK: - generateContentStream

    /// Makes an API request to generate content with a given model and yields the
    /// response in chunks.
    public func generateContentStream(
        _ params: GenerateContentParameters
    ) async throws -> AsyncThrowingStream<GenerateContentResponse, Error> {
        var params = params
        maybeMoveToResponseJsonSchem(&params)
        if shouldDisableAfc(params.config) {
            let transformedParams = try await processParamsMaybeAddMcpUsage(params)
            return try await generateContentStreamInternal(transformedParams)
        }
        let incompatibleToolIndexes = findAfcIncompatibleToolIndexes(params)
        if !incompatibleToolIndexes.isEmpty {
            let formattedIndexes = incompatibleToolIndexes
                .map { "tools[\($0)]" }
                .joined(separator: ", ")
            throw GenAIError.invalidArgument(
                "Incompatible tools found at \(formattedIndexes). Automatic function calling with CallableTools (or MCP objects) and basic FunctionDeclarations\" is not yet supported."
            )
        }

        let streamFunctionCall =
            params.config?.toolConfig?.functionCallingConfig?.streamFunctionCallArguments
        let disableAfc = params.config?.automaticFunctionCalling?.disable

        if (streamFunctionCall ?? false) && !(disableAfc ?? false) {
            throw GenAIError.invalidArgument(
                "Running in streaming mode with 'streamFunctionCallArguments' enabled, "
                + "this feature is not compatible with automatic function calling (AFC). "
                + "Please set 'config.automaticFunctionCalling.disable' to true to disable AFC "
                + "or leave 'config.toolConfig.functionCallingConfig.streamFunctionCallArguments' "
                + "to be undefined or set to false to disable streaming function call arguments feature."
            )
        }

        return try await processAfcStream(params)
    }

    /// Transforms the CallableTools in the parameters to be simply Tools, copies
    /// the params into a new object and replaces the tools, then sets the MCP
    /// usage header if there are MCP tools present.
    private func processParamsMaybeAddMcpUsage(
        _ params: GenerateContentParameters
    ) async throws -> GenerateContentParameters {
        guard let tools = params.config?.tools else { return params }
        var transformedTools: [ToolUnion] = []
        for tool in tools {
            if case .callable(let callableTool) = tool {
                let resolved = try await callableTool.tool()
                transformedTools.append(.tool(resolved))
            } else {
                transformedTools.append(tool)
            }
        }

        var newConfig = params.config ?? GenerateContentConfig()
        newConfig.tools = transformedTools

        if let originalTools = params.config?.tools, await hasMcpToolUsage(originalTools) {
            let headers = params.config?.httpOptions?.headers ?? [:]
            var newHeaders = headers
            if newHeaders.isEmpty {
                newHeaders = apiClient.getDefaultHeaders()
            }
            setMcpUsageHeader(&newHeaders)
            var httpOptions = params.config?.httpOptions ?? HttpOptions()
            httpOptions.headers = newHeaders
            newConfig.httpOptions = httpOptions
        }

        return GenerateContentParameters(
            model: params.model,
            contents: params.contents,
            config: newConfig
        )
    }

    private func initAfcToolsMap(
        _ params: GenerateContentParameters
    ) async throws -> [String: any CallableTool] {
        var afcTools: [String: any CallableTool] = [:]
        for tool in params.config?.tools ?? [] {
            if case .callable(let callableTool) = tool {
                let toolDeclaration = try await callableTool.tool()
                for declaration in toolDeclaration.functionDeclarations ?? [] {
                    guard let name = declaration.name else {
                        throw GenAIError.invalidArgument("Function declaration name is required.")
                    }
                    if afcTools[name] != nil {
                        throw GenAIError.invalidArgument(
                            "Duplicate tool declaration name: \(name)"
                        )
                    }
                    afcTools[name] = callableTool
                }
            }
        }
        return afcTools
    }

    private func processAfcStream(
        _ params: GenerateContentParameters
    ) async throws -> AsyncThrowingStream<GenerateContentResponse, Error> {
        let maxRemoteCalls =
            params.config?.automaticFunctionCalling?.maximumRemoteCalls
            ?? DEFAULT_MAX_REMOTE_CALLS
        let afcToolsMap = try await initAfcToolsMap(params)
        let initialParams = params

        return AsyncThrowingStream { continuation in
            let task = Task { [weak self] in
                guard let self = self else {
                    continuation.finish()
                    return
                }
                do {
                    var params = initialParams
                    var wereFunctionsCalled = false
                    var remoteCallCount = 0
                    while remoteCallCount < maxRemoteCalls {
                        if wereFunctionsCalled {
                            remoteCallCount += 1
                            wereFunctionsCalled = false
                        }
                        let transformedParams = try await self.processParamsMaybeAddMcpUsage(params)
                        let response = try await self.generateContentStreamInternal(transformedParams)

                        var functionResponses: [Part] = []
                        var responseContents: [Content] = []

                        for try await chunk in response {
                            continuation.yield(chunk)
                            if let content = chunk.candidates?.first?.content {
                                responseContents.append(content)
                                for part in content.parts ?? [] {
                                    if remoteCallCount < maxRemoteCalls, let fc = part.functionCall {
                                        guard let name = fc.name else {
                                            throw GenAIError.runtime(
                                                "Function call name was not returned by the model."
                                            )
                                        }
                                        guard let callable = afcToolsMap[name] else {
                                            let availableTools = afcToolsMap.keys.joined(separator: ", ")
                                            throw GenAIError.runtime(
                                                "Automatic function calling was requested, but not all the tools the model used implement the CallableTool interface. Available tools: \(availableTools), mising tool: \(name)"
                                            )
                                        }
                                        let responseParts = try await callable.callTool(functionCalls: [fc])
                                        functionResponses.append(contentsOf: responseParts)
                                    }
                                }
                            }
                        }

                        if !functionResponses.isEmpty {
                            wereFunctionsCalled = true
                            let typedResponseChunk = GenerateContentResponse()
                            typedResponseChunk.candidates = [
                                Candidate(
                                    content: Content(
                                        parts: functionResponses,
                                        role: "user"
                                    )
                                )
                            ]
                            continuation.yield(typedResponseChunk)

                            var newContents: [Content] = []
                            newContents.append(contentsOf: responseContents)
                            newContents.append(Content(parts: functionResponses, role: "user"))
                            var updatedContents = try tContents(params.contents)
                            updatedContents.append(contentsOf: newContents)
                            params.contents = .contents(updatedContents)
                        } else {
                            break
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - generateImages

    /// Generates an image based on a text description and configuration.
    public func generateImages(
        _ params: GenerateImagesParameters
    ) async throws -> GenerateImagesResponse {
        let apiResponse = try await generateImagesInternal(params)
        var positivePromptSafetyAttributes: SafetyAttributes?
        var generatedImages: [GeneratedImage] = []

        if let images = apiResponse.generatedImages {
            for generatedImage in images {
                if let attrs = generatedImage.safetyAttributes,
                   attrs.contentType == "Positive Prompt" {
                    positivePromptSafetyAttributes = attrs
                } else {
                    generatedImages.append(generatedImage)
                }
            }
        }

        let response: GenerateImagesResponse
        if let positivePromptSafetyAttributes = positivePromptSafetyAttributes {
            response = GenerateImagesResponse(
                sdkHttpResponse: apiResponse.sdkHttpResponse,
                generatedImages: generatedImages,
                positivePromptSafetyAttributes: positivePromptSafetyAttributes
            )
        } else {
            response = GenerateImagesResponse(
                sdkHttpResponse: apiResponse.sdkHttpResponse,
                generatedImages: generatedImages
            )
        }
        return response
    }

    // MARK: - list

    public func list(
        _ params: ListModelsParameters? = nil
    ) async throws -> Pager<Model> {
        var actualConfig = ListModelsConfig(queryBase: true)
        if let provided = params?.config {
            // Shallow-merge user-provided config onto defaults.
            if let httpOptions = provided.httpOptions { actualConfig.httpOptions = httpOptions }
            if let abortSignal = provided.abortSignal { actualConfig.abortSignal = abortSignal }
            if let pageSize = provided.pageSize { actualConfig.pageSize = pageSize }
            if let pageToken = provided.pageToken { actualConfig.pageToken = pageToken }
            if let filter = provided.filter { actualConfig.filter = filter }
            if let queryBase = provided.queryBase { actualConfig.queryBase = queryBase }
        }
        var actualParams = ListModelsParameters(config: actualConfig)

        if apiClient.isVertexAI() {
            if actualParams.config?.queryBase != true {
                if actualParams.config?.filter != nil {
                    throw GenAIError.invalidArgument(
                        "Filtering tuned models list is only supported in Gemini Developer API mode, not in Gemini Enterprise Agent Platform mode."
                    )
                } else {
                    var cfg = actualParams.config ?? ListModelsConfig()
                    cfg.filter = "labels.tune-type:*"
                    actualParams.config = cfg
                }
            }
        }

        let initial = try await listInternal(actualParams)
        let apiClient = self.apiClient
        let request: @Sendable (Any) async throws -> Any = { paramsAny in
            let typedParams: ListModelsParameters
            if let p = paramsAny as? ListModelsParameters {
                typedParams = p
            } else {
                typedParams = ListModelsParameters()
            }
            // Create a local Models instance bound to the same client. (We
            // capture the apiClient rather than `self` to avoid retain cycles.)
            let models = Models(apiClient: apiClient)
            return try await models.listInternal(typedParams)
        }
        return Pager<Model>(
            .models,
            request,
            initial,
            actualParams
        )
    }

    // MARK: - editImage

    /// Edits an image based on a prompt, list of reference images, and configuration.
    public func editImage(
        _ params: EditImageParameters
    ) async throws -> EditImageResponse {
        var paramsInternal = EditImageParametersInternal(
            model: params.model,
            prompt: params.prompt,
            referenceImages: [],
            config: params.config
        )
        paramsInternal.referenceImages = params.referenceImages.map { img in
            switch img {
            case .raw(let v): return v.toReferenceImageAPI()
            case .mask(let v): return v.toReferenceImageAPI()
            case .control(let v): return v.toReferenceImageAPI()
            case .style(let v): return v.toReferenceImageAPI()
            case .subject(let v): return v.toReferenceImageAPI()
            case .content(let v): return v.toReferenceImageAPI()
            }
        }
        return try await editImageInternal(paramsInternal)
    }

    // MARK: - upscaleImage

    /// Upscales an image based on an image, upscale factor, and configuration.
    /// Only supported in Gemini Enterprise Agent Platform currently.
    public func upscaleImage(
        _ params: UpscaleImageParameters
    ) async throws -> UpscaleImageResponse {
        var apiConfig = UpscaleImageAPIConfigInternal(
            numberOfImages: 1,
            mode: "upscale"
        )

        if let userConfig = params.config {
            // Shallow-merge user config onto defaults.
            if let v = userConfig.httpOptions { apiConfig.httpOptions = v }
            if let v = userConfig.abortSignal { apiConfig.abortSignal = v }
            if let v = userConfig.outputGcsUri { apiConfig.outputGcsUri = v }
            if let v = userConfig.safetyFilterLevel { apiConfig.safetyFilterLevel = v }
            if let v = userConfig.personGeneration { apiConfig.personGeneration = v }
            if let v = userConfig.includeRaiReason { apiConfig.includeRaiReason = v }
            if let v = userConfig.outputMimeType { apiConfig.outputMimeType = v }
            if let v = userConfig.outputCompressionQuality { apiConfig.outputCompressionQuality = v }
            if let v = userConfig.enhanceInputImage { apiConfig.enhanceInputImage = v }
            if let v = userConfig.imagePreservationFactor { apiConfig.imagePreservationFactor = v }
            if let v = userConfig.labels { apiConfig.labels = v }
        }

        let apiParams = UpscaleImageAPIParametersInternal(
            model: params.model,
            image: params.image,
            upscaleFactor: params.upscaleFactor,
            config: apiConfig
        )
        return try await upscaleImageInternal(apiParams)
    }

    // MARK: - generateVideos

    /// Generates videos based on a text description and configuration.
    public func generateVideos(
        _ params: GenerateVideosParameters
    ) async throws -> GenerateVideosOperation {
        var params = params
        if (params.prompt != nil || params.image != nil || params.video != nil) && params.source != nil {
            throw GenAIError.invalidArgument(
                "Source and prompt/image/video are mutually exclusive. Please only use source."
            )
        }
        // Gemini API does not support video bytes.
        if !apiClient.isVertexAI() {
            if let v = params.video, v.uri != nil, v.videoBytes != nil {
                params.video = Video(uri: v.uri, videoBytes: nil, mimeType: v.mimeType)
            } else if let sv = params.source?.video, sv.uri != nil, sv.videoBytes != nil {
                var source = params.source
                source?.video = Video(uri: sv.uri, videoBytes: nil, mimeType: sv.mimeType)
                params.source = source
            }
        }
        return try await generateVideosInternal(params)
    }

    // MARK: - generateContentInternal

    private func generateContentInternal(
        _ params: GenerateContentParameters
    ) async throws -> GenerateContentResponse {
        var parentObject: [String: JSONValue] = [:]
        var path = ""
        var queryParams: [String: String] = [:]
        var body: [String: JSONValue]
        let isVertex = apiClient.isVertexAI()
        let paramsDict = try jsonObject(params)
        if isVertex {
            body = try generateContentParametersToVertex(
                apiClient: apiClient,
                fromObject: paramsDict,
                parentObject: &parentObject
            )
        } else {
            body = try generateContentParametersToMldev(
                apiClient: apiClient,
                fromObject: paramsDict,
                parentObject: &parentObject
            )
        }
        let urlMap = extractUrlMap(body["_url"])
        path = try formatMap("{model}:generateContent", urlMap)
        queryParams = extractQueryParams(body["_query"])
        body.removeValue(forKey: "_url")
        body.removeValue(forKey: "_query")

        let bodyData = try JSONEncoder().encode(JSONValue.object(body))
        let bodyString = String(data: bodyData, encoding: .utf8) ?? "{}"
        let httpResponse = try await apiClient.request(HttpRequest(
            path: path,
            queryParams: queryParams,
            body: .string(bodyString),
            httpMethod: .POST,
            httpOptions: params.config?.httpOptions,
            abortSignal: params.config?.abortSignal
        ))
        let jsonResponse = try httpResponse.json()
        guard case .object(let jsonObj) = jsonResponse else {
            throw GenAIError.runtime("Expected object response from generateContent")
        }
        var respParent: [String: JSONValue] = [:]
        let respDict = isVertex
            ? try generateContentResponseFromVertex(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
            : try generateContentResponseFromMldev(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
        let typedResp = try decode(GenerateContentResponse.self, from: respDict)
        typedResp.sdkHttpResponse = HttpResponse(headers: httpResponse.headers)
        return typedResp
    }

    // MARK: - generateContentStreamInternal

    private func generateContentStreamInternal(
        _ params: GenerateContentParameters
    ) async throws -> AsyncThrowingStream<GenerateContentResponse, Error> {
        var parentObject: [String: JSONValue] = [:]
        var path = ""
        var queryParams: [String: String] = [:]
        var body: [String: JSONValue]
        let isVertex = apiClient.isVertexAI()
        let paramsDict = try jsonObject(params)
        if isVertex {
            body = try generateContentParametersToVertex(
                apiClient: apiClient,
                fromObject: paramsDict,
                parentObject: &parentObject
            )
        } else {
            body = try generateContentParametersToMldev(
                apiClient: apiClient,
                fromObject: paramsDict,
                parentObject: &parentObject
            )
        }
        let urlMap = extractUrlMap(body["_url"])
        path = try formatMap("{model}:streamGenerateContent?alt=sse", urlMap)
        queryParams = extractQueryParams(body["_query"])
        body.removeValue(forKey: "_url")
        body.removeValue(forKey: "_query")

        let bodyData = try JSONEncoder().encode(JSONValue.object(body))
        let bodyString = String(data: bodyData, encoding: .utf8) ?? "{}"
        let upstream = try await apiClient.requestStream(HttpRequest(
            path: path,
            queryParams: queryParams,
            body: .string(bodyString),
            httpMethod: .POST,
            httpOptions: params.config?.httpOptions,
            abortSignal: params.config?.abortSignal
        ))

        let apiClient = self.apiClient
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await chunk in upstream {
                        let jsonResp = try chunk.json()
                        guard case .object(let obj) = jsonResp else { continue }
                        var respParent: [String: JSONValue] = [:]
                        let respDict = isVertex
                            ? try generateContentResponseFromVertex(apiClient: apiClient, fromObject: obj, parentObject: &respParent)
                            : try generateContentResponseFromMldev(apiClient: apiClient, fromObject: obj, parentObject: &respParent)
                        let typedResp = try decode(GenerateContentResponse.self, from: respDict)
                        typedResp.sdkHttpResponse = HttpResponse(headers: chunk.headers)
                        continuation.yield(typedResp)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - embedContentInternal

    private func embedContentInternal(
        _ params: EmbedContentParametersPrivate
    ) async throws -> EmbedContentResponse {
        var parentObject: [String: JSONValue] = [:]
        var path = ""
        var queryParams: [String: String] = [:]
        var body: [String: JSONValue]
        let isVertex = apiClient.isVertexAI()
        let paramsDict = try jsonObject(params)
        if isVertex {
            body = try embedContentParametersPrivateToVertex(
                apiClient: apiClient,
                fromObject: paramsDict,
                parentObject: &parentObject
            )
            let endpointUrl = tIsVertexEmbedContentModel(params.model)
                ? "{model}:embedContent"
                : "{model}:predict"
            let urlMap = extractUrlMap(body["_url"])
            path = try formatMap(endpointUrl, urlMap)
        } else {
            body = try embedContentParametersPrivateToMldev(
                apiClient: apiClient,
                fromObject: paramsDict,
                parentObject: &parentObject
            )
            let urlMap = extractUrlMap(body["_url"])
            path = try formatMap("{model}:batchEmbedContents", urlMap)
        }
        queryParams = extractQueryParams(body["_query"])
        body.removeValue(forKey: "_url")
        body.removeValue(forKey: "_query")

        let bodyData = try JSONEncoder().encode(JSONValue.object(body))
        let bodyString = String(data: bodyData, encoding: .utf8) ?? "{}"
        let httpResponse = try await apiClient.request(HttpRequest(
            path: path,
            queryParams: queryParams,
            body: .string(bodyString),
            httpMethod: .POST,
            httpOptions: params.config?.httpOptions,
            abortSignal: params.config?.abortSignal
        ))
        let jsonResponse = try httpResponse.json()
        guard case .object(let jsonObj) = jsonResponse else {
            throw GenAIError.runtime("Expected object response from embedContent")
        }
        var respParent: [String: JSONValue] = [:]
        let respDict = isVertex
            ? try embedContentResponseFromVertex(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
            : try embedContentResponseFromMldev(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
        let typedResp = try decode(EmbedContentResponse.self, from: respDict)
        typedResp.sdkHttpResponse = HttpResponse(headers: httpResponse.headers)
        return typedResp
    }

    // MARK: - generateImagesInternal

    private func generateImagesInternal(
        _ params: GenerateImagesParameters
    ) async throws -> GenerateImagesResponse {
        var parentObject: [String: JSONValue] = [:]
        var path = ""
        var queryParams: [String: String] = [:]
        var body: [String: JSONValue]
        let isVertex = apiClient.isVertexAI()
        let paramsDict = try jsonObject(params)
        if isVertex {
            body = try generateImagesParametersToVertex(
                apiClient: apiClient,
                fromObject: paramsDict,
                parentObject: &parentObject
            )
        } else {
            body = try generateImagesParametersToMldev(
                apiClient: apiClient,
                fromObject: paramsDict,
                parentObject: &parentObject
            )
        }
        let urlMap = extractUrlMap(body["_url"])
        path = try formatMap("{model}:predict", urlMap)
        queryParams = extractQueryParams(body["_query"])
        body.removeValue(forKey: "_url")
        body.removeValue(forKey: "_query")

        let bodyData = try JSONEncoder().encode(JSONValue.object(body))
        let bodyString = String(data: bodyData, encoding: .utf8) ?? "{}"
        let httpResponse = try await apiClient.request(HttpRequest(
            path: path,
            queryParams: queryParams,
            body: .string(bodyString),
            httpMethod: .POST,
            httpOptions: params.config?.httpOptions,
            abortSignal: params.config?.abortSignal
        ))
        let jsonResponse = try httpResponse.json()
        guard case .object(let jsonObj) = jsonResponse else {
            throw GenAIError.runtime("Expected object response from generateImages")
        }
        var respParent: [String: JSONValue] = [:]
        let respDict = isVertex
            ? try generateImagesResponseFromVertex(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
            : try generateImagesResponseFromMldev(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
        let typedResp = try decode(GenerateImagesResponse.self, from: respDict)
        typedResp.sdkHttpResponse = HttpResponse(headers: httpResponse.headers)
        return typedResp
    }

    // MARK: - editImageInternal

    private func editImageInternal(
        _ params: EditImageParametersInternal
    ) async throws -> EditImageResponse {
        guard apiClient.isVertexAI() else {
            throw GenAIError.unsupported(
                "This method is only supported by the Gemini Enterprise Agent Platform (previously known as Vertex AI)."
            )
        }
        var parentObject: [String: JSONValue] = [:]
        let paramsDict = try jsonObject(params)
        var body = try editImageParametersInternalToVertex(
            apiClient: apiClient,
            fromObject: paramsDict,
            parentObject: &parentObject
        )
        let urlMap = extractUrlMap(body["_url"])
        let path = try formatMap("{model}:predict", urlMap)
        let queryParams = extractQueryParams(body["_query"])
        body.removeValue(forKey: "_url")
        body.removeValue(forKey: "_query")

        let bodyData = try JSONEncoder().encode(JSONValue.object(body))
        let bodyString = String(data: bodyData, encoding: .utf8) ?? "{}"
        let httpResponse = try await apiClient.request(HttpRequest(
            path: path,
            queryParams: queryParams,
            body: .string(bodyString),
            httpMethod: .POST,
            httpOptions: params.config?.httpOptions,
            abortSignal: params.config?.abortSignal
        ))
        let jsonResponse = try httpResponse.json()
        guard case .object(let jsonObj) = jsonResponse else {
            throw GenAIError.runtime("Expected object response from editImage")
        }
        var respParent: [String: JSONValue] = [:]
        let respDict = try editImageResponseFromVertex(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
        let typedResp = try decode(EditImageResponse.self, from: respDict)
        typedResp.sdkHttpResponse = HttpResponse(headers: httpResponse.headers)
        return typedResp
    }

    // MARK: - upscaleImageInternal

    private func upscaleImageInternal(
        _ params: UpscaleImageAPIParametersInternal
    ) async throws -> UpscaleImageResponse {
        guard apiClient.isVertexAI() else {
            throw GenAIError.unsupported(
                "This method is only supported by the Gemini Enterprise Agent Platform (previously known as Vertex AI)."
            )
        }
        var parentObject: [String: JSONValue] = [:]
        let paramsDict = try jsonObject(params)
        var body = try upscaleImageAPIParametersInternalToVertex(
            apiClient: apiClient,
            fromObject: paramsDict,
            parentObject: &parentObject
        )
        let urlMap = extractUrlMap(body["_url"])
        let path = try formatMap("{model}:predict", urlMap)
        let queryParams = extractQueryParams(body["_query"])
        body.removeValue(forKey: "_url")
        body.removeValue(forKey: "_query")

        let bodyData = try JSONEncoder().encode(JSONValue.object(body))
        let bodyString = String(data: bodyData, encoding: .utf8) ?? "{}"
        let httpResponse = try await apiClient.request(HttpRequest(
            path: path,
            queryParams: queryParams,
            body: .string(bodyString),
            httpMethod: .POST,
            httpOptions: params.config?.httpOptions,
            abortSignal: params.config?.abortSignal
        ))
        let jsonResponse = try httpResponse.json()
        guard case .object(let jsonObj) = jsonResponse else {
            throw GenAIError.runtime("Expected object response from upscaleImage")
        }
        var respParent: [String: JSONValue] = [:]
        let respDict = try upscaleImageResponseFromVertex(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
        let typedResp = try decode(UpscaleImageResponse.self, from: respDict)
        typedResp.sdkHttpResponse = HttpResponse(headers: httpResponse.headers)
        return typedResp
    }

    // MARK: - recontextImage

    /// Recontextualizes an image.
    public func recontextImage(
        _ params: RecontextImageParameters
    ) async throws -> RecontextImageResponse {
        guard apiClient.isVertexAI() else {
            throw GenAIError.unsupported(
                "This method is only supported by the Gemini Enterprise Agent Platform (previously known as Vertex AI)."
            )
        }
        var parentObject: [String: JSONValue] = [:]
        let paramsDict = try jsonObject(params)
        var body = try recontextImageParametersToVertex(
            apiClient: apiClient,
            fromObject: paramsDict,
            parentObject: &parentObject
        )
        let urlMap = extractUrlMap(body["_url"])
        let path = try formatMap("{model}:predict", urlMap)
        let queryParams = extractQueryParams(body["_query"])
        body.removeValue(forKey: "_url")
        body.removeValue(forKey: "_query")

        let bodyData = try JSONEncoder().encode(JSONValue.object(body))
        let bodyString = String(data: bodyData, encoding: .utf8) ?? "{}"
        let httpResponse = try await apiClient.request(HttpRequest(
            path: path,
            queryParams: queryParams,
            body: .string(bodyString),
            httpMethod: .POST,
            httpOptions: params.config?.httpOptions,
            abortSignal: params.config?.abortSignal
        ))
        let jsonResponse = try httpResponse.json()
        guard case .object(let jsonObj) = jsonResponse else {
            throw GenAIError.runtime("Expected object response from recontextImage")
        }
        var respParent: [String: JSONValue] = [:]
        let respDict = try recontextImageResponseFromVertex(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
        return try decode(RecontextImageResponse.self, from: respDict)
    }

    // MARK: - segmentImage

    /// Segments an image, creating a mask of a specified area.
    public func segmentImage(
        _ params: SegmentImageParameters
    ) async throws -> SegmentImageResponse {
        guard apiClient.isVertexAI() else {
            throw GenAIError.unsupported(
                "This method is only supported by the Gemini Enterprise Agent Platform (previously known as Vertex AI)."
            )
        }
        var parentObject: [String: JSONValue] = [:]
        let paramsDict = try jsonObject(params)
        var body = try segmentImageParametersToVertex(
            apiClient: apiClient,
            fromObject: paramsDict,
            parentObject: &parentObject
        )
        let urlMap = extractUrlMap(body["_url"])
        let path = try formatMap("{model}:predict", urlMap)
        let queryParams = extractQueryParams(body["_query"])
        body.removeValue(forKey: "_url")
        body.removeValue(forKey: "_query")

        let bodyData = try JSONEncoder().encode(JSONValue.object(body))
        let bodyString = String(data: bodyData, encoding: .utf8) ?? "{}"
        let httpResponse = try await apiClient.request(HttpRequest(
            path: path,
            queryParams: queryParams,
            body: .string(bodyString),
            httpMethod: .POST,
            httpOptions: params.config?.httpOptions,
            abortSignal: params.config?.abortSignal
        ))
        let jsonResponse = try httpResponse.json()
        guard case .object(let jsonObj) = jsonResponse else {
            throw GenAIError.runtime("Expected object response from segmentImage")
        }
        var respParent: [String: JSONValue] = [:]
        let respDict = try segmentImageResponseFromVertex(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
        return try decode(SegmentImageResponse.self, from: respDict)
    }

    // MARK: - get

    /// Fetches information about a model by name.
    public func get(_ params: GetModelParameters) async throws -> Model {
        var parentObject: [String: JSONValue] = [:]
        var body: [String: JSONValue]
        let isVertex = apiClient.isVertexAI()
        let paramsDict = try jsonObject(params)
        if isVertex {
            body = try getModelParametersToVertex(
                apiClient: apiClient,
                fromObject: paramsDict,
                parentObject: &parentObject
            )
        } else {
            body = try getModelParametersToMldev(
                apiClient: apiClient,
                fromObject: paramsDict,
                parentObject: &parentObject
            )
        }
        let urlMap = extractUrlMap(body["_url"])
        let path = try formatMap("{name}", urlMap)
        let queryParams = extractQueryParams(body["_query"])
        body.removeValue(forKey: "_url")
        body.removeValue(forKey: "_query")

        let bodyData = try JSONEncoder().encode(JSONValue.object(body))
        let bodyString = String(data: bodyData, encoding: .utf8) ?? "{}"
        let httpResponse = try await apiClient.request(HttpRequest(
            path: path,
            queryParams: queryParams,
            body: .string(bodyString),
            httpMethod: .GET,
            httpOptions: params.config?.httpOptions,
            abortSignal: params.config?.abortSignal
        ))
        let jsonResponse = try httpResponse.json()
        guard case .object(let jsonObj) = jsonResponse else {
            throw GenAIError.runtime("Expected object response from get(model)")
        }
        var respParent: [String: JSONValue] = [:]
        let respDict = isVertex
            ? try modelFromVertex(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
            : try modelFromMldev(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
        return try decode(Model.self, from: respDict)
    }

    // MARK: - listInternal

    private func listInternal(
        _ params: ListModelsParameters
    ) async throws -> ListModelsResponse {
        var parentObject: [String: JSONValue] = [:]
        var body: [String: JSONValue]
        let isVertex = apiClient.isVertexAI()
        let paramsDict = try jsonObject(params)
        if isVertex {
            body = try listModelsParametersToVertex(
                apiClient: apiClient,
                fromObject: paramsDict,
                parentObject: &parentObject
            )
        } else {
            body = try listModelsParametersToMldev(
                apiClient: apiClient,
                fromObject: paramsDict,
                parentObject: &parentObject
            )
        }
        let urlMap = extractUrlMap(body["_url"])
        let path = try formatMap("{models_url}", urlMap)
        let queryParams = extractQueryParams(body["_query"])
        body.removeValue(forKey: "_url")
        body.removeValue(forKey: "_query")

        let bodyData = try JSONEncoder().encode(JSONValue.object(body))
        let bodyString = String(data: bodyData, encoding: .utf8) ?? "{}"
        let httpResponse = try await apiClient.request(HttpRequest(
            path: path,
            queryParams: queryParams,
            body: .string(bodyString),
            httpMethod: .GET,
            httpOptions: params.config?.httpOptions,
            abortSignal: params.config?.abortSignal
        ))
        let jsonResponse = try httpResponse.json()
        guard case .object(let jsonObj) = jsonResponse else {
            throw GenAIError.runtime("Expected object response from list(models)")
        }
        var respParent: [String: JSONValue] = [:]
        let respDict = isVertex
            ? try listModelsResponseFromVertex(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
            : try listModelsResponseFromMldev(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
        let typedResp = try decode(ListModelsResponse.self, from: respDict)
        typedResp.sdkHttpResponse = HttpResponse(headers: httpResponse.headers)
        return typedResp
    }

    // MARK: - update

    /// Updates a tuned model by its name.
    public func update(_ params: UpdateModelParameters) async throws -> Model {
        var parentObject: [String: JSONValue] = [:]
        var body: [String: JSONValue]
        let isVertex = apiClient.isVertexAI()
        let pathTemplate: String
        let paramsDict = try jsonObject(params)
        if isVertex {
            body = try updateModelParametersToVertex(
                apiClient: apiClient,
                fromObject: paramsDict,
                parentObject: &parentObject
            )
            pathTemplate = "{model}"
        } else {
            body = try updateModelParametersToMldev(
                apiClient: apiClient,
                fromObject: paramsDict,
                parentObject: &parentObject
            )
            pathTemplate = "{name}"
        }
        let urlMap = extractUrlMap(body["_url"])
        let path = try formatMap(pathTemplate, urlMap)
        let queryParams = extractQueryParams(body["_query"])
        body.removeValue(forKey: "_url")
        body.removeValue(forKey: "_query")

        let bodyData = try JSONEncoder().encode(JSONValue.object(body))
        let bodyString = String(data: bodyData, encoding: .utf8) ?? "{}"
        let httpResponse = try await apiClient.request(HttpRequest(
            path: path,
            queryParams: queryParams,
            body: .string(bodyString),
            httpMethod: .PATCH,
            httpOptions: params.config?.httpOptions,
            abortSignal: params.config?.abortSignal
        ))
        let jsonResponse = try httpResponse.json()
        guard case .object(let jsonObj) = jsonResponse else {
            throw GenAIError.runtime("Expected object response from update(model)")
        }
        var respParent: [String: JSONValue] = [:]
        let respDict = isVertex
            ? try modelFromVertex(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
            : try modelFromMldev(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
        return try decode(Model.self, from: respDict)
    }

    // MARK: - delete

    /// Deletes a tuned model by its name.
    public func delete(
        _ params: DeleteModelParameters
    ) async throws -> DeleteModelResponse {
        var parentObject: [String: JSONValue] = [:]
        var body: [String: JSONValue]
        let isVertex = apiClient.isVertexAI()
        let paramsDict = try jsonObject(params)
        if isVertex {
            body = try deleteModelParametersToVertex(
                apiClient: apiClient,
                fromObject: paramsDict,
                parentObject: &parentObject
            )
        } else {
            body = try deleteModelParametersToMldev(
                apiClient: apiClient,
                fromObject: paramsDict,
                parentObject: &parentObject
            )
        }
        let urlMap = extractUrlMap(body["_url"])
        let path = try formatMap("{name}", urlMap)
        let queryParams = extractQueryParams(body["_query"])
        body.removeValue(forKey: "_url")
        body.removeValue(forKey: "_query")

        let bodyData = try JSONEncoder().encode(JSONValue.object(body))
        let bodyString = String(data: bodyData, encoding: .utf8) ?? "{}"
        let httpResponse = try await apiClient.request(HttpRequest(
            path: path,
            queryParams: queryParams,
            body: .string(bodyString),
            httpMethod: .DELETE,
            httpOptions: params.config?.httpOptions,
            abortSignal: params.config?.abortSignal
        ))
        let jsonResponse = try httpResponse.json()
        guard case .object(let jsonObj) = jsonResponse else {
            throw GenAIError.runtime("Expected object response from delete(model)")
        }
        var respParent: [String: JSONValue] = [:]
        let respDict = isVertex
            ? try deleteModelResponseFromVertex(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
            : try deleteModelResponseFromMldev(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
        let typedResp = try decode(DeleteModelResponse.self, from: respDict)
        typedResp.sdkHttpResponse = HttpResponse(headers: httpResponse.headers)
        return typedResp
    }

    // MARK: - countTokens

    /// Counts the number of tokens in the given contents.
    public func countTokens(
        _ params: CountTokensParameters
    ) async throws -> CountTokensResponse {
        var parentObject: [String: JSONValue] = [:]
        var body: [String: JSONValue]
        let isVertex = apiClient.isVertexAI()
        let paramsDict = try jsonObject(params)
        if isVertex {
            body = try countTokensParametersToVertex(
                apiClient: apiClient,
                fromObject: paramsDict,
                parentObject: &parentObject
            )
        } else {
            body = try countTokensParametersToMldev(
                apiClient: apiClient,
                fromObject: paramsDict,
                parentObject: &parentObject
            )
        }
        let urlMap = extractUrlMap(body["_url"])
        let path = try formatMap("{model}:countTokens", urlMap)
        let queryParams = extractQueryParams(body["_query"])
        body.removeValue(forKey: "_url")
        body.removeValue(forKey: "_query")

        let bodyData = try JSONEncoder().encode(JSONValue.object(body))
        let bodyString = String(data: bodyData, encoding: .utf8) ?? "{}"
        let httpResponse = try await apiClient.request(HttpRequest(
            path: path,
            queryParams: queryParams,
            body: .string(bodyString),
            httpMethod: .POST,
            httpOptions: params.config?.httpOptions,
            abortSignal: params.config?.abortSignal
        ))
        let jsonResponse = try httpResponse.json()
        guard case .object(let jsonObj) = jsonResponse else {
            throw GenAIError.runtime("Expected object response from countTokens")
        }
        var respParent: [String: JSONValue] = [:]
        let respDict = isVertex
            ? try countTokensResponseFromVertex(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
            : try countTokensResponseFromMldev(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
        let typedResp = try decode(CountTokensResponse.self, from: respDict)
        typedResp.sdkHttpResponse = HttpResponse(headers: httpResponse.headers)
        return typedResp
    }

    // MARK: - computeTokens

    /// Given a list of contents, returns a corresponding TokensInfo. Vertex-only.
    public func computeTokens(
        _ params: ComputeTokensParameters
    ) async throws -> ComputeTokensResponse {
        guard apiClient.isVertexAI() else {
            throw GenAIError.unsupported(
                "This method is only supported by the Gemini Enterprise Agent Platform (previously known as Vertex AI)."
            )
        }
        var parentObject: [String: JSONValue] = [:]
        let paramsDict = try jsonObject(params)
        var body = try computeTokensParametersToVertex(
            apiClient: apiClient,
            fromObject: paramsDict,
            parentObject: &parentObject
        )
        let urlMap = extractUrlMap(body["_url"])
        let path = try formatMap("{model}:computeTokens", urlMap)
        let queryParams = extractQueryParams(body["_query"])
        body.removeValue(forKey: "_url")
        body.removeValue(forKey: "_query")

        let bodyData = try JSONEncoder().encode(JSONValue.object(body))
        let bodyString = String(data: bodyData, encoding: .utf8) ?? "{}"
        let httpResponse = try await apiClient.request(HttpRequest(
            path: path,
            queryParams: queryParams,
            body: .string(bodyString),
            httpMethod: .POST,
            httpOptions: params.config?.httpOptions,
            abortSignal: params.config?.abortSignal
        ))
        let jsonResponse = try httpResponse.json()
        guard case .object(let jsonObj) = jsonResponse else {
            throw GenAIError.runtime("Expected object response from computeTokens")
        }
        var respParent: [String: JSONValue] = [:]
        let respDict = try computeTokensResponseFromVertex(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
        let typedResp = try decode(ComputeTokensResponse.self, from: respDict)
        typedResp.sdkHttpResponse = HttpResponse(headers: httpResponse.headers)
        return typedResp
    }

    // MARK: - generateVideosInternal

    private func generateVideosInternal(
        _ params: GenerateVideosParameters
    ) async throws -> GenerateVideosOperation {
        var parentObject: [String: JSONValue] = [:]
        var body: [String: JSONValue]
        let isVertex = apiClient.isVertexAI()
        let paramsDict = try jsonObject(params)
        if isVertex {
            body = try generateVideosParametersToVertex(
                apiClient: apiClient,
                fromObject: paramsDict,
                parentObject: &parentObject
            )
        } else {
            body = try generateVideosParametersToMldev(
                apiClient: apiClient,
                fromObject: paramsDict,
                parentObject: &parentObject
            )
        }
        let urlMap = extractUrlMap(body["_url"])
        let path = try formatMap("{model}:predictLongRunning", urlMap)
        let queryParams = extractQueryParams(body["_query"])
        body.removeValue(forKey: "_url")
        body.removeValue(forKey: "_query")

        let bodyData = try JSONEncoder().encode(JSONValue.object(body))
        let bodyString = String(data: bodyData, encoding: .utf8) ?? "{}"
        let httpResponse = try await apiClient.request(HttpRequest(
            path: path,
            queryParams: queryParams,
            body: .string(bodyString),
            httpMethod: .POST,
            httpOptions: params.config?.httpOptions,
            abortSignal: params.config?.abortSignal
        ))
        let jsonResponse = try httpResponse.json()
        guard case .object(let jsonObj) = jsonResponse else {
            throw GenAIError.runtime("Expected object response from generateVideos")
        }
        var respParent: [String: JSONValue] = paramsDict
        let respDict = try (isVertex
            ? generateVideosOperationFromVertex(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent)
            : generateVideosOperationFromMldev(apiClient: apiClient, fromObject: jsonObj, parentObject: &respParent))
        return try decode(GenerateVideosOperation.self, from: respDict)
    }
}

// MARK: - Internal helpers

/// Decodes a `[String: JSONValue]` dict into a `Codable` Swift type by
/// re-encoding through JSON. Mirrors `Object.assign(typedResp, resp)` in TS.
private func decode<T: Decodable>(_ type: T.Type, from dict: [String: JSONValue]) throws -> T {
    let data = try JSONEncoder().encode(JSONValue.object(dict))
    return try JSONDecoder().decode(T.self, from: data)
}

/// Extracts the `_url` placeholder map produced by converters.
private func extractUrlMap(_ value: JSONValue?) -> [String: JSONValue] {
    if let v = value, case .object(let obj) = v { return obj }
    return [:]
}

/// Extracts the `_query` string map produced by converters.
private func extractQueryParams(_ value: JSONValue?) -> [String: String] {
    guard let v = value, case .object(let obj) = v else { return [:] }
    var out: [String: String] = [:]
    for (k, vv) in obj {
        switch vv {
        case .string(let s): out[k] = s
        case .int(let i): out[k] = String(i)
        case .double(let d): out[k] = String(d)
        case .bool(let b): out[k] = b ? "true" : "false"
        default: break
        }
    }
    return out
}

// MARK: - JS-style convenience overloads
//
// Mirrors the JavaScript SDK's `ai.models.generateContent({ model, contents })`
// call shape so Swift call sites can omit the explicit parameter struct.

extension Models {
    public func generateContent(
        model: String,
        contents: String,
        config: GenerateContentConfig? = nil
    ) async throws -> GenerateContentResponse {
        try await generateContent(GenerateContentParameters(
            model: model,
            contents: .part(.text(contents)),
            config: config
        ))
    }

    public func generateContent(
        model: String,
        contents: [Content],
        config: GenerateContentConfig? = nil
    ) async throws -> GenerateContentResponse {
        try await generateContent(GenerateContentParameters(
            model: model,
            contents: .contents(contents),
            config: config
        ))
    }

    public func generateContent(
        model: String,
        contents: Content,
        config: GenerateContentConfig? = nil
    ) async throws -> GenerateContentResponse {
        try await generateContent(GenerateContentParameters(
            model: model,
            contents: .content(contents),
            config: config
        ))
    }

    public func generateContentStream(
        model: String,
        contents: String,
        config: GenerateContentConfig? = nil
    ) async throws -> AsyncThrowingStream<GenerateContentResponse, Error> {
        try await generateContentStream(GenerateContentParameters(
            model: model,
            contents: .part(.text(contents)),
            config: config
        ))
    }

    public func generateContentStream(
        model: String,
        contents: [Content],
        config: GenerateContentConfig? = nil
    ) async throws -> AsyncThrowingStream<GenerateContentResponse, Error> {
        try await generateContentStream(GenerateContentParameters(
            model: model,
            contents: .contents(contents),
            config: config
        ))
    }

    public func generateContentStream(
        model: String,
        contents: Content,
        config: GenerateContentConfig? = nil
    ) async throws -> AsyncThrowingStream<GenerateContentResponse, Error> {
        try await generateContentStream(GenerateContentParameters(
            model: model,
            contents: .content(contents),
            config: config
        ))
    }

    public func embedContent(
        model: String,
        contents: String,
        config: EmbedContentConfig? = nil
    ) async throws -> EmbedContentResponse {
        try await embedContent(EmbedContentParameters(
            model: model,
            contents: .part(.text(contents)),
            config: config
        ))
    }

    public func embedContent(
        model: String,
        contents: [String],
        config: EmbedContentConfig? = nil
    ) async throws -> EmbedContentResponse {
        let parts: [PartUnion] = contents.map { .text($0) }
        return try await embedContent(EmbedContentParameters(
            model: model,
            contents: .parts(parts),
            config: config
        ))
    }

    public func countTokens(
        model: String,
        contents: String,
        config: CountTokensConfig? = nil
    ) async throws -> CountTokensResponse {
        try await countTokens(CountTokensParameters(
            model: model,
            contents: .part(.text(contents)),
            config: config
        ))
    }

    public func computeTokens(
        model: String,
        contents: String,
        config: ComputeTokensConfig? = nil
    ) async throws -> ComputeTokensResponse {
        try await computeTokens(ComputeTokensParameters(
            model: model,
            contents: .part(.text(contents)),
            config: config
        ))
    }

    public func generateImages(
        model: String,
        prompt: String,
        config: GenerateImagesConfig? = nil
    ) async throws -> GenerateImagesResponse {
        try await generateImages(GenerateImagesParameters(
            model: model,
            prompt: prompt,
            config: config
        ))
    }
}
