// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Converter shims
//
// Local-typed wrappers that bridge strongly-typed parameter structs to the
// JSON-based converter functions in `Converters/FileSearchStoresConverters.swift`
// (and `Converters/OperationsConverters.swift`).

private func _fsObject<T: Encodable>(_ value: T) throws -> [String: JSONValue] {
    return try jsonObject(value)
}

private func _fsAsObject(_ value: JSONValue) -> [String: JSONValue] {
    if case .object(let o) = value { return o }
    return [:]
}

private func _fsMerge(_ dst: inout [String: JSONValue], _ src: [String: JSONValue]) {
    for (k, v) in src { dst[k] = v }
}

internal func createFileSearchStoreParametersToMldevShim(
    _ apiClient: ApiClient,
    _ fromObject: CreateFileSearchStoreParameters
) throws -> [String: JSONValue] {
    let dict = try _fsObject(fromObject)
    var parent: [String: JSONValue] = [:]
    let inner = try createFileSearchStoreParametersToMldev(
        apiClient: apiClient, fromObject: dict, parentObject: &parent
    )
    _fsMerge(&parent, inner)
    return parent
}

internal func getFileSearchStoreParametersToMldevShim(
    _ apiClient: ApiClient,
    _ fromObject: GetFileSearchStoreParameters
) throws -> [String: JSONValue] {
    let dict = try _fsObject(fromObject)
    var parent: [String: JSONValue] = [:]
    let inner = try getFileSearchStoreParametersToMldev(
        apiClient: apiClient, fromObject: dict, parentObject: &parent
    )
    _fsMerge(&parent, inner)
    return parent
}

internal func deleteFileSearchStoreParametersToMldevShim(
    _ apiClient: ApiClient,
    _ fromObject: DeleteFileSearchStoreParameters
) throws -> [String: JSONValue] {
    let dict = try _fsObject(fromObject)
    var parent: [String: JSONValue] = [:]
    let inner = try deleteFileSearchStoreParametersToMldev(
        apiClient: apiClient, fromObject: dict, parentObject: &parent
    )
    _fsMerge(&parent, inner)
    return parent
}

internal func listFileSearchStoresParametersToMldevShim(
    _ apiClient: ApiClient,
    _ fromObject: ListFileSearchStoresParameters
) throws -> [String: JSONValue] {
    let dict = try _fsObject(fromObject)
    var parent: [String: JSONValue] = [:]
    let inner = try listFileSearchStoresParametersToMldev(
        apiClient: apiClient, fromObject: dict, parentObject: &parent
    )
    _fsMerge(&parent, inner)
    return parent
}

internal func listFileSearchStoresResponseFromMldevShim(
    _ apiClient: ApiClient,
    _ fromObject: JSONValue
) throws -> [String: JSONValue] {
    let dict = _fsAsObject(fromObject)
    var parent: [String: JSONValue] = [:]
    return try listFileSearchStoresResponseFromMldev(
        apiClient: apiClient, fromObject: dict, parentObject: &parent
    )
}

internal func uploadToFileSearchStoreParametersToMldevShim(
    _ apiClient: ApiClient,
    _ fromObject: UploadToFileSearchStoreParameters
) throws -> [String: JSONValue] {
    // `file` is a non-Codable FileInput (uploaded separately via multipart);
    // hand-build the dict, exclude `file`, include `config` if present.
    var dict: [String: JSONValue] = [
        "fileSearchStoreName": .string(fromObject.fileSearchStoreName)
    ]
    if let config = fromObject.config {
        let configDict = try jsonObject(config)
        dict["config"] = .object(configDict)
    }
    var parent: [String: JSONValue] = [:]
    let inner = try uploadToFileSearchStoreParametersToMldev(
        apiClient: apiClient, fromObject: dict, parentObject: &parent
    )
    _fsMerge(&parent, inner)
    return parent
}

internal func uploadToFileSearchStoreResumableResponseFromMldevShim(
    _ apiClient: ApiClient,
    _ fromObject: JSONValue
) throws -> [String: JSONValue] {
    let dict = _fsAsObject(fromObject)
    var parent: [String: JSONValue] = [:]
    return try uploadToFileSearchStoreResumableResponseFromMldev(
        apiClient: apiClient, fromObject: dict, parentObject: &parent
    )
}

internal func importFileParametersToMldevShim(
    _ apiClient: ApiClient,
    _ fromObject: ImportFileParameters
) throws -> [String: JSONValue] {
    let dict = try _fsObject(fromObject)
    var parent: [String: JSONValue] = [:]
    let inner = try importFileParametersToMldev(
        apiClient: apiClient, fromObject: dict, parentObject: &parent
    )
    _fsMerge(&parent, inner)
    return parent
}

internal func importFileOperationFromMldevShim(
    _ apiClient: ApiClient,
    _ fromObject: JSONValue
) throws -> [String: JSONValue] {
    let dict = _fsAsObject(fromObject)
    var parent: [String: JSONValue] = [:]
    return try importFileOperationFromMldev(
        apiClient: apiClient, fromObject: dict, parentObject: &parent
    )
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
            var body = try createFileSearchStoreParametersToMldevShim(self.apiClient, params)
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
            var body = try getFileSearchStoreParametersToMldevShim(self.apiClient, params)
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
            var body = try deleteFileSearchStoreParametersToMldevShim(self.apiClient, params)
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
            var body = try listFileSearchStoresParametersToMldevShim(self.apiClient, params)
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
            let resp = try listFileSearchStoresResponseFromMldevShim(self.apiClient, apiResponse)
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
            var body = try uploadToFileSearchStoreParametersToMldevShim(self.apiClient, params)
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
            let resp = try uploadToFileSearchStoreResumableResponseFromMldevShim(self.apiClient, apiResponse)
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
            var body = try importFileParametersToMldevShim(self.apiClient, params)
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
            let resp = try importFileOperationFromMldevShim(self.apiClient, apiResponse)
            return try decodeFromJSONObject(ImportFileOperation.self, resp)
        }
    }
}
