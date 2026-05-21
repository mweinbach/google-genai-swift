// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Optional parameters for importing a file.
public struct ImportFileConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    public var abortSignal: AbortSignal?
    /// User provided custom metadata stored as key-value pairs used for querying.
    public var customMetadata: [CustomMetadata]?
    /// Config for telling the service how to chunk the file.
    public var chunkingConfig: ChunkingConfig?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        customMetadata: [CustomMetadata]? = nil,
        chunkingConfig: ChunkingConfig? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.customMetadata = customMetadata
        self.chunkingConfig = chunkingConfig
    }
}

/// Config for `file_search_stores.import_file` parameters.
public struct ImportFileParameters: Codable, Sendable {
    /// The resource name of the FileSearchStore. Example: `fileSearchStores/my-file-search-store-123`.
    public var fileSearchStoreName: String
    /// The name of the File API File to import. Example: `files/abc-123`.
    public var fileName: String
    /// Optional parameters for the request.
    public var config: ImportFileConfig?

    public init(
        fileSearchStoreName: String,
        fileName: String,
        config: ImportFileConfig? = nil
    ) {
        self.fileSearchStoreName = fileSearchStoreName
        self.fileName = fileName
        self.config = config
    }
}

/// Response for `ImportFile` to import a File API file with a file search store.
public final class ImportFileResponse: Codable, @unchecked Sendable {
    /// Used to retain the full HTTP response.
    public var sdkHttpResponse: HttpResponse?
    /// The name of the FileSearchStore containing Documents.
    public var parent: String?
    /// The identifier for the Document imported.
    public var documentName: String?

    public init(
        sdkHttpResponse: HttpResponse? = nil,
        parent: String? = nil,
        documentName: String? = nil
    ) {
        self.sdkHttpResponse = sdkHttpResponse
        self.parent = parent
        self.documentName = documentName
    }
}

/// Long-running operation for importing a file to a FileSearchStore.
public final class ImportFileOperation: Codable, @unchecked Sendable {
    /// The server-assigned name.
    public var name: String?
    /// Service-specific metadata associated with the operation.
    public var metadata: [String: JSONValue]?
    /// If the value is `false`, it means the operation is still in progress.
    public var done: Bool?
    /// The error result of the operation in case of failure or cancellation.
    public var error: [String: JSONValue]?
    /// The result of the ImportFile operation, available when the operation is done.
    public var response: ImportFileResponse?
    /// The full HTTP response.
    public var sdkHttpResponse: HttpResponse?

    public init(
        name: String? = nil,
        metadata: [String: JSONValue]? = nil,
        done: Bool? = nil,
        error: [String: JSONValue]? = nil,
        response: ImportFileResponse? = nil,
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
    public func fromAPIResponse(
        apiClient: ApiClient,
        apiResponse: [String: JSONValue],
        isVertexAI: Bool
    ) -> ImportFileOperation {
        let operation = ImportFileOperation()
        let mapped: [String: JSONValue]
        do {
            var parent: [String: JSONValue] = [:]
            mapped = try importFileOperationFromMldev(apiClient: apiClient, fromObject: apiResponse, parentObject: &parent)
        } catch {
            return operation
        }
        if let data = try? JSONEncoder().encode(JSONValue.object(mapped)),
           let decoded = try? JSONDecoder().decode(ImportFileOperation.self, from: data) {
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

/// Used to override the default configuration.
public struct ListFilesConfig: Codable, Sendable {
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

/// Generates the parameters for the list method.
public struct ListFilesParameters: Codable, Sendable {
    /// Used to override the default configuration.
    public var config: ListFilesConfig?

    public init(config: ListFilesConfig? = nil) {
        self.config = config
    }
}

/// Status of a File that uses a common error model.
public struct FileStatus: Codable, Sendable {
    /// A list of messages that carry the error details.
    public var details: [[String: JSONValue]]?
    /// A developer-facing error message.
    public var message: String?
    /// The status code. 0 for OK, 1 for CANCELLED.
    public var code: Double?

    public init(
        details: [[String: JSONValue]]? = nil,
        message: String? = nil,
        code: Double? = nil
    ) {
        self.details = details
        self.message = message
        self.code = code
    }
}

/// A file uploaded to the API.
public struct File: Codable, Sendable {
    /// The `File` resource name.
    public var name: String?
    /// Optional. The human-readable display name for the File.
    public var displayName: String?
    /// Output only. MIME type of the file.
    public var mimeType: String?
    /// Output only. Size of the file in bytes.
    public var sizeBytes: String?
    /// Output only. The timestamp of when the File was created.
    public var createTime: String?
    /// Output only. The timestamp of when the File will be deleted.
    public var expirationTime: String?
    /// Output only. The timestamp of when the File was last updated.
    public var updateTime: String?
    /// Output only. SHA-256 hash of the uploaded bytes (base64).
    public var sha256Hash: String?
    /// Output only. The URI of the File.
    public var uri: String?
    /// Output only. The URI of the File, only set for downloadable (generated) files.
    public var downloadUri: String?
    /// Output only. Processing state of the File.
    public var state: FileState?
    /// Output only. The source of the File.
    public var source: FileSource?
    /// Output only. Metadata for a video.
    public var videoMetadata: [String: JSONValue]?
    /// Output only. Error status if File processing failed.
    public var error: FileStatus?

    public init(
        name: String? = nil,
        displayName: String? = nil,
        mimeType: String? = nil,
        sizeBytes: String? = nil,
        createTime: String? = nil,
        expirationTime: String? = nil,
        updateTime: String? = nil,
        sha256Hash: String? = nil,
        uri: String? = nil,
        downloadUri: String? = nil,
        state: FileState? = nil,
        source: FileSource? = nil,
        videoMetadata: [String: JSONValue]? = nil,
        error: FileStatus? = nil
    ) {
        self.name = name
        self.displayName = displayName
        self.mimeType = mimeType
        self.sizeBytes = sizeBytes
        self.createTime = createTime
        self.expirationTime = expirationTime
        self.updateTime = updateTime
        self.sha256Hash = sha256Hash
        self.uri = uri
        self.downloadUri = downloadUri
        self.state = state
        self.source = source
        self.videoMetadata = videoMetadata
        self.error = error
    }
}

/// Response for the list files method.
public final class ListFilesResponse: Codable, @unchecked Sendable {
    public var sdkHttpResponse: HttpResponse?
    /// A token that can be sent as a `page_token` into a subsequent `ListFiles` call.
    public var nextPageToken: String?
    /// The list of `File`s.
    public var files: [File]?

    public init(
        sdkHttpResponse: HttpResponse? = nil,
        nextPageToken: String? = nil,
        files: [File]? = nil
    ) {
        self.sdkHttpResponse = sdkHttpResponse
        self.nextPageToken = nextPageToken
        self.files = files
    }
}

/// Used to override the default configuration.
public struct CreateFileConfig: Codable, Sendable {
    public var httpOptions: HttpOptions?
    public var abortSignal: AbortSignal?

    public init(httpOptions: HttpOptions? = nil, abortSignal: AbortSignal? = nil) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

/// Generates the parameters for the private `_create` method.
public struct CreateFileParameters: Codable, Sendable {
    /// The file to be uploaded.
    public var file: File
    /// Used to override the default configuration.
    public var config: CreateFileConfig?

    public init(file: File, config: CreateFileConfig? = nil) {
        self.file = file
        self.config = config
    }
}

/// Response for the create file method.
public final class CreateFileResponse: Codable, @unchecked Sendable {
    public var sdkHttpResponse: HttpResponse?

    public init(sdkHttpResponse: HttpResponse? = nil) {
        self.sdkHttpResponse = sdkHttpResponse
    }
}

/// Used to override the default configuration.
public struct GetFileConfig: Codable, Sendable {
    public var httpOptions: HttpOptions?
    public var abortSignal: AbortSignal?

    public init(httpOptions: HttpOptions? = nil, abortSignal: AbortSignal? = nil) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

/// Generates the parameters for the get method.
public struct GetFileParameters: Codable, Sendable {
    /// The name identifier for the file to retrieve.
    public var name: String
    /// Used to override the default configuration.
    public var config: GetFileConfig?

    public init(name: String, config: GetFileConfig? = nil) {
        self.name = name
        self.config = config
    }
}

/// Used to override the default configuration.
public struct DeleteFileConfig: Codable, Sendable {
    public var httpOptions: HttpOptions?
    public var abortSignal: AbortSignal?

    public init(httpOptions: HttpOptions? = nil, abortSignal: AbortSignal? = nil) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

/// Generates the parameters for the delete method.
public struct DeleteFileParameters: Codable, Sendable {
    /// The name identifier for the file to be deleted.
    public var name: String
    /// Used to override the default configuration.
    public var config: DeleteFileConfig?

    public init(name: String, config: DeleteFileConfig? = nil) {
        self.name = name
        self.config = config
    }
}

/// Response for the delete file method.
public final class DeleteFileResponse: Codable, @unchecked Sendable {
    public var sdkHttpResponse: HttpResponse?

    public init(sdkHttpResponse: HttpResponse? = nil) {
        self.sdkHttpResponse = sdkHttpResponse
    }
}

/// Used to override the default configuration.
public struct RegisterFilesConfig: Codable, Sendable {
    public var httpOptions: HttpOptions?
    public var abortSignal: AbortSignal?

    public init(httpOptions: HttpOptions? = nil, abortSignal: AbortSignal? = nil) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

/// Parameters for the private `_Register` method.
internal struct InternalRegisterFilesParameters: Codable, Sendable {
    /// The Google Cloud Storage URIs to register. Example: `gs://bucket/object`.
    public var uris: [String]
    /// Used to override the default configuration.
    public var config: RegisterFilesConfig?

    public init(uris: [String], config: RegisterFilesConfig? = nil) {
        self.uris = uris
        self.config = config
    }
}

/// Response for the `_register` file method.
public final class RegisterFilesResponse: Codable, @unchecked Sendable {
    public var sdkHttpResponse: HttpResponse?
    /// The registered files.
    public var files: [File]?

    public init(sdkHttpResponse: HttpResponse? = nil, files: [File]? = nil) {
        self.sdkHttpResponse = sdkHttpResponse
        self.files = files
    }
}

/// Config for inlined request.
public struct InlinedRequest: Codable, Sendable {
    /// ID of the model to use.
    public var model: String?
    /// Content of the request.
    public var contents: ContentListUnion?
    /// The metadata to be associated with the request.
    public var metadata: [String: String]?
    /// Configuration that contains optional model parameters.
    public var config: GenerateContentConfig?

    public init(
        model: String? = nil,
        contents: ContentListUnion? = nil,
        metadata: [String: String]? = nil,
        config: GenerateContentConfig? = nil
    ) {
        self.model = model
        self.contents = contents
        self.metadata = metadata
        self.config = config
    }
}

/// Config for `src` parameter.
public struct BatchJobSource: Codable, Sendable {
    /// Storage format of the input files. Must be one of: 'jsonl', 'bigquery', 'vertex-dataset'.
    public var format: String?
    /// The Google Cloud Storage URIs to input files.
    public var gcsUri: [String]?
    /// The BigQuery URI to input table.
    public var bigqueryUri: String?
    /// The Gemini Developer API's file resource name of the input data.
    public var fileName: String?
    /// The Gemini Developer API's inlined input data to run batch job.
    public var inlinedRequests: [InlinedRequest]?
    /// This field is experimental. The Vertex AI dataset resource name to use as input.
    public var vertexDatasetName: String?

    public init(
        format: String? = nil,
        gcsUri: [String]? = nil,
        bigqueryUri: String? = nil,
        fileName: String? = nil,
        inlinedRequests: [InlinedRequest]? = nil,
        vertexDatasetName: String? = nil
    ) {
        self.format = format
        self.gcsUri = gcsUri
        self.bigqueryUri = bigqueryUri
        self.fileName = fileName
        self.inlinedRequests = inlinedRequests
        self.vertexDatasetName = vertexDatasetName
    }
}

/// This class is experimental. The specification for an output Vertex AI multimodal dataset.
public struct VertexMultimodalDatasetDestination: Codable, Sendable {
    /// The BigQuery destination for the multimodal dataset.
    public var bigqueryDestination: String?
    /// The display name of the multimodal dataset.
    public var displayName: String?

    public init(bigqueryDestination: String? = nil, displayName: String? = nil) {
        self.bigqueryDestination = bigqueryDestination
        self.displayName = displayName
    }
}

/// Job error.
public struct JobError: Codable, Sendable {
    /// A list of messages that carry the error details.
    public var details: [String]?
    /// The status code.
    public var code: Double?
    /// A developer-facing error message.
    public var message: String?

    public init(
        details: [String]? = nil,
        code: Double? = nil,
        message: String? = nil
    ) {
        self.details = details
        self.code = code
        self.message = message
    }
}

