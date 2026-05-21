// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Converter stubs (Wave 5)

// TODO Wave 5: Port from ./converters/_files_converters.js
internal func listFilesParametersToMldev(
    _ fromObject: ListFilesParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (listFilesParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_files_converters.js
internal func listFilesResponseFromMldev(_ fromObject: JSONValue) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (listFilesResponseFromMldev)")
}

// TODO Wave 5: Port from ./converters/_files_converters.js
internal func createFileParametersToMldev(
    _ fromObject: CreateFileParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (createFileParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_files_converters.js
internal func createFileResponseFromMldev(_ fromObject: JSONValue) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (createFileResponseFromMldev)")
}

// TODO Wave 5: Port from ./converters/_files_converters.js
internal func getFileParametersToMldev(
    _ fromObject: GetFileParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (getFileParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_files_converters.js
internal func deleteFileParametersToMldev(
    _ fromObject: DeleteFileParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (deleteFileParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_files_converters.js
internal func deleteFileResponseFromMldev(_ fromObject: JSONValue) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (deleteFileResponseFromMldev)")
}

// TODO Wave 5: Port from ./converters/_files_converters.js
internal func internalRegisterFilesParametersToMldev(
    _ fromObject: InternalRegisterFilesParameters
) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (internalRegisterFilesParametersToMldev)")
}

// TODO Wave 5: Port from ./converters/_files_converters.js
internal func registerFilesResponseFromMldev(_ fromObject: JSONValue) -> [String: JSONValue] {
    fatalError("Not yet ported — see Wave 5 (registerFilesResponseFromMldev)")
}

// MARK: - Files

public final class Files: BaseModule, @unchecked Sendable {
    private let apiClient: ApiClient

    public init(apiClient: ApiClient) {
        self.apiClient = apiClient
        super.init()
    }

    /// Lists files.
    public func list(
        _ params: ListFilesParameters = ListFilesParameters()
    ) async throws -> Pager<File> {
        let initial = try await self.listInternal(params)
        return Pager<File>(
            PagedItem.files,
            { x in
                guard let p = x as? ListFilesParameters else {
                    throw GenAIError.invalidArgument("Expected ListFilesParameters")
                }
                return try await self.listInternal(p)
            },
            initial,
            params
        )
    }

    /// Uploads a file asynchronously to the Gemini API.
    public func upload(_ params: UploadFileParameters) async throws -> File {
        if self.apiClient.isVertexAI() {
            throw ApiError(
                message: "Gemini Enterprise Agent Platform (previously known as Vertex AI) does not support uploading files. You can share files through a GCS bucket.",
                status: 400
            )
        }
        return try await self.apiClient.uploadFile(params.file, config: params.config)
    }

    /// Downloads a remotely stored file asynchronously to a location specified in the `params` object.
    public func download(_ params: DownloadFileParameters) async throws {
        try await self.apiClient.downloadFile(params)
    }

    /// Registers Google Cloud Storage files for use with the API.
    public func registerFiles(
        _ params: RegisterFilesParameters
    ) async throws -> RegisterFilesResponse {
        _ = params
        throw ApiError(
            message: "registerFiles is only supported in Node.js environments.",
            status: 400
        )
    }

    internal func _registerFiles(
        _ params: InternalRegisterFilesParameters
    ) async throws -> RegisterFilesResponse {
        return try await self.registerFilesInternal(params)
    }

    private func listInternal(
        _ params: ListFilesParameters
    ) async throws -> ListFilesResponse {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            throw ApiError(
                message: "This method is only supported by the Gemini Developer API.",
                status: 400
            )
        } else {
            var body = listFilesParametersToMldev(params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("files", urlMap)
            } else {
                path = try formatMap("files", [:])
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
            let resp = listFilesResponseFromMldev(apiResponse)
            let typed = try decodeFromJSONObject(ListFilesResponse.self, resp)
            typed.sdkHttpResponse = HttpResponse(headers: httpResponse.headers, bodyData: nil)
            return typed
        }
    }

    private func createInternal(
        _ params: CreateFileParameters
    ) async throws -> CreateFileResponse {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            throw ApiError(
                message: "This method is only supported by the Gemini Developer API.",
                status: 400
            )
        } else {
            var body = createFileParametersToMldev(params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("upload/v1beta/files", urlMap)
            } else {
                path = try formatMap("upload/v1beta/files", [:])
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
            let resp = createFileResponseFromMldev(apiResponse)
            return try decodeFromJSONObject(CreateFileResponse.self, resp)
        }
    }

    /// Retrieves the file information from the service.
    public func get(_ params: GetFileParameters) async throws -> File {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            throw ApiError(
                message: "This method is only supported by the Gemini Developer API.",
                status: 400
            )
        } else {
            var body = getFileParametersToMldev(params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("files/{file}", urlMap)
            } else {
                path = try formatMap("files/{file}", [:])
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
            return try decodeFromJSONValue(File.self, apiResponse)
        }
    }

    /// Deletes a remotely stored file.
    public func delete(
        _ params: DeleteFileParameters
    ) async throws -> DeleteFileResponse {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            throw ApiError(
                message: "This method is only supported by the Gemini Developer API.",
                status: 400
            )
        } else {
            var body = deleteFileParametersToMldev(params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("files/{file}", urlMap)
            } else {
                path = try formatMap("files/{file}", [:])
            }
            queryParams = extractStringMap(body["_query"])
            body.removeValue(forKey: "_url")
            body.removeValue(forKey: "_query")

            let bodyString = jsonValueObjectToString(body)
            let httpResponse = try await self.apiClient.request(HttpRequest(
                path: path,
                queryParams: queryParams,
                body: .string(bodyString),
                httpMethod: .DELETE,
                httpOptions: params.config?.httpOptions,
                abortSignal: params.config?.abortSignal
            ))
            let apiResponse = try httpResponse.json()
            let resp = deleteFileResponseFromMldev(apiResponse)
            let typed = try decodeFromJSONObject(DeleteFileResponse.self, resp)
            typed.sdkHttpResponse = HttpResponse(headers: httpResponse.headers, bodyData: nil)
            return typed
        }
    }

    private func registerFilesInternal(
        _ params: InternalRegisterFilesParameters
    ) async throws -> RegisterFilesResponse {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            throw ApiError(
                message: "This method is only supported by the Gemini Developer API.",
                status: 400
            )
        } else {
            var body = internalRegisterFilesParametersToMldev(params)
            if case .object(let urlMap) = body["_url"] ?? .null {
                path = try formatMap("files:register", urlMap)
            } else {
                path = try formatMap("files:register", [:])
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
            let resp = registerFilesResponseFromMldev(apiResponse)
            return try decodeFromJSONObject(RegisterFilesResponse.self, resp)
        }
    }
}
