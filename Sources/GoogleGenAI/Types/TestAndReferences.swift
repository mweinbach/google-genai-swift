// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

public struct TestTableItem: Codable, Sendable {
    /// The name of the test. This is used to derive the replay id.
    public var name: String?
    /// The parameters to the test. Use pydantic models.
    public var parameters: [String: JSONValue]?
    /// Expects an exception for MLDev matching the string.
    public var exceptionIfMldev: String?
    /// Expects an exception for Vertex matching the string.
    public var exceptionIfVertex: String?
    /// Use if you don't want to use the default replay id which is derived
    /// from the test name.
    public var overrideReplayId: String?
    /// True if the parameters contain an unsupported union type. This test
    /// will be skipped for languages that do not support the union type.
    public var hasUnion: Bool?
    /// When set to a reason string, this test will be skipped in the API
    /// mode. Use this flag for tests that can not be reproduced with the
    /// real API. E.g. a test that deletes a resource.
    public var skipInApiMode: String?
    /// Keys to ignore when comparing the request and response. This is
    /// useful for tests that are not deterministic.
    public var ignoreKeys: [String]?

    public init(
        name: String? = nil,
        parameters: [String: JSONValue]? = nil,
        exceptionIfMldev: String? = nil,
        exceptionIfVertex: String? = nil,
        overrideReplayId: String? = nil,
        hasUnion: Bool? = nil,
        skipInApiMode: String? = nil,
        ignoreKeys: [String]? = nil
    ) {
        self.name = name
        self.parameters = parameters
        self.exceptionIfMldev = exceptionIfMldev
        self.exceptionIfVertex = exceptionIfVertex
        self.overrideReplayId = overrideReplayId
        self.hasUnion = hasUnion
        self.skipInApiMode = skipInApiMode
        self.ignoreKeys = ignoreKeys
    }
}

public struct TestTableFile: Codable, Sendable {
    public var comment: String?
    public var testMethod: String?
    public var parameterNames: [String]?
    public var testTable: [TestTableItem]?

    public init(
        comment: String? = nil,
        testMethod: String? = nil,
        parameterNames: [String]? = nil,
        testTable: [TestTableItem]? = nil
    ) {
        self.comment = comment
        self.testMethod = testMethod
        self.parameterNames = parameterNames
        self.testTable = testTable
    }
}

/// Represents a single request in a replay.
public struct ReplayRequest: Codable, Sendable {
    public var method: String?
    public var url: String?
    public var headers: [String: String]?
    public var bodySegments: [[String: JSONValue]]?

    public init(
        method: String? = nil,
        url: String? = nil,
        headers: [String: String]? = nil,
        bodySegments: [[String: JSONValue]]? = nil
    ) {
        self.method = method
        self.url = url
        self.headers = headers
        self.bodySegments = bodySegments
    }
}

/// Represents a single response in a replay.
public final class ReplayResponse: Codable, @unchecked Sendable {
    public var statusCode: Double?
    public var headers: [String: String]?
    public var bodySegments: [[String: JSONValue]]?
    public var sdkResponseSegments: [[String: JSONValue]]?

    public init(
        statusCode: Double? = nil,
        headers: [String: String]? = nil,
        bodySegments: [[String: JSONValue]]? = nil,
        sdkResponseSegments: [[String: JSONValue]]? = nil
    ) {
        self.statusCode = statusCode
        self.headers = headers
        self.bodySegments = bodySegments
        self.sdkResponseSegments = sdkResponseSegments
    }
}

/// Represents a single interaction, request and response in a replay.
public struct ReplayInteraction: Codable, Sendable {
    public var request: ReplayRequest?
    public var response: ReplayResponse?

    public init(request: ReplayRequest? = nil, response: ReplayResponse? = nil) {
        self.request = request
        self.response = response
    }
}

/// Represents a recorded session.
public struct ReplayFile: Codable, Sendable {
    public var replayId: String?
    public var interactions: [ReplayInteraction]?

    public init(replayId: String? = nil, interactions: [ReplayInteraction]? = nil) {
        self.replayId = replayId
        self.interactions = interactions
    }
}

/// Used to override the default configuration.
public struct UploadFileConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    ///
    /// NOTE: AbortSignal is a client-only operation. Using it to cancel an
    /// operation will not cancel the request in the service. You will still
    /// be charged usage for any applicable operations.
    public var abortSignal: AbortSignal?
    /// The name of the file in the destination (e.g., 'files/sample-image'.
    /// If not provided one will be generated.
    public var name: String?
    /// mime_type: The MIME type of the file. If not provided, it will be
    /// inferred from the file extension.
    public var mimeType: String?
    /// Optional display name of the file.
    public var displayName: String?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        name: String? = nil,
        mimeType: String? = nil,
        displayName: String? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.name = name
        self.mimeType = mimeType
        self.displayName = displayName
    }
}

/// Used to override the default configuration.
public struct DownloadFileConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    ///
    /// NOTE: AbortSignal is a client-only operation. Using it to cancel an
    /// operation will not cancel the request in the service. You will still
    /// be charged usage for any applicable operations.
    public var abortSignal: AbortSignal?

    public init(httpOptions: HttpOptions? = nil, abortSignal: AbortSignal? = nil) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

/// Parameters used to download a file.
public struct DownloadFileParameters: Codable, Sendable {
    /// The file to download. It can be a file name, a file object or a
    /// generated video.
    public var file: DownloadableFileUnion
    /// Location where the file should be downloaded to.
    public var downloadPath: String
    /// Configuration to for the download operation.
    public var config: DownloadFileConfig?

    public init(
        file: DownloadableFileUnion,
        downloadPath: String,
        config: DownloadFileConfig? = nil
    ) {
        self.file = file
        self.downloadPath = downloadPath
        self.config = config
    }
}

/// Configuration for upscaling an image.
///
/// For more information on this configuration, refer to the [Imagen API
/// reference documentation](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/imagen-api).
public struct UpscaleImageConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    ///
    /// NOTE: AbortSignal is a client-only operation. Using it to cancel an
    /// operation will not cancel the request in the service. You will still
    /// be charged usage for any applicable operations.
    public var abortSignal: AbortSignal?
    /// Cloud Storage URI used to store the generated images.
    public var outputGcsUri: String?
    /// Filter level for safety filtering.
    public var safetyFilterLevel: SafetyFilterLevel?
    /// Allows generation of people by the model.
    public var personGeneration: PersonGeneration?
    /// Whether to include a reason for filtered-out images in the response.
    public var includeRaiReason: Bool?
    /// The image format that the output should be saved as.
    public var outputMimeType: String?
    /// The level of compression. Only applicable if the
    /// ``output_mime_type`` is ``image/jpeg``.
    public var outputCompressionQuality: Double?
    /// Whether to add an image enhancing step before upscaling.
    /// It is expected to suppress the noise and JPEG compression artifacts
    /// from the input image.
    public var enhanceInputImage: Bool?
    /// With a higher image preservation factor, the original image
    /// pixels are more respected. With a lower image preservation factor,
    /// the output image will have be more different from the input image,
    /// but with finer details and less noise.
    public var imagePreservationFactor: Double?
    /// User specified labels to track billing usage.
    public var labels: [String: String]?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        outputGcsUri: String? = nil,
        safetyFilterLevel: SafetyFilterLevel? = nil,
        personGeneration: PersonGeneration? = nil,
        includeRaiReason: Bool? = nil,
        outputMimeType: String? = nil,
        outputCompressionQuality: Double? = nil,
        enhanceInputImage: Bool? = nil,
        imagePreservationFactor: Double? = nil,
        labels: [String: String]? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.outputGcsUri = outputGcsUri
        self.safetyFilterLevel = safetyFilterLevel
        self.personGeneration = personGeneration
        self.includeRaiReason = includeRaiReason
        self.outputMimeType = outputMimeType
        self.outputCompressionQuality = outputCompressionQuality
        self.enhanceInputImage = enhanceInputImage
        self.imagePreservationFactor = imagePreservationFactor
        self.labels = labels
    }
}

/// User-facing config UpscaleImageParameters.
public struct UpscaleImageParameters: Codable, Sendable {
    /// The model to use.
    public var model: String
    /// The input image to upscale.
    public var image: Image
    /// The factor to upscale the image (x2 or x4).
    public var upscaleFactor: String
    /// Configuration for upscaling.
    public var config: UpscaleImageConfig?

    public init(
        model: String,
        image: Image,
        upscaleFactor: String,
        config: UpscaleImageConfig? = nil
    ) {
        self.model = model
        self.image = image
        self.upscaleFactor = upscaleFactor
        self.config = config
    }
}

/// A raw reference image.
///
/// A raw reference image represents the base image to edit, provided by the
/// user. It can optionally be provided in addition to a mask reference image or
/// a style reference image.
public final class RawReferenceImage: Codable, @unchecked Sendable {
    /// The reference image for the editing operation.
    public var referenceImage: Image?
    /// The id of the reference image.
    public var referenceId: Double?
    /// The type of the reference image. Only set by the SDK.
    public var referenceType: String?

    public init(
        referenceImage: Image? = nil,
        referenceId: Double? = nil,
        referenceType: String? = nil
    ) {
        self.referenceImage = referenceImage
        self.referenceId = referenceId
        self.referenceType = referenceType
    }

    /// Internal method to convert to ReferenceImageAPIInternal.
    public func toReferenceImageAPI() -> ReferenceImageAPIInternal {
        return _rawReferenceImageToAPIInternal(
            referenceImage: referenceImage,
            referenceId: referenceId
        )
    }
}

/// A mask reference image.
///
/// This encapsulates either a mask image provided by the user and configs for
/// the user provided mask, or only config parameters for the model to generate
/// a mask.
///
/// A mask image is an image whose non-zero values indicate where to edit the
/// base image. If the user provides a mask image, the mask must be in the same
/// dimensions as the raw image.
public final class MaskReferenceImage: Codable, @unchecked Sendable {
    /// The reference image for the editing operation.
    public var referenceImage: Image?
    /// The id of the reference image.
    public var referenceId: Double?
    /// The type of the reference image. Only set by the SDK.
    public var referenceType: String?
    /// Configuration for the mask reference image.
    public var config: MaskReferenceConfig?

    public init(
        referenceImage: Image? = nil,
        referenceId: Double? = nil,
        referenceType: String? = nil,
        config: MaskReferenceConfig? = nil
    ) {
        self.referenceImage = referenceImage
        self.referenceId = referenceId
        self.referenceType = referenceType
        self.config = config
    }

    /// Internal method to convert to ReferenceImageAPIInternal.
    public func toReferenceImageAPI() -> ReferenceImageAPIInternal {
        return _maskReferenceImageToAPIInternal(
            referenceImage: referenceImage,
            referenceId: referenceId,
            config: config
        )
    }
}

/// A control reference image.
///
/// The image of the control reference image is either a control image provided
/// by the user, or a regular image which the backend will use to generate a
/// control image of. In the case of the latter, the
/// enable_control_image_computation field in the config should be set to True.
///
/// A control image is an image that represents a sketch image of areas for the
/// model to fill in based on the prompt.
public final class ControlReferenceImage: Codable, @unchecked Sendable {
    /// The reference image for the editing operation.
    public var referenceImage: Image?
    /// The id of the reference image.
    public var referenceId: Double?
    /// The type of the reference image. Only set by the SDK.
    public var referenceType: String?
    /// Configuration for the control reference image.
    public var config: ControlReferenceConfig?

    public init(
        referenceImage: Image? = nil,
        referenceId: Double? = nil,
        referenceType: String? = nil,
        config: ControlReferenceConfig? = nil
    ) {
        self.referenceImage = referenceImage
        self.referenceId = referenceId
        self.referenceType = referenceType
        self.config = config
    }

    /// Internal method to convert to ReferenceImageAPIInternal.
    public func toReferenceImageAPI() -> ReferenceImageAPIInternal {
        return _controlReferenceImageToAPIInternal(
            referenceImage: referenceImage,
            referenceId: referenceId,
            config: config
        )
    }
}

/// A style reference image.
///
/// This encapsulates a style reference image provided by the user, and
/// additionally optional config parameters for the style reference image.
///
/// A raw reference image can also be provided as a destination for the style
/// to be applied to.
public final class StyleReferenceImage: Codable, @unchecked Sendable {
    /// The reference image for the editing operation.
    public var referenceImage: Image?
    /// The id of the reference image.
    public var referenceId: Double?
    /// The type of the reference image. Only set by the SDK.
    public var referenceType: String?
    /// Configuration for the style reference image.
    public var config: StyleReferenceConfig?

    public init(
        referenceImage: Image? = nil,
        referenceId: Double? = nil,
        referenceType: String? = nil,
        config: StyleReferenceConfig? = nil
    ) {
        self.referenceImage = referenceImage
        self.referenceId = referenceId
        self.referenceType = referenceType
        self.config = config
    }

    /// Internal method to convert to ReferenceImageAPIInternal.
    public func toReferenceImageAPI() -> ReferenceImageAPIInternal {
        return _styleReferenceImageToAPIInternal(
            referenceImage: referenceImage,
            referenceId: referenceId,
            config: config
        )
    }
}

/// A subject reference image.
///
/// This encapsulates a subject reference image provided by the user, and
/// additionally optional config parameters for the subject reference image.
///
/// A raw reference image can also be provided as a destination for the subject
/// to be applied to.
public final class SubjectReferenceImage: Codable, @unchecked Sendable {
    /// The reference image for the editing operation.
    public var referenceImage: Image?
    /// The id of the reference image.
    public var referenceId: Double?
    /// The type of the reference image. Only set by the SDK.
    public var referenceType: String?
    /// Configuration for the subject reference image.
    public var config: SubjectReferenceConfig?

    public init(
        referenceImage: Image? = nil,
        referenceId: Double? = nil,
        referenceType: String? = nil,
        config: SubjectReferenceConfig? = nil
    ) {
        self.referenceImage = referenceImage
        self.referenceId = referenceId
        self.referenceType = referenceType
        self.config = config
    }

    /// Internal method to convert to ReferenceImageAPIInternal.
    public func toReferenceImageAPI() -> ReferenceImageAPIInternal {
        return _subjectReferenceImageToAPIInternal(
            referenceImage: referenceImage,
            referenceId: referenceId,
            config: config
        )
    }
}

/// A content reference image.
///
/// A content reference image represents a subject to reference (ex. person,
/// product, animal) provided by the user. It can optionally be provided in
/// addition to a style reference image (ex. background, style reference).
public final class ContentReferenceImage: Codable, @unchecked Sendable {
    /// The reference image for the editing operation.
    public var referenceImage: Image?
    /// The id of the reference image.
    public var referenceId: Double?
    /// The type of the reference image. Only set by the SDK.
    public var referenceType: String?

    public init(
        referenceImage: Image? = nil,
        referenceId: Double? = nil,
        referenceType: String? = nil
    ) {
        self.referenceImage = referenceImage
        self.referenceId = referenceId
        self.referenceType = referenceType
    }

    /// Internal method to convert to ReferenceImageAPIInternal.
    public func toReferenceImageAPI() -> ReferenceImageAPIInternal {
        return _contentReferenceImageToAPIInternal(
            referenceImage: referenceImage,
            referenceId: referenceId
        )
    }
}

// MARK: - Reference-image → ReferenceImageAPIInternal helpers
//
// Mirrors the TS reference-image flatten step that consolidates per-class
// config fields into a single shape the wire-format converter consumes.
// The TS `referenceType` strings ("REFERENCE_TYPE_RAW", "_MASK", "_CONTROL",
// "_STYLE", "_SUBJECT", "_CONTENT") are emitted here so downstream
// converters can dispatch on them.

internal func _rawReferenceImageToAPIInternal(
    referenceImage: Image?,
    referenceId: Double?
) -> ReferenceImageAPIInternal {
    ReferenceImageAPIInternal(
        referenceImage: referenceImage,
        referenceId: referenceId,
        referenceType: "REFERENCE_TYPE_RAW"
    )
}

internal func _maskReferenceImageToAPIInternal(
    referenceImage: Image?,
    referenceId: Double?,
    config: MaskReferenceConfig?
) -> ReferenceImageAPIInternal {
    ReferenceImageAPIInternal(
        referenceImage: referenceImage,
        referenceId: referenceId,
        referenceType: "REFERENCE_TYPE_MASK",
        maskImageConfig: config
    )
}

internal func _controlReferenceImageToAPIInternal(
    referenceImage: Image?,
    referenceId: Double?,
    config: ControlReferenceConfig?
) -> ReferenceImageAPIInternal {
    ReferenceImageAPIInternal(
        referenceImage: referenceImage,
        referenceId: referenceId,
        referenceType: "REFERENCE_TYPE_CONTROL",
        controlImageConfig: config
    )
}

internal func _styleReferenceImageToAPIInternal(
    referenceImage: Image?,
    referenceId: Double?,
    config: StyleReferenceConfig?
) -> ReferenceImageAPIInternal {
    ReferenceImageAPIInternal(
        referenceImage: referenceImage,
        referenceId: referenceId,
        referenceType: "REFERENCE_TYPE_STYLE",
        styleImageConfig: config
    )
}

internal func _subjectReferenceImageToAPIInternal(
    referenceImage: Image?,
    referenceId: Double?,
    config: SubjectReferenceConfig?
) -> ReferenceImageAPIInternal {
    ReferenceImageAPIInternal(
        referenceImage: referenceImage,
        referenceId: referenceId,
        referenceType: "REFERENCE_TYPE_SUBJECT",
        subjectImageConfig: config
    )
}

internal func _contentReferenceImageToAPIInternal(
    referenceImage: Image?,
    referenceId: Double?
) -> ReferenceImageAPIInternal {
    ReferenceImageAPIInternal(
        referenceImage: referenceImage,
        referenceId: referenceId,
        referenceType: "REFERENCE_TYPE_CONTENT"
    )
}
