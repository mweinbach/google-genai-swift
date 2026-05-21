// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

public func createFileParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromFile = getValueByPath(.object(fromObject), ["file"])
    if case .null = fromFile {} else {
        try setValueByPath(&toObject, ["file"], fromFile)
    }

    return toObject
}

public func createFileResponseFromMldev(
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

public func deleteFileParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromName = getValueByPath(.object(fromObject), ["name"])
    if case .null = fromName {} else {
        let nameString: String
        if case .string(let s) = fromName { nameString = s } else {
            throw GenAIError.invalidArgument("name must be a string")
        }
        if let transformed = try tFileName(.string(nameString)) {
            try setValueByPath(&toObject, ["_url", "file"], .string(transformed))
        }
    }

    return toObject
}

public func deleteFileResponseFromMldev(
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

public func getFileParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromName = getValueByPath(.object(fromObject), ["name"])
    if case .null = fromName {} else {
        let nameString: String
        if case .string(let s) = fromName { nameString = s } else {
            throw GenAIError.invalidArgument("name must be a string")
        }
        if let transformed = try tFileName(.string(nameString)) {
            try setValueByPath(&toObject, ["_url", "file"], .string(transformed))
        }
    }

    return toObject
}

public func internalRegisterFilesParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromUris = getValueByPath(.object(fromObject), ["uris"])
    if case .null = fromUris {} else {
        try setValueByPath(&toObject, ["uris"], fromUris)
    }

    return toObject
}

public func listFilesConfigToMldev(
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

public func listFilesParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromConfig = getValueByPath(.object(fromObject), ["config"])
    if case .object(let configObj) = fromConfig {
        _ = try listFilesConfigToMldev(apiClient: apiClient, fromObject: configObj, parentObject: &toObject)
    }

    return toObject
}

public func listFilesResponseFromMldev(
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

    let fromFiles = getValueByPath(.object(fromObject), ["files"])
    if case .null = fromFiles {} else {
        try setValueByPath(&toObject, ["files"], fromFiles)
    }

    return toObject
}

public func registerFilesResponseFromMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromSdkHttpResponse = getValueByPath(.object(fromObject), ["sdkHttpResponse"])
    if case .null = fromSdkHttpResponse {} else {
        try setValueByPath(&toObject, ["sdkHttpResponse"], fromSdkHttpResponse)
    }

    let fromFiles = getValueByPath(.object(fromObject), ["files"])
    if case .null = fromFiles {} else {
        try setValueByPath(&toObject, ["files"], fromFiles)
    }

    return toObject
}
