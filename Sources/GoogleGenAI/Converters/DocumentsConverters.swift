// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

public func deleteDocumentConfigToMldev(
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

public func deleteDocumentParametersToMldev(
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
        _ = try deleteDocumentConfigToMldev(apiClient: apiClient, fromObject: configObj, parentObject: &toObject)
    }

    return toObject
}

public func getDocumentParametersToMldev(
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

public func listDocumentsConfigToMldev(
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

public func listDocumentsParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromParent = getValueByPath(.object(fromObject), ["parent"])
    if case .null = fromParent {} else {
        try setValueByPath(&toObject, ["_url", "parent"], fromParent)
    }

    let fromConfig = getValueByPath(.object(fromObject), ["config"])
    if case .object(let configObj) = fromConfig {
        _ = try listDocumentsConfigToMldev(apiClient: apiClient, fromObject: configObj, parentObject: &toObject)
    }

    return toObject
}

public func listDocumentsResponseFromMldev(
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

    let fromDocuments = getValueByPath(.object(fromObject), ["documents"])
    if case .null = fromDocuments {} else {
        try setValueByPath(&toObject, ["documents"], fromDocuments)
    }

    return toObject
}
