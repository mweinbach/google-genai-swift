// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

// Union types (`ContentUnion`, `ContentListUnion`, `SchemaUnion`, `SpeechConfigUnion`,
// `ToolUnion`, `ToolListUnion`) are declared in `Unions.swift`.

/// The configuration for automatic function calling.
public struct AutomaticFunctionCallingConfig: Codable, Sendable {
    public var disable: Bool?
    public var maximumRemoteCalls: Int?
    public var ignoreCallHistory: Bool?
    public init(
        disable: Bool? = nil,
        maximumRemoteCalls: Int? = nil,
        ignoreCallHistory: Bool? = nil
    ) {
        self.disable = disable
        self.maximumRemoteCalls = maximumRemoteCalls
        self.ignoreCallHistory = ignoreCallHistory
    }
}

/// The thinking features configuration.
public struct ThinkingConfig: Codable, Sendable {
    public var includeThoughts: Bool?
    public var thinkingBudget: Int?
    public var thinkingLevel: ThinkingLevel?
    public init(
        includeThoughts: Bool? = nil,
        thinkingBudget: Int? = nil,
        thinkingLevel: ThinkingLevel? = nil
    ) {
        self.includeThoughts = includeThoughts
        self.thinkingBudget = thinkingBudget
        self.thinkingLevel = thinkingLevel
    }
}

/// The image output format for generated images.
public struct ImageConfigImageOutputOptions: Codable, Sendable {
    public var compressionQuality: Double?
    public var mimeType: String?
    public init(compressionQuality: Double? = nil, mimeType: String? = nil) {
        self.compressionQuality = compressionQuality
        self.mimeType = mimeType
    }
}

/// The image generation configuration to be used in GenerateContentConfig.
public struct ImageConfig: Codable, Sendable {
    public var aspectRatio: String?
    public var imageSize: String?
    public var personGeneration: String?
    public var prominentPeople: ProminentPeople?
    public var outputMimeType: String?
    public var outputCompressionQuality: Double?
    public var imageOutputOptions: ImageConfigImageOutputOptions?
    public init(
        aspectRatio: String? = nil,
        imageSize: String? = nil,
        personGeneration: String? = nil,
        prominentPeople: ProminentPeople? = nil,
        outputMimeType: String? = nil,
        outputCompressionQuality: Double? = nil,
        imageOutputOptions: ImageConfigImageOutputOptions? = nil
    ) {
        self.aspectRatio = aspectRatio
        self.imageSize = imageSize
        self.personGeneration = personGeneration
        self.prominentPeople = prominentPeople
        self.outputMimeType = outputMimeType
        self.outputCompressionQuality = outputCompressionQuality
        self.imageOutputOptions = imageOutputOptions
    }
}

/// The configuration for automated routing.
public struct GenerationConfigRoutingConfigAutoRoutingMode: Codable, Sendable {
    public enum ModelRoutingPreference: String, Codable, Sendable {
        case unknown = "UNKNOWN"
        case prioritizeQuality = "PRIORITIZE_QUALITY"
        case balanced = "BALANCED"
        case prioritizeCost = "PRIORITIZE_COST"
    }
    public var modelRoutingPreference: ModelRoutingPreference?
    public init(modelRoutingPreference: ModelRoutingPreference? = nil) {
        self.modelRoutingPreference = modelRoutingPreference
    }
}

/// The configuration for manual routing.
public struct GenerationConfigRoutingConfigManualRoutingMode: Codable, Sendable {
    public var modelName: String?
    public init(modelName: String? = nil) {
        self.modelName = modelName
    }
}

/// The configuration for routing the request to a specific model.
public struct GenerationConfigRoutingConfig: Codable, Sendable {
    public var autoMode: GenerationConfigRoutingConfigAutoRoutingMode?
    public var manualMode: GenerationConfigRoutingConfigManualRoutingMode?
    public init(
        autoMode: GenerationConfigRoutingConfigAutoRoutingMode? = nil,
        manualMode: GenerationConfigRoutingConfigManualRoutingMode? = nil
    ) {
        self.autoMode = autoMode
        self.manualMode = manualMode
    }
}

/// A safety setting that affects the safety-blocking behavior.
public struct SafetySetting: Codable, Sendable {
    public var category: HarmCategory?
    public var method: HarmBlockMethod?
    public var threshold: HarmBlockThreshold?
    public init(
        category: HarmCategory? = nil,
        method: HarmBlockMethod? = nil,
        threshold: HarmBlockThreshold? = nil
    ) {
        self.category = category
        self.method = method
        self.threshold = threshold
    }
}

/// Configuration for Model Armor.
public struct ModelArmorConfig: Codable, Sendable {
    public var promptTemplateName: String?
    public var responseTemplateName: String?
    public init(promptTemplateName: String? = nil, responseTemplateName: String? = nil) {
        self.promptTemplateName = promptTemplateName
        self.responseTemplateName = responseTemplateName
    }
}

/// Optional model configuration parameters.
public struct GenerateContentConfig: Codable, Sendable {
    public var httpOptions: HttpOptions?
    public var abortSignal: AbortSignal?
    public var systemInstruction: ContentUnion?
    public var temperature: Double?
    public var topP: Double?
    public var topK: Double?
    public var candidateCount: Int?
    public var maxOutputTokens: Int?
    public var stopSequences: [String]?
    public var responseLogprobs: Bool?
    public var logprobs: Int?
    public var presencePenalty: Double?
    public var frequencyPenalty: Double?
    public var seed: Int?
    public var responseMimeType: String?
    public var responseSchema: SchemaUnion?
    public var responseJsonSchema: JSONValue?
    public var routingConfig: GenerationConfigRoutingConfig?
    public var modelSelectionConfig: ModelSelectionConfig?
    public var safetySettings: [SafetySetting]?
    public var tools: ToolListUnion?
    public var toolConfig: ToolConfig?
    public var labels: [String: String]?
    public var cachedContent: String?
    public var responseModalities: [String]?
    public var mediaResolution: MediaResolution?
    public var speechConfig: SpeechConfigUnion?
    public var audioTimestamp: Bool?
    public var automaticFunctionCalling: AutomaticFunctionCallingConfig?
    public var thinkingConfig: ThinkingConfig?
    public var imageConfig: ImageConfig?
    public var enableEnhancedCivicAnswers: Bool?
    public var modelArmorConfig: ModelArmorConfig?
    public var serviceTier: ServiceTier?
    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        systemInstruction: ContentUnion? = nil,
        temperature: Double? = nil,
        topP: Double? = nil,
        topK: Double? = nil,
        candidateCount: Int? = nil,
        maxOutputTokens: Int? = nil,
        stopSequences: [String]? = nil,
        responseLogprobs: Bool? = nil,
        logprobs: Int? = nil,
        presencePenalty: Double? = nil,
        frequencyPenalty: Double? = nil,
        seed: Int? = nil,
        responseMimeType: String? = nil,
        responseSchema: SchemaUnion? = nil,
        responseJsonSchema: JSONValue? = nil,
        routingConfig: GenerationConfigRoutingConfig? = nil,
        modelSelectionConfig: ModelSelectionConfig? = nil,
        safetySettings: [SafetySetting]? = nil,
        tools: ToolListUnion? = nil,
        toolConfig: ToolConfig? = nil,
        labels: [String: String]? = nil,
        cachedContent: String? = nil,
        responseModalities: [String]? = nil,
        mediaResolution: MediaResolution? = nil,
        speechConfig: SpeechConfigUnion? = nil,
        audioTimestamp: Bool? = nil,
        automaticFunctionCalling: AutomaticFunctionCallingConfig? = nil,
        thinkingConfig: ThinkingConfig? = nil,
        imageConfig: ImageConfig? = nil,
        enableEnhancedCivicAnswers: Bool? = nil,
        modelArmorConfig: ModelArmorConfig? = nil,
        serviceTier: ServiceTier? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.systemInstruction = systemInstruction
        self.temperature = temperature
        self.topP = topP
        self.topK = topK
        self.candidateCount = candidateCount
        self.maxOutputTokens = maxOutputTokens
        self.stopSequences = stopSequences
        self.responseLogprobs = responseLogprobs
        self.logprobs = logprobs
        self.presencePenalty = presencePenalty
        self.frequencyPenalty = frequencyPenalty
        self.seed = seed
        self.responseMimeType = responseMimeType
        self.responseSchema = responseSchema
        self.responseJsonSchema = responseJsonSchema
        self.routingConfig = routingConfig
        self.modelSelectionConfig = modelSelectionConfig
        self.safetySettings = safetySettings
        self.tools = tools
        self.toolConfig = toolConfig
        self.labels = labels
        self.cachedContent = cachedContent
        self.responseModalities = responseModalities
        self.mediaResolution = mediaResolution
        self.speechConfig = speechConfig
        self.audioTimestamp = audioTimestamp
        self.automaticFunctionCalling = automaticFunctionCalling
        self.thinkingConfig = thinkingConfig
        self.imageConfig = imageConfig
        self.enableEnhancedCivicAnswers = enableEnhancedCivicAnswers
        self.modelArmorConfig = modelArmorConfig
        self.serviceTier = serviceTier
    }
}

/// Config for models.generate_content parameters.
public struct GenerateContentParameters: Codable, Sendable {
    public var model: String
    public var contents: ContentListUnion
    public var config: GenerateContentConfig?
    public init(
        model: String,
        contents: ContentListUnion,
        config: GenerateContentConfig? = nil
    ) {
        self.model = model
        self.contents = contents
        self.config = config
    }
}

/// A wrapper class for the http response.
public final class HttpResponse: Codable, @unchecked Sendable {
    public var headers: [String: String]?
    /// Wraps the original Foundation `HTTPURLResponse` (and accompanying body data when available).
    /// Optional because instances may be constructed from decoded data without a live URL response.
    public var responseInternal: HTTPURLResponse?
    /// Captured response body. Mirrors `responseInternal.json()` access in TS.
    public var bodyData: Data?

    public init(_ response: HTTPURLResponse, bodyData: Data? = nil) {
        var headers: [String: String] = [:]
        for (key, value) in response.allHeaderFields {
            if let k = key as? String, let v = value as? String {
                headers[k] = v
            }
        }
        self.headers = headers
        self.responseInternal = response
        self.bodyData = bodyData
    }

    public init(headers: [String: String]? = nil, bodyData: Data? = nil) {
        self.headers = headers
        self.responseInternal = nil
        self.bodyData = bodyData
    }

    /// Returns the body as decoded JSON (mirrors TS `responseInternal.json()`).
    public func json() throws -> JSONValue {
        guard let data = bodyData else {
            throw GenAIError.runtime("No body data captured for HttpResponse.json()")
        }
        return try JSONDecoder().decode(JSONValue.self, from: data)
    }

    // Codable: only the serializable surface (headers + bodyData) round-trips.
    private enum CodingKeys: String, CodingKey {
        case headers
        case bodyData
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.headers = try c.decodeIfPresent([String: String].self, forKey: .headers)
        self.bodyData = try c.decodeIfPresent(Data.self, forKey: .bodyData)
        self.responseInternal = nil
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(headers, forKey: .headers)
        try c.encodeIfPresent(bodyData, forKey: .bodyData)
    }
}

/// Represents a whole or partial calendar date.
public struct GoogleTypeDate: Codable, Sendable {
    public var day: Int?
    public var month: Int?
    public var year: Int?
    public init(day: Int? = nil, month: Int? = nil, year: Int? = nil) {
        self.day = day
        self.month = month
        self.year = year
    }
}

/// A citation for a piece of generated content.
public struct Citation: Codable, Sendable {
    public var endIndex: Int?
    public var license: String?
    public var publicationDate: GoogleTypeDate?
    public var startIndex: Int?
    public var title: String?
    public var uri: String?
    public init(
        endIndex: Int? = nil,
        license: String? = nil,
        publicationDate: GoogleTypeDate? = nil,
        startIndex: Int? = nil,
        title: String? = nil,
        uri: String? = nil
    ) {
        self.endIndex = endIndex
        self.license = license
        self.publicationDate = publicationDate
        self.startIndex = startIndex
        self.title = title
        self.uri = uri
    }
}

/// Citation information when the model quotes another source.
public struct CitationMetadata: Codable, Sendable {
    public var citations: [Citation]?
    public init(citations: [Citation]? = nil) {
        self.citations = citations
    }
}

/// Author attribution for a photo or review.
public struct GroundingChunkMapsPlaceAnswerSourcesAuthorAttribution: Codable, Sendable {
    public var displayName: String?
    public var photoUri: String?
    public var uri: String?
    public init(displayName: String? = nil, photoUri: String? = nil, uri: String? = nil) {
        self.displayName = displayName
        self.photoUri = photoUri
        self.uri = uri
    }
}

/// Encapsulates a review snippet.
public struct GroundingChunkMapsPlaceAnswerSourcesReviewSnippet: Codable, Sendable {
    public var authorAttribution: GroundingChunkMapsPlaceAnswerSourcesAuthorAttribution?
    public var flagContentUri: String?
    public var googleMapsUri: String?
    public var relativePublishTimeDescription: String?
    public var review: String?
    public var reviewId: String?
    public var title: String?
    public init(
        authorAttribution: GroundingChunkMapsPlaceAnswerSourcesAuthorAttribution? = nil,
        flagContentUri: String? = nil,
        googleMapsUri: String? = nil,
        relativePublishTimeDescription: String? = nil,
        review: String? = nil,
        reviewId: String? = nil,
        title: String? = nil
    ) {
        self.authorAttribution = authorAttribution
        self.flagContentUri = flagContentUri
        self.googleMapsUri = googleMapsUri
        self.relativePublishTimeDescription = relativePublishTimeDescription
        self.review = review
        self.reviewId = reviewId
        self.title = title
    }
}

/// The sources that were used to generate the place answer.
public struct GroundingChunkMapsPlaceAnswerSources: Codable, Sendable {
    public var reviewSnippet: [GroundingChunkMapsPlaceAnswerSourcesReviewSnippet]?
    public var flagContentUri: String?
    public var reviewSnippets: [GroundingChunkMapsPlaceAnswerSourcesReviewSnippet]?
    public init(
        reviewSnippet: [GroundingChunkMapsPlaceAnswerSourcesReviewSnippet]? = nil,
        flagContentUri: String? = nil,
        reviewSnippets: [GroundingChunkMapsPlaceAnswerSourcesReviewSnippet]? = nil
    ) {
        self.reviewSnippet = reviewSnippet
        self.flagContentUri = flagContentUri
        self.reviewSnippets = reviewSnippets
    }
}

/// Route information from Google Maps.
public struct GroundingChunkMapsRoute: Codable, Sendable {
    public var distanceMeters: Double?
    public var duration: String?
    public var encodedPolyline: String?
    public init(
        distanceMeters: Double? = nil,
        duration: String? = nil,
        encodedPolyline: String? = nil
    ) {
        self.distanceMeters = distanceMeters
        self.duration = duration
        self.encodedPolyline = encodedPolyline
    }
}

/// A `Maps` chunk is a piece of evidence that comes from Google Maps.
public struct GroundingChunkMaps: Codable, Sendable {
    public var placeAnswerSources: GroundingChunkMapsPlaceAnswerSources?
    public var placeId: String?
    public var text: String?
    public var title: String?
    public var uri: String?
    public var route: GroundingChunkMapsRoute?
    public init(
        placeAnswerSources: GroundingChunkMapsPlaceAnswerSources? = nil,
        placeId: String? = nil,
        text: String? = nil,
        title: String? = nil,
        uri: String? = nil,
        route: GroundingChunkMapsRoute? = nil
    ) {
        self.placeAnswerSources = placeAnswerSources
        self.placeId = placeId
        self.text = text
        self.title = title
        self.uri = uri
        self.route = route
    }
}

/// An `Image` chunk is a piece of evidence that comes from an image search result.
public struct GroundingChunkImage: Codable, Sendable {
    public var sourceUri: String?
    public var imageUri: String?
    public var title: String?
    public var domain: String?
    public init(
        sourceUri: String? = nil,
        imageUri: String? = nil,
        title: String? = nil,
        domain: String? = nil
    ) {
        self.sourceUri = sourceUri
        self.imageUri = imageUri
        self.title = title
        self.domain = domain
    }
}

/// Represents where the chunk starts and ends in the document.
public struct RagChunkPageSpan: Codable, Sendable {
    public var firstPage: Int?
    public var lastPage: Int?
    public init(firstPage: Int? = nil, lastPage: Int? = nil) {
        self.firstPage = firstPage
        self.lastPage = lastPage
    }
}

/// A RagChunk includes the content of a chunk of a RagFile, and associated metadata.
public struct RagChunk: Codable, Sendable {
    public var pageSpan: RagChunkPageSpan?
    public var text: String?
    public init(pageSpan: RagChunkPageSpan? = nil, text: String? = nil) {
        self.pageSpan = pageSpan
        self.text = text
    }
}

/// A list of string values.
public struct GroundingChunkStringList: Codable, Sendable {
    public var values: [String]?
    public init(values: [String]? = nil) {
        self.values = values
    }
}

/// User provided metadata about the GroundingFact.
public struct GroundingChunkCustomMetadata: Codable, Sendable {
    public var key: String?
    public var numericValue: Double?
    public var stringListValue: GroundingChunkStringList?
    public var stringValue: String?
    public init(
        key: String? = nil,
        numericValue: Double? = nil,
        stringListValue: GroundingChunkStringList? = nil,
        stringValue: String? = nil
    ) {
        self.key = key
        self.numericValue = numericValue
        self.stringListValue = stringListValue
        self.stringValue = stringValue
    }
}

/// Context retrieved from a data source to ground the model's response.
public struct GroundingChunkRetrievedContext: Codable, Sendable {
    public var documentName: String?
    public var ragChunk: RagChunk?
    public var text: String?
    public var title: String?
    public var uri: String?
    public var customMetadata: [GroundingChunkCustomMetadata]?
    public var fileSearchStore: String?
    public var pageNumber: Int?
    public var mediaId: String?
    public init(
        documentName: String? = nil,
        ragChunk: RagChunk? = nil,
        text: String? = nil,
        title: String? = nil,
        uri: String? = nil,
        customMetadata: [GroundingChunkCustomMetadata]? = nil,
        fileSearchStore: String? = nil,
        pageNumber: Int? = nil,
        mediaId: String? = nil
    ) {
        self.documentName = documentName
        self.ragChunk = ragChunk
        self.text = text
        self.title = title
        self.uri = uri
        self.customMetadata = customMetadata
        self.fileSearchStore = fileSearchStore
        self.pageNumber = pageNumber
        self.mediaId = mediaId
    }
}

/// A `Web` chunk is a piece of evidence that comes from a web page.
public struct GroundingChunkWeb: Codable, Sendable {
    public var domain: String?
    public var title: String?
    public var uri: String?
    public init(domain: String? = nil, title: String? = nil, uri: String? = nil) {
        self.domain = domain
        self.title = title
        self.uri = uri
    }
}

/// A piece of evidence that supports a claim made by the model.
public struct GroundingChunk: Codable, Sendable {
    public var image: GroundingChunkImage?
    public var maps: GroundingChunkMaps?
    public var retrievedContext: GroundingChunkRetrievedContext?
    public var web: GroundingChunkWeb?
    public init(
        image: GroundingChunkImage? = nil,
        maps: GroundingChunkMaps? = nil,
        retrievedContext: GroundingChunkRetrievedContext? = nil,
        web: GroundingChunkWeb? = nil
    ) {
        self.image = image
        self.maps = maps
        self.retrievedContext = retrievedContext
        self.web = web
    }
}

/// Segment of the content this support belongs to.
public struct Segment: Codable, Sendable {
    public var startIndex: Int?
    public var endIndex: Int?
    public var partIndex: Int?
    public var text: String?
    public init(
        startIndex: Int? = nil,
        endIndex: Int? = nil,
        partIndex: Int? = nil,
        text: String? = nil
    ) {
        self.startIndex = startIndex
        self.endIndex = endIndex
        self.partIndex = partIndex
        self.text = text
    }
}

/// Grounding support.
public struct GroundingSupport: Codable, Sendable {
    public var confidenceScores: [Double]?
    public var groundingChunkIndices: [Int]?
    public var segment: Segment?
    public var renderedParts: [Int]?
    public init(
        confidenceScores: [Double]? = nil,
        groundingChunkIndices: [Int]? = nil,
        segment: Segment? = nil,
        renderedParts: [Int]? = nil
    ) {
        self.confidenceScores = confidenceScores
        self.groundingChunkIndices = groundingChunkIndices
        self.segment = segment
        self.renderedParts = renderedParts
    }
}

/// Metadata returned to client when grounding is enabled.
public struct RetrievalMetadata: Codable, Sendable {
    public var googleSearchDynamicRetrievalScore: Double?
    public init(googleSearchDynamicRetrievalScore: Double? = nil) {
        self.googleSearchDynamicRetrievalScore = googleSearchDynamicRetrievalScore
    }
}

/// The entry point used to search for grounding sources.
public struct SearchEntryPoint: Codable, Sendable {
    public var renderedContent: String?
    public var sdkBlob: String?
    public init(renderedContent: String? = nil, sdkBlob: String? = nil) {
        self.renderedContent = renderedContent
        self.sdkBlob = sdkBlob
    }
}

/// A URI that can be used to flag a place or review for inappropriate content.
public struct GroundingMetadataSourceFlaggingUri: Codable, Sendable {
    public var flagContentUri: String?
    public var sourceId: String?
    public init(flagContentUri: String? = nil, sourceId: String? = nil) {
        self.flagContentUri = flagContentUri
        self.sourceId = sourceId
    }
}

/// Information for various kinds of grounding.
public struct GroundingMetadata: Codable, Sendable {
    public var imageSearchQueries: [String]?
    public var groundingChunks: [GroundingChunk]?
    public var groundingSupports: [GroundingSupport]?
    public var retrievalMetadata: RetrievalMetadata?
    public var searchEntryPoint: SearchEntryPoint?
    public var webSearchQueries: [String]?
    public var googleMapsWidgetContextToken: String?
    public var retrievalQueries: [String]?
    public var sourceFlaggingUris: [GroundingMetadataSourceFlaggingUri]?
    public init(
        imageSearchQueries: [String]? = nil,
        groundingChunks: [GroundingChunk]? = nil,
        groundingSupports: [GroundingSupport]? = nil,
        retrievalMetadata: RetrievalMetadata? = nil,
        searchEntryPoint: SearchEntryPoint? = nil,
        webSearchQueries: [String]? = nil,
        googleMapsWidgetContextToken: String? = nil,
        retrievalQueries: [String]? = nil,
        sourceFlaggingUris: [GroundingMetadataSourceFlaggingUri]? = nil
    ) {
        self.imageSearchQueries = imageSearchQueries
        self.groundingChunks = groundingChunks
        self.groundingSupports = groundingSupports
        self.retrievalMetadata = retrievalMetadata
        self.searchEntryPoint = searchEntryPoint
        self.webSearchQueries = webSearchQueries
        self.googleMapsWidgetContextToken = googleMapsWidgetContextToken
        self.retrievalQueries = retrievalQueries
        self.sourceFlaggingUris = sourceFlaggingUris
    }
}

/// A single token and its associated log probability.
public struct LogprobsResultCandidate: Codable, Sendable {
    public var logProbability: Double?
    public var token: String?
    public var tokenId: Int?
    public init(logProbability: Double? = nil, token: String? = nil, tokenId: Int? = nil) {
        self.logProbability = logProbability
        self.token = token
        self.tokenId = tokenId
    }
}

/// A list of the top candidate tokens and their log probabilities at each decoding step.
public struct LogprobsResultTopCandidates: Codable, Sendable {
    public var candidates: [LogprobsResultCandidate]?
    public init(candidates: [LogprobsResultCandidate]? = nil) {
        self.candidates = candidates
    }
}

/// The log probabilities of the tokens generated by the model.
public struct LogprobsResult: Codable, Sendable {
    public var chosenCandidates: [LogprobsResultCandidate]?
    public var topCandidates: [LogprobsResultTopCandidates]?
    public var logProbabilitySum: Double?
    public init(
        chosenCandidates: [LogprobsResultCandidate]? = nil,
        topCandidates: [LogprobsResultTopCandidates]? = nil,
        logProbabilitySum: Double? = nil
    ) {
        self.chosenCandidates = chosenCandidates
        self.topCandidates = topCandidates
        self.logProbabilitySum = logProbabilitySum
    }
}

/// A safety rating for a piece of content.
public struct SafetyRating: Codable, Sendable {
    public var blocked: Bool?
    public var category: HarmCategory?
    public var overwrittenThreshold: HarmBlockThreshold?
    public var probability: HarmProbability?
    public var probabilityScore: Double?
    public var severity: HarmSeverity?
    public var severityScore: Double?
    public init(
        blocked: Bool? = nil,
        category: HarmCategory? = nil,
        overwrittenThreshold: HarmBlockThreshold? = nil,
        probability: HarmProbability? = nil,
        probabilityScore: Double? = nil,
        severity: HarmSeverity? = nil,
        severityScore: Double? = nil
    ) {
        self.blocked = blocked
        self.category = category
        self.overwrittenThreshold = overwrittenThreshold
        self.probability = probability
        self.probabilityScore = probabilityScore
        self.severity = severity
        self.severityScore = severityScore
    }
}

/// The metadata for a single URL retrieval.
public struct UrlMetadata: Codable, Sendable {
    public var retrievedUrl: String?
    public var urlRetrievalStatus: UrlRetrievalStatus?
    public init(retrievedUrl: String? = nil, urlRetrievalStatus: UrlRetrievalStatus? = nil) {
        self.retrievedUrl = retrievedUrl
        self.urlRetrievalStatus = urlRetrievalStatus
    }
}

/// Metadata returned when the model uses the `url_context` tool.
public struct UrlContextMetadata: Codable, Sendable {
    public var urlMetadata: [UrlMetadata]?
    public init(urlMetadata: [UrlMetadata]? = nil) {
        self.urlMetadata = urlMetadata
    }
}

/// A response candidate generated from the model.
public struct Candidate: Codable, Sendable {
    public var content: Content?
    public var citationMetadata: CitationMetadata?
    public var finishMessage: String?
    public var tokenCount: Int?
    public var finishReason: FinishReason?
    public var groundingMetadata: GroundingMetadata?
    public var avgLogprobs: Double?
    public var index: Int?
    public var logprobsResult: LogprobsResult?
    public var safetyRatings: [SafetyRating]?
    public var urlContextMetadata: UrlContextMetadata?
    public init(
        content: Content? = nil,
        citationMetadata: CitationMetadata? = nil,
        finishMessage: String? = nil,
        tokenCount: Int? = nil,
        finishReason: FinishReason? = nil,
        groundingMetadata: GroundingMetadata? = nil,
        avgLogprobs: Double? = nil,
        index: Int? = nil,
        logprobsResult: LogprobsResult? = nil,
        safetyRatings: [SafetyRating]? = nil,
        urlContextMetadata: UrlContextMetadata? = nil
    ) {
        self.content = content
        self.citationMetadata = citationMetadata
        self.finishMessage = finishMessage
        self.tokenCount = tokenCount
        self.finishReason = finishReason
        self.groundingMetadata = groundingMetadata
        self.avgLogprobs = avgLogprobs
        self.index = index
        self.logprobsResult = logprobsResult
        self.safetyRatings = safetyRatings
        self.urlContextMetadata = urlContextMetadata
    }
}

/// Content filter results for a prompt sent in the request.
public final class GenerateContentResponsePromptFeedback: Codable, @unchecked Sendable {
    public var blockReason: BlockedReason?
    public var blockReasonMessage: String?
    public var safetyRatings: [SafetyRating]?
    public init(
        blockReason: BlockedReason? = nil,
        blockReasonMessage: String? = nil,
        safetyRatings: [SafetyRating]? = nil
    ) {
        self.blockReason = blockReason
        self.blockReasonMessage = blockReasonMessage
        self.safetyRatings = safetyRatings
    }
}

/// Represents token counting info for a single modality.
public struct ModalityTokenCount: Codable, Sendable {
    public var modality: MediaModality?
    public var tokenCount: Int?
    public init(modality: MediaModality? = nil, tokenCount: Int? = nil) {
        self.modality = modality
        self.tokenCount = tokenCount
    }
}

/// Usage metadata about the content generation request and response.
public final class GenerateContentResponseUsageMetadata: Codable, @unchecked Sendable {
    public var cacheTokensDetails: [ModalityTokenCount]?
    public var cachedContentTokenCount: Int?
    public var candidatesTokenCount: Int?
    public var candidatesTokensDetails: [ModalityTokenCount]?
    public var promptTokenCount: Int?
    public var promptTokensDetails: [ModalityTokenCount]?
    public var thoughtsTokenCount: Int?
    public var toolUsePromptTokenCount: Int?
    public var toolUsePromptTokensDetails: [ModalityTokenCount]?
    public var totalTokenCount: Int?
    public var trafficType: TrafficType?
    public init(
        cacheTokensDetails: [ModalityTokenCount]? = nil,
        cachedContentTokenCount: Int? = nil,
        candidatesTokenCount: Int? = nil,
        candidatesTokensDetails: [ModalityTokenCount]? = nil,
        promptTokenCount: Int? = nil,
        promptTokensDetails: [ModalityTokenCount]? = nil,
        thoughtsTokenCount: Int? = nil,
        toolUsePromptTokenCount: Int? = nil,
        toolUsePromptTokensDetails: [ModalityTokenCount]? = nil,
        totalTokenCount: Int? = nil,
        trafficType: TrafficType? = nil
    ) {
        self.cacheTokensDetails = cacheTokensDetails
        self.cachedContentTokenCount = cachedContentTokenCount
        self.candidatesTokenCount = candidatesTokenCount
        self.candidatesTokensDetails = candidatesTokensDetails
        self.promptTokenCount = promptTokenCount
        self.promptTokensDetails = promptTokensDetails
        self.thoughtsTokenCount = thoughtsTokenCount
        self.toolUsePromptTokenCount = toolUsePromptTokenCount
        self.toolUsePromptTokensDetails = toolUsePromptTokensDetails
        self.totalTokenCount = totalTokenCount
        self.trafficType = trafficType
    }
}

/// The status of the underlying model.
public struct ModelStatus: Codable, Sendable {
    public var message: String?
    public var modelStage: ModelStage?
    public var retirementTime: String?
    public init(
        message: String? = nil,
        modelStage: ModelStage? = nil,
        retirementTime: String? = nil
    ) {
        self.message = message
        self.modelStage = modelStage
        self.retirementTime = retirementTime
    }
}

/// Response message for PredictionService.GenerateContent.
public final class GenerateContentResponse: Codable, @unchecked Sendable {
    public var sdkHttpResponse: HttpResponse?
    public var candidates: [Candidate]?
    public var createTime: String?
    public var automaticFunctionCallingHistory: [Content]?
    public var modelVersion: String?
    public var promptFeedback: GenerateContentResponsePromptFeedback?
    public var responseId: String?
    public var usageMetadata: GenerateContentResponseUsageMetadata?
    public var modelStatus: ModelStatus?

    public init(
        sdkHttpResponse: HttpResponse? = nil,
        candidates: [Candidate]? = nil,
        createTime: String? = nil,
        automaticFunctionCallingHistory: [Content]? = nil,
        modelVersion: String? = nil,
        promptFeedback: GenerateContentResponsePromptFeedback? = nil,
        responseId: String? = nil,
        usageMetadata: GenerateContentResponseUsageMetadata? = nil,
        modelStatus: ModelStatus? = nil
    ) {
        self.sdkHttpResponse = sdkHttpResponse
        self.candidates = candidates
        self.createTime = createTime
        self.automaticFunctionCallingHistory = automaticFunctionCallingHistory
        self.modelVersion = modelVersion
        self.promptFeedback = promptFeedback
        self.responseId = responseId
        self.usageMetadata = usageMetadata
        self.modelStatus = modelStatus
    }

    /// Returns the concatenation of all text parts from the first candidate in the response.
    public var text: String? {
        guard let parts = candidates?.first?.content?.parts else { return nil }
        if parts.isEmpty { return nil }
        if (candidates?.count ?? 0) > 1 {
            print("there are multiple candidates in the response, returning text from the first one.")
        }
        var text = ""
        var anyTextPartText = false
        var nonTextParts: [String] = []
        for part in parts {
            // Track non-text fields present on the part
            if part.codeExecutionResult != nil { nonTextParts.append("codeExecutionResult") }
            if part.executableCode != nil { nonTextParts.append("executableCode") }
            if part.fileData != nil { nonTextParts.append("fileData") }
            if part.functionCall != nil { nonTextParts.append("functionCall") }
            if part.functionResponse != nil { nonTextParts.append("functionResponse") }
            if part.inlineData != nil { nonTextParts.append("inlineData") }
            if part.videoMetadata != nil { nonTextParts.append("videoMetadata") }
            if part.toolCall != nil { nonTextParts.append("toolCall") }
            if part.toolResponse != nil { nonTextParts.append("toolResponse") }
            if part.mediaResolution != nil { nonTextParts.append("mediaResolution") }
            if part.partMetadata != nil { nonTextParts.append("partMetadata") }

            if let t = part.text {
                if let thought = part.thought, thought {
                    continue
                }
                anyTextPartText = true
                text += t
            }
        }
        if !nonTextParts.isEmpty {
            print("there are non-text parts \(nonTextParts) in the response, returning concatenation of all text parts. Please refer to the non text parts for a full response from model.")
        }
        return anyTextPartText ? text : nil
    }

    /// Returns the concatenation of all inline data parts from the first candidate
    /// in the response, re-encoded as base64.
    public var data: String? {
        guard let parts = candidates?.first?.content?.parts else { return nil }
        if parts.isEmpty { return nil }
        if (candidates?.count ?? 0) > 1 {
            print("there are multiple candidates in the response, returning data from the first one.")
        }
        var accumulated = Data()
        var nonDataParts: [String] = []
        for part in parts {
            if part.text != nil { nonDataParts.append("text") }
            if part.codeExecutionResult != nil { nonDataParts.append("codeExecutionResult") }
            if part.executableCode != nil { nonDataParts.append("executableCode") }
            if part.fileData != nil { nonDataParts.append("fileData") }
            if part.functionCall != nil { nonDataParts.append("functionCall") }
            if part.functionResponse != nil { nonDataParts.append("functionResponse") }
            if part.videoMetadata != nil { nonDataParts.append("videoMetadata") }
            if part.toolCall != nil { nonDataParts.append("toolCall") }
            if part.toolResponse != nil { nonDataParts.append("toolResponse") }

            if let inline = part.inlineData, let str = inline.data,
               let decoded = Data(base64Encoded: str) {
                accumulated.append(decoded)
            }
        }
        if !nonDataParts.isEmpty {
            print("there are non-data parts \(nonDataParts) in the response, returning concatenation of all data parts. Please refer to the non data parts for a full response from model.")
        }
        return accumulated.isEmpty ? nil : accumulated.base64EncodedString()
    }

    /// Returns the function calls from the first candidate in the response.
    public var functionCalls: [FunctionCall]? {
        guard let parts = candidates?.first?.content?.parts else { return nil }
        if parts.isEmpty { return nil }
        if (candidates?.count ?? 0) > 1 {
            print("there are multiple candidates in the response, returning function calls from the first one.")
        }
        let calls = parts.compactMap { $0.functionCall }
        return calls.isEmpty ? nil : calls
    }

    /// Returns the first executable code from the first candidate in the response.
    public var executableCode: String? {
        guard let parts = candidates?.first?.content?.parts else { return nil }
        if parts.isEmpty { return nil }
        if (candidates?.count ?? 0) > 1 {
            print("there are multiple candidates in the response, returning executable code from the first one.")
        }
        let codes = parts.compactMap { $0.executableCode }
        return codes.first?.code
    }

    /// Returns the first code execution result from the first candidate in the response.
    public var codeExecutionResult: String? {
        guard let parts = candidates?.first?.content?.parts else { return nil }
        if parts.isEmpty { return nil }
        if (candidates?.count ?? 0) > 1 {
            print("there are multiple candidates in the response, returning code execution result from the first one.")
        }
        let results = parts.compactMap { $0.codeExecutionResult }
        return results.first?.output
    }
}
