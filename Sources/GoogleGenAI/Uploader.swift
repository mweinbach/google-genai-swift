// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// MARK: - Constants (ported from cross/_cross_uploader.ts)

internal let MAX_CHUNK_SIZE: Int = 1024 * 1024 * 8 // bytes
internal let MAX_RETRY_COUNT: Int = 3
internal let INITIAL_RETRY_DELAY_MS: UInt64 = 1000
internal let DELAY_MULTIPLIER: UInt64 = 2
internal let X_GOOG_UPLOAD_STATUS_HEADER_FIELD = "x-goog-upload-status"

// MARK: - FileStat

/// Represents the size and MIME type of a file. Used to request an upload URL from
/// the resumable upload endpoint. Ports `FileStat` from `_uploader.ts`.
public struct FileStat: Sendable {
    /// The size of the file in bytes.
    public var size: Int64
    /// The MIME type of the file (nil if it cannot be inferred).
    public var type: String?

    public init(size: Int64, type: String? = nil) {
        self.size = size
        self.type = type
    }
}

// MARK: - Uploader protocol

/// Foundation-native uploader contract. Collapses the Node, Browser, and Cross TS variants
/// (`_uploader.ts` + `cross/_cross_uploader.ts` + `node/_node_uploader.ts` +
/// `web/_browser_uploader.ts`) into one Swift protocol.
public protocol Uploader: Sendable {
    /// Uploads a file to the given resumable upload URL. Returns the resulting `File`.
    func upload(
        _ file: FileInput,
        uploadUrl: String,
        apiClient: ApiClient
    ) async throws -> File

    /// Uploads a file to a file-search store via the given upload URL.
    func uploadToFileSearchStore(
        _ file: FileInput,
        uploadUrl: String,
        apiClient: ApiClient
    ) async throws -> UploadToFileSearchStoreOperation

    /// Returns size + inferred MIME type for the input file. Mirrors `stat` in
    /// `_uploader.ts` — when the file is a path the MIME type is inferred from the
    /// extension; when the file is raw bytes the MIME type is nil.
    func stat(_ file: FileInput) async throws -> FileStat
}

// MARK: - URLSessionUploader (collapsed implementation)

/// Foundation implementation that handles both path-based and data-based uploads.
/// Collapses `NodeUploader` (resumable upload of a file path) and `CrossUploader`/
/// `BrowserUploader` (in-memory Blob upload) into a single class.
public final class URLSessionUploader: Uploader, @unchecked Sendable {
    public init() {}

    // MARK: stat

    public func stat(_ file: FileInput) async throws -> FileStat {
        switch file {
        case .path(let p):
            let attrs = try FileManager.default.attributesOfItem(atPath: p)
            let size = (attrs[.size] as? NSNumber)?.int64Value ?? 0
            return FileStat(size: size, type: Self.inferMimeType(p))
        case .data(let d):
            return FileStat(size: Int64(d.count), type: nil)
        }
    }

    // MARK: upload

    public func upload(
        _ file: FileInput,
        uploadUrl: String,
        apiClient: ApiClient
    ) async throws -> File {
        let response = try await self.uploadInternal(
            file: file,
            uploadUrl: uploadUrl,
            apiClient: apiClient
        )
        try Self.requireFinalStatus(response)
        let json = try response.json()
        guard case .object(let obj) = json, let fileVal = obj["file"] else {
            throw GenAIError.runtime("Upload response did not include a `file` field.")
        }
        let data = try JSONEncoder().encode(fileVal)
        return try JSONDecoder().decode(File.self, from: data)
    }

    // MARK: uploadToFileSearchStore

    public func uploadToFileSearchStore(
        _ file: FileInput,
        uploadUrl: String,
        apiClient: ApiClient
    ) async throws -> UploadToFileSearchStoreOperation {
        let response = try await self.uploadInternal(
            file: file,
            uploadUrl: uploadUrl,
            apiClient: apiClient
        )
        try Self.requireFinalStatus(response)
        let json = try response.json()
        guard case .object(let obj) = json else {
            throw GenAIError.runtime("Upload response is not a JSON object.")
        }
        var parent: [String: JSONValue] = [:]
        let converted = try uploadToFileSearchStoreOperationFromMldev(
            apiClient: apiClient,
            fromObject: obj,
            parentObject: &parent
        )
        let encoded = try JSONEncoder().encode(JSONValue.object(converted))
        let typed = try JSONDecoder().decode(UploadToFileSearchStoreOperation.self, from: encoded)
        return typed
    }

    // MARK: - Internal: resumable upload protocol

    private func uploadInternal(
        file: FileInput,
        uploadUrl: String,
        apiClient: ApiClient
    ) async throws -> HttpResponse {
        // Resolve the final URL, optionally rewriting host/scheme from clientOptions.httpOptions.baseUrl.
        let finalUrl = Self.resolveFinalUploadUrl(uploadUrl, apiClient: apiClient)

        switch file {
        case .path(let path):
            return try await self.uploadFromPath(
                path: path,
                uploadUrl: finalUrl,
                apiClient: apiClient
            )
        case .data(let data):
            return try await self.uploadFromData(
                data: data,
                uploadUrl: finalUrl,
                apiClient: apiClient
            )
        }
    }

    /// Resumable chunked upload from a file path. Ports `uploadFileFromPathInternal` in
    /// `node/_node_uploader.ts`. Reads the file via `FileHandle` and streams chunks.
    private func uploadFromPath(
        path: String,
        uploadUrl: String,
        apiClient: ApiClient
    ) async throws -> HttpResponse {
        let fileName = (path as NSString).lastPathComponent
        let url = URL(fileURLWithPath: path)
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }

        let attrs = try FileManager.default.attributesOfItem(atPath: path)
        let fileSize = (attrs[.size] as? NSNumber)?.int64Value ?? 0

        var offset: Int64 = 0
        var uploadCommand = "upload"
        var lastResponse = HttpResponse(headers: nil, bodyData: nil)

        while offset < fileSize {
            let chunkSize = min(Int64(MAX_CHUNK_SIZE), fileSize - offset)
            if offset + chunkSize >= fileSize {
                uploadCommand += ", finalize"
            }
            try handle.seek(toOffset: UInt64(offset))
            let chunk = handle.readData(ofLength: Int(chunkSize))
            if Int64(chunk.count) != chunkSize {
                throw GenAIError.runtime(
                    "Failed to read \(chunkSize) bytes from file at offset \(offset). bytes actually read: \(chunk.count)"
                )
            }

            lastResponse = try await self.postChunkWithRetries(
                chunk: chunk,
                offset: offset,
                bytesRead: Int64(chunk.count),
                uploadCommand: uploadCommand,
                uploadUrl: uploadUrl,
                fileName: fileName,
                apiClient: apiClient
            )
            offset += Int64(chunk.count)

            // The `x-goog-upload-status` header can be `active`, `final`, or `cancelled`.
            let status = Self.headerValue(lastResponse.headers, key: X_GOOG_UPLOAD_STATUS_HEADER_FIELD)
            if status != "active" { break }
            if fileSize <= offset {
                throw GenAIError.runtime(
                    "All content has been uploaded, but the upload status is not finalized."
                )
            }
        }
        return lastResponse
    }

    /// Resumable chunked upload from in-memory `Data`. Ports `uploadBlobInternal` in
    /// `cross/_cross_uploader.ts`.
    private func uploadFromData(
        data: Data,
        uploadUrl: String,
        apiClient: ApiClient
    ) async throws -> HttpResponse {
        let fileSize = Int64(data.count)
        var offset: Int64 = 0
        var uploadCommand = "upload"
        var lastResponse = HttpResponse(headers: nil, bodyData: nil)

        while offset < fileSize {
            let chunkSize = min(Int64(MAX_CHUNK_SIZE), fileSize - offset)
            if offset + chunkSize >= fileSize {
                uploadCommand += ", finalize"
            }
            let start = Int(offset)
            let end = Int(offset + chunkSize)
            let chunk = data.subdata(in: start..<end)
            lastResponse = try await self.postChunkWithRetries(
                chunk: chunk,
                offset: offset,
                bytesRead: chunkSize,
                uploadCommand: uploadCommand,
                uploadUrl: uploadUrl,
                fileName: nil,
                apiClient: apiClient
            )
            offset += chunkSize

            let status = Self.headerValue(lastResponse.headers, key: X_GOOG_UPLOAD_STATUS_HEADER_FIELD)
            if status != "active" { break }
            if fileSize <= offset {
                throw GenAIError.runtime(
                    "All content has been uploaded, but the upload status is not finalized."
                )
            }
        }
        return lastResponse
    }

    private func postChunkWithRetries(
        chunk: Data,
        offset: Int64,
        bytesRead: Int64,
        uploadCommand: String,
        uploadUrl: String,
        fileName: String?,
        apiClient: ApiClient
    ) async throws -> HttpResponse {
        var retryCount = 0
        var currentDelayMs: UInt64 = INITIAL_RETRY_DELAY_MS
        var lastResponse: HttpResponse = HttpResponse(headers: nil, bodyData: nil)

        while retryCount < MAX_RETRY_COUNT {
            var headers: [String: String] = [
                "X-Goog-Upload-Command": uploadCommand,
                "X-Goog-Upload-Offset": String(offset),
                "Content-Length": String(bytesRead),
            ]
            if let fileName = fileName, !fileName.isEmpty {
                headers["X-Goog-Upload-File-Name"] = fileName
            }
            let httpOptions = HttpOptions(
                baseUrl: uploadUrl,
                apiVersion: "",
                headers: headers
            )
            lastResponse = try await apiClient.request(HttpRequest(
                path: "",
                body: .data(chunk),
                httpMethod: .POST,
                httpOptions: httpOptions
            ))
            if Self.headerValue(lastResponse.headers, key: X_GOOG_UPLOAD_STATUS_HEADER_FIELD) != nil {
                return lastResponse
            }
            retryCount += 1
            if retryCount < MAX_RETRY_COUNT {
                try await Task.sleep(nanoseconds: currentDelayMs * 1_000_000)
                currentDelayMs *= DELAY_MULTIPLIER
            }
        }
        return lastResponse
    }

    // MARK: - Helpers

    private static func headerValue(_ headers: [String: String]?, key: String) -> String? {
        guard let headers = headers else { return nil }
        // Header lookup is case-insensitive.
        let target = key.lowercased()
        for (k, v) in headers where k.lowercased() == target {
            return v
        }
        return nil
    }

    private static func requireFinalStatus(_ response: HttpResponse) throws {
        let status = headerValue(response.headers, key: X_GOOG_UPLOAD_STATUS_HEADER_FIELD)
        if status != "final" {
            throw GenAIError.runtime("Failed to upload file: Upload status is not finalized.")
        }
    }

    /// Mirrors the URL rewrite block in `uploadBlobInternal` — when the API client has a
    /// custom `baseUrl`, the upload URL's scheme/host/port are replaced.
    private static func resolveFinalUploadUrl(_ uploadUrl: String, apiClient: ApiClient) -> String {
        guard let effectiveBaseUrl = apiClient.clientOptions.httpOptions?.baseUrl,
              let baseUri = URL(string: effectiveBaseUrl),
              var uploadComps = URLComponents(string: uploadUrl) else {
            return uploadUrl
        }
        if let scheme = baseUri.scheme { uploadComps.scheme = scheme }
        if let host = baseUri.host { uploadComps.host = host }
        uploadComps.port = baseUri.port
        return uploadComps.string ?? uploadUrl
    }

    /// Mirrors `inferMimeType` in `node/_node_uploader.ts`. Returns nil when unknown.
    internal static func inferMimeType(_ filePath: String) -> String? {
        let ext = (filePath as NSString).pathExtension.lowercased()
        guard !ext.isEmpty else { return nil }
        return mimeTypeMap[ext]
    }
}

// Extension-to-MIME map ported verbatim from `node/_node_uploader.ts`.
private let mimeTypeMap: [String: String] = [
    "aac": "audio/aac",
    "abw": "application/x-abiword",
    "arc": "application/x-freearc",
    "avi": "video/x-msvideo",
    "azw": "application/vnd.amazon.ebook",
    "bin": "application/octet-stream",
    "bmp": "image/bmp",
    "bz": "application/x-bzip",
    "bz2": "application/x-bzip2",
    "csh": "application/x-csh",
    "css": "text/css",
    "csv": "text/csv",
    "doc": "application/msword",
    "docx": "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
    "eot": "application/vnd.ms-fontobject",
    "epub": "application/epub+zip",
    "gz": "application/gzip",
    "gif": "image/gif",
    "htm": "text/html",
    "html": "text/html",
    "ico": "image/vnd.microsoft.icon",
    "ics": "text/calendar",
    "jar": "application/java-archive",
    "jpeg": "image/jpeg",
    "jpg": "image/jpeg",
    "js": "text/javascript",
    "json": "application/json",
    "jsonld": "application/ld+json",
    "kml": "application/vnd.google-earth.kml+xml",
    "kmz": "application/vnd.google-earth.kmz+xml",
    "mjs": "text/javascript",
    "mp3": "audio/mpeg",
    "mp4": "video/mp4",
    "mpeg": "video/mpeg",
    "mpkg": "application/vnd.apple.installer+xml",
    "odt": "application/vnd.oasis.opendocument.text",
    "oga": "audio/ogg",
    "ogv": "video/ogg",
    "ogx": "application/ogg",
    "opus": "audio/opus",
    "otf": "font/otf",
    "png": "image/png",
    "pdf": "application/pdf",
    "php": "application/x-httpd-php",
    "ppt": "application/vnd.ms-powerpoint",
    "pptx": "application/vnd.openxmlformats-officedocument.presentationml.presentation",
    "rar": "application/vnd.rar",
    "rtf": "application/rtf",
    "sh": "application/x-sh",
    "svg": "image/svg+xml",
    "swf": "application/x-shockwave-flash",
    "tar": "application/x-tar",
    "tif": "image/tiff",
    "tiff": "image/tiff",
    "ts": "video/mp2t",
    "ttf": "font/ttf",
    "txt": "text/plain",
    "vsd": "application/vnd.visio",
    "wav": "audio/wav",
    "weba": "audio/webm",
    "webm": "video/webm",
    "webp": "image/webp",
    "woff": "font/woff",
    "woff2": "font/woff2",
    "xhtml": "application/xhtml+xml",
    "xls": "application/vnd.ms-excel",
    "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "xml": "application/xml",
    "xul": "application/vnd.mozilla.xul+xml",
    "zip": "application/zip",
    "3gp": "video/3gpp",
    "3g2": "video/3gpp2",
    "7z": "application/x-7z-compressed",
]
