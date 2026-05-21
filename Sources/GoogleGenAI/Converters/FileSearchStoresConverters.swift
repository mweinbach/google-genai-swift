// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

public func createFileSearchStoreConfigToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromDisplayName = getValueByPath(.object(fromObject), ["displayName"])
    if case .null = fromDisplayName {} else {
        try setValueByPath(&parentObject, ["displayName"], fromDisplayName)
    }

    let fromEmbeddingModel = getValueByPath(.object(fromObject), ["embeddingModel"])
    if case .null = fromEmbeddingModel {} else {
        let transformed = try tModel(apiClient: apiClient, model: fromEmbeddingModel)
        try setValueByPath(&parentObject, ["embeddingModel"], .string(transformed))
    }

    return toObject
}

public func createFileSearchStoreParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromConfig = getValueByPath(.object(fromObject), ["config"])
    if case .object(let configObj) = fromConfig {
        _ = try createFileSearchStoreConfigToMldev(apiClient: apiClient, fromObject: configObj, parentObject: &toObject)
    }

    return toObject
}

public func deleteFileSearchStoreConfigToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromForce = getValueByPath(.object(fromObject), ["force"])
    if case .null = fromForce {} else {
        try setValueByPath(&parentObject, ["_query", "force"], fromForce)
    }

    return toObject
}

public func deleteFileSearchStoreParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromName = getValueByPath(.object(fromObject), ["name"])
    if case .null = fromName {} else {
        try setValueByPath(&toObject, ["_url", "name"], fromName)
    }

    let fromConfig = getValueByPath(.object(fromObject), ["config"])
    if case .object(let configObj) = fromConfig {
        _ = try deleteFileSearchStoreConfigToMldev(apiClient: apiClient, fromObject: configObj, parentObject: &toObject)
    }

    return toObject
}

public func getFileSearchStoreParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromName = getValueByPath(.object(fromObject), ["name"])
    if case .null = fromName {} else {
        try setValueByPath(&toObject, ["_url", "name"], fromName)
    }

    return toObject
}

public func importFileConfigToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromCustomMetadata = getValueByPath(.object(fromObject), ["customMetadata"])
    if case .null = fromCustomMetadata {} else {
        try setValueByPath(&parentObject, ["customMetadata"], fromCustomMetadata)
    }

    let fromChunkingConfig = getValueByPath(.object(fromObject), ["chunkingConfig"])
    if case .null = fromChunkingConfig {} else {
        try setValueByPath(&parentObject, ["chunkingConfig"], fromChunkingConfig)
    }

    return toObject
}

public func importFileParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromFileSearchStoreName = getValueByPath(.object(fromObject), ["fileSearchStoreName"])
    if case .null = fromFileSearchStoreName {} else {
        try setValueByPath(&toObject, ["_url", "file_search_store_name"], fromFileSearchStoreName)
    }

    let fromFileName = getValueByPath(.object(fromObject), ["fileName"])
    if case .null = fromFileName {} else {
        try setValueByPath(&toObject, ["fileName"], fromFileName)
    }

    let fromConfig = getValueByPath(.object(fromObject), ["config"])
    if case .object(let configObj) = fromConfig {
        _ = try importFileConfigToMldev(apiClient: apiClient, fromObject: configObj, parentObject: &toObject)
    }

    return toObject
}

// Note: `importFileResponseFromMldev` is defined in OperationsConverters.swift
// (TS exposes the same function in both `_filesearchstores_converters.ts` and
// `_operations_converters.ts`; Swift requires a single definition.)

public func listFileSearchStoresConfigToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromPageSize = getValueByPath(.object(fromObject), ["pageSize"])
    if case .null = fromPageSize {} else {
        try setValueByPath(&parentObject, ["_query", "pageSize"], fromPageSize)
    }

    let fromPageToken = getValueByPath(.object(fromObject), ["pageToken"])
    if case .null = fromPageToken {} else {
        try setValueByPath(&parentObject, ["_query", "pageToken"], fromPageToken)
    }

    return toObject
}

public func listFileSearchStoresParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromConfig = getValueByPath(.object(fromObject), ["config"])
    if case .object(let configObj) = fromConfig {
        _ = try listFileSearchStoresConfigToMldev(apiClient: apiClient, fromObject: configObj, parentObject: &toObject)
    }

    return toObject
}

public func listFileSearchStoresResponseFromMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromSdkHttpResponse = getValueByPath(.object(fromObject), ["sdkHttpResponse"])
    if case .null = fromSdkHttpResponse {} else {
        try setValueByPath(&toObject, ["sdkHttpResponse"], fromSdkHttpResponse)
    }

    let fromNextPageToken = getValueByPath(.object(fromObject), ["nextPageToken"])
    if case .null = fromNextPageToken {} else {
        try setValueByPath(&toObject, ["nextPageToken"], fromNextPageToken)
    }

    let fromFileSearchStores = getValueByPath(.object(fromObject), ["fileSearchStores"])
    if case .null = fromFileSearchStores {} else {
        try setValueByPath(&toObject, ["fileSearchStores"], fromFileSearchStores)
    }

    return toObject
}

public func uploadToFileSearchStoreConfigToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromMimeType = getValueByPath(.object(fromObject), ["mimeType"])
    if case .null = fromMimeType {} else {
        try setValueByPath(&parentObject, ["mimeType"], fromMimeType)
    }

    let fromDisplayName = getValueByPath(.object(fromObject), ["displayName"])
    if case .null = fromDisplayName {} else {
        try setValueByPath(&parentObject, ["displayName"], fromDisplayName)
    }

    let fromCustomMetadata = getValueByPath(.object(fromObject), ["customMetadata"])
    if case .null = fromCustomMetadata {} else {
        try setValueByPath(&parentObject, ["customMetadata"], fromCustomMetadata)
    }

    let fromChunkingConfig = getValueByPath(.object(fromObject), ["chunkingConfig"])
    if case .null = fromChunkingConfig {} else {
        try setValueByPath(&parentObject, ["chunkingConfig"], fromChunkingConfig)
    }

    return toObject
}

public func uploadToFileSearchStoreParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromFileSearchStoreName = getValueByPath(.object(fromObject), ["fileSearchStoreName"])
    if case .null = fromFileSearchStoreName {} else {
        try setValueByPath(&toObject, ["_url", "file_search_store_name"], fromFileSearchStoreName)
    }

    let fromConfig = getValueByPath(.object(fromObject), ["config"])
    if case .object(let configObj) = fromConfig {
        _ = try uploadToFileSearchStoreConfigToMldev(apiClient: apiClient, fromObject: configObj, parentObject: &toObject)
    }

    return toObject
}

public func uploadToFileSearchStoreResumableResponseFromMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromSdkHttpResponse = getValueByPath(.object(fromObject), ["sdkHttpResponse"])
    if case .null = fromSdkHttpResponse {} else {
        try setValueByPath(&toObject, ["sdkHttpResponse"], fromSdkHttpResponse)
    }

    return toObject
}
