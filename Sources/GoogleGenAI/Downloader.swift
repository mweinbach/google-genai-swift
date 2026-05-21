// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Foundation-native implementation of `_downloader.ts` + `cross/_cross_downloader.ts` +
/// `node/_node_downloader.ts`. Collapses the platform-specific TS variants into one
/// Foundation type built on top of `URLSession`.
///
/// `Downloader` is also the protocol type used by `ApiClient` to abstract over future
/// download backends (e.g. test doubles).
public protocol Downloader: Sendable {
    /// Downloads a file to the given location.
    ///
    /// - Parameters:
    ///   - params: The parameters for downloading the file.
    ///   - apiClient: The ApiClient to use for downloading.
    func download(_ params: DownloadFileParameters, apiClient: ApiClient) async throws
}

/// Default downloader backed by `URLSession`. Mirrors `NodeDownloader` from
/// `_node_downloader.ts` — supports writing a file resource to a local path, and writing
/// base64 video bytes directly to disk.
public final class URLSessionDownloader: Downloader, @unchecked Sendable {
    public init() {}

    public func download(
        _ params: DownloadFileParameters,
        apiClient: ApiClient
    ) async throws {
        let downloadPath = params.downloadPath
        // Empty path means "no-op" — matches TS where `if (params.downloadPath)` is the gate.
        if downloadPath.isEmpty { return }

        let result = try await Self.downloadFile(params, apiClient: apiClient)
        switch result {
        case .response(let resp):
            // Streamed file response from the API.
            guard let bodyData = resp.bodyData else {
                throw GenAIError.runtime("Downloaded HTTP response had no body data.")
            }
            do {
                let url = URL(fileURLWithPath: downloadPath)
                try bodyData.write(to: url, options: .atomic)
            } catch {
                throw GenAIError.runtime("Failed to write file to \(downloadPath): \(error)")
            }
        case .base64(let base64String):
            // GeneratedVideo / Video with inline `videoBytes` — TS writes base64-decoded bytes.
            guard let data = Data(base64Encoded: base64String) else {
                throw GenAIError.runtime("Failed to base64-decode video bytes.")
            }
            do {
                let url = URL(fileURLWithPath: downloadPath)
                try data.write(to: url, options: .atomic)
            } catch {
                throw GenAIError.runtime("Failed to write file to \(downloadPath): \(error)")
            }
        }
    }

    /// Internal discriminated result returned by `downloadFile` — mirrors the
    /// `HttpResponse | string` return type in TS.
    private enum DownloadResult {
        case response(HttpResponse)
        case base64(String)
    }

    private static func downloadFile(
        _ params: DownloadFileParameters,
        apiClient: ApiClient
    ) async throws -> DownloadResult {
        let nameOpt = try tFileName(params.file)
        if let name = nameOpt {
            let response = try await apiClient.request(HttpRequest(
                path: "files/\(name):download",
                queryParams: ["alt": "media"],
                httpMethod: .GET,
                httpOptions: params.config?.httpOptions,
                abortSignal: params.config?.abortSignal
            ))
            return .response(response)
        }
        if isGeneratedVideo(params.file) {
            if case .generatedVideo(let gv) = params.file,
               let bytes = gv.video?.videoBytes {
                return .base64(bytes)
            }
            throw GenAIError.runtime(
                "Failed to download generated video, Uri or videoBytes not found."
            )
        }
        if isVideo(params.file) {
            if case .video(let v) = params.file, let bytes = v.videoBytes {
                return .base64(bytes)
            }
            throw GenAIError.runtime(
                "Failed to download video, Uri or videoBytes not found."
            )
        }
        throw GenAIError.runtime("Unsupported file type")
    }
}
