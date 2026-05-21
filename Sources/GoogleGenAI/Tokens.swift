// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Helpers

/// Returns a comma-separated list of field masks from a given object.
private func getFieldMasks(_ setup: [String: JSONValue]) -> String {
    var fields: [String] = []
    for (key, value) in setup {
        // 2nd layer, recursively get field masks see TODO(b/418290100)
        if case .object(let obj) = value, !obj.isEmpty {
            for kk in obj.keys {
                fields.append("\(key).\(kk)")
            }
        } else {
            fields.append(key) // 1st layer
        }
    }
    return fields.joined(separator: ",")
}

/// Converts bidiGenerateContentSetup.
private func convertBidiSetupToTokenSetup(
    _ requestDict: [String: JSONValue],
    config: CreateAuthTokenConfig?
) -> [String: JSONValue] {
    var requestDict = requestDict
    // Convert bidiGenerateContentSetup from bidiGenerateContentSetup.setup.
    var setupForMaskGeneration: [String: JSONValue]? = nil
    let bidiValue = requestDict["bidiGenerateContentSetup"]
    if case .object(let bidiObj) = bidiValue ?? .null {
        if let innerSetupValue = bidiObj["setup"],
           case .object(let innerSetup) = innerSetupValue {
            // Valid inner setup found.
            requestDict["bidiGenerateContentSetup"] = .object(innerSetup)
            setupForMaskGeneration = innerSetup
        } else {
            // `bidiGenerateContentSetupValue.setup` is not a valid object; treat as
            // if bidiGenerateContentSetup is invalid.
            requestDict.removeValue(forKey: "bidiGenerateContentSetup")
        }
    } else if bidiValue != nil {
        // `bidiGenerateContentSetup` exists but not in the expected shape; treat as invalid.
        requestDict.removeValue(forKey: "bidiGenerateContentSetup")
    }

    let preExistingFieldMask = requestDict["fieldMask"]
    let preExistingMaskArray: [JSONValue]?
    if case .array(let a) = preExistingFieldMask ?? .null {
        preExistingMaskArray = a
    } else {
        preExistingMaskArray = nil
    }
    // Handle mask generation setup.
    if let setupForMaskGeneration = setupForMaskGeneration {
        let generatedMaskFromBidi = getFieldMasks(setupForMaskGeneration)
        let lockAdditionalFields = config?.lockAdditionalFields

        if let lockAdditionalFields = lockAdditionalFields, lockAdditionalFields.isEmpty {
            // Case 1: lockAdditionalFields is an empty array. Lock only fields from bidi setup.
            if !generatedMaskFromBidi.isEmpty {
                requestDict["fieldMask"] = .string(generatedMaskFromBidi)
            } else {
                requestDict.removeValue(forKey: "fieldMask")
            }
        } else if let lockAdditionalFields = lockAdditionalFields,
                  !lockAdditionalFields.isEmpty,
                  let preExistingMaskArray = preExistingMaskArray,
                  !preExistingMaskArray.isEmpty {
            // Case 2: Lock fields from bidi setup + additional fields (preExistingFieldMask).
            let generationConfigFields: Set<String> = [
                "temperature",
                "topK",
                "topP",
                "maxOutputTokens",
                "responseModalities",
                "seed",
                "speechConfig"
            ]

            var mappedFieldsFromPreExisting: [String] = []
            for field in preExistingMaskArray {
                if case .string(let f) = field {
                    if generationConfigFields.contains(f) {
                        mappedFieldsFromPreExisting.append("generationConfig.\(f)")
                    } else {
                        mappedFieldsFromPreExisting.append(f)
                    }
                }
            }

            var finalMaskParts: [String] = []
            if !generatedMaskFromBidi.isEmpty {
                finalMaskParts.append(generatedMaskFromBidi)
            }
            if !mappedFieldsFromPreExisting.isEmpty {
                finalMaskParts.append(contentsOf: mappedFieldsFromPreExisting)
            }
            if !finalMaskParts.isEmpty {
                requestDict["fieldMask"] = .string(finalMaskParts.joined(separator: ","))
            } else {
                requestDict.removeValue(forKey: "fieldMask")
            }
        } else {
            // Case 3: "Lock all fields"
            requestDict.removeValue(forKey: "fieldMask")
        }
    } else {
        // No valid `bidiGenerateContentSetup` was found or extracted.
        // "Lock additional null fields if any".
        if let preExistingMaskArray = preExistingMaskArray, !preExistingMaskArray.isEmpty {
            let parts = preExistingMaskArray.compactMap { v -> String? in
                if case .string(let s) = v { return s }
                return nil
            }
            requestDict["fieldMask"] = .string(parts.joined(separator: ","))
        } else {
            requestDict.removeValue(forKey: "fieldMask")
        }
    }

    return requestDict
}

// MARK: - Tokens

public final class Tokens: BaseModule, @unchecked Sendable {
    private let apiClient: ApiClient

    public init(apiClient: ApiClient) {
        self.apiClient = apiClient
        super.init()
    }

    /// Creates an ephemeral auth token resource.
    ///
    /// @experimental
    ///
    /// Ephemeral auth tokens is only supported in the Gemini Developer API.
    /// It can be used for the session connection to the Live constrained API.
    /// Support in v1alpha only.
    public func create(
        _ params: CreateAuthTokenParameters
    ) async throws -> AuthToken {
        var path = ""
        var queryParams: [String: String] = [:]
        if self.apiClient.isVertexAI() {
            throw GenAIError.unsupported(
                "The client.tokens.create method is only supported by the Gemini Developer API."
            )
        } else {
            let paramsDict = try jsonObject(params)
            var parent: [String: JSONValue] = [:]
            var body = try createAuthTokenParametersToMldev(
                apiClient: self.apiClient, fromObject: paramsDict, parentObject: &parent
            )
            guard case .object(let urlMap) = body["_url"] ?? .null else {
                throw GenAIError.runtime("Missing _url in body.")
            }
            path = try formatMap("auth_tokens", urlMap)
            queryParams = extractStringMap(body["_query"])
            body.removeValue(forKey: "config")
            body.removeValue(forKey: "_url")
            body.removeValue(forKey: "_query")

            let transformedBody = convertBidiSetupToTokenSetup(body, config: params.config)

            let httpResponse = try await self.apiClient.request(HttpRequest(
                path: path,
                queryParams: queryParams,
                body: .string(jsonValueObjectToString(transformedBody)),
                httpMethod: .POST,
                httpOptions: params.config?.httpOptions,
                abortSignal: params.config?.abortSignal
            ))
            let apiResponse = try httpResponse.json()
            return try decodeFromJSONObject(AuthToken.self, apiResponse.asObjectOrEmpty())
        }
    }
}

// MARK: - Internal helper extension

private extension JSONValue {
    func asObjectOrEmpty() -> [String: JSONValue] {
        if case .object(let o) = self { return o }
        return [:]
    }
}
