// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// HTTP retry options to be used in each of the requests.
public struct HttpRetryOptions: Codable, Sendable {
    public var attempts: Int?
    public init(attempts: Int? = nil) {
        self.attempts = attempts
    }
}

/// HTTP options to be used in each of the requests.
public struct HttpOptions: Codable, Sendable {
    public var baseUrl: String?
    public var baseUrlResourceScope: ResourceScope?
    public var apiVersion: String?
    public var headers: [String: String]?
    public var timeout: Double?
    public var extraBody: [String: JSONValue]?
    public var retryOptions: HttpRetryOptions?
    public init(
        baseUrl: String? = nil,
        baseUrlResourceScope: ResourceScope? = nil,
        apiVersion: String? = nil,
        headers: [String: String]? = nil,
        timeout: Double? = nil,
        extraBody: [String: JSONValue]? = nil,
        retryOptions: HttpRetryOptions? = nil
    ) {
        self.baseUrl = baseUrl
        self.baseUrlResourceScope = baseUrlResourceScope
        self.apiVersion = apiVersion
        self.headers = headers
        self.timeout = timeout
        self.extraBody = extraBody
        self.retryOptions = retryOptions
    }
}

/// Schema is used to define the format of input/output data.
public struct Schema: Codable, Sendable {
    public var anyOf: [Schema]?
    public var `default`: JSONValue?
    public var description: String?
    public var `enum`: [String]?
    public var example: JSONValue?
    public var format: String?
    /// Recursive sub-schema (`items` per TS) — boxed via a class to break value-type recursion.
    public var items: SchemaRef?
    public var maxItems: String?
    public var maxLength: String?
    public var maxProperties: String?
    public var maximum: Double?
    public var minItems: String?
    public var minLength: String?
    public var minProperties: String?
    public var minimum: Double?
    public var nullable: Bool?
    public var pattern: String?
    public var properties: [String: Schema]?
    public var propertyOrdering: [String]?
    public var required: [String]?
    public var title: String?
    public var type: `Type`?
    public init(
        anyOf: [Schema]? = nil,
        `default`: JSONValue? = nil,
        description: String? = nil,
        `enum`: [String]? = nil,
        example: JSONValue? = nil,
        format: String? = nil,
        items: SchemaRef? = nil,
        maxItems: String? = nil,
        maxLength: String? = nil,
        maxProperties: String? = nil,
        maximum: Double? = nil,
        minItems: String? = nil,
        minLength: String? = nil,
        minProperties: String? = nil,
        minimum: Double? = nil,
        nullable: Bool? = nil,
        pattern: String? = nil,
        properties: [String: Schema]? = nil,
        propertyOrdering: [String]? = nil,
        required: [String]? = nil,
        title: String? = nil,
        type: `Type`? = nil
    ) {
        self.anyOf = anyOf
        self.default = `default`
        self.description = description
        self.enum = `enum`
        self.example = example
        self.format = format
        self.items = items
        self.maxItems = maxItems
        self.maxLength = maxLength
        self.maxProperties = maxProperties
        self.maximum = maximum
        self.minItems = minItems
        self.minLength = minLength
        self.minProperties = minProperties
        self.minimum = minimum
        self.nullable = nullable
        self.pattern = pattern
        self.properties = properties
        self.propertyOrdering = propertyOrdering
        self.required = required
        self.title = title
        self.type = type
    }
}

/// Class-based indirection wrapper so `Schema` can reference itself for `items`.
public final class SchemaRef: Codable, @unchecked Sendable {
    public var value: Schema
    public init(_ value: Schema) { self.value = value }
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        self.value = try c.decode(Schema.self)
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(value)
    }
}

/// Config for model selection.
public struct ModelSelectionConfig: Codable, Sendable {
    public var featureSelectionPreference: FeatureSelectionPreference?
    public init(featureSelectionPreference: FeatureSelectionPreference? = nil) {
        self.featureSelectionPreference = featureSelectionPreference
    }
}

/// Tool to support computer use.
public struct ComputerUse: Codable, Sendable {
    public var environment: Environment?
    public var excludedPredefinedFunctions: [String]?
    public var enablePromptInjectionDetection: Bool?
    public init(environment: Environment? = nil, excludedPredefinedFunctions: [String]? = nil, enablePromptInjectionDetection: Bool? = nil) {
        self.environment = environment
        self.excludedPredefinedFunctions = excludedPredefinedFunctions
        self.enablePromptInjectionDetection = enablePromptInjectionDetection
    }
}

/// Config for authentication with API key. This data type is not supported in Gemini API.
public struct ApiKeyConfig: Codable, Sendable {
    public var apiKeySecret: String?
    public var apiKeyString: String?
    public var httpElementLocation: HttpElementLocation?
    public var name: String?
    public init(
        apiKeySecret: String? = nil,
        apiKeyString: String? = nil,
        httpElementLocation: HttpElementLocation? = nil,
        name: String? = nil
    ) {
        self.apiKeySecret = apiKeySecret
        self.apiKeyString = apiKeyString
        self.httpElementLocation = httpElementLocation
        self.name = name
    }
}

/// Config for Google Service Account Authentication. This data type is not supported in Gemini API.
public struct AuthConfigGoogleServiceAccountConfig: Codable, Sendable {
    public var serviceAccount: String?
    public init(serviceAccount: String? = nil) {
        self.serviceAccount = serviceAccount
    }
}

/// Config for HTTP Basic Authentication. This data type is not supported in Gemini API.
public struct AuthConfigHttpBasicAuthConfig: Codable, Sendable {
    public var credentialSecret: String?
    public init(credentialSecret: String? = nil) {
        self.credentialSecret = credentialSecret
    }
}

/// Config for user oauth. This data type is not supported in Gemini API.
public struct AuthConfigOauthConfig: Codable, Sendable {
    public var accessToken: String?
    public var serviceAccount: String?
    public init(accessToken: String? = nil, serviceAccount: String? = nil) {
        self.accessToken = accessToken
        self.serviceAccount = serviceAccount
    }
}

/// Config for user OIDC auth. This data type is not supported in Gemini API.
public struct AuthConfigOidcConfig: Codable, Sendable {
    public var idToken: String?
    public var serviceAccount: String?
    public init(idToken: String? = nil, serviceAccount: String? = nil) {
        self.idToken = idToken
        self.serviceAccount = serviceAccount
    }
}

/// The authentication config to access the API.
public struct AuthConfig: Codable, Sendable {
    public var apiKey: String?
    public var apiKeyConfig: ApiKeyConfig?
    public var authType: AuthType?
    public var googleServiceAccountConfig: AuthConfigGoogleServiceAccountConfig?
    public var httpBasicAuthConfig: AuthConfigHttpBasicAuthConfig?
    public var oauthConfig: AuthConfigOauthConfig?
    public var oidcConfig: AuthConfigOidcConfig?
    public init(
        apiKey: String? = nil,
        apiKeyConfig: ApiKeyConfig? = nil,
        authType: AuthType? = nil,
        googleServiceAccountConfig: AuthConfigGoogleServiceAccountConfig? = nil,
        httpBasicAuthConfig: AuthConfigHttpBasicAuthConfig? = nil,
        oauthConfig: AuthConfigOauthConfig? = nil,
        oidcConfig: AuthConfigOidcConfig? = nil
    ) {
        self.apiKey = apiKey
        self.apiKeyConfig = apiKeyConfig
        self.authType = authType
        self.googleServiceAccountConfig = googleServiceAccountConfig
        self.httpBasicAuthConfig = httpBasicAuthConfig
        self.oauthConfig = oauthConfig
        self.oidcConfig = oidcConfig
    }
}

/// Tool to retrieve knowledge from Google Maps.
public struct GoogleMaps: Codable, Sendable {
    public var authConfig: AuthConfig?
    public var enableWidget: Bool?
    public init(authConfig: AuthConfig? = nil, enableWidget: Bool? = nil) {
        self.authConfig = authConfig
        self.enableWidget = enableWidget
    }
}

/// The API secret. This data type is not supported in Gemini API.
public struct ApiAuthApiKeyConfig: Codable, Sendable {
    public var apiKeySecretVersion: String?
    public var apiKeyString: String?
    public init(apiKeySecretVersion: String? = nil, apiKeyString: String? = nil) {
        self.apiKeySecretVersion = apiKeySecretVersion
        self.apiKeyString = apiKeyString
    }
}

/// The generic reusable api auth config. Deprecated. Please use AuthConfig instead.
public struct ApiAuth: Codable, Sendable {
    public var apiKeyConfig: ApiAuthApiKeyConfig?
    public init(apiKeyConfig: ApiAuthApiKeyConfig? = nil) {
        self.apiKeyConfig = apiKeyConfig
    }
}

/// The search parameters to use for the ELASTIC_SEARCH spec.
public struct ExternalApiElasticSearchParams: Codable, Sendable {
    public var index: String?
    public var numHits: Int?
    public var searchTemplate: String?
    public init(index: String? = nil, numHits: Int? = nil, searchTemplate: String? = nil) {
        self.index = index
        self.numHits = numHits
        self.searchTemplate = searchTemplate
    }
}

/// The search parameters to use for SIMPLE_SEARCH spec.
public struct ExternalApiSimpleSearchParams: Codable, Sendable {
    public init() {}
}

/// Retrieve from data source powered by external API for grounding.
public struct ExternalApi: Codable, Sendable {
    public var apiAuth: ApiAuth?
    public var apiSpec: ApiSpec?
    public var authConfig: AuthConfig?
    public var elasticSearchParams: ExternalApiElasticSearchParams?
    public var endpoint: String?
    public var simpleSearchParams: ExternalApiSimpleSearchParams?
    public init(
        apiAuth: ApiAuth? = nil,
        apiSpec: ApiSpec? = nil,
        authConfig: AuthConfig? = nil,
        elasticSearchParams: ExternalApiElasticSearchParams? = nil,
        endpoint: String? = nil,
        simpleSearchParams: ExternalApiSimpleSearchParams? = nil
    ) {
        self.apiAuth = apiAuth
        self.apiSpec = apiSpec
        self.authConfig = authConfig
        self.elasticSearchParams = elasticSearchParams
        self.endpoint = endpoint
        self.simpleSearchParams = simpleSearchParams
    }
}

/// Define data stores within engine to filter on in a search call.
public struct VertexAISearchDataStoreSpec: Codable, Sendable {
    public var dataStore: String?
    public var filter: String?
    public init(dataStore: String? = nil, filter: String? = nil) {
        self.dataStore = dataStore
        self.filter = filter
    }
}

/// Retrieve from Vertex AI Search datastore or engine for grounding.
public struct VertexAISearch: Codable, Sendable {
    public var dataStoreSpecs: [VertexAISearchDataStoreSpec]?
    public var datastore: String?
    public var engine: String?
    public var filter: String?
    public var maxResults: Int?
    public init(
        dataStoreSpecs: [VertexAISearchDataStoreSpec]? = nil,
        datastore: String? = nil,
        engine: String? = nil,
        filter: String? = nil,
        maxResults: Int? = nil
    ) {
        self.dataStoreSpecs = dataStoreSpecs
        self.datastore = datastore
        self.engine = engine
        self.filter = filter
        self.maxResults = maxResults
    }
}

/// The definition of the Rag resource.
public struct VertexRagStoreRagResource: Codable, Sendable {
    public var ragCorpus: String?
    public var ragFileIds: [String]?
    public init(ragCorpus: String? = nil, ragFileIds: [String]? = nil) {
        self.ragCorpus = ragCorpus
        self.ragFileIds = ragFileIds
    }
}

/// Config for filters.
public struct RagRetrievalConfigFilter: Codable, Sendable {
    public var metadataFilter: String?
    public var vectorDistanceThreshold: Double?
    public var vectorSimilarityThreshold: Double?
    public init(
        metadataFilter: String? = nil,
        vectorDistanceThreshold: Double? = nil,
        vectorSimilarityThreshold: Double? = nil
    ) {
        self.metadataFilter = metadataFilter
        self.vectorDistanceThreshold = vectorDistanceThreshold
        self.vectorSimilarityThreshold = vectorSimilarityThreshold
    }
}

/// Config for Hybrid Search.
public struct RagRetrievalConfigHybridSearch: Codable, Sendable {
    public var alpha: Double?
    public init(alpha: Double? = nil) {
        self.alpha = alpha
    }
}

/// Config for LlmRanker.
public struct RagRetrievalConfigRankingLlmRanker: Codable, Sendable {
    public var modelName: String?
    public init(modelName: String? = nil) {
        self.modelName = modelName
    }
}

/// Config for Rank Service.
public struct RagRetrievalConfigRankingRankService: Codable, Sendable {
    public var modelName: String?
    public init(modelName: String? = nil) {
        self.modelName = modelName
    }
}

/// Config for ranking and reranking.
public struct RagRetrievalConfigRanking: Codable, Sendable {
    public var llmRanker: RagRetrievalConfigRankingLlmRanker?
    public var rankService: RagRetrievalConfigRankingRankService?
    public init(
        llmRanker: RagRetrievalConfigRankingLlmRanker? = nil,
        rankService: RagRetrievalConfigRankingRankService? = nil
    ) {
        self.llmRanker = llmRanker
        self.rankService = rankService
    }
}

/// Specifies the context retrieval config.
public struct RagRetrievalConfig: Codable, Sendable {
    public var filter: RagRetrievalConfigFilter?
    public var hybridSearch: RagRetrievalConfigHybridSearch?
    public var ranking: RagRetrievalConfigRanking?
    public var topK: Int?
    public init(
        filter: RagRetrievalConfigFilter? = nil,
        hybridSearch: RagRetrievalConfigHybridSearch? = nil,
        ranking: RagRetrievalConfigRanking? = nil,
        topK: Int? = nil
    ) {
        self.filter = filter
        self.hybridSearch = hybridSearch
        self.ranking = ranking
        self.topK = topK
    }
}

/// Retrieve from Vertex RAG Store for grounding.
public struct VertexRagStore: Codable, Sendable {
    public var ragCorpora: [String]?
    public var ragResources: [VertexRagStoreRagResource]?
    public var ragRetrievalConfig: RagRetrievalConfig?
    public var similarityTopK: Int?
    public var storeContext: Bool?
    public var vectorDistanceThreshold: Double?
    public init(
        ragCorpora: [String]? = nil,
        ragResources: [VertexRagStoreRagResource]? = nil,
        ragRetrievalConfig: RagRetrievalConfig? = nil,
        similarityTopK: Int? = nil,
        storeContext: Bool? = nil,
        vectorDistanceThreshold: Double? = nil
    ) {
        self.ragCorpora = ragCorpora
        self.ragResources = ragResources
        self.ragRetrievalConfig = ragRetrievalConfig
        self.similarityTopK = similarityTopK
        self.storeContext = storeContext
        self.vectorDistanceThreshold = vectorDistanceThreshold
    }
}

/// Defines a retrieval tool that model can call to access external knowledge.
public struct Retrieval: Codable, Sendable {
    public var disableAttribution: Bool?
    public var externalApi: ExternalApi?
    public var vertexAiSearch: VertexAISearch?
    public var vertexRagStore: VertexRagStore?
    public init(
        disableAttribution: Bool? = nil,
        externalApi: ExternalApi? = nil,
        vertexAiSearch: VertexAISearch? = nil,
        vertexRagStore: VertexRagStore? = nil
    ) {
        self.disableAttribution = disableAttribution
        self.externalApi = externalApi
        self.vertexAiSearch = vertexAiSearch
        self.vertexRagStore = vertexRagStore
    }
}

/// The FileSearch tool that retrieves knowledge from Semantic Retrieval corpora.
public struct FileSearch: Codable, Sendable {
    public var fileSearchStoreNames: [String]?
    public var topK: Int?
    public var metadataFilter: String?
    public init(
        fileSearchStoreNames: [String]? = nil,
        topK: Int? = nil,
        metadataFilter: String? = nil
    ) {
        self.fileSearchStoreNames = fileSearchStoreNames
        self.topK = topK
        self.metadataFilter = metadataFilter
    }
}

/// Standard web search for grounding and related configurations.
public struct WebSearch: Codable, Sendable {
    public init() {}
}

/// Image search for grounding and related configurations.
public struct ImageSearch: Codable, Sendable {
    public init() {}
}

/// Different types of search that can be enabled on the GoogleSearch tool.
public struct SearchTypes: Codable, Sendable {
    public var webSearch: WebSearch?
    public var imageSearch: ImageSearch?
    public init(webSearch: WebSearch? = nil, imageSearch: ImageSearch? = nil) {
        self.webSearch = webSearch
        self.imageSearch = imageSearch
    }
}

/// Represents a time interval.
public struct Interval: Codable, Sendable {
    public var endTime: String?
    public var startTime: String?
    public init(endTime: String? = nil, startTime: String? = nil) {
        self.endTime = endTime
        self.startTime = startTime
    }
}

/// GoogleSearch tool type. Tool to support Google Search in Model.
public struct GoogleSearch: Codable, Sendable {
    public var searchTypes: SearchTypes?
    public var blockingConfidence: PhishBlockThreshold?
    public var excludeDomains: [String]?
    public var timeRangeFilter: Interval?
    public init(
        searchTypes: SearchTypes? = nil,
        blockingConfidence: PhishBlockThreshold? = nil,
        excludeDomains: [String]? = nil,
        timeRangeFilter: Interval? = nil
    ) {
        self.searchTypes = searchTypes
        self.blockingConfidence = blockingConfidence
        self.excludeDomains = excludeDomains
        self.timeRangeFilter = timeRangeFilter
    }
}

/// Tool that executes code generated by the model.
public struct ToolCodeExecution: Codable, Sendable {
    public init() {}
}

/// Tool to search public web data, powered by Vertex AI Search.
public struct EnterpriseWebSearch: Codable, Sendable {
    public var blockingConfidence: PhishBlockThreshold?
    public var excludeDomains: [String]?
    public init(blockingConfidence: PhishBlockThreshold? = nil, excludeDomains: [String]? = nil) {
        self.blockingConfidence = blockingConfidence
        self.excludeDomains = excludeDomains
    }
}

/// Structured representation of a function declaration.
public struct FunctionDeclaration: Codable, Sendable {
    public var description: String?
    public var name: String?
    public var parameters: Schema?
    public var parametersJsonSchema: JSONValue?
    public var response: Schema?
    public var responseJsonSchema: JSONValue?
    public var behavior: Behavior?
    public init(
        description: String? = nil,
        name: String? = nil,
        parameters: Schema? = nil,
        parametersJsonSchema: JSONValue? = nil,
        response: Schema? = nil,
        responseJsonSchema: JSONValue? = nil,
        behavior: Behavior? = nil
    ) {
        self.description = description
        self.name = name
        self.parameters = parameters
        self.parametersJsonSchema = parametersJsonSchema
        self.response = response
        self.responseJsonSchema = responseJsonSchema
        self.behavior = behavior
    }
}

/// Describes the options to customize dynamic retrieval.
public struct DynamicRetrievalConfig: Codable, Sendable {
    public var dynamicThreshold: Double?
    public var mode: DynamicRetrievalConfigMode?
    public init(dynamicThreshold: Double? = nil, mode: DynamicRetrievalConfigMode? = nil) {
        self.dynamicThreshold = dynamicThreshold
        self.mode = mode
    }
}

/// Tool to retrieve public web data for grounding, powered by Google.
public struct GoogleSearchRetrieval: Codable, Sendable {
    public var dynamicRetrievalConfig: DynamicRetrievalConfig?
    public init(dynamicRetrievalConfig: DynamicRetrievalConfig? = nil) {
        self.dynamicRetrievalConfig = dynamicRetrievalConfig
    }
}

/// ParallelAiSearch tool type.
public struct ToolParallelAiSearch: Codable, Sendable {
    public var apiKey: String?
    public var customConfigs: [String: JSONValue]?
    public init(apiKey: String? = nil, customConfigs: [String: JSONValue]? = nil) {
        self.apiKey = apiKey
        self.customConfigs = customConfigs
    }
}

/// Tool to support URL context.
public struct UrlContext: Codable, Sendable {
    public init() {}
}

/// A transport that can stream HTTP requests and responses.
public struct StreamableHttpTransport: Codable, Sendable {
    public var headers: [String: String]?
    public var sseReadTimeout: String?
    public var terminateOnClose: Bool?
    public var timeout: String?
    public var url: String?
    public init(
        headers: [String: String]? = nil,
        sseReadTimeout: String? = nil,
        terminateOnClose: Bool? = nil,
        timeout: String? = nil,
        url: String? = nil
    ) {
        self.headers = headers
        self.sseReadTimeout = sseReadTimeout
        self.terminateOnClose = terminateOnClose
        self.timeout = timeout
        self.url = url
    }
}

/// A MCPServer is a server that can be called by the model to perform actions.
public struct McpServer: Codable, Sendable {
    public var name: String?
    public var streamableHttpTransport: StreamableHttpTransport?
    public init(name: String? = nil, streamableHttpTransport: StreamableHttpTransport? = nil) {
        self.name = name
        self.streamableHttpTransport = streamableHttpTransport
    }
}

/// Tool details of a tool that the model may use to generate a response.
public struct Tool: Codable, Sendable {
    public var retrieval: Retrieval?
    public var computerUse: ComputerUse?
    public var fileSearch: FileSearch?
    public var googleSearch: GoogleSearch?
    public var googleMaps: GoogleMaps?
    public var codeExecution: ToolCodeExecution?
    public var enterpriseWebSearch: EnterpriseWebSearch?
    public var functionDeclarations: [FunctionDeclaration]?
    public var googleSearchRetrieval: GoogleSearchRetrieval?
    public var parallelAiSearch: ToolParallelAiSearch?
    public var urlContext: UrlContext?
    public var mcpServers: [McpServer]?
    public init(
        retrieval: Retrieval? = nil,
        computerUse: ComputerUse? = nil,
        fileSearch: FileSearch? = nil,
        googleSearch: GoogleSearch? = nil,
        googleMaps: GoogleMaps? = nil,
        codeExecution: ToolCodeExecution? = nil,
        enterpriseWebSearch: EnterpriseWebSearch? = nil,
        functionDeclarations: [FunctionDeclaration]? = nil,
        googleSearchRetrieval: GoogleSearchRetrieval? = nil,
        parallelAiSearch: ToolParallelAiSearch? = nil,
        urlContext: UrlContext? = nil,
        mcpServers: [McpServer]? = nil
    ) {
        self.retrieval = retrieval
        self.computerUse = computerUse
        self.fileSearch = fileSearch
        self.googleSearch = googleSearch
        self.googleMaps = googleMaps
        self.codeExecution = codeExecution
        self.enterpriseWebSearch = enterpriseWebSearch
        self.functionDeclarations = functionDeclarations
        self.googleSearchRetrieval = googleSearchRetrieval
        self.parallelAiSearch = parallelAiSearch
        self.urlContext = urlContext
        self.mcpServers = mcpServers
    }
}

/// An object that represents a latitude/longitude pair.
public struct LatLng: Codable, Sendable {
    public var latitude: Double?
    public var longitude: Double?
    public init(latitude: Double? = nil, longitude: Double? = nil) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// Retrieval config.
public struct RetrievalConfig: Codable, Sendable {
    public var latLng: LatLng?
    public var languageCode: String?
    public init(latLng: LatLng? = nil, languageCode: String? = nil) {
        self.latLng = latLng
        self.languageCode = languageCode
    }
}

/// Function calling config.
public struct FunctionCallingConfig: Codable, Sendable {
    public var allowedFunctionNames: [String]?
    public var mode: FunctionCallingConfigMode?
    public var streamFunctionCallArguments: Bool?
    public init(
        allowedFunctionNames: [String]? = nil,
        mode: FunctionCallingConfigMode? = nil,
        streamFunctionCallArguments: Bool? = nil
    ) {
        self.allowedFunctionNames = allowedFunctionNames
        self.mode = mode
        self.streamFunctionCallArguments = streamFunctionCallArguments
    }
}

/// Tool config. This config is shared for all tools provided in the request.
public struct ToolConfig: Codable, Sendable {
    public var retrievalConfig: RetrievalConfig?
    public var functionCallingConfig: FunctionCallingConfig?
    public var includeServerSideToolInvocations: Bool?
    public init(
        retrievalConfig: RetrievalConfig? = nil,
        functionCallingConfig: FunctionCallingConfig? = nil,
        includeServerSideToolInvocations: Bool? = nil
    ) {
        self.retrievalConfig = retrievalConfig
        self.functionCallingConfig = functionCallingConfig
        self.includeServerSideToolInvocations = includeServerSideToolInvocations
    }
}

/// The configuration for the replicated voice to use.
public struct ReplicatedVoiceConfig: Codable, Sendable {
    public var mimeType: String?
    public var voiceSampleAudio: String?
    public init(mimeType: String? = nil, voiceSampleAudio: String? = nil) {
        self.mimeType = mimeType
        self.voiceSampleAudio = voiceSampleAudio
    }
}

/// Configuration for a prebuilt voice.
public struct PrebuiltVoiceConfig: Codable, Sendable {
    public var voiceName: String?
    public init(voiceName: String? = nil) {
        self.voiceName = voiceName
    }
}

/// The configuration for the voice to use.
public struct VoiceConfig: Codable, Sendable {
    public var replicatedVoiceConfig: ReplicatedVoiceConfig?
    public var prebuiltVoiceConfig: PrebuiltVoiceConfig?
    public init(
        replicatedVoiceConfig: ReplicatedVoiceConfig? = nil,
        prebuiltVoiceConfig: PrebuiltVoiceConfig? = nil
    ) {
        self.replicatedVoiceConfig = replicatedVoiceConfig
        self.prebuiltVoiceConfig = prebuiltVoiceConfig
    }
}

/// Configuration for a single speaker in a multi-speaker setup.
public struct SpeakerVoiceConfig: Codable, Sendable {
    public var speaker: String?
    public var voiceConfig: VoiceConfig?
    public init(speaker: String? = nil, voiceConfig: VoiceConfig? = nil) {
        self.speaker = speaker
        self.voiceConfig = voiceConfig
    }
}

/// Configuration for a multi-speaker text-to-speech request.
public struct MultiSpeakerVoiceConfig: Codable, Sendable {
    public var speakerVoiceConfigs: [SpeakerVoiceConfig]?
    public init(speakerVoiceConfigs: [SpeakerVoiceConfig]? = nil) {
        self.speakerVoiceConfigs = speakerVoiceConfigs
    }
}

/// Config for speech generation and transcription.
public struct SpeechConfig: Codable, Sendable {
    public var voiceConfig: VoiceConfig?
    public var languageCode: String?
    public var multiSpeakerVoiceConfig: MultiSpeakerVoiceConfig?
    public init(
        voiceConfig: VoiceConfig? = nil,
        languageCode: String? = nil,
        multiSpeakerVoiceConfig: MultiSpeakerVoiceConfig? = nil
    ) {
        self.voiceConfig = voiceConfig
        self.languageCode = languageCode
        self.multiSpeakerVoiceConfig = multiSpeakerVoiceConfig
    }
}
