// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

public enum ReferenceImage: Codable, Sendable {
    case raw(RawReferenceImage)
    case mask(MaskReferenceImage)
    case control(ControlReferenceImage)
    case style(StyleReferenceImage)
    case subject(SubjectReferenceImage)
    case content(ContentReferenceImage)

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(RawReferenceImage.self) { self = .raw(v); return }
        if let v = try? c.decode(MaskReferenceImage.self) { self = .mask(v); return }
        if let v = try? c.decode(ControlReferenceImage.self) { self = .control(v); return }
        if let v = try? c.decode(StyleReferenceImage.self) { self = .style(v); return }
        if let v = try? c.decode(SubjectReferenceImage.self) { self = .subject(v); return }
        if let v = try? c.decode(ContentReferenceImage.self) { self = .content(v); return }
        throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unknown ReferenceImage variant")
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .raw(let v): try c.encode(v)
        case .mask(let v): try c.encode(v)
        case .control(let v): try c.encode(v)
        case .style(let v): try c.encode(v)
        case .subject(let v): try c.encode(v)
        case .content(let v): try c.encode(v)
        }
    }
}

/// Parameters for the request to edit an image.
public struct EditImageParameters: Codable, Sendable {
    /// The model to use.
    public var model: String
    /// A text description of the edit to apply to the image.
    public var prompt: String
    /// The reference images for Imagen 3 editing.
    public var referenceImages: [ReferenceImage]
    /// Configuration for editing.
    public var config: EditImageConfig?

    public init(
        model: String,
        prompt: String,
        referenceImages: [ReferenceImage],
        config: EditImageConfig? = nil
    ) {
        self.model = model
        self.prompt = prompt
        self.referenceImages = referenceImages
        self.config = config
    }
}

/// Optional parameters for the embed_content method.
public struct EmbedContentConfig: Codable, Sendable {
    /// Type of task for which the embedding will be used.
    public var taskType: String?
    /// Title for the text. Only applicable when TaskType is `RETRIEVAL_DOCUMENT`.
    public var title: String?
    /// Reduced dimension for the output embedding.
    public var outputDimensionality: Double?
    /// Gemini Enterprise Agent Platform only. The MIME type of the input.
    public var mimeType: String?
    /// Gemini Enterprise Agent Platform only. Whether to silently truncate inputs longer than the max sequence length.
    public var autoTruncate: Bool?
    /// Gemini Enterprise Agent Platform only. Whether to enable OCR for document content.
    public var documentOcr: Bool?
    /// Gemini Enterprise Agent Platform only. Whether to extract audio from video content.
    public var audioTrackExtraction: Bool?
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    public var abortSignal: AbortSignal?

    public init(
        taskType: String? = nil,
        title: String? = nil,
        outputDimensionality: Double? = nil,
        mimeType: String? = nil,
        autoTruncate: Bool? = nil,
        documentOcr: Bool? = nil,
        audioTrackExtraction: Bool? = nil,
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil
    ) {
        self.taskType = taskType
        self.title = title
        self.outputDimensionality = outputDimensionality
        self.mimeType = mimeType
        self.autoTruncate = autoTruncate
        self.documentOcr = documentOcr
        self.audioTrackExtraction = audioTrackExtraction
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

/// Parameters for the _embed_content method.
public struct EmbedContentParametersPrivate: Codable, Sendable {
    /// ID of the model to use.
    public var model: String
    /// The content to embed. Only the `parts.text` fields will be counted.
    public var contents: ContentListUnion?
    /// The single content to embed. Only the `parts.text` fields will be counted.
    public var content: ContentUnion?
    /// The Gemini Enterprise Agent Platform embedding API to use.
    public var embeddingApiType: EmbeddingApiType?
    /// Configuration that contains optional parameters.
    public var config: EmbedContentConfig?

    public init(
        model: String,
        contents: ContentListUnion? = nil,
        content: ContentUnion? = nil,
        embeddingApiType: EmbeddingApiType? = nil,
        config: EmbedContentConfig? = nil
    ) {
        self.model = model
        self.contents = contents
        self.content = content
        self.embeddingApiType = embeddingApiType
        self.config = config
    }
}

/// Statistics of the input text associated with the result of content embedding.
public struct ContentEmbeddingStatistics: Codable, Sendable {
    /// Gemini Enterprise Agent Platform only. If the input text was truncated.
    public var truncated: Bool?
    /// Gemini Enterprise Agent Platform only. Number of tokens of the input text.
    public var tokenCount: Double?

    public init(truncated: Bool? = nil, tokenCount: Double? = nil) {
        self.truncated = truncated
        self.tokenCount = tokenCount
    }
}

/// The embedding generated from an input content.
public struct ContentEmbedding: Codable, Sendable {
    /// A list of floats representing an embedding.
    public var values: [Double]?
    /// Gemini Enterprise Agent Platform only. Statistics of the input text associated with this embedding.
    public var statistics: ContentEmbeddingStatistics?

    public init(values: [Double]? = nil, statistics: ContentEmbeddingStatistics? = nil) {
        self.values = values
        self.statistics = statistics
    }
}

/// Request-level metadata for the Gemini Enterprise Agent Platform Embed Content API.
public struct EmbedContentMetadata: Codable, Sendable {
    /// Gemini Enterprise Agent Platform only. The total number of billable characters included in the request.
    public var billableCharacterCount: Double?

    public init(billableCharacterCount: Double? = nil) {
        self.billableCharacterCount = billableCharacterCount
    }
}

/// Response for the embed_content method.
public final class EmbedContentResponse: Codable, @unchecked Sendable {
    /// Used to retain the full HTTP response.
    public var sdkHttpResponse: HttpResponse?
    /// The embeddings for each request, in the same order as provided in the batch request.
    public var embeddings: [ContentEmbedding]?
    /// Gemini Enterprise Agent Platform only. Metadata about the request.
    public var metadata: EmbedContentMetadata?

    public init(
        sdkHttpResponse: HttpResponse? = nil,
        embeddings: [ContentEmbedding]? = nil,
        metadata: EmbedContentMetadata? = nil
    ) {
        self.sdkHttpResponse = sdkHttpResponse
        self.embeddings = embeddings
        self.metadata = metadata
    }
}

/// The config for generating an images.
public struct GenerateImagesConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    public var abortSignal: AbortSignal?
    /// Cloud Storage URI used to store the generated images.
    public var outputGcsUri: String?
    /// Description of what to discourage in the generated images.
    public var negativePrompt: String?
    /// Number of images to generate.
    public var numberOfImages: Double?
    /// Aspect ratio of the generated images.
    public var aspectRatio: String?
    /// Controls how much the model adheres to the text prompt.
    public var guidanceScale: Double?
    /// Random seed for image generation.
    public var seed: Double?
    /// Filter level for safety filtering.
    public var safetyFilterLevel: SafetyFilterLevel?
    /// Allows generation of people by the model.
    public var personGeneration: PersonGeneration?
    /// Whether to report the safety scores of each generated image and the positive prompt in the response.
    public var includeSafetyAttributes: Bool?
    /// Whether to include the Responsible AI filter reason if the image is filtered out of the response.
    public var includeRaiReason: Bool?
    /// Language of the text in the prompt.
    public var language: ImagePromptLanguage?
    /// MIME type of the generated image.
    public var outputMimeType: String?
    /// Compression quality of the generated image (for `image/jpeg` only).
    public var outputCompressionQuality: Double?
    /// Whether to add a watermark to the generated images.
    public var addWatermark: Bool?
    /// User specified labels to track billing usage.
    public var labels: [String: String]?
    /// The size of the largest dimension of the generated image.
    public var imageSize: String?
    /// Whether to use the prompt rewriting logic.
    public var enhancePrompt: Bool?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        outputGcsUri: String? = nil,
        negativePrompt: String? = nil,
        numberOfImages: Double? = nil,
        aspectRatio: String? = nil,
        guidanceScale: Double? = nil,
        seed: Double? = nil,
        safetyFilterLevel: SafetyFilterLevel? = nil,
        personGeneration: PersonGeneration? = nil,
        includeSafetyAttributes: Bool? = nil,
        includeRaiReason: Bool? = nil,
        language: ImagePromptLanguage? = nil,
        outputMimeType: String? = nil,
        outputCompressionQuality: Double? = nil,
        addWatermark: Bool? = nil,
        labels: [String: String]? = nil,
        imageSize: String? = nil,
        enhancePrompt: Bool? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.outputGcsUri = outputGcsUri
        self.negativePrompt = negativePrompt
        self.numberOfImages = numberOfImages
        self.aspectRatio = aspectRatio
        self.guidanceScale = guidanceScale
        self.seed = seed
        self.safetyFilterLevel = safetyFilterLevel
        self.personGeneration = personGeneration
        self.includeSafetyAttributes = includeSafetyAttributes
        self.includeRaiReason = includeRaiReason
        self.language = language
        self.outputMimeType = outputMimeType
        self.outputCompressionQuality = outputCompressionQuality
        self.addWatermark = addWatermark
        self.labels = labels
        self.imageSize = imageSize
        self.enhancePrompt = enhancePrompt
    }
}

/// The parameters for generating images.
public struct GenerateImagesParameters: Codable, Sendable {
    /// ID of the model to use.
    public var model: String
    /// Text prompt that typically describes the images to output.
    public var prompt: String
    /// Configuration for generating images.
    public var config: GenerateImagesConfig?

    public init(model: String, prompt: String, config: GenerateImagesConfig? = nil) {
        self.model = model
        self.prompt = prompt
        self.config = config
    }
}

/// An image.
public struct Image: Codable, Sendable {
    /// The Cloud Storage URI of the image.
    public var gcsUri: String?
    /// The image bytes data. Encoded as base64 string.
    public var imageBytes: String?
    /// The MIME type of the image.
    public var mimeType: String?

    public init(gcsUri: String? = nil, imageBytes: String? = nil, mimeType: String? = nil) {
        self.gcsUri = gcsUri
        self.imageBytes = imageBytes
        self.mimeType = mimeType
    }
}

/// Safety attributes of a GeneratedImage or the user-provided prompt.
public struct SafetyAttributes: Codable, Sendable {
    /// List of RAI categories.
    public var categories: [String]?
    /// List of scores of each categories.
    public var scores: [Double]?
    /// Internal use only.
    public var contentType: String?

    public init(categories: [String]? = nil, scores: [Double]? = nil, contentType: String? = nil) {
        self.categories = categories
        self.scores = scores
        self.contentType = contentType
    }
}

/// An output image.
public struct GeneratedImage: Codable, Sendable {
    /// The output image data.
    public var image: Image?
    /// Responsible AI filter reason if the image is filtered out of the response.
    public var raiFilteredReason: String?
    /// Safety attributes of the image.
    public var safetyAttributes: SafetyAttributes?
    /// The rewritten prompt used for the image generation if the prompt enhancer is enabled.
    public var enhancedPrompt: String?

    public init(
        image: Image? = nil,
        raiFilteredReason: String? = nil,
        safetyAttributes: SafetyAttributes? = nil,
        enhancedPrompt: String? = nil
    ) {
        self.image = image
        self.raiFilteredReason = raiFilteredReason
        self.safetyAttributes = safetyAttributes
        self.enhancedPrompt = enhancedPrompt
    }
}

/// The output images response.
public final class GenerateImagesResponse: Codable, @unchecked Sendable {
    /// Used to retain the full HTTP response.
    public var sdkHttpResponse: HttpResponse?
    /// List of generated images.
    public var generatedImages: [GeneratedImage]?
    /// Safety attributes of the positive prompt. Only populated if `include_safety_attributes` is set to True.
    public var positivePromptSafetyAttributes: SafetyAttributes?

    public init(
        sdkHttpResponse: HttpResponse? = nil,
        generatedImages: [GeneratedImage]? = nil,
        positivePromptSafetyAttributes: SafetyAttributes? = nil
    ) {
        self.sdkHttpResponse = sdkHttpResponse
        self.generatedImages = generatedImages
        self.positivePromptSafetyAttributes = positivePromptSafetyAttributes
    }
}

/// Configuration for a Mask reference image.
public struct MaskReferenceConfig: Codable, Sendable {
    /// Prompts the model to generate a mask instead of you needing to provide one.
    public var maskMode: MaskReferenceMode?
    /// A list of up to 5 class ids to use for semantic segmentation.
    public var segmentationClasses: [Double]?
    /// Dilation percentage of the mask provided. Float between 0 and 1.
    public var maskDilation: Double?

    public init(
        maskMode: MaskReferenceMode? = nil,
        segmentationClasses: [Double]? = nil,
        maskDilation: Double? = nil
    ) {
        self.maskMode = maskMode
        self.segmentationClasses = segmentationClasses
        self.maskDilation = maskDilation
    }
}

/// Configuration for a Control reference image.
public struct ControlReferenceConfig: Codable, Sendable {
    /// The type of control reference image to use.
    public var controlType: ControlReferenceType?
    /// Defaults to False. When set to True, the control image will be computed by the model based on the control type.
    public var enableControlImageComputation: Bool?

    public init(
        controlType: ControlReferenceType? = nil,
        enableControlImageComputation: Bool? = nil
    ) {
        self.controlType = controlType
        self.enableControlImageComputation = enableControlImageComputation
    }
}

/// Configuration for a Style reference image.
public struct StyleReferenceConfig: Codable, Sendable {
    /// A text description of the style to use for the generated image.
    public var styleDescription: String?

    public init(styleDescription: String? = nil) {
        self.styleDescription = styleDescription
    }
}

/// Configuration for a Subject reference image.
public struct SubjectReferenceConfig: Codable, Sendable {
    /// The subject type of a subject reference image.
    public var subjectType: SubjectReferenceType?
    /// Subject description for the image.
    public var subjectDescription: String?

    public init(
        subjectType: SubjectReferenceType? = nil,
        subjectDescription: String? = nil
    ) {
        self.subjectType = subjectType
        self.subjectDescription = subjectDescription
    }
}

/// Configuration for editing an image.
public struct EditImageConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    public var abortSignal: AbortSignal?
    /// Cloud Storage URI used to store the generated images.
    public var outputGcsUri: String?
    /// Description of what to discourage in the generated images.
    public var negativePrompt: String?
    /// Number of images to generate.
    public var numberOfImages: Double?
    /// Aspect ratio of the generated images.
    public var aspectRatio: String?
    /// Controls how much the model adheres to the text prompt.
    public var guidanceScale: Double?
    /// Random seed for image generation.
    public var seed: Double?
    /// Filter level for safety filtering.
    public var safetyFilterLevel: SafetyFilterLevel?
    /// Allows generation of people by the model.
    public var personGeneration: PersonGeneration?
    /// Whether to report the safety scores of each generated image and the positive prompt in the response.
    public var includeSafetyAttributes: Bool?
    /// Whether to include the Responsible AI filter reason if the image is filtered out of the response.
    public var includeRaiReason: Bool?
    /// Language of the text in the prompt.
    public var language: ImagePromptLanguage?
    /// MIME type of the generated image.
    public var outputMimeType: String?
    /// Compression quality of the generated image (for `image/jpeg` only).
    public var outputCompressionQuality: Double?
    /// Whether to add a watermark to the generated images.
    public var addWatermark: Bool?
    /// User specified labels to track billing usage.
    public var labels: [String: String]?
    /// Describes the editing mode for the request.
    public var editMode: EditMode?
    /// The number of sampling steps.
    public var baseSteps: Double?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        outputGcsUri: String? = nil,
        negativePrompt: String? = nil,
        numberOfImages: Double? = nil,
        aspectRatio: String? = nil,
        guidanceScale: Double? = nil,
        seed: Double? = nil,
        safetyFilterLevel: SafetyFilterLevel? = nil,
        personGeneration: PersonGeneration? = nil,
        includeSafetyAttributes: Bool? = nil,
        includeRaiReason: Bool? = nil,
        language: ImagePromptLanguage? = nil,
        outputMimeType: String? = nil,
        outputCompressionQuality: Double? = nil,
        addWatermark: Bool? = nil,
        labels: [String: String]? = nil,
        editMode: EditMode? = nil,
        baseSteps: Double? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.outputGcsUri = outputGcsUri
        self.negativePrompt = negativePrompt
        self.numberOfImages = numberOfImages
        self.aspectRatio = aspectRatio
        self.guidanceScale = guidanceScale
        self.seed = seed
        self.safetyFilterLevel = safetyFilterLevel
        self.personGeneration = personGeneration
        self.includeSafetyAttributes = includeSafetyAttributes
        self.includeRaiReason = includeRaiReason
        self.language = language
        self.outputMimeType = outputMimeType
        self.outputCompressionQuality = outputCompressionQuality
        self.addWatermark = addWatermark
        self.labels = labels
        self.editMode = editMode
        self.baseSteps = baseSteps
    }
}

/// Response for the request to edit an image.
public final class EditImageResponse: Codable, @unchecked Sendable {
    /// Used to retain the full HTTP response.
    public var sdkHttpResponse: HttpResponse?
    /// Generated images.
    public var generatedImages: [GeneratedImage]?

    public init(
        sdkHttpResponse: HttpResponse? = nil,
        generatedImages: [GeneratedImage]? = nil
    ) {
        self.sdkHttpResponse = sdkHttpResponse
        self.generatedImages = generatedImages
    }
}

public final class UpscaleImageResponse: Codable, @unchecked Sendable {
    /// Used to retain the full HTTP response.
    public var sdkHttpResponse: HttpResponse?
    /// Generated images.
    public var generatedImages: [GeneratedImage]?

    public init(
        sdkHttpResponse: HttpResponse? = nil,
        generatedImages: [GeneratedImage]? = nil
    ) {
        self.sdkHttpResponse = sdkHttpResponse
        self.generatedImages = generatedImages
    }
}

/// An image of the product.
public struct ProductImage: Codable, Sendable {
    /// An image of the product to be recontextualized.
    public var productImage: Image?

    public init(productImage: Image? = nil) {
        self.productImage = productImage
    }
}

/// A set of source input(s) for image recontextualization.
public struct RecontextImageSource: Codable, Sendable {
    /// A text prompt for guiding the model during image recontextualization. Not supported for Virtual Try-On.
    public var prompt: String?
    /// Image of the person or subject who will be wearing the product(s).
    public var personImage: Image?
    /// A list of product images.
    public var productImages: [ProductImage]?

    public init(
        prompt: String? = nil,
        personImage: Image? = nil,
        productImages: [ProductImage]? = nil
    ) {
        self.prompt = prompt
        self.personImage = personImage
        self.productImages = productImages
    }
}

/// Configuration for recontextualizing an image.
public struct RecontextImageConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    public var abortSignal: AbortSignal?
    /// Number of images to generate.
    public var numberOfImages: Double?
    /// The number of sampling steps.
    public var baseSteps: Double?
    /// Cloud Storage URI used to store the generated images.
    public var outputGcsUri: String?
    /// Random seed for image generation.
    public var seed: Double?
    /// Filter level for safety filtering.
    public var safetyFilterLevel: SafetyFilterLevel?
    /// Whether allow to generate person images, and restrict to specific ages.
    public var personGeneration: PersonGeneration?
    /// Whether to add a SynthID watermark to the generated images.
    public var addWatermark: Bool?
    /// MIME type of the generated image.
    public var outputMimeType: String?
    /// Compression quality of the generated image (for `image/jpeg` only).
    public var outputCompressionQuality: Double?
    /// Whether to use the prompt rewriting logic.
    public var enhancePrompt: Bool?
    /// User specified labels to track billing usage.
    public var labels: [String: String]?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        numberOfImages: Double? = nil,
        baseSteps: Double? = nil,
        outputGcsUri: String? = nil,
        seed: Double? = nil,
        safetyFilterLevel: SafetyFilterLevel? = nil,
        personGeneration: PersonGeneration? = nil,
        addWatermark: Bool? = nil,
        outputMimeType: String? = nil,
        outputCompressionQuality: Double? = nil,
        enhancePrompt: Bool? = nil,
        labels: [String: String]? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.numberOfImages = numberOfImages
        self.baseSteps = baseSteps
        self.outputGcsUri = outputGcsUri
        self.seed = seed
        self.safetyFilterLevel = safetyFilterLevel
        self.personGeneration = personGeneration
        self.addWatermark = addWatermark
        self.outputMimeType = outputMimeType
        self.outputCompressionQuality = outputCompressionQuality
        self.enhancePrompt = enhancePrompt
        self.labels = labels
    }
}

/// The parameters for recontextualizing an image.
public struct RecontextImageParameters: Codable, Sendable {
    /// ID of the model to use.
    public var model: String
    /// A set of source input(s) for image recontextualization.
    public var source: RecontextImageSource
    /// Configuration for image recontextualization.
    public var config: RecontextImageConfig?

    public init(
        model: String,
        source: RecontextImageSource,
        config: RecontextImageConfig? = nil
    ) {
        self.model = model
        self.source = source
        self.config = config
    }
}

/// The output images response.
public final class RecontextImageResponse: Codable, @unchecked Sendable {
    /// List of generated images.
    public var generatedImages: [GeneratedImage]?

    public init(generatedImages: [GeneratedImage]? = nil) {
        self.generatedImages = generatedImages
    }
}

/// An image mask representing a brush scribble.
public struct ScribbleImage: Codable, Sendable {
    /// The brush scribble to guide segmentation. Valid for the interactive mode.
    public var image: Image?

    public init(image: Image? = nil) {
        self.image = image
    }
}

/// A set of source input(s) for image segmentation.
public struct SegmentImageSource: Codable, Sendable {
    /// A text prompt for guiding the model during image segmentation.
    public var prompt: String?
    /// The image to be segmented.
    public var image: Image?
    /// The brush scribble to guide segmentation.
    public var scribbleImage: ScribbleImage?

    public init(
        prompt: String? = nil,
        image: Image? = nil,
        scribbleImage: ScribbleImage? = nil
    ) {
        self.prompt = prompt
        self.image = image
        self.scribbleImage = scribbleImage
    }
}

/// Configuration for segmenting an image.
public struct SegmentImageConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    public var abortSignal: AbortSignal?
    /// The segmentation mode to use.
    public var mode: SegmentMode?
    /// The maximum number of predictions to return up to, by top confidence score.
    public var maxPredictions: Double?
    /// The confidence score threshold for the detections as a decimal value.
    public var confidenceThreshold: Double?
    /// A decimal value representing how much dilation to apply to the masks.
    public var maskDilation: Double?
    /// The binary color threshold to apply to the masks.
    public var binaryColorThreshold: Double?
    /// User specified labels to track billing usage.
    public var labels: [String: String]?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        mode: SegmentMode? = nil,
        maxPredictions: Double? = nil,
        confidenceThreshold: Double? = nil,
        maskDilation: Double? = nil,
        binaryColorThreshold: Double? = nil,
        labels: [String: String]? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.mode = mode
        self.maxPredictions = maxPredictions
        self.confidenceThreshold = confidenceThreshold
        self.maskDilation = maskDilation
        self.binaryColorThreshold = binaryColorThreshold
        self.labels = labels
    }
}

/// The parameters for segmenting an image.
public struct SegmentImageParameters: Codable, Sendable {
    /// ID of the model to use.
    public var model: String
    /// A set of source input(s) for image segmentation.
    public var source: SegmentImageSource
    /// Configuration for image segmentation.
    public var config: SegmentImageConfig?

    public init(
        model: String,
        source: SegmentImageSource,
        config: SegmentImageConfig? = nil
    ) {
        self.model = model
        self.source = source
        self.config = config
    }
}

/// An entity representing the segmented area.
public struct EntityLabel: Codable, Sendable {
    /// The label of the segmented entity.
    public var label: String?
    /// The confidence score of the detected label.
    public var score: Double?

    public init(label: String? = nil, score: Double? = nil) {
        self.label = label
        self.score = score
    }
}

/// A generated image mask.
public struct GeneratedImageMask: Codable, Sendable {
    /// The generated image mask.
    public var mask: Image?
    /// The detected entities on the segmented area.
    public var labels: [EntityLabel]?

    public init(mask: Image? = nil, labels: [EntityLabel]? = nil) {
        self.mask = mask
        self.labels = labels
    }
}

/// The output images response.
public final class SegmentImageResponse: Codable, @unchecked Sendable {
    /// List of generated image masks.
    public var generatedMasks: [GeneratedImageMask]?

    public init(generatedMasks: [GeneratedImageMask]? = nil) {
        self.generatedMasks = generatedMasks
    }
}
