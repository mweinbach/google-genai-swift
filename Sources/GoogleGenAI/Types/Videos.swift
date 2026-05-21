// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// A generated video.
public struct Video: Codable, Sendable {
    /// Path to another storage.
    public var uri: String?
    /// Video bytes. Encoded as base64 string.
    public var videoBytes: String?
    /// Video encoding, for example `video/mp4`.
    public var mimeType: String?

    public init(uri: String? = nil, videoBytes: String? = nil, mimeType: String? = nil) {
        self.uri = uri
        self.videoBytes = videoBytes
        self.mimeType = mimeType
    }
}

/// A set of source input(s) for video generation.
public struct GenerateVideosSource: Codable, Sendable {
    /// The text prompt for generating the videos.
    public var prompt: String?
    /// The input image for generating the videos.
    public var image: Image?
    /// The input video for video extension use cases.
    public var video: Video?

    public init(prompt: String? = nil, image: Image? = nil, video: Video? = nil) {
        self.prompt = prompt
        self.image = image
        self.video = video
    }
}

/// A reference image for video generation.
public struct VideoGenerationReferenceImage: Codable, Sendable {
    /// The reference image.
    public var image: Image?
    /// The type of the reference image, which defines how the reference image will be used to generate the video.
    public var referenceType: VideoGenerationReferenceType?

    public init(image: Image? = nil, referenceType: VideoGenerationReferenceType? = nil) {
        self.image = image
        self.referenceType = referenceType
    }
}

/// A mask for video generation.
public struct VideoGenerationMask: Codable, Sendable {
    /// The image mask to use for generating videos.
    public var image: Image?
    /// Describes how the mask will be used.
    public var maskMode: VideoGenerationMaskMode?

    public init(image: Image? = nil, maskMode: VideoGenerationMaskMode? = nil) {
        self.image = image
        self.maskMode = maskMode
    }
}

/// Configuration for webhook notifications.
public struct WebhookConfig: Codable, Sendable {
    /// The webhook URIs to receive notifications.
    public var uris: [String]?
    /// User metadata that will be included in each webhook event notification.
    public var userMetadata: [String: JSONValue]?

    public init(uris: [String]? = nil, userMetadata: [String: JSONValue]? = nil) {
        self.uris = uris
        self.userMetadata = userMetadata
    }
}

/// Configuration for generating videos.
public struct GenerateVideosConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    public var abortSignal: AbortSignal?
    /// Number of output videos.
    public var numberOfVideos: Double?
    /// The gcs bucket where to save the generated videos.
    public var outputGcsUri: String?
    /// Frames per second for video generation.
    public var fps: Double?
    /// Duration of the clip for video generation in seconds.
    public var durationSeconds: Double?
    /// The RNG seed.
    public var seed: Double?
    /// The aspect ratio for the generated video.
    public var aspectRatio: String?
    /// The resolution for the generated video.
    public var resolution: String?
    /// Whether allow to generate person videos, and restrict to specific ages.
    public var personGeneration: String?
    /// The pubsub topic where to publish the video generation progress.
    public var pubsubTopic: String?
    /// Explicitly state what should not be included in the generated videos.
    public var negativePrompt: String?
    /// Whether to use the prompt rewriting logic.
    public var enhancePrompt: Bool?
    /// Whether to generate audio along with the video.
    public var generateAudio: Bool?
    /// Image to use as the last frame of generated videos.
    public var lastFrame: Image?
    /// The images to use as the references to generate the videos.
    public var referenceImages: [VideoGenerationReferenceImage]?
    /// The mask to use for generating videos.
    public var mask: VideoGenerationMask?
    /// Compression quality of the generated videos.
    public var compressionQuality: VideoCompressionQuality?
    /// User specified labels to track billing usage.
    public var labels: [String: String]?
    /// Webhook configuration for receiving notifications when the video generation operation completes.
    public var webhookConfig: WebhookConfig?
    /// Resize mode of the image input for video generation.
    public var resizeMode: ImageResizeMode?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        numberOfVideos: Double? = nil,
        outputGcsUri: String? = nil,
        fps: Double? = nil,
        durationSeconds: Double? = nil,
        seed: Double? = nil,
        aspectRatio: String? = nil,
        resolution: String? = nil,
        personGeneration: String? = nil,
        pubsubTopic: String? = nil,
        negativePrompt: String? = nil,
        enhancePrompt: Bool? = nil,
        generateAudio: Bool? = nil,
        lastFrame: Image? = nil,
        referenceImages: [VideoGenerationReferenceImage]? = nil,
        mask: VideoGenerationMask? = nil,
        compressionQuality: VideoCompressionQuality? = nil,
        labels: [String: String]? = nil,
        webhookConfig: WebhookConfig? = nil,
        resizeMode: ImageResizeMode? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.numberOfVideos = numberOfVideos
        self.outputGcsUri = outputGcsUri
        self.fps = fps
        self.durationSeconds = durationSeconds
        self.seed = seed
        self.aspectRatio = aspectRatio
        self.resolution = resolution
        self.personGeneration = personGeneration
        self.pubsubTopic = pubsubTopic
        self.negativePrompt = negativePrompt
        self.enhancePrompt = enhancePrompt
        self.generateAudio = generateAudio
        self.lastFrame = lastFrame
        self.referenceImages = referenceImages
        self.mask = mask
        self.compressionQuality = compressionQuality
        self.labels = labels
        self.webhookConfig = webhookConfig
        self.resizeMode = resizeMode
    }
}

/// Class that represents the parameters for generating videos.
public struct GenerateVideosParameters: Codable, Sendable {
    /// ID of the model to use.
    public var model: String
    /// The text prompt for generating the videos.
    public var prompt: String?
    /// The input image for generating the videos.
    public var image: Image?
    /// The input video for video extension use cases.
    public var video: Video?
    /// A set of source input(s) for video generation.
    public var source: GenerateVideosSource?
    /// Configuration for generating videos.
    public var config: GenerateVideosConfig?

    public init(
        model: String,
        prompt: String? = nil,
        image: Image? = nil,
        video: Video? = nil,
        source: GenerateVideosSource? = nil,
        config: GenerateVideosConfig? = nil
    ) {
        self.model = model
        self.prompt = prompt
        self.image = image
        self.video = video
        self.source = source
        self.config = config
    }
}

/// A generated video.
public struct GeneratedVideo: Codable, Sendable {
    /// The output video.
    public var video: Video?

    public init(video: Video? = nil) {
        self.video = video
    }
}

/// Response with generated videos.
public final class GenerateVideosResponse: Codable, @unchecked Sendable {
    /// List of the generated videos.
    public var generatedVideos: [GeneratedVideo]?
    /// Returns if any videos were filtered due to RAI policies.
    public var raiMediaFilteredCount: Double?
    /// Returns rai failure reasons if any.
    public var raiMediaFilteredReasons: [String]?

    public init(
        generatedVideos: [GeneratedVideo]? = nil,
        raiMediaFilteredCount: Double? = nil,
        raiMediaFilteredReasons: [String]? = nil
    ) {
        self.generatedVideos = generatedVideos
        self.raiMediaFilteredCount = raiMediaFilteredCount
        self.raiMediaFilteredReasons = raiMediaFilteredReasons
    }
}

/// A long-running operation.
public struct Operation<T: Codable & Sendable>: Codable, Sendable {
    /// The server-assigned name, which is only unique within the same service that originally returns it.
    public var name: String?
    /// Service-specific metadata associated with the operation.
    public var metadata: [String: JSONValue]?
    /// If the value is `false`, it means the operation is still in progress.
    public var done: Bool?
    /// The error result of the operation in case of failure or cancellation.
    public var error: [String: JSONValue]?
    /// The response if the operation is successful.
    public var response: T?

    public init(
        name: String? = nil,
        metadata: [String: JSONValue]? = nil,
        done: Bool? = nil,
        error: [String: JSONValue]? = nil,
        response: T? = nil
    ) {
        self.name = name
        self.metadata = metadata
        self.done = done
        self.error = error
        self.response = response
    }
}

/// A video generation operation.
public final class GenerateVideosOperation: Codable, @unchecked Sendable {
    /// The server-assigned name, which is only unique within the same service that originally returns it.
    public var name: String?
    /// Service-specific metadata associated with the operation.
    public var metadata: [String: JSONValue]?
    /// If the value is `false`, it means the operation is still in progress.
    public var done: Bool?
    /// The error result of the operation in case of failure or cancellation.
    public var error: [String: JSONValue]?
    /// The generated videos.
    public var response: GenerateVideosResponse?
    /// The full HTTP response.
    public var sdkHttpResponse: HttpResponse?

    public init(
        name: String? = nil,
        metadata: [String: JSONValue]? = nil,
        done: Bool? = nil,
        error: [String: JSONValue]? = nil,
        response: GenerateVideosResponse? = nil,
        sdkHttpResponse: HttpResponse? = nil
    ) {
        self.name = name
        self.metadata = metadata
        self.done = done
        self.error = error
        self.response = response
        self.sdkHttpResponse = sdkHttpResponse
    }

    /// Instantiates an Operation of the same type as the one being called with the fields set from the API response.
    public static func fromAPIResponse(
        apiClient: ApiClient,
        apiResponse: [String: JSONValue],
        isVertexAI: Bool
    ) -> GenerateVideosOperation {
        let operation = GenerateVideosOperation()
        let response: [String: JSONValue]
        do {
            var parent: [String: JSONValue] = [:]
            if isVertexAI {
                response = try generateVideosOperationFromVertex(apiClient: apiClient, fromObject: apiResponse, parentObject: &parent)
            } else {
                response = try generateVideosOperationFromMldev(apiClient: apiClient, fromObject: apiResponse, parentObject: &parent)
            }
        } catch {
            return operation
        }
        // Object.assign(operation, response) — mirror by decoding then copying fields.
        if let data = try? JSONEncoder().encode(response),
           let decoded = try? JSONDecoder().decode(GenerateVideosOperation.self, from: data) {
            operation.name = decoded.name
            operation.metadata = decoded.metadata
            operation.done = decoded.done
            operation.error = decoded.error
            operation.response = decoded.response
            operation.sdkHttpResponse = decoded.sdkHttpResponse
        }
        return operation
    }
}

