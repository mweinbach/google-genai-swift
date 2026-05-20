// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Optional Config for `documents.get`.
public struct GetDocumentConfig: Codable, Sendable {
    public var httpOptions: HttpOptions?
    public var abortSignal: AbortSignal?

    public init(httpOptions: HttpOptions? = nil, abortSignal: AbortSignal? = nil) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

/// Parameters for `documents.get`.
public struct GetDocumentParameters: Codable, Sendable {
    /// The resource name of the Document.
    public var name: String
    /// Optional parameters for the request.
    public var config: GetDocumentConfig?

    public init(name: String, config: GetDocumentConfig? = nil) {
        self.name = name
        self.config = config
    }
}

/// User provided string values assigned to a single metadata key. This data type is not supported in Vertex AI.
public struct StringList: Codable, Sendable {
    /// The string values of the metadata to store.
    public var values: [String]?

    public init(values: [String]? = nil) {
        self.values = values
    }
}

/// User provided metadata stored as key-value pairs. This data type is not supported in Vertex AI.
public struct CustomMetadata: Codable, Sendable {
    /// Required. The key of the metadata to store.
    public var key: String?
    /// The numeric value of the metadata to store.
    public var numericValue: Double?
    /// The StringList value of the metadata to store.
    public var stringListValue: StringList?
    /// The string value of the metadata to store.
    public var stringValue: String?

    public init(
        key: String? = nil,
        numericValue: Double? = nil,
        stringListValue: StringList? = nil,
        stringValue: String? = nil
    ) {
        self.key = key
        self.numericValue = numericValue
        self.stringListValue = stringListValue
        self.stringValue = stringValue
    }
}

/// A Document is a collection of Chunks.
public struct Document: Codable, Sendable {
    /// Immutable. Identifier. The `Document` resource name.
    public var name: String?
    /// Optional. The human-readable display name for the Document.
    public var displayName: String?
    /// Output only. Current state of the Document.
    public var state: DocumentState?
    /// Output only. The size of raw bytes ingested into the Document.
    public var sizeBytes: String?
    /// Output only. The mime type of the Document.
    public var mimeType: String?
    /// Output only. The Timestamp of when the Document was created.
    public var createTime: String?
    /// Optional. User provided custom metadata.
    public var customMetadata: [CustomMetadata]?
    /// Output only. The Timestamp of when the Document was last updated.
    public var updateTime: String?

    public init(
        name: String? = nil,
        displayName: String? = nil,
        state: DocumentState? = nil,
        sizeBytes: String? = nil,
        mimeType: String? = nil,
        createTime: String? = nil,
        customMetadata: [CustomMetadata]? = nil,
        updateTime: String? = nil
    ) {
        self.name = name
        self.displayName = displayName
        self.state = state
        self.sizeBytes = sizeBytes
        self.mimeType = mimeType
        self.createTime = createTime
        self.customMetadata = customMetadata
        self.updateTime = updateTime
    }
}

/// Config for optional parameters of `documents.delete`.
public struct DeleteDocumentConfig: Codable, Sendable {
    public var httpOptions: HttpOptions?
    public var abortSignal: AbortSignal?
    /// If set to true, any `Chunk`s and objects related to this `Document` will also be deleted.
    public var force: Bool?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        force: Bool? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.force = force
    }
}

/// Config for `documents.delete` parameters.
public struct DeleteDocumentParameters: Codable, Sendable {
    /// The resource name of the Document.
    public var name: String
    /// Optional parameters for the request.
    public var config: DeleteDocumentConfig?

    public init(name: String, config: DeleteDocumentConfig? = nil) {
        self.name = name
        self.config = config
    }
}

/// Config for optional parameters of `documents.list`.
public struct ListDocumentsConfig: Codable, Sendable {
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

/// Config for `documents.list` parameters.
public struct ListDocumentsParameters: Codable, Sendable {
    /// The resource name of the FileSearchStores.
    public var parent: String
    public var config: ListDocumentsConfig?

    public init(parent: String, config: ListDocumentsConfig? = nil) {
        self.parent = parent
        self.config = config
    }
}

/// Config for `documents.list` return value.
public final class ListDocumentsResponse: Codable, @unchecked Sendable {
    public var sdkHttpResponse: HttpResponse?
    /// A token, which can be sent as `page_token` to retrieve the next page.
    public var nextPageToken: String?
    /// The returned `Document`s.
    public var documents: [Document]?

    public init(
        sdkHttpResponse: HttpResponse? = nil,
        nextPageToken: String? = nil,
        documents: [Document]? = nil
    ) {
        self.sdkHttpResponse = sdkHttpResponse
        self.nextPageToken = nextPageToken
        self.documents = documents
    }
}

/// Optional parameters for creating a file search store.
public struct CreateFileSearchStoreConfig: Codable, Sendable {
    public var httpOptions: HttpOptions?
    public var abortSignal: AbortSignal?
    /// The human-readable display name for the file search store.
    public var displayName: String?
    /// The embedding model to use for the FileSearchStore. Format: `models/{model}`.
    public var embeddingModel: String?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        displayName: String? = nil,
        embeddingModel: String? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.displayName = displayName
        self.embeddingModel = embeddingModel
    }
}

/// Config for `file_search_stores.create` parameters.
public struct CreateFileSearchStoreParameters: Codable, Sendable {
    /// Optional parameters for creating a file search store.
    public var config: CreateFileSearchStoreConfig?

    public init(config: CreateFileSearchStoreConfig? = nil) {
        self.config = config
    }
}

/// A collection of Documents.
public struct FileSearchStore: Codable, Sendable {
    /// The resource name of the FileSearchStore.
    public var name: String?
    /// The human-readable display name for the FileSearchStore.
    public var displayName: String?
    /// The Timestamp of when the FileSearchStore was created.
    public var createTime: String?
    /// The Timestamp of when the FileSearchStore was last updated.
    public var updateTime: String?
    /// The number of documents in the FileSearchStore that are active and ready for retrieval.
    public var activeDocumentsCount: String?
    /// The number of documents in the FileSearchStore that are being processed.
    public var pendingDocumentsCount: String?
    /// The number of documents in the FileSearchStore that have failed processing.
    public var failedDocumentsCount: String?
    /// The size of raw bytes ingested into the FileSearchStore.
    public var sizeBytes: String?
    /// The embedding model used by the FileSearchStore.
    public var embeddingModel: String?

    public init(
        name: String? = nil,
        displayName: String? = nil,
        createTime: String? = nil,
        updateTime: String? = nil,
        activeDocumentsCount: String? = nil,
        pendingDocumentsCount: String? = nil,
        failedDocumentsCount: String? = nil,
        sizeBytes: String? = nil,
        embeddingModel: String? = nil
    ) {
        self.name = name
        self.displayName = displayName
        self.createTime = createTime
        self.updateTime = updateTime
        self.activeDocumentsCount = activeDocumentsCount
        self.pendingDocumentsCount = pendingDocumentsCount
        self.failedDocumentsCount = failedDocumentsCount
        self.sizeBytes = sizeBytes
        self.embeddingModel = embeddingModel
    }
}

/// Optional parameters for getting a FileSearchStore.
public struct GetFileSearchStoreConfig: Codable, Sendable {
    public var httpOptions: HttpOptions?
    public var abortSignal: AbortSignal?

    public init(httpOptions: HttpOptions? = nil, abortSignal: AbortSignal? = nil) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

/// Config for `file_search_stores.get` parameters.
public struct GetFileSearchStoreParameters: Codable, Sendable {
    /// The resource name of the FileSearchStore.
    public var name: String
    /// Optional parameters for the request.
    public var config: GetFileSearchStoreConfig?

    public init(name: String, config: GetFileSearchStoreConfig? = nil) {
        self.name = name
        self.config = config
    }
}

/// Optional parameters for deleting a FileSearchStore.
public struct DeleteFileSearchStoreConfig: Codable, Sendable {
    public var httpOptions: HttpOptions?
    public var abortSignal: AbortSignal?
    /// If set to true, any Documents and objects related to this FileSearchStore will also be deleted.
    public var force: Bool?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        force: Bool? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.force = force
    }
}

/// Config for `file_search_stores.delete` parameters.
public struct DeleteFileSearchStoreParameters: Codable, Sendable {
    /// The resource name of the FileSearchStore.
    public var name: String
    /// Optional parameters for the request.
    public var config: DeleteFileSearchStoreConfig?

    public init(name: String, config: DeleteFileSearchStoreConfig? = nil) {
        self.name = name
        self.config = config
    }
}

/// Optional parameters for listing FileSearchStore.
public struct ListFileSearchStoresConfig: Codable, Sendable {
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

/// Config for `file_search_stores.list` parameters.
public struct ListFileSearchStoresParameters: Codable, Sendable {
    /// Optional parameters for the list request.
    public var config: ListFileSearchStoresConfig?

    public init(config: ListFileSearchStoresConfig? = nil) {
        self.config = config
    }
}

/// Config for `file_search_stores.list` return value.
public final class ListFileSearchStoresResponse: Codable, @unchecked Sendable {
    public var sdkHttpResponse: HttpResponse?
    /// A token, which can be sent as `page_token` to retrieve the next page.
    public var nextPageToken: String?
    /// The returned file search stores.
    public var fileSearchStores: [FileSearchStore]?

    public init(
        sdkHttpResponse: HttpResponse? = nil,
        nextPageToken: String? = nil,
        fileSearchStores: [FileSearchStore]? = nil
    ) {
        self.sdkHttpResponse = sdkHttpResponse
        self.nextPageToken = nextPageToken
        self.fileSearchStores = fileSearchStores
    }
}

/// Configuration for a white space chunking algorithm.
public struct WhiteSpaceConfig: Codable, Sendable {
    /// Maximum number of tokens per chunk.
    public var maxTokensPerChunk: Double?
    /// Maximum number of overlapping tokens between two adjacent chunks.
    public var maxOverlapTokens: Double?

    public init(maxTokensPerChunk: Double? = nil, maxOverlapTokens: Double? = nil) {
        self.maxTokensPerChunk = maxTokensPerChunk
        self.maxOverlapTokens = maxOverlapTokens
    }
}

/// Config for telling the service how to chunk the file.
public struct ChunkingConfig: Codable, Sendable {
    /// White space chunking configuration.
    public var whiteSpaceConfig: WhiteSpaceConfig?

    public init(whiteSpaceConfig: WhiteSpaceConfig? = nil) {
        self.whiteSpaceConfig = whiteSpaceConfig
    }
}

/// Optional parameters for uploading a file to a FileSearchStore.
public struct UploadToFileSearchStoreConfig: Codable, Sendable {
    public var httpOptions: HttpOptions?
    public var abortSignal: AbortSignal?
    /// MIME type of the file to be uploaded.
    public var mimeType: String?
    /// Display name of the created document.
    public var displayName: String?
    /// User provided custom metadata.
    public var customMetadata: [CustomMetadata]?
    /// Config for telling the service how to chunk the file.
    public var chunkingConfig: ChunkingConfig?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        mimeType: String? = nil,
        displayName: String? = nil,
        customMetadata: [CustomMetadata]? = nil,
        chunkingConfig: ChunkingConfig? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.mimeType = mimeType
        self.displayName = displayName
        self.customMetadata = customMetadata
        self.chunkingConfig = chunkingConfig
    }
}

/// Generates the parameters for the private `_upload_to_file_search_store` method.
public struct UploadToFileSearchStoreParameters: Codable, Sendable {
    /// The resource name of the FileSearchStore.
    public var fileSearchStoreName: String
    /// Used to override the default configuration.
    public var config: UploadToFileSearchStoreConfig?

    public init(fileSearchStoreName: String, config: UploadToFileSearchStoreConfig? = nil) {
        self.fileSearchStoreName = fileSearchStoreName
        self.config = config
    }
}

/// Response for the resumable upload method.
public final class UploadToFileSearchStoreResumableResponse: Codable, @unchecked Sendable {
    public var sdkHttpResponse: HttpResponse?

    public init(sdkHttpResponse: HttpResponse? = nil) {
        self.sdkHttpResponse = sdkHttpResponse
    }
}
