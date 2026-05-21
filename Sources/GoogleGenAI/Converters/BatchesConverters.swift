// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

// NOTE: The following converters are also defined in `_batches_converters.ts` but are
// duplicated with the same body in `_live_converters.ts`. To avoid Swift name collisions
// inside a single module, this file relies on the definitions in `LiveConverters.swift`:
//   authConfigToMldev, blobToMldev, contentToMldev, fileDataToMldev,
//   functionCallToMldev, googleMapsToMldev, googleSearchToMldev,
//   partToMldev, safetySettingToMldev, toolToMldev.

public func batchJobDestinationFromMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromFileName = getValueByPath(.object(fromObject), ["responsesFile"])
    if case .null = fromFileName {} else {
        try setValueByPath(&toObject, ["fileName"], fromFileName)
    }

    let fromInlinedResponses = getValueByPath(.object(fromObject), ["inlinedResponses", "inlinedResponses"])
    if case .null = fromInlinedResponses {} else {
        var transformed: JSONValue = fromInlinedResponses
        if case .array(let arr) = fromInlinedResponses {
            var mapped: [JSONValue] = []
            for item in arr {
                if case .object(let itemObj) = item {
                    var dummy: [String: JSONValue] = [:]
                    let result = try inlinedResponseFromMldev(apiClient: apiClient, fromObject: itemObj, parentObject: &dummy)
                    mapped.append(.object(result))
                } else {
                    mapped.append(item)
                }
            }
            transformed = .array(mapped)
        }
        try setValueByPath(&toObject, ["inlinedResponses"], transformed)
    }

    let fromInlinedEmbedContentResponses = getValueByPath(.object(fromObject), ["inlinedEmbedContentResponses", "inlinedResponses"])
    if case .null = fromInlinedEmbedContentResponses {} else {
        try setValueByPath(&toObject, ["inlinedEmbedContentResponses"], fromInlinedEmbedContentResponses)
    }

    return toObject
}

public func batchJobDestinationFromVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromFormat = getValueByPath(.object(fromObject), ["predictionsFormat"])
    if case .null = fromFormat {} else {
        try setValueByPath(&toObject, ["format"], fromFormat)
    }

    let fromGcsUri = getValueByPath(.object(fromObject), ["gcsDestination", "outputUriPrefix"])
    if case .null = fromGcsUri {} else {
        try setValueByPath(&toObject, ["gcsUri"], fromGcsUri)
    }

    let fromBigqueryUri = getValueByPath(.object(fromObject), ["bigqueryDestination", "outputUri"])
    if case .null = fromBigqueryUri {} else {
        try setValueByPath(&toObject, ["bigqueryUri"], fromBigqueryUri)
    }

    let fromVertexDataset = getValueByPath(.object(fromObject), ["vertexMultimodalDatasetDestination"])
    if case .object(let vdObj) = fromVertexDataset {
        var dummy: [String: JSONValue] = [:]
        let result = try vertexMultimodalDatasetDestinationFromVertex(apiClient: apiClient, fromObject: vdObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["vertexDataset"], .object(result))
    }

    return toObject
}

public func batchJobDestinationToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromFormat = getValueByPath(.object(fromObject), ["format"])
    if case .null = fromFormat {} else {
        try setValueByPath(&toObject, ["predictionsFormat"], fromFormat)
    }

    let fromGcsUri = getValueByPath(.object(fromObject), ["gcsUri"])
    if case .null = fromGcsUri {} else {
        try setValueByPath(&toObject, ["gcsDestination", "outputUriPrefix"], fromGcsUri)
    }

    let fromBigqueryUri = getValueByPath(.object(fromObject), ["bigqueryUri"])
    if case .null = fromBigqueryUri {} else {
        try setValueByPath(&toObject, ["bigqueryDestination", "outputUri"], fromBigqueryUri)
    }

    if case .null = getValueByPath(.object(fromObject), ["fileName"]) {} else {
        throw GenAIError.runtime(
            "fileName parameter is only supported in Gemini Developer API mode, not in Gemini Enterprise Agent Platform mode."
        )
    }

    if case .null = getValueByPath(.object(fromObject), ["inlinedResponses"]) {} else {
        throw GenAIError.runtime(
            "inlinedResponses parameter is only supported in Gemini Developer API mode, not in Gemini Enterprise Agent Platform mode."
        )
    }

    if case .null = getValueByPath(.object(fromObject), ["inlinedEmbedContentResponses"]) {} else {
        throw GenAIError.runtime(
            "inlinedEmbedContentResponses parameter is only supported in Gemini Developer API mode, not in Gemini Enterprise Agent Platform mode."
        )
    }

    let fromVertexDataset = getValueByPath(.object(fromObject), ["vertexDataset"])
    if case .object(let vdObj) = fromVertexDataset {
        var dummy: [String: JSONValue] = [:]
        let result = try vertexMultimodalDatasetDestinationToVertex(apiClient: apiClient, fromObject: vdObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["vertexMultimodalDatasetDestination"], .object(result))
    }

    return toObject
}

public func batchJobFromMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromName = getValueByPath(.object(fromObject), ["name"])
    if case .null = fromName {} else {
        try setValueByPath(&toObject, ["name"], fromName)
    }

    let fromDisplayName = getValueByPath(.object(fromObject), ["metadata", "displayName"])
    if case .null = fromDisplayName {} else {
        try setValueByPath(&toObject, ["displayName"], fromDisplayName)
    }

    let fromState = getValueByPath(.object(fromObject), ["metadata", "state"])
    if case .null = fromState {} else {
        let transformed = tJobState(fromState)
        try setValueByPath(&toObject, ["state"], .string(transformed))
    }

    let fromCreateTime = getValueByPath(.object(fromObject), ["metadata", "createTime"])
    if case .null = fromCreateTime {} else {
        try setValueByPath(&toObject, ["createTime"], fromCreateTime)
    }

    let fromEndTime = getValueByPath(.object(fromObject), ["metadata", "endTime"])
    if case .null = fromEndTime {} else {
        try setValueByPath(&toObject, ["endTime"], fromEndTime)
    }

    let fromUpdateTime = getValueByPath(.object(fromObject), ["metadata", "updateTime"])
    if case .null = fromUpdateTime {} else {
        try setValueByPath(&toObject, ["updateTime"], fromUpdateTime)
    }

    let fromModel = getValueByPath(.object(fromObject), ["metadata", "model"])
    if case .null = fromModel {} else {
        try setValueByPath(&toObject, ["model"], fromModel)
    }

    let fromDest = getValueByPath(.object(fromObject), ["metadata", "output"])
    if case .null = fromDest {} else {
        let recv = tRecvBatchJobDestination(fromDest)
        if case .object(let recvObj) = recv {
            var dummy: [String: JSONValue] = [:]
            let result = try batchJobDestinationFromMldev(apiClient: apiClient, fromObject: recvObj, parentObject: &dummy)
            try setValueByPath(&toObject, ["dest"], .object(result))
        } else {
            try setValueByPath(&toObject, ["dest"], recv)
        }
    }

    return toObject
}

public func batchJobFromVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromName = getValueByPath(.object(fromObject), ["name"])
    if case .null = fromName {} else {
        try setValueByPath(&toObject, ["name"], fromName)
    }

    let fromDisplayName = getValueByPath(.object(fromObject), ["displayName"])
    if case .null = fromDisplayName {} else {
        try setValueByPath(&toObject, ["displayName"], fromDisplayName)
    }

    let fromState = getValueByPath(.object(fromObject), ["state"])
    if case .null = fromState {} else {
        let transformed = tJobState(fromState)
        try setValueByPath(&toObject, ["state"], .string(transformed))
    }

    let fromError = getValueByPath(.object(fromObject), ["error"])
    if case .null = fromError {} else {
        try setValueByPath(&toObject, ["error"], fromError)
    }

    let fromCreateTime = getValueByPath(.object(fromObject), ["createTime"])
    if case .null = fromCreateTime {} else {
        try setValueByPath(&toObject, ["createTime"], fromCreateTime)
    }

    let fromStartTime = getValueByPath(.object(fromObject), ["startTime"])
    if case .null = fromStartTime {} else {
        try setValueByPath(&toObject, ["startTime"], fromStartTime)
    }

    let fromEndTime = getValueByPath(.object(fromObject), ["endTime"])
    if case .null = fromEndTime {} else {
        try setValueByPath(&toObject, ["endTime"], fromEndTime)
    }

    let fromUpdateTime = getValueByPath(.object(fromObject), ["updateTime"])
    if case .null = fromUpdateTime {} else {
        try setValueByPath(&toObject, ["updateTime"], fromUpdateTime)
    }

    let fromModel = getValueByPath(.object(fromObject), ["model"])
    if case .null = fromModel {} else {
        try setValueByPath(&toObject, ["model"], fromModel)
    }

    let fromSrc = getValueByPath(.object(fromObject), ["inputConfig"])
    if case .object(let srcObj) = fromSrc {
        var dummy: [String: JSONValue] = [:]
        let result = try batchJobSourceFromVertex(apiClient: apiClient, fromObject: srcObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["src"], .object(result))
    }

    let fromDest = getValueByPath(.object(fromObject), ["outputConfig"])
    if case .null = fromDest {} else {
        let recv = tRecvBatchJobDestination(fromDest)
        if case .object(let recvObj) = recv {
            var dummy: [String: JSONValue] = [:]
            let result = try batchJobDestinationFromVertex(apiClient: apiClient, fromObject: recvObj, parentObject: &dummy)
            try setValueByPath(&toObject, ["dest"], .object(result))
        } else {
            try setValueByPath(&toObject, ["dest"], recv)
        }
    }

    let fromCompletionStats = getValueByPath(.object(fromObject), ["completionStats"])
    if case .null = fromCompletionStats {} else {
        try setValueByPath(&toObject, ["completionStats"], fromCompletionStats)
    }

    let fromOutputInfo = getValueByPath(.object(fromObject), ["outputInfo"])
    if case .null = fromOutputInfo {} else {
        try setValueByPath(&toObject, ["outputInfo"], fromOutputInfo)
    }

    return toObject
}

public func batchJobSourceFromVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromFormat = getValueByPath(.object(fromObject), ["instancesFormat"])
    if case .null = fromFormat {} else {
        try setValueByPath(&toObject, ["format"], fromFormat)
    }

    let fromGcsUri = getValueByPath(.object(fromObject), ["gcsSource", "uris"])
    if case .null = fromGcsUri {} else {
        try setValueByPath(&toObject, ["gcsUri"], fromGcsUri)
    }

    let fromBigqueryUri = getValueByPath(.object(fromObject), ["bigquerySource", "inputUri"])
    if case .null = fromBigqueryUri {} else {
        try setValueByPath(&toObject, ["bigqueryUri"], fromBigqueryUri)
    }

    let fromVertexDatasetName = getValueByPath(.object(fromObject), ["vertexMultimodalDatasetSource", "datasetName"])
    if case .null = fromVertexDatasetName {} else {
        try setValueByPath(&toObject, ["vertexDatasetName"], fromVertexDatasetName)
    }

    return toObject
}

public func batchJobSourceToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    if case .null = getValueByPath(.object(fromObject), ["format"]) {} else {
        throw GenAIError.runtime(
            "format parameter is only supported in Gemini Enterprise Agent Platform mode, not in Gemini Developer API mode."
        )
    }

    if case .null = getValueByPath(.object(fromObject), ["gcsUri"]) {} else {
        throw GenAIError.runtime(
            "gcsUri parameter is only supported in Gemini Enterprise Agent Platform mode, not in Gemini Developer API mode."
        )
    }

    if case .null = getValueByPath(.object(fromObject), ["bigqueryUri"]) {} else {
        throw GenAIError.runtime(
            "bigqueryUri parameter is only supported in Gemini Enterprise Agent Platform mode, not in Gemini Developer API mode."
        )
    }

    let fromFileName = getValueByPath(.object(fromObject), ["fileName"])
    if case .null = fromFileName {} else {
        try setValueByPath(&toObject, ["fileName"], fromFileName)
    }

    let fromInlinedRequests = getValueByPath(.object(fromObject), ["inlinedRequests"])
    if case .null = fromInlinedRequests {} else {
        var transformed: JSONValue = fromInlinedRequests
        if case .array(let arr) = fromInlinedRequests {
            var mapped: [JSONValue] = []
            for item in arr {
                if case .object(let itemObj) = item {
                    var dummy: [String: JSONValue] = [:]
                    let result = try inlinedRequestToMldev(apiClient: apiClient, fromObject: itemObj, parentObject: &dummy)
                    mapped.append(.object(result))
                } else {
                    mapped.append(item)
                }
            }
            transformed = .array(mapped)
        }
        try setValueByPath(&toObject, ["requests", "requests"], transformed)
    }

    if case .null = getValueByPath(.object(fromObject), ["vertexDatasetName"]) {} else {
        throw GenAIError.runtime(
            "vertexDatasetName parameter is only supported in Gemini Enterprise Agent Platform mode, not in Gemini Developer API mode."
        )
    }

    return toObject
}

public func batchJobSourceToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromFormat = getValueByPath(.object(fromObject), ["format"])
    if case .null = fromFormat {} else {
        try setValueByPath(&toObject, ["instancesFormat"], fromFormat)
    }

    let fromGcsUri = getValueByPath(.object(fromObject), ["gcsUri"])
    if case .null = fromGcsUri {} else {
        try setValueByPath(&toObject, ["gcsSource", "uris"], fromGcsUri)
    }

    let fromBigqueryUri = getValueByPath(.object(fromObject), ["bigqueryUri"])
    if case .null = fromBigqueryUri {} else {
        try setValueByPath(&toObject, ["bigquerySource", "inputUri"], fromBigqueryUri)
    }

    if case .null = getValueByPath(.object(fromObject), ["fileName"]) {} else {
        throw GenAIError.runtime(
            "fileName parameter is only supported in Gemini Developer API mode, not in Gemini Enterprise Agent Platform mode."
        )
    }

    if case .null = getValueByPath(.object(fromObject), ["inlinedRequests"]) {} else {
        throw GenAIError.runtime(
            "inlinedRequests parameter is only supported in Gemini Developer API mode, not in Gemini Enterprise Agent Platform mode."
        )
    }

    let fromVertexDatasetName = getValueByPath(.object(fromObject), ["vertexDatasetName"])
    if case .null = fromVertexDatasetName {} else {
        try setValueByPath(&toObject, ["vertexMultimodalDatasetSource", "datasetName"], fromVertexDatasetName)
    }

    return toObject
}

public func cancelBatchJobParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromName = getValueByPath(.object(fromObject), ["name"])
    if case .null = fromName {} else {
        let transformed = try tBatchJobName(apiClient: apiClient, name: fromName)
        try setValueByPath(&toObject, ["_url", "name"], .string(transformed))
    }

    return toObject
}

public func cancelBatchJobParametersToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromName = getValueByPath(.object(fromObject), ["name"])
    if case .null = fromName {} else {
        let transformed = try tBatchJobName(apiClient: apiClient, name: fromName)
        try setValueByPath(&toObject, ["_url", "name"], .string(transformed))
    }

    return toObject
}

public func createBatchJobConfigToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    let toObject: [String: JSONValue] = [:]

    let fromDisplayName = getValueByPath(.object(fromObject), ["displayName"])
    if case .null = fromDisplayName {} else {
        try setValueByPath(&parentObject, ["batch", "displayName"], fromDisplayName)
    }

    if case .null = getValueByPath(.object(fromObject), ["dest"]) {} else {
        throw GenAIError.runtime(
            "dest parameter is only supported in Gemini Enterprise Agent Platform mode, not in Gemini Developer API mode."
        )
    }

    let fromWebhookConfig = getValueByPath(.object(fromObject), ["webhookConfig"])
    if case .null = fromWebhookConfig {} else {
        try setValueByPath(&parentObject, ["batch", "webhookConfig"], fromWebhookConfig)
    }

    return toObject
}

public func createBatchJobConfigToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    let toObject: [String: JSONValue] = [:]

    let fromDisplayName = getValueByPath(.object(fromObject), ["displayName"])
    if case .null = fromDisplayName {} else {
        try setValueByPath(&parentObject, ["displayName"], fromDisplayName)
    }

    let fromDest = getValueByPath(.object(fromObject), ["dest"])
    if case .null = fromDest {} else {
        let destTransformed = try tBatchJobDestination(fromDest)
        if case .object(let destObj) = destTransformed {
            var dummy: [String: JSONValue] = [:]
            let result = try batchJobDestinationToVertex(apiClient: apiClient, fromObject: destObj, parentObject: &dummy)
            try setValueByPath(&parentObject, ["outputConfig"], .object(result))
        } else {
            try setValueByPath(&parentObject, ["outputConfig"], destTransformed)
        }
    }

    if case .null = getValueByPath(.object(fromObject), ["webhookConfig"]) {} else {
        throw GenAIError.runtime(
            "webhookConfig parameter is only supported in Gemini Developer API mode, not in Gemini Enterprise Agent Platform mode."
        )
    }

    return toObject
}

public func createBatchJobParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromModel = getValueByPath(.object(fromObject), ["model"])
    if case .null = fromModel {} else {
        let transformed = try tModel(apiClient: apiClient, model: fromModel)
        try setValueByPath(&toObject, ["_url", "model"], .string(transformed))
    }

    let fromSrc = getValueByPath(.object(fromObject), ["src"])
    if case .null = fromSrc {} else {
        let srcTransformed = try tBatchJobSource(client: apiClient, src: fromSrc)
        if case .object(let srcObj) = srcTransformed {
            var dummy: [String: JSONValue] = [:]
            let result = try batchJobSourceToMldev(apiClient: apiClient, fromObject: srcObj, parentObject: &dummy)
            try setValueByPath(&toObject, ["batch", "inputConfig"], .object(result))
        } else {
            try setValueByPath(&toObject, ["batch", "inputConfig"], srcTransformed)
        }
    }

    let fromConfig = getValueByPath(.object(fromObject), ["config"])
    if case .object(let configObj) = fromConfig {
        _ = try createBatchJobConfigToMldev(apiClient: apiClient, fromObject: configObj, parentObject: &toObject)
    }

    return toObject
}

public func createBatchJobParametersToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromModel = getValueByPath(.object(fromObject), ["model"])
    if case .null = fromModel {} else {
        let transformed = try tModel(apiClient: apiClient, model: fromModel)
        try setValueByPath(&toObject, ["model"], .string(transformed))
    }

    let fromSrc = getValueByPath(.object(fromObject), ["src"])
    if case .null = fromSrc {} else {
        let srcTransformed = try tBatchJobSource(client: apiClient, src: fromSrc)
        if case .object(let srcObj) = srcTransformed {
            var dummy: [String: JSONValue] = [:]
            let result = try batchJobSourceToVertex(apiClient: apiClient, fromObject: srcObj, parentObject: &dummy)
            try setValueByPath(&toObject, ["inputConfig"], .object(result))
        } else {
            try setValueByPath(&toObject, ["inputConfig"], srcTransformed)
        }
    }

    let fromConfig = getValueByPath(.object(fromObject), ["config"])
    if case .object(let configObj) = fromConfig {
        _ = try createBatchJobConfigToVertex(apiClient: apiClient, fromObject: configObj, parentObject: &toObject)
    }

    return toObject
}

public func createEmbeddingsBatchJobConfigToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    let toObject: [String: JSONValue] = [:]

    let fromDisplayName = getValueByPath(.object(fromObject), ["displayName"])
    if case .null = fromDisplayName {} else {
        try setValueByPath(&parentObject, ["batch", "displayName"], fromDisplayName)
    }

    return toObject
}

public func createEmbeddingsBatchJobParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromModel = getValueByPath(.object(fromObject), ["model"])
    if case .null = fromModel {} else {
        let transformed = try tModel(apiClient: apiClient, model: fromModel)
        try setValueByPath(&toObject, ["_url", "model"], .string(transformed))
    }

    let fromSrc = getValueByPath(.object(fromObject), ["src"])
    if case .object(let srcObj) = fromSrc {
        var dummy: [String: JSONValue] = [:]
        let result = try embeddingsBatchJobSourceToMldev(apiClient: apiClient, fromObject: srcObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["batch", "inputConfig"], .object(result))
    }

    let fromConfig = getValueByPath(.object(fromObject), ["config"])
    if case .object(let configObj) = fromConfig {
        _ = try createEmbeddingsBatchJobConfigToMldev(apiClient: apiClient, fromObject: configObj, parentObject: &toObject)
    }

    return toObject
}

public func deleteBatchJobParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromName = getValueByPath(.object(fromObject), ["name"])
    if case .null = fromName {} else {
        let transformed = try tBatchJobName(apiClient: apiClient, name: fromName)
        try setValueByPath(&toObject, ["_url", "name"], .string(transformed))
    }

    return toObject
}

public func deleteBatchJobParametersToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromName = getValueByPath(.object(fromObject), ["name"])
    if case .null = fromName {} else {
        let transformed = try tBatchJobName(apiClient: apiClient, name: fromName)
        try setValueByPath(&toObject, ["_url", "name"], .string(transformed))
    }

    return toObject
}

public func deleteResourceJobFromMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromSdkHttpResponse = getValueByPath(.object(fromObject), ["sdkHttpResponse"])
    if case .null = fromSdkHttpResponse {} else {
        try setValueByPath(&toObject, ["sdkHttpResponse"], fromSdkHttpResponse)
    }

    let fromName = getValueByPath(.object(fromObject), ["name"])
    if case .null = fromName {} else {
        try setValueByPath(&toObject, ["name"], fromName)
    }

    let fromDone = getValueByPath(.object(fromObject), ["done"])
    if case .null = fromDone {} else {
        try setValueByPath(&toObject, ["done"], fromDone)
    }

    let fromError = getValueByPath(.object(fromObject), ["error"])
    if case .null = fromError {} else {
        try setValueByPath(&toObject, ["error"], fromError)
    }

    return toObject
}

public func deleteResourceJobFromVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromSdkHttpResponse = getValueByPath(.object(fromObject), ["sdkHttpResponse"])
    if case .null = fromSdkHttpResponse {} else {
        try setValueByPath(&toObject, ["sdkHttpResponse"], fromSdkHttpResponse)
    }

    let fromName = getValueByPath(.object(fromObject), ["name"])
    if case .null = fromName {} else {
        try setValueByPath(&toObject, ["name"], fromName)
    }

    let fromDone = getValueByPath(.object(fromObject), ["done"])
    if case .null = fromDone {} else {
        try setValueByPath(&toObject, ["done"], fromDone)
    }

    let fromError = getValueByPath(.object(fromObject), ["error"])
    if case .null = fromError {} else {
        try setValueByPath(&toObject, ["error"], fromError)
    }

    return toObject
}

public func embedContentBatchToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromContents = getValueByPath(.object(fromObject), ["contents"])
    if case .null = fromContents {} else {
        let transformedList = try tContentsForEmbed(apiClient: apiClient, origin: fromContents)
        try setValueByPath(&toObject, ["requests[]", "request", "content"], transformedList)
    }

    let fromConfig = getValueByPath(.object(fromObject), ["config"])
    if case .object(let configObj) = fromConfig {
        let result = try embedContentConfigToMldev(apiClient: apiClient, fromObject: configObj, parentObject: &toObject)
        try setValueByPath(&toObject, ["_self"], .object(result))
        var asJV: JSONValue = .object(toObject)
        try moveValueByPath(&asJV, ["requests[].*": "requests[].request.*"])
        if case .object(let updated) = asJV {
            toObject = updated
        }
    }

    return toObject
}

public func embeddingsBatchJobSourceToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromFileName = getValueByPath(.object(fromObject), ["fileName"])
    if case .null = fromFileName {} else {
        try setValueByPath(&toObject, ["file_name"], fromFileName)
    }

    let fromInlinedRequests = getValueByPath(.object(fromObject), ["inlinedRequests"])
    if case .object(let irObj) = fromInlinedRequests {
        var dummy: [String: JSONValue] = [:]
        let result = try embedContentBatchToMldev(apiClient: apiClient, fromObject: irObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["requests"], .object(result))
    }

    return toObject
}

public func getBatchJobParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromName = getValueByPath(.object(fromObject), ["name"])
    if case .null = fromName {} else {
        let transformed = try tBatchJobName(apiClient: apiClient, name: fromName)
        try setValueByPath(&toObject, ["_url", "name"], .string(transformed))
    }

    return toObject
}

public func getBatchJobParametersToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromName = getValueByPath(.object(fromObject), ["name"])
    if case .null = fromName {} else {
        let transformed = try tBatchJobName(apiClient: apiClient, name: fromName)
        try setValueByPath(&toObject, ["_url", "name"], .string(transformed))
    }

    return toObject
}

public func inlinedRequestToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromModel = getValueByPath(.object(fromObject), ["model"])
    if case .null = fromModel {} else {
        let transformed = try tModel(apiClient: apiClient, model: fromModel)
        try setValueByPath(&toObject, ["request", "model"], .string(transformed))
    }

    let fromContents = getValueByPath(.object(fromObject), ["contents"])
    if case .null = fromContents {} else {
        let transformedListRaw = try tContents(fromContents)
        var mapped: [JSONValue] = []
        if case .array(let arr) = transformedListRaw {
            for item in arr {
                if case .object(let itemObj) = item {
                    var dummy: [String: JSONValue] = [:]
                    let result = try contentToMldev(apiClient: apiClient, fromObject: itemObj, parentObject: &dummy)
                    mapped.append(.object(result))
                } else {
                    mapped.append(item)
                }
            }
            try setValueByPath(&toObject, ["request", "contents"], .array(mapped))
        } else {
            try setValueByPath(&toObject, ["request", "contents"], transformedListRaw)
        }
    }

    let fromMetadata = getValueByPath(.object(fromObject), ["metadata"])
    if case .null = fromMetadata {} else {
        try setValueByPath(&toObject, ["metadata"], fromMetadata)
    }

    let fromConfig = getValueByPath(.object(fromObject), ["config"])
    if case .object(let configObj) = fromConfig {
        var requestParent: [String: JSONValue]
        let existing = getValueByPath(.object(toObject), ["request"])
        if case .object(let obj) = existing {
            requestParent = obj
        } else {
            requestParent = [:]
        }
        let result = try generateContentConfigToMldev(apiClient: apiClient, fromObject: configObj, parentObject: &requestParent)
        // Write back the (possibly mutated) request parent.
        try setValueByPath(&toObject, ["request"], .object(requestParent))
        try setValueByPath(&toObject, ["request", "generationConfig"], .object(result))
    }

    return toObject
}

public func inlinedResponseFromMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromResponse = getValueByPath(.object(fromObject), ["response"])
    if case .object(let respObj) = fromResponse {
        var dummy: [String: JSONValue] = [:]
        let result = try generateContentResponseFromMldev(apiClient: apiClient, fromObject: respObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["response"], .object(result))
    }

    let fromMetadata = getValueByPath(.object(fromObject), ["metadata"])
    if case .null = fromMetadata {} else {
        try setValueByPath(&toObject, ["metadata"], fromMetadata)
    }

    let fromError = getValueByPath(.object(fromObject), ["error"])
    if case .null = fromError {} else {
        try setValueByPath(&toObject, ["error"], fromError)
    }

    return toObject
}

public func listBatchJobsConfigToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    let toObject: [String: JSONValue] = [:]

    let fromPageSize = getValueByPath(.object(fromObject), ["pageSize"])
    if case .null = fromPageSize {} else {
        try setValueByPath(&parentObject, ["_query", "pageSize"], fromPageSize)
    }

    let fromPageToken = getValueByPath(.object(fromObject), ["pageToken"])
    if case .null = fromPageToken {} else {
        try setValueByPath(&parentObject, ["_query", "pageToken"], fromPageToken)
    }

    if case .null = getValueByPath(.object(fromObject), ["filter"]) {} else {
        throw GenAIError.runtime(
            "filter parameter is only supported in Gemini Enterprise Agent Platform mode, not in Gemini Developer API mode."
        )
    }

    return toObject
}

public func listBatchJobsConfigToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    let toObject: [String: JSONValue] = [:]

    let fromPageSize = getValueByPath(.object(fromObject), ["pageSize"])
    if case .null = fromPageSize {} else {
        try setValueByPath(&parentObject, ["_query", "pageSize"], fromPageSize)
    }

    let fromPageToken = getValueByPath(.object(fromObject), ["pageToken"])
    if case .null = fromPageToken {} else {
        try setValueByPath(&parentObject, ["_query", "pageToken"], fromPageToken)
    }

    let fromFilter = getValueByPath(.object(fromObject), ["filter"])
    if case .null = fromFilter {} else {
        try setValueByPath(&parentObject, ["_query", "filter"], fromFilter)
    }

    return toObject
}

public func listBatchJobsParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromConfig = getValueByPath(.object(fromObject), ["config"])
    if case .object(let configObj) = fromConfig {
        _ = try listBatchJobsConfigToMldev(apiClient: apiClient, fromObject: configObj, parentObject: &toObject)
    }

    return toObject
}

public func listBatchJobsParametersToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromConfig = getValueByPath(.object(fromObject), ["config"])
    if case .object(let configObj) = fromConfig {
        _ = try listBatchJobsConfigToVertex(apiClient: apiClient, fromObject: configObj, parentObject: &toObject)
    }

    return toObject
}

public func listBatchJobsResponseFromMldev(
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

    let fromBatchJobs = getValueByPath(.object(fromObject), ["operations"])
    if case .null = fromBatchJobs {} else {
        var transformed: JSONValue = fromBatchJobs
        if case .array(let arr) = fromBatchJobs {
            var mapped: [JSONValue] = []
            for item in arr {
                if case .object(let itemObj) = item {
                    var dummy: [String: JSONValue] = [:]
                    let result = try batchJobFromMldev(apiClient: apiClient, fromObject: itemObj, parentObject: &dummy)
                    mapped.append(.object(result))
                } else {
                    mapped.append(item)
                }
            }
            transformed = .array(mapped)
        }
        try setValueByPath(&toObject, ["batchJobs"], transformed)
    }

    return toObject
}

public func listBatchJobsResponseFromVertex(
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

    let fromBatchJobs = getValueByPath(.object(fromObject), ["batchPredictionJobs"])
    if case .null = fromBatchJobs {} else {
        var transformed: JSONValue = fromBatchJobs
        if case .array(let arr) = fromBatchJobs {
            var mapped: [JSONValue] = []
            for item in arr {
                if case .object(let itemObj) = item {
                    var dummy: [String: JSONValue] = [:]
                    let result = try batchJobFromVertex(apiClient: apiClient, fromObject: itemObj, parentObject: &dummy)
                    mapped.append(.object(result))
                } else {
                    mapped.append(item)
                }
            }
            transformed = .array(mapped)
        }
        try setValueByPath(&toObject, ["batchJobs"], transformed)
    }

    return toObject
}

public func vertexMultimodalDatasetDestinationFromVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromBigqueryDestination = getValueByPath(.object(fromObject), ["bigqueryDestination", "outputUri"])
    if case .null = fromBigqueryDestination {} else {
        try setValueByPath(&toObject, ["bigqueryDestination"], fromBigqueryDestination)
    }

    let fromDisplayName = getValueByPath(.object(fromObject), ["displayName"])
    if case .null = fromDisplayName {} else {
        try setValueByPath(&toObject, ["displayName"], fromDisplayName)
    }

    return toObject
}

public func vertexMultimodalDatasetDestinationToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromBigqueryDestination = getValueByPath(.object(fromObject), ["bigqueryDestination"])
    if case .null = fromBigqueryDestination {} else {
        try setValueByPath(&toObject, ["bigqueryDestination", "outputUri"], fromBigqueryDestination)
    }

    let fromDisplayName = getValueByPath(.object(fromObject), ["displayName"])
    if case .null = fromDisplayName {} else {
        try setValueByPath(&toObject, ["displayName"], fromDisplayName)
    }

    return toObject
}
