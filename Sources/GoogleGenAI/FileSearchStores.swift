// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Converter stubs (Wave 5)

// TODO Wave 5: Port from ./converters/_filesearchstores_converters.js
internal func createFileSearchStoreParametersToMldev(
    _ apiClient: ApiClient,
    _ fromObject: CreateFileSearchStoreParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (createFileSearchStoreParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_filesearchstores_converters.js
internal func getFileSearchStoreParametersToMldev(
    _ fromObject: GetFileSearchStoreParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (getFileSearchStoreParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_filesearchstores_converters.js
internal func deleteFileSearchStoreParametersToMldev(
    _ fromObject: DeleteFileSearchStoreParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (deleteFileSearchStoreParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_filesearchstores_converters.js
internal func listFileSearchStoresParametersToMldev(
    _ fromObject: ListFileSearchStoresParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (listFileSearchStoresParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_filesearchstores_converters.js
internal func listFileSearchStoresResponseFromMldev(
    _ fromObject: JSONValue
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (listFileSearchStoresResponseFromMldev)")
}

// TODO Wave 5: Port from ./converters/_filesearchstores_converters.js
internal func uploadToFileSearchStoreParametersToMldev(
    _ fromObject: UploadToFileSearchStoreParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (uploadToFileSearchStoreParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_filesearchstores_converters.js
internal func uploadToFileSearchStoreResumableResponseFromMldev(
    _ fromObject: JSONValue
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (uploadToFileSearchStoreResumableResponseFromMldev)")
}

// TODO Wave 5: Port from ./converters/_filesearchstores_converters.js
internal func importFileParametersToMldev(
    _ fromObject: ImportFileParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (importFileParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_filesearchstores_converters.js
internal func importFileOperationFromMldev(_ fromObject: JSONValue) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (importFileOperationFromMldev)")
}

// MARK: - FileSearchStores

public final class FileSearchStores: BaseModule, @unchecked Sendable {
    private let apiClient: ApiClient
    public let documents: Documents

    public init(apiClient: ApiClient, documents: Documents? = nil) {
        self.apiClient = apiClient
        self.documents = documents ?? Documents(apiClient: apiClient)
        super.init()
    }

    /// Lists file search stores.
    public func list(
        _ params: ListFileSearchStoresParameters = ListFileSearchStoresParameters()
    ) async throws -> Pager<FileSearchStore> {
        let initial = try await self.listInternal(params)
        return Pager<FileSearchStore>(
            PagedItem.fileSearchStores,
            { x in
                guard let p = x as? ListFileSearchStoresParameters else {
                    throw GenAIError.invalidArgument("Expected ListFileSearchStoresParameters")
                }
                return try await self.listInternal(p)
            },
            initial,
            params
        )
    }

    /// Uploads a file asynchronously to a given File Search Store.
    public func uploadToFileSearchStore(
        _ params: UploadToFileSearchStoreParameters
    ) async throws -> UploadToFileSearchStoreOperation {
        if self.apiClient.isVertexAI() {
            throw ApiError(
                message: "Gemini Enterprise Agent Platform (previously known as Vertex AI) does not support uploading files to a file search store.",
                status: 400
            )
        }
        return try await self.apiClient.uploadFileToFileSearchStore(
            fileSearchStoreName: params.fileSearchStoreName,
            file: params.file,
            config: params.config
        )
    }

    /// Downloads media using a Media ID or URI.
    public func downloadMedia(
        uri: String,
        config: DownloadMediaConfig? = nil
    ) async throws -> Data {
        if self.apiClient.isVertexAI() {
            throw ApiError(
                message: "This method is only supported in the Gemini Developer client.",
                status: 400
            )
        }

        guard let parsedUri = URL(string: uri, relativeTo: URL(string: "http://dummy.com")) else {
            throw GenAIError.invalidArgument("Invalid uri format: \(uri).")
        }
        var pathname = parsedUri.path
        if pathname.hasPrefix("/") {
            pathname = String(pathname.dropFirst())
        }

        if !pathname.contains("/media/") {
            throw ApiError(
                message: "Invalid uri format: \(uri). Expected to contain /media/",
                status: 400
            )
        }

        var queryParams: [String: String] = [:]
        if let comps = URLComponents(url: parsedUri, resolvingAgainstBaseURL: true),
           let items = comps.queryItems {
            for item in items {
                queryParams[item.name] = item.value ?? ""
            }
        }
        queryParams["alt"] = "media"

        let httpOptions = config?.httpOptions

        let response = try await self.apiClient.request(HttpRequest(
            path: pathname,
            queryParams: queryParams,
            body: nil,
            httpMethod: .GET,
            httpOptions: httpOptions
        ))

        if let data = response.bodyData {
            return data
        }
        throw GenAIError.runtime("Unexpected response type from downloadMedia")
    }

    /// Creates a File Search Store.
    public func create(
        _ params: CreateFileSearchStoreParameters
    ) async throws -> FileSearchStore {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            throw ApiError(
                message: "This method is only supported by the Gemini Developer API.",
                status: 400
            )
        } else {
            var body = createFileSearchStoreParametersToMldev(self.apiClient, params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("fileSearchStores", urlMap)
            } else {
                path = try formatMap("fileSearchStores", [:])
            }
            queryParams = extractStringMap(body["_query"])
            body.removeValue(forKey: "_url")
            body.removeValue(forKey: "_query")

            let bodyString = jsonValueObjectToString(body)
            let httpResponse = try await self.apiClient.request(HttpRequest(
                path: path,
                queryParams: queryParams,
                body: .string(bodyString),
                httpMethod: .POST,
                httpOptions: params.config?.httpOptions,
                abortSignal: params.config?.abortSignal
            ))
            let apiResponse = try httpResponse.json()
            return try decodeFromJSONValue(FileSearchStore.self, apiResponse)
        }
    }

    /// Gets a File Search Store.
    public func get(
        _ params: GetFileSearchStoreParameters
    ) async throws -> FileSearchStore {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            throw ApiError(
                message: "This method is only supported by the Gemini Developer API.",
                status: 400
            )
        } else {
            var body = getFileSearchStoreParametersToMldev(params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("{name}", urlMap)
            } else {
                path = try formatMap("{name}", [:])
            }
            queryParams = extractStringMap(body["_query"])
            body.removeValue(forKey: "_url")
            body.removeValue(forKey: "_query")

            let bodyString = jsonValueObjectToString(body)
            let httpResponse = try await self.apiClient.request(HttpRequest(
                path: path,
                queryParams: queryParams,
                body: .string(bodyString),
                httpMethod: .GET,
                httpOptions: params.config?.httpOptions,
                abortSignal: params.config?.abortSignal
            ))
            let apiResponse = try httpResponse.json()
            return try decodeFromJSONValue(FileSearchStore.self, apiResponse)
        }
    }

    /// Deletes a File Search Store.
    public func delete(_ params: DeleteFileSearchStoreParameters) async throws {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            throw ApiError(
                message: "This method is only supported by the Gemini Developer API.",
                status: 400
            )
        } else {
            var body = deleteFileSearchStoreParametersToMldev(params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("{name}", urlMap)
            } else {
                path = try formatMap("{name}", [:])
            }
            queryParams = extractStringMap(body["_query"])
            body.removeValue(forKey: "_url")
            body.removeValue(forKey: "_query")

            let bodyString = jsonValueObjectToString(body)
            _ = try await self.apiClient.request(HttpRequest(
                path: path,
                queryParams: queryParams,
                body: .string(bodyString),
                httpMethod: .DELETE,
                httpOptions: params.config?.httpOptions,
                abortSignal: params.config?.abortSignal
            ))
        }
    }

    private func listInternal(
        _ params: ListFileSearchStoresParameters
    ) async throws -> ListFileSearchStoresResponse {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            throw ApiError(
                message: "This method is only supported by the Gemini Developer API.",
                status: 400
            )
        } else {
            var body = listFileSearchStoresParametersToMldev(params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("fileSearchStores", urlMap)
            } else {
                path = try formatMap("fileSearchStores", [:])
            }
            queryParams = extractStringMap(body["_query"])
            body.removeValue(forKey: "_url")
            body.removeValue(forKey: "_query")

            let bodyString = jsonValueObjectToString(body)
            let httpResponse = try await self.apiClient.request(HttpRequest(
                path: path,
                queryParams: queryParams,
                body: .string(bodyString),
                httpMethod: .GET,
                httpOptions: params.config?.httpOptions,
                abortSignal: params.config?.abortSignal
            ))
            let apiResponse = try httpResponse.json()
            let resp = listFileSearchStoresResponseFromMldev(apiResponse)
            return try decodeFromJSONObject(ListFileSearchStoresResponse.self, resp)
        }
    }

    private func uploadToFileSearchStoreInternal(
        _ params: UploadToFileSearchStoreParameters
    ) async throws -> UploadToFileSearchStoreResumableResponse {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            throw ApiError(
                message: "This method is only supported by the Gemini Developer API.",
                status: 400
            )
        } else {
            var body = uploadToFileSearchStoreParametersToMldev(params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap(
                    "upload/v1beta/{file_search_store_name}:uploadToFileSearchStore",
                    urlMap
                )
            } else {
                path = try formatMap(
                    "upload/v1beta/{file_search_store_name}:uploadToFileSearchStore",
                    [:]
                )
            }
            queryParams = extractStringMap(body["_query"])
            body.removeValue(forKey: "_url")
            body.removeValue(forKey: "_query")

            let bodyString = jsonValueObjectToString(body)
            let httpResponse = try await self.apiClient.request(HttpRequest(
                path: path,
                queryParams: queryParams,
                body: .string(bodyString),
                httpMethod: .POST,
                httpOptions: params.config?.httpOptions,
                abortSignal: params.config?.abortSignal
            ))
            let apiResponse = try httpResponse.json()
            let resp = uploadToFileSearchStoreResumableResponseFromMldev(apiResponse)
            return try decodeFromJSONObject(UploadToFileSearchStoreResumableResponse.self, resp)
        }
    }

    /// Imports a File from File Service to a FileSearchStore.
    public func importFile(
        _ params: ImportFileParameters
    ) async throws -> ImportFileOperation {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            throw ApiError(
                message: "This method is only supported by the Gemini Developer API.",
                status: 400
            )
        } else {
            var body = importFileParametersToMldev(params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("{file_search_store_name}:importFile", urlMap)
            } else {
                path = try formatMap("{file_search_store_name}:importFile", [:])
            }
            queryParams = extractStringMap(body["_query"])
            body.removeValue(forKey: "_url")
            body.removeValue(forKey: "_query")

            let bodyString = jsonValueObjectToString(body)
            let httpResponse = try await self.apiClient.request(HttpRequest(
                path: path,
                queryParams: queryParams,
                body: .string(bodyString),
                httpMethod: .POST,
                httpOptions: params.config?.httpOptions,
                abortSignal: params.config?.abortSignal
            ))
            let apiResponse = try httpResponse.json()
            let resp = importFileOperationFromMldev(apiResponse)
            return try decodeFromJSONObject(ImportFileOperation.self, resp)
        }
    }
}
