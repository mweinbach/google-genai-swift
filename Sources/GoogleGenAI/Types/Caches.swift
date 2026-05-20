// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Optional configuration for cached content creation.
public struct CreateCachedContentConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    public var abortSignal: AbortSignal?
    /// The TTL for this resource. Duration string, e.g. "3.5s".
    public var ttl: String?
    /// Timestamp of when this resource is considered expired (RFC 3339).
    public var expireTime: String?
    /// The user-generated meaningful display name of the cached content.
    public var displayName: String?
    /// The content to cache.
    public var contents: ContentListUnion?
    /// Developer set system instruction.
    public var systemInstruction: ContentUnion?
    /// A list of `Tools` the model may use to generate the next response.
    public var tools: [Tool]?
    /// Configuration for the tools to use.
    public var toolConfig: ToolConfig?
    /// The Cloud KMS resource identifier of the customer managed encryption key.
    public var kmsKeyName: String?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        ttl: String? = nil,
        expireTime: String? = nil,
        displayName: String? = nil,
        contents: ContentListUnion? = nil,
        systemInstruction: ContentUnion? = nil,
        tools: [Tool]? = nil,
        toolConfig: ToolConfig? = nil,
        kmsKeyName: String? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.ttl = ttl
        self.expireTime = expireTime
        self.displayName = displayName
        self.contents = contents
        self.systemInstruction = systemInstruction
        self.tools = tools
        self.toolConfig = toolConfig
        self.kmsKeyName = kmsKeyName
    }
}

/// Parameters for `caches.create` method.
public struct CreateCachedContentParameters: Codable, Sendable {
    /// ID of the model to use. Example: gemini-2.0-flash.
    public var model: String
    /// Configuration that contains optional parameters.
    public var config: CreateCachedContentConfig?

    public init(model: String, config: CreateCachedContentConfig? = nil) {
        self.model = model
        self.config = config
    }
}

/// Metadata on the usage of the cached content.
public struct CachedContentUsageMetadata: Codable, Sendable {
    /// Duration of audio in seconds. Not supported in Gemini API.
    public var audioDurationSeconds: Double?
    /// Number of images. Not supported in Gemini API.
    public var imageCount: Double?
    /// Number of text characters. Not supported in Gemini API.
    public var textCount: Double?
    /// Total number of tokens that the cached content consumes.
    public var totalTokenCount: Double?
    /// Duration of video in seconds. Not supported in Gemini API.
    public var videoDurationSeconds: Double?

    public init(
        audioDurationSeconds: Double? = nil,
        imageCount: Double? = nil,
        textCount: Double? = nil,
        totalTokenCount: Double? = nil,
        videoDurationSeconds: Double? = nil
    ) {
        self.audioDurationSeconds = audioDurationSeconds
        self.imageCount = imageCount
        self.textCount = textCount
        self.totalTokenCount = totalTokenCount
        self.videoDurationSeconds = videoDurationSeconds
    }
}

/// A resource used in LLM queries for users to explicitly specify what to cache.
public struct CachedContent: Codable, Sendable {
    /// The server-generated resource name of the cached content.
    public var name: String?
    /// The user-generated meaningful display name of the cached content.
    public var displayName: String?
    /// The name of the publisher model to use for cached content.
    public var model: String?
    /// Creation time of the cache entry.
    public var createTime: String?
    /// When the cache entry was last updated in UTC time.
    public var updateTime: String?
    /// Expiration time of the cached content.
    public var expireTime: String?
    /// Metadata on the usage of the cached content.
    public var usageMetadata: CachedContentUsageMetadata?

    public init(
        name: String? = nil,
        displayName: String? = nil,
        model: String? = nil,
        createTime: String? = nil,
        updateTime: String? = nil,
        expireTime: String? = nil,
        usageMetadata: CachedContentUsageMetadata? = nil
    ) {
        self.name = name
        self.displayName = displayName
        self.model = model
        self.createTime = createTime
        self.updateTime = updateTime
        self.expireTime = expireTime
        self.usageMetadata = usageMetadata
    }
}

/// Optional parameters for `caches.get` method.
public struct GetCachedContentConfig: Codable, Sendable {
    public var httpOptions: HttpOptions?
    public var abortSignal: AbortSignal?

    public init(httpOptions: HttpOptions? = nil, abortSignal: AbortSignal? = nil) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

/// Parameters for `caches.get` method.
public struct GetCachedContentParameters: Codable, Sendable {
    /// The server-generated resource name of the cached content.
    public var name: String
    /// Optional parameters for the request.
    public var config: GetCachedContentConfig?

    public init(name: String, config: GetCachedContentConfig? = nil) {
        self.name = name
        self.config = config
    }
}

/// Optional parameters for `caches.delete` method.
public struct DeleteCachedContentConfig: Codable, Sendable {
    public var httpOptions: HttpOptions?
    public var abortSignal: AbortSignal?

    public init(httpOptions: HttpOptions? = nil, abortSignal: AbortSignal? = nil) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

/// Parameters for `caches.delete` method.
public struct DeleteCachedContentParameters: Codable, Sendable {
    /// The server-generated resource name of the cached content.
    public var name: String
    /// Optional parameters for the request.
    public var config: DeleteCachedContentConfig?

    public init(name: String, config: DeleteCachedContentConfig? = nil) {
        self.name = name
        self.config = config
    }
}

/// Empty response for `caches.delete` method.
public final class DeleteCachedContentResponse: Codable, @unchecked Sendable {
    public var sdkHttpResponse: HttpResponse?

    public init(sdkHttpResponse: HttpResponse? = nil) {
        self.sdkHttpResponse = sdkHttpResponse
    }
}

/// Optional parameters for `caches.update` method.
public struct UpdateCachedContentConfig: Codable, Sendable {
    public var httpOptions: HttpOptions?
    public var abortSignal: AbortSignal?
    /// The TTL for this resource. Duration string, e.g. "3.5s".
    public var ttl: String?
    /// Timestamp of when this resource is considered expired (RFC 3339).
    public var expireTime: String?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        ttl: String? = nil,
        expireTime: String? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.ttl = ttl
        self.expireTime = expireTime
    }
}

public struct UpdateCachedContentParameters: Codable, Sendable {
    /// The server-generated resource name of the cached content.
    public var name: String
    /// Configuration that contains optional parameters.
    public var config: UpdateCachedContentConfig?

    public init(name: String, config: UpdateCachedContentConfig? = nil) {
        self.name = name
        self.config = config
    }
}

/// Config for `caches.list` method.
public struct ListCachedContentsConfig: Codable, Sendable {
    public var httpOptions: HttpOptions?
    public var abortSignal: AbortSignal?
    public var pageSize: Double?
    public var pageToken: String?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        pageSize: Double? = nil,
        pageToken: String? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.pageSize = pageSize
        self.pageToken = pageToken
    }
}

/// Parameters for `caches.list` method.
public struct ListCachedContentsParameters: Codable, Sendable {
    /// Configuration that contains optional parameters.
    public var config: ListCachedContentsConfig?

    public init(config: ListCachedContentsConfig? = nil) {
        self.config = config
    }
}

public final class ListCachedContentsResponse: Codable, @unchecked Sendable {
    public var sdkHttpResponse: HttpResponse?
    public var nextPageToken: String?
    /// List of cached contents.
    public var cachedContents: [CachedContent]?

    public init(
        sdkHttpResponse: HttpResponse? = nil,
        nextPageToken: String? = nil,
        cachedContents: [CachedContent]? = nil
    ) {
        self.sdkHttpResponse = sdkHttpResponse
        self.nextPageToken = nextPageToken
        self.cachedContents = cachedContents
    }
}
