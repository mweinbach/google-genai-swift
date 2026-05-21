// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

public func fetchPredictOperationParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    let toObject: [String: JSONValue] = [:]

    if case .null = getValueByPath(.object(fromObject), ["operationName"]) {} else {
        throw GenAIError.unsupported("operationName parameter is only supported in Gemini Enterprise Agent Platform mode, not in Gemini Developer API mode.")
    }

    if case .null = getValueByPath(.object(fromObject), ["resourceName"]) {} else {
        throw GenAIError.unsupported("resourceName parameter is only supported in Gemini Enterprise Agent Platform mode, not in Gemini Developer API mode.")
    }

    if case .null = getValueByPath(.object(fromObject), ["config"]) {} else {
        throw GenAIError.unsupported("config parameter is only supported in Gemini Enterprise Agent Platform mode, not in Gemini Developer API mode.")
    }

    return toObject
}

public func fetchPredictOperationParametersToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromOperationName = getValueByPath(.object(fromObject), ["operationName"])
    if case .null = fromOperationName {} else {
        try setValueByPath(&toObject, ["operationName"], fromOperationName)
    }

    let fromResourceName = getValueByPath(.object(fromObject), ["resourceName"])
    if case .null = fromResourceName {} else {
        try setValueByPath(&toObject, ["_url", "resourceName"], fromResourceName)
    }

    return toObject
}

public func generateVideosOperationFromMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromName = getValueByPath(.object(fromObject), ["name"])
    if case .null = fromName {} else {
        try setValueByPath(&toObject, ["name"], fromName)
    }

    let fromMetadata = getValueByPath(.object(fromObject), ["metadata"])
    if case .null = fromMetadata {} else {
        try setValueByPath(&toObject, ["metadata"], fromMetadata)
    }

    let fromDone = getValueByPath(.object(fromObject), ["done"])
    if case .null = fromDone {} else {
        try setValueByPath(&toObject, ["done"], fromDone)
    }

    let fromError = getValueByPath(.object(fromObject), ["error"])
    if case .null = fromError {} else {
        try setValueByPath(&toObject, ["error"], fromError)
    }

    let fromResponse = getValueByPath(.object(fromObject), ["response", "generateVideoResponse"])
    if case .object(let respObj) = fromResponse {
        var emptyParent: [String: JSONValue] = [:]
        let transformed = try generateVideosResponseFromMldev(apiClient: apiClient, fromObject: respObj, parentObject: &emptyParent)
        try setValueByPath(&toObject, ["response"], .object(transformed))
    }

    return toObject
}

public func generateVideosOperationFromVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromName = getValueByPath(.object(fromObject), ["name"])
    if case .null = fromName {} else {
        try setValueByPath(&toObject, ["name"], fromName)
    }

    let fromMetadata = getValueByPath(.object(fromObject), ["metadata"])
    if case .null = fromMetadata {} else {
        try setValueByPath(&toObject, ["metadata"], fromMetadata)
    }

    let fromDone = getValueByPath(.object(fromObject), ["done"])
    if case .null = fromDone {} else {
        try setValueByPath(&toObject, ["done"], fromDone)
    }

    let fromError = getValueByPath(.object(fromObject), ["error"])
    if case .null = fromError {} else {
        try setValueByPath(&toObject, ["error"], fromError)
    }

    let fromResponse = getValueByPath(.object(fromObject), ["response"])
    if case .object(let respObj) = fromResponse {
        var emptyParent: [String: JSONValue] = [:]
        let transformed = try generateVideosResponseFromVertex(apiClient: apiClient, fromObject: respObj, parentObject: &emptyParent)
        try setValueByPath(&toObject, ["response"], .object(transformed))
    }

    return toObject
}

public func generateVideosResponseFromMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromGeneratedVideos = getValueByPath(.object(fromObject), ["generatedSamples"])
    if case .array(let arr) = fromGeneratedVideos {
        var transformedList: [JSONValue] = []
        for item in arr {
            if case .object(let itemObj) = item {
                var emptyParent: [String: JSONValue] = [:]
                let t = try generatedVideoFromMldev(apiClient: apiClient, fromObject: itemObj, parentObject: &emptyParent)
                transformedList.append(.object(t))
            } else {
                transformedList.append(item)
            }
        }
        try setValueByPath(&toObject, ["generatedVideos"], .array(transformedList))
    }

    let fromRaiMediaFilteredCount = getValueByPath(.object(fromObject), ["raiMediaFilteredCount"])
    if case .null = fromRaiMediaFilteredCount {} else {
        try setValueByPath(&toObject, ["raiMediaFilteredCount"], fromRaiMediaFilteredCount)
    }

    let fromRaiMediaFilteredReasons = getValueByPath(.object(fromObject), ["raiMediaFilteredReasons"])
    if case .null = fromRaiMediaFilteredReasons {} else {
        try setValueByPath(&toObject, ["raiMediaFilteredReasons"], fromRaiMediaFilteredReasons)
    }

    return toObject
}

public func generateVideosResponseFromVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromGeneratedVideos = getValueByPath(.object(fromObject), ["videos"])
    if case .array(let arr) = fromGeneratedVideos {
        var transformedList: [JSONValue] = []
        for item in arr {
            if case .object(let itemObj) = item {
                var emptyParent: [String: JSONValue] = [:]
                let t = try generatedVideoFromVertex(apiClient: apiClient, fromObject: itemObj, parentObject: &emptyParent)
                transformedList.append(.object(t))
            } else {
                transformedList.append(item)
            }
        }
        try setValueByPath(&toObject, ["generatedVideos"], .array(transformedList))
    }

    let fromRaiMediaFilteredCount = getValueByPath(.object(fromObject), ["raiMediaFilteredCount"])
    if case .null = fromRaiMediaFilteredCount {} else {
        try setValueByPath(&toObject, ["raiMediaFilteredCount"], fromRaiMediaFilteredCount)
    }

    let fromRaiMediaFilteredReasons = getValueByPath(.object(fromObject), ["raiMediaFilteredReasons"])
    if case .null = fromRaiMediaFilteredReasons {} else {
        try setValueByPath(&toObject, ["raiMediaFilteredReasons"], fromRaiMediaFilteredReasons)
    }

    return toObject
}

public func generatedVideoFromMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromVideo = getValueByPath(.object(fromObject), ["video"])
    if case .object(let videoObj) = fromVideo {
        var emptyParent: [String: JSONValue] = [:]
        let transformed = try videoFromMldev(apiClient: apiClient, fromObject: videoObj, parentObject: &emptyParent)
        try setValueByPath(&toObject, ["video"], .object(transformed))
    }

    return toObject
}

public func generatedVideoFromVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    // `_self` is a special pseudo-key meaning "use the object itself".
    let fromVideo = getValueByPath(.object(fromObject), ["_self"])
    if case .null = fromVideo {} else {
        let videoObj: [String: JSONValue]
        if case .object(let o) = fromVideo {
            videoObj = o
        } else {
            videoObj = fromObject
        }
        var emptyParent: [String: JSONValue] = [:]
        let transformed = try videoFromVertex(apiClient: apiClient, fromObject: videoObj, parentObject: &emptyParent)
        try setValueByPath(&toObject, ["video"], .object(transformed))
    }

    return toObject
}

public func getOperationParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromOperationName = getValueByPath(.object(fromObject), ["operationName"])
    if case .null = fromOperationName {} else {
        try setValueByPath(&toObject, ["_url", "operationName"], fromOperationName)
    }

    return toObject
}

public func getOperationParametersToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromOperationName = getValueByPath(.object(fromObject), ["operationName"])
    if case .null = fromOperationName {} else {
        try setValueByPath(&toObject, ["_url", "operationName"], fromOperationName)
    }

    return toObject
}

public func importFileOperationFromMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromName = getValueByPath(.object(fromObject), ["name"])
    if case .null = fromName {} else {
        try setValueByPath(&toObject, ["name"], fromName)
    }

    let fromMetadata = getValueByPath(.object(fromObject), ["metadata"])
    if case .null = fromMetadata {} else {
        try setValueByPath(&toObject, ["metadata"], fromMetadata)
    }

    let fromDone = getValueByPath(.object(fromObject), ["done"])
    if case .null = fromDone {} else {
        try setValueByPath(&toObject, ["done"], fromDone)
    }

    let fromError = getValueByPath(.object(fromObject), ["error"])
    if case .null = fromError {} else {
        try setValueByPath(&toObject, ["error"], fromError)
    }

    let fromResponse = getValueByPath(.object(fromObject), ["response"])
    if case .object(let respObj) = fromResponse {
        var emptyParent: [String: JSONValue] = [:]
        let transformed = try importFileResponseFromMldev(apiClient: apiClient, fromObject: respObj, parentObject: &emptyParent)
        try setValueByPath(&toObject, ["response"], .object(transformed))
    }

    return toObject
}

public func importFileResponseFromMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromSdkHttpResponse = getValueByPath(.object(fromObject), ["sdkHttpResponse"])
    if case .null = fromSdkHttpResponse {} else {
        try setValueByPath(&toObject, ["sdkHttpResponse"], fromSdkHttpResponse)
    }

    let fromParent = getValueByPath(.object(fromObject), ["parent"])
    if case .null = fromParent {} else {
        try setValueByPath(&toObject, ["parent"], fromParent)
    }

    let fromDocumentName = getValueByPath(.object(fromObject), ["documentName"])
    if case .null = fromDocumentName {} else {
        try setValueByPath(&toObject, ["documentName"], fromDocumentName)
    }

    return toObject
}

public func uploadToFileSearchStoreOperationFromMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromName = getValueByPath(.object(fromObject), ["name"])
    if case .null = fromName {} else {
        try setValueByPath(&toObject, ["name"], fromName)
    }

    let fromMetadata = getValueByPath(.object(fromObject), ["metadata"])
    if case .null = fromMetadata {} else {
        try setValueByPath(&toObject, ["metadata"], fromMetadata)
    }

    let fromDone = getValueByPath(.object(fromObject), ["done"])
    if case .null = fromDone {} else {
        try setValueByPath(&toObject, ["done"], fromDone)
    }

    let fromError = getValueByPath(.object(fromObject), ["error"])
    if case .null = fromError {} else {
        try setValueByPath(&toObject, ["error"], fromError)
    }

    let fromResponse = getValueByPath(.object(fromObject), ["response"])
    if case .object(let respObj) = fromResponse {
        var emptyParent: [String: JSONValue] = [:]
        let transformed = try uploadToFileSearchStoreResponseFromMldev(apiClient: apiClient, fromObject: respObj, parentObject: &emptyParent)
        try setValueByPath(&toObject, ["response"], .object(transformed))
    }

    return toObject
}

public func uploadToFileSearchStoreResponseFromMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromSdkHttpResponse = getValueByPath(.object(fromObject), ["sdkHttpResponse"])
    if case .null = fromSdkHttpResponse {} else {
        try setValueByPath(&toObject, ["sdkHttpResponse"], fromSdkHttpResponse)
    }

    let fromParent = getValueByPath(.object(fromObject), ["parent"])
    if case .null = fromParent {} else {
        try setValueByPath(&toObject, ["parent"], fromParent)
    }

    let fromDocumentName = getValueByPath(.object(fromObject), ["documentName"])
    if case .null = fromDocumentName {} else {
        try setValueByPath(&toObject, ["documentName"], fromDocumentName)
    }

    return toObject
}

public func videoFromMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromUri = getValueByPath(.object(fromObject), ["uri"])
    if case .null = fromUri {} else {
        try setValueByPath(&toObject, ["uri"], fromUri)
    }

    let fromVideoBytes = getValueByPath(.object(fromObject), ["encodedVideo"])
    if case .null = fromVideoBytes {} else {
        let transformed = try tBytes(fromVideoBytes)
        try setValueByPath(&toObject, ["videoBytes"], .string(transformed))
    }

    let fromMimeType = getValueByPath(.object(fromObject), ["encoding"])
    if case .null = fromMimeType {} else {
        try setValueByPath(&toObject, ["mimeType"], fromMimeType)
    }

    return toObject
}

public func videoFromVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromUri = getValueByPath(.object(fromObject), ["gcsUri"])
    if case .null = fromUri {} else {
        try setValueByPath(&toObject, ["uri"], fromUri)
    }

    let fromVideoBytes = getValueByPath(.object(fromObject), ["bytesBase64Encoded"])
    if case .null = fromVideoBytes {} else {
        let transformed = try tBytes(fromVideoBytes)
        try setValueByPath(&toObject, ["videoBytes"], .string(transformed))
    }

    let fromMimeType = getValueByPath(.object(fromObject), ["mimeType"])
    if case .null = fromMimeType {} else {
        try setValueByPath(&toObject, ["mimeType"], fromMimeType)
    }

    return toObject
}
