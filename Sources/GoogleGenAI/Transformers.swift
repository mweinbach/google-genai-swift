// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

// MARK: - Internal MCP Tool placeholder
//
// The JS SDK depends on `@modelcontextprotocol/sdk` for the `Tool as McpTool`
// type. Swift has no first-party MCP SDK yet, so we model the MCP tool shape
// as a typed alias over `[String: JSONValue]` for now.

/// MCP tool representation. Mirrors the shape of `@modelcontextprotocol/sdk`'s `Tool`:
/// at minimum exposes `name`, `description`, `inputSchema`, optionally `outputSchema`.
public typealias McpTool = [String: JSONValue]

public func tModel(apiClient: ApiClient, model: JSONValue) throws -> String {
    guard case .string(let s) = model, !s.isEmpty else {
        throw GenAIError.invalidArgument("model is required and must be a string")
    }
    return try tModel(apiClient: apiClient, model: s)
}

public func tModel(apiClient: ApiClient, model: String) throws -> String {
    if model.isEmpty {
        throw GenAIError.invalidArgument("model is required and must be a string")
    }
    if model.contains("..") || model.contains("?") || model.contains("&") {
        throw GenAIError.invalidArgument("invalid model parameter")
    }

    if apiClient.isVertexAI() {
        if model.hasPrefix("publishers/") ||
            model.hasPrefix("projects/") ||
            model.hasPrefix("models/") {
            return model
        } else if model.contains("/") {
            let parts = model.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: false).map(String.init)
            return "publishers/\(parts[0])/models/\(parts[1])"
        } else {
            return "publishers/google/models/\(model)"
        }
    } else {
        if model.hasPrefix("models/") || model.hasPrefix("tunedModels/") {
            return model
        } else {
            return "models/\(model)"
        }
    }
}

public func tCachesModel(apiClient: ApiClient, model: JSONValue) throws -> String {
    guard case .string(let s) = model else {
        return ""
    }
    return try tCachesModel(apiClient: apiClient, model: s)
}

public func tCachesModel(apiClient: ApiClient, model: String) throws -> String {
    let transformedModel = try tModel(apiClient: apiClient, model: model)
    if transformedModel.isEmpty {
        return ""
    }

    if transformedModel.hasPrefix("publishers/") && apiClient.isVertexAI() {
        // vertex caches only support model name start with projects.
        return "projects/\(apiClient.getProject() ?? "")/locations/\(apiClient.getLocation() ?? "")/\(transformedModel)"
    } else if transformedModel.hasPrefix("models/") && apiClient.isVertexAI() {
        return "projects/\(apiClient.getProject() ?? "")/locations/\(apiClient.getLocation() ?? "")/publishers/google/\(transformedModel)"
    } else {
        return transformedModel
    }
}

public func tBlobs(_ blobs: [BlobImageUnion]) throws -> [Blob] {
    return try blobs.map { try tBlob($0) }
}

public func tBlobs(_ blob: BlobImageUnion) throws -> [Blob] {
    return [try tBlob(blob)]
}

public func tBlob(_ blob: BlobImageUnion) throws -> Blob {
    // In Swift, `BlobImageUnion = Blob`, so this is effectively an identity.
    // The TS version threw if `blob` was not an object — Swift's type system
    // already enforces this, but we keep the explicit check for parity.
    return blob
}

public func tImageBlob(_ blob: BlobImageUnion) throws -> Blob {
    let transformedBlob = try tBlob(blob)
    if let mt = transformedBlob.mimeType, mt.hasPrefix("image/") {
        return transformedBlob
    }
    throw GenAIError.invalidArgument("Unsupported mime type: \(transformedBlob.mimeType ?? "")")
}

public func tAudioBlob(_ blob: Blob) throws -> Blob {
    let transformedBlob = try tBlob(blob)
    if let mt = transformedBlob.mimeType, mt.hasPrefix("audio/") {
        return transformedBlob
    }
    throw GenAIError.invalidArgument("Unsupported mime type: \(transformedBlob.mimeType ?? "")")
}

public func tPart(_ origin: PartUnion?) throws -> Part {
    guard let origin else {
        throw GenAIError.invalidArgument("PartUnion is required")
    }
    switch origin {
    case .part(let p): return p
    case .text(let s): return Part(text: s)
    }
}

public func tParts(_ origin: PartListUnion?) throws -> [Part] {
    guard let origin else {
        throw GenAIError.invalidArgument("PartListUnion is required")
    }
    switch origin {
    case .single(let u):
        return [try tPart(u)]
    case .many(let arr):
        if arr.isEmpty {
            throw GenAIError.invalidArgument("PartListUnion is required")
        }
        return try arr.map { try tPart($0) }
    }
}

private func _isContent(_ origin: ContentUnion) -> Bool {
    if case .content(let c) = origin, c.parts != nil {
        return true
    }
    return false
}

private func _isFunctionCallPart(_ origin: PartUnion) -> Bool {
    if case .part(let p) = origin, p.functionCall != nil {
        return true
    }
    return false
}

private func _isFunctionResponsePart(_ origin: PartUnion) -> Bool {
    if case .part(let p) = origin, p.functionResponse != nil {
        return true
    }
    return false
}

public func tContent(_ origin: ContentUnion?) throws -> Content {
    guard let origin else {
        throw GenAIError.invalidArgument("ContentUnion is required")
    }
    switch origin {
    case .content(let c):
        if c.parts != nil {
            return c
        }
        // Not a real Content (no parts) — treat as parts-less user content.
        return Content(parts: [], role: "user")
    case .part(let u):
        return Content(parts: [try tPart(u)], role: "user")
    case .parts(let arr):
        return Content(parts: try arr.map { try tPart($0) }, role: "user")
    }
}

public func tContentsForEmbed(apiClient: ApiClient, origin: ContentListUnion?) throws -> [ContentUnion] {
    guard let origin else {
        return []
    }

    func textsFromContent(_ c: Content) -> [ContentUnion] {
        if let parts = c.parts, !parts.isEmpty, let text = parts[0].text {
            return [.part(.text(text))]
        }
        return []
    }

    if apiClient.isVertexAI() {
        switch origin {
        case .contents(let arr):
            var out: [ContentUnion] = []
            for item in arr {
                let content = try tContent(.content(item))
                out.append(contentsOf: textsFromContent(content))
            }
            return out
        case .parts(let arr):
            // Mirrors `Array.isArray(origin)` branch with each item as a PartUnion.
            var out: [ContentUnion] = []
            for item in arr {
                let content = try tContent(.part(item))
                out.append(contentsOf: textsFromContent(content))
            }
            return out
        case .content(let c):
            let content = try tContent(.content(c))
            return textsFromContent(content)
        case .part(let u):
            let content = try tContent(.part(u))
            return textsFromContent(content)
        }
    }

    switch origin {
    case .contents(let arr):
        return try arr.map { try ContentUnion.content(tContent(.content($0))) }
    case .parts(let arr):
        return try arr.map { try ContentUnion.content(tContent(.part($0))) }
    case .content(let c):
        return [try .content(tContent(.content(c)))]
    case .part(let u):
        return [try .content(tContent(.part(u)))]
    }
}

public func tContents(_ origin: ContentListUnion?) throws -> [Content] {
    guard let origin else {
        throw GenAIError.invalidArgument("contents are required")
    }

    switch origin {
    case .content(let c):
        return [try tContent(.content(c))]
    case .part(let u):
        if _isFunctionCallPart(u) || _isFunctionResponsePart(u) {
            throw GenAIError.invalidArgument(
                "To specify functionCall or functionResponse parts, please wrap them in a Content object, specifying the role for them"
            )
        }
        return [try tContent(.part(u))]
    case .contents(let arr):
        if arr.isEmpty {
            throw GenAIError.invalidArgument("contents are required")
        }
        // All items are Content — pass through after canonicalizing.
        return arr
    case .parts(let arr):
        if arr.isEmpty {
            throw GenAIError.invalidArgument("contents are required")
        }
        // All items are PartUnion. Reject explicit function-call/response parts.
        var accumulated: [PartUnion] = []
        for item in arr {
            if _isFunctionCallPart(item) || _isFunctionResponsePart(item) {
                throw GenAIError.invalidArgument(
                    "To specify functionCall or functionResponse parts, please wrap them, and any other parts, in Content objects as appropriate, specifying the role for them"
                )
            }
            accumulated.append(item)
        }
        return [Content(parts: try accumulated.map { try tPart($0) }, role: "user")]
    }
}

/*
Transform the type field from an array of types to an array of anyOf fields.
Example:
  {type: ['STRING', 'NUMBER']}
will be transformed to
  {anyOf: [{type: 'STRING'}, {type: 'NUMBER'}]}
*/
private func flattenTypeArrayToAnyOf(_ typeList: [String], _ resultingSchema: inout Schema) {
    if typeList.contains("null") {
        resultingSchema.nullable = true
    }
    let listWithoutNull = typeList.filter { $0 != "null" }
    let allValues = Set(["TYPE_UNSPECIFIED", "STRING", "NUMBER", "INTEGER", "BOOLEAN", "ARRAY", "OBJECT", "NULL"])

    func toType(_ s: String) -> `Type` {
        let upper = s.uppercased()
        if allValues.contains(upper), let t = `Type`(rawValue: upper) {
            return t
        }
        return .typeUnspecified
    }

    if listWithoutNull.count == 1 {
        resultingSchema.type = toType(listWithoutNull[0])
    } else {
        var anyOfList: [Schema] = []
        for i in listWithoutNull {
            anyOfList.append(Schema(type: toType(i)))
        }
        resultingSchema.anyOf = anyOfList
    }
}

public func processJsonSchema(_ jsonSchema: JSONValue) throws -> Schema {
    guard case .object(var obj) = jsonSchema else {
        return Schema()
    }
    var genAISchema = Schema()
    let schemaFieldNames = Set(["items"])
    let listSchemaFieldNames = Set(["anyOf"])
    let dictSchemaFieldNames = Set(["properties"])

    if obj["type"] != nil, obj["anyOf"] != nil {
        throw GenAIError.invalidArgument("type and anyOf cannot be both populated.")
    }

    // Handle nullable-via-anyOf collapse.
    if case .array(let incomingAnyOf) = obj["anyOf"] ?? .null, incomingAnyOf.count == 2 {
        func anyOfTypeIsNull(_ v: JSONValue) -> Bool {
            if case .object(let o) = v, case .string(let s) = o["type"] ?? .null, s == "null" {
                return true
            }
            return false
        }
        if anyOfTypeIsNull(incomingAnyOf[0]) {
            genAISchema.nullable = true
            if case .object(let next) = incomingAnyOf[1] {
                obj = next
            }
        } else if anyOfTypeIsNull(incomingAnyOf[1]) {
            genAISchema.nullable = true
            if case .object(let next) = incomingAnyOf[0] {
                obj = next
            }
        }
    }

    // Handle `type: [...]` array form up-front.
    if case .array(let typeArr) = obj["type"] ?? .null {
        var stringTypes: [String] = []
        for t in typeArr {
            if case .string(let s) = t { stringTypes.append(s) }
        }
        flattenTypeArrayToAnyOf(stringTypes, &genAISchema)
    }

    let allTypeValues = Set(["TYPE_UNSPECIFIED", "STRING", "NUMBER", "INTEGER", "BOOLEAN", "ARRAY", "OBJECT", "NULL"])

    for (fieldName, fieldValue) in obj {
        if case .null = fieldValue { continue }

        if fieldName == "type" {
            if case .string(let s) = fieldValue, s == "null" {
                throw GenAIError.invalidArgument("type: null can not be the only possible type for the field.")
            }
            if case .array = fieldValue {
                // Already handled above.
                continue
            }
            if case .string(let s) = fieldValue {
                let upper = s.uppercased()
                if allTypeValues.contains(upper), let t = `Type`(rawValue: upper) {
                    genAISchema.type = t
                } else {
                    genAISchema.type = .typeUnspecified
                }
            }
        } else if schemaFieldNames.contains(fieldName) {
            // `items`
            genAISchema.items = SchemaRef(try processJsonSchema(fieldValue))
        } else if listSchemaFieldNames.contains(fieldName) {
            // `anyOf`
            guard case .array(let arr) = fieldValue else { continue }
            var listValue: [Schema] = []
            for item in arr {
                if case .object(let o) = item,
                   case .string(let s) = o["type"] ?? .null,
                   s == "null" {
                    genAISchema.nullable = true
                    continue
                }
                listValue.append(try processJsonSchema(item))
            }
            genAISchema.anyOf = listValue
        } else if dictSchemaFieldNames.contains(fieldName) {
            // `properties`
            guard case .object(let dict) = fieldValue else { continue }
            var dictValue: [String: Schema] = [:]
            for (k, v) in dict {
                dictValue[k] = try processJsonSchema(v)
            }
            genAISchema.properties = dictValue
        } else {
            // additionalProperties is not included in JSONSchema, skipping it.
            if fieldName == "additionalProperties" { continue }
            try _assignSchemaField(&genAISchema, fieldName: fieldName, value: fieldValue)
        }
    }
    return genAISchema
}

/// Assign a generic field to `Schema` by name. Mirrors the dynamic TS
/// `genAISchema[fieldName] = fieldValue` for fields not handled by special
/// cases. Unknown fields are silently dropped (Swift's `Schema` is closed).
private func _assignSchemaField(_ schema: inout Schema, fieldName: String, value: JSONValue) throws {
    switch fieldName {
    case "default": schema.default = value
    case "description":
        if case .string(let s) = value { schema.description = s }
    case "enum":
        if case .array(let arr) = value {
            schema.enum = arr.compactMap { if case .string(let s) = $0 { return s } else { return nil } }
        }
    case "example": schema.example = value
    case "format":
        if case .string(let s) = value { schema.format = s }
    case "maxItems":
        if case .string(let s) = value { schema.maxItems = s }
        else if case .int(let i) = value { schema.maxItems = String(i) }
    case "maxLength":
        if case .string(let s) = value { schema.maxLength = s }
        else if case .int(let i) = value { schema.maxLength = String(i) }
    case "maxProperties":
        if case .string(let s) = value { schema.maxProperties = s }
        else if case .int(let i) = value { schema.maxProperties = String(i) }
    case "maximum":
        if case .double(let d) = value { schema.maximum = d }
        else if case .int(let i) = value { schema.maximum = Double(i) }
    case "minItems":
        if case .string(let s) = value { schema.minItems = s }
        else if case .int(let i) = value { schema.minItems = String(i) }
    case "minLength":
        if case .string(let s) = value { schema.minLength = s }
        else if case .int(let i) = value { schema.minLength = String(i) }
    case "minProperties":
        if case .string(let s) = value { schema.minProperties = s }
        else if case .int(let i) = value { schema.minProperties = String(i) }
    case "minimum":
        if case .double(let d) = value { schema.minimum = d }
        else if case .int(let i) = value { schema.minimum = Double(i) }
    case "nullable":
        if case .bool(let b) = value { schema.nullable = b }
    case "pattern":
        if case .string(let s) = value { schema.pattern = s }
    case "propertyOrdering":
        if case .array(let arr) = value {
            schema.propertyOrdering = arr.compactMap { if case .string(let s) = $0 { return s } else { return nil } }
        }
    case "required":
        if case .array(let arr) = value {
            schema.required = arr.compactMap { if case .string(let s) = $0 { return s } else { return nil } }
        }
    case "title":
        if case .string(let s) = value { schema.title = s }
    default:
        // Unknown field; drop silently to match closed Swift Schema shape.
        break
    }
}

// we take the unknown in the schema field because we want enable user to pass
// the output of major schema declaration tools without casting.
public func tSchema(_ schema: JSONValue) throws -> Schema {
    return try processJsonSchema(schema)
}

public func tSchema(_ schema: Schema) throws -> Schema {
    // Re-encode through JSONValue to reuse processJsonSchema logic.
    let data = try JSONEncoder().encode(schema)
    let json = try JSONDecoder().decode(JSONValue.self, from: data)
    return try processJsonSchema(json)
}

public func tSpeechConfig(_ speechConfig: SpeechConfigUnion) throws -> SpeechConfig {
    switch speechConfig {
    case .config(let c):
        return c
    case .string(let s):
        return SpeechConfig(
            voiceConfig: VoiceConfig(prebuiltVoiceConfig: PrebuiltVoiceConfig(voiceName: s))
        )
    }
}

public func tLiveSpeechConfig(_ speechConfig: SpeechConfig) throws -> SpeechConfig {
    if speechConfig.multiSpeakerVoiceConfig != nil {
        throw GenAIError.invalidArgument("multiSpeakerVoiceConfig is not supported in the live API.")
    }
    return speechConfig
}

public func tTool(_ tool: Tool) throws -> Tool {
    var tool = tool
    if var decls = tool.functionDeclarations {
        for i in decls.indices {
            var fd = decls[i]
            if let parameters = fd.parameters {
                // Schemas in Swift never carry `$schema` (closed shape), so
                // always run them through processJsonSchema.
                let data = try JSONEncoder().encode(parameters)
                let json = try JSONDecoder().decode(JSONValue.self, from: data)
                fd.parameters = try processJsonSchema(json)
            } else if let parametersJsonSchema = fd.parametersJsonSchema {
                // If user provided a raw JSON schema (with `$schema`), route to
                // parametersJsonSchema. Already the case — preserve.
                fd.parametersJsonSchema = parametersJsonSchema
            }
            if let response = fd.response {
                let data = try JSONEncoder().encode(response)
                let json = try JSONDecoder().decode(JSONValue.self, from: data)
                fd.response = try processJsonSchema(json)
            } else if let responseJsonSchema = fd.responseJsonSchema {
                fd.responseJsonSchema = responseJsonSchema
            }
            decls[i] = fd
        }
        tool.functionDeclarations = decls
    }
    return tool
}

public func tTools(_ tools: [Tool]?) throws -> [Tool] {
    guard let tools else {
        throw GenAIError.invalidArgument("tools is required")
    }
    var result: [Tool] = []
    for tool in tools {
        result.append(tool)
    }
    return result
}

/// Prepends resource name with project, location, resource_prefix if needed.
private func resourceName(
    client: ApiClient,
    resourceName: String,
    resourcePrefix: String,
    splitsAfterPrefix: Int = 1
) -> String {
    let shouldAppendPrefix = !resourceName.hasPrefix("\(resourcePrefix)/")
        && resourceName.split(separator: "/", omittingEmptySubsequences: false).count == splitsAfterPrefix
    if client.isVertexAI() {
        if resourceName.hasPrefix("projects/") {
            return resourceName
        } else if resourceName.hasPrefix("locations/") {
            return "projects/\(client.getProject() ?? "")/\(resourceName)"
        } else if resourceName.hasPrefix("\(resourcePrefix)/") {
            return "projects/\(client.getProject() ?? "")/locations/\(client.getLocation() ?? "")/\(resourceName)"
        } else if shouldAppendPrefix {
            return "projects/\(client.getProject() ?? "")/locations/\(client.getLocation() ?? "")/\(resourcePrefix)/\(resourceName)"
        } else {
            return resourceName
        }
    }
    if shouldAppendPrefix {
        return "\(resourcePrefix)/\(resourceName)"
    }
    return resourceName
}

public func tCachedContentName(apiClient: ApiClient, name: JSONValue) throws -> String {
    guard case .string(let s) = name else {
        throw GenAIError.invalidArgument("name must be a string")
    }
    return resourceName(client: apiClient, resourceName: s, resourcePrefix: "cachedContents")
}

public func tCachedContentName(apiClient: ApiClient, name: String) -> String {
    return resourceName(client: apiClient, resourceName: name, resourcePrefix: "cachedContents")
}

public func tTuningJobStatus(_ status: JSONValue) -> String {
    if case .string(let s) = status {
        return tTuningJobStatus(s)
    }
    return ""
}

public func tTuningJobStatus(_ status: String) -> String {
    switch status {
    case "STATE_UNSPECIFIED": return "JOB_STATE_UNSPECIFIED"
    case "CREATING": return "JOB_STATE_RUNNING"
    case "ACTIVE": return "JOB_STATE_SUCCEEDED"
    case "FAILED": return "JOB_STATE_FAILED"
    default: return status
    }
}

private func _isFile(_ origin: DownloadableFileUnion) -> Bool {
    if case .file = origin { return true }
    return false
}

public func isGeneratedVideo(_ origin: DownloadableFileUnion) -> Bool {
    if case .generatedVideo = origin { return true }
    return false
}

public func isVideo(_ origin: DownloadableFileUnion) -> Bool {
    if case .video = origin { return true }
    return false
}

public func tFileName(_ fromName: DownloadableFileUnion) throws -> String? {
    var name: String?

    switch fromName {
    case .file(let f):
        name = f.name
    case .video(let v):
        guard let uri = v.uri else { return nil }
        name = uri
    case .generatedVideo(let gv):
        guard let uri = gv.video?.uri else { return nil }
        name = uri
    case .string(let s):
        name = s
    }

    guard var resolved = name else {
        throw GenAIError.invalidArgument("Could not extract file name from the provided input.")
    }

    if resolved.hasPrefix("https://") {
        let parts = resolved.components(separatedBy: "files/")
        guard parts.count >= 2 else {
            throw GenAIError.invalidArgument("Could not extract file name from URI \(resolved)")
        }
        let suffix = parts[1]
        // Match `/[a-z0-9]+/`
        guard let regex = try? NSRegularExpression(pattern: "[a-z0-9]+") else {
            throw GenAIError.runtime("Failed to compile file-name regex")
        }
        let range = NSRange(suffix.startIndex..<suffix.endIndex, in: suffix)
        guard let match = regex.firstMatch(in: suffix, range: range),
              let matchRange = Range(match.range, in: suffix) else {
            throw GenAIError.invalidArgument("Could not extract file name from URI \(resolved)")
        }
        resolved = String(suffix[matchRange])
    } else if resolved.hasPrefix("files/") {
        let parts = resolved.components(separatedBy: "files/")
        if parts.count >= 2 { resolved = parts[1] }
    }
    return resolved
}

public func tModelsUrl(apiClient: ApiClient, baseModels: JSONValue) -> String {
    var truthy = false
    switch baseModels {
    case .bool(let b): truthy = b
    case .null: truthy = false
    case .string(let s): truthy = !s.isEmpty
    case .int(let i): truthy = i != 0
    case .double(let d): truthy = d != 0
    default: truthy = true
    }
    return tModelsUrl(apiClient: apiClient, baseModels: truthy)
}

public func tModelsUrl(apiClient: ApiClient, baseModels: Bool) -> String {
    if apiClient.isVertexAI() {
        return baseModels ? "publishers/google/models" : "models"
    } else {
        return baseModels ? "models" : "tunedModels"
    }
}

public func tExtractModels(_ response: JSONValue) -> [[String: JSONValue]] {
    for key in ["models", "tunedModels", "publisherModels"] {
        if hasField(response, fieldName: key) {
            if case .object(let obj) = response, case .array(let arr) = obj[key] ?? .null {
                var out: [[String: JSONValue]] = []
                for item in arr {
                    if case .object(let o) = item { out.append(o) }
                }
                return out
            }
        }
    }
    return []
}

private func hasField(_ data: JSONValue, fieldName: String) -> Bool {
    if case .object(let obj) = data, obj[fieldName] != nil {
        return true
    }
    return false
}

public func mcpToGeminiTool(_ mcpTool: McpTool, config: CallableToolConfig = CallableToolConfig()) -> Tool {
    var name: String?
    if case .string(let s) = mcpTool["name"] ?? .null { name = s }
    var description: String?
    if case .string(let s) = mcpTool["description"] ?? .null { description = s }

    var functionDeclaration = FunctionDeclaration(
        description: description,
        name: name,
        parametersJsonSchema: mcpTool["inputSchema"]
    )
    if let outputSchema = mcpTool["outputSchema"], case .null = outputSchema {
        // Skip when null
    } else if let outputSchema = mcpTool["outputSchema"] {
        functionDeclaration.responseJsonSchema = outputSchema
    }
    if let behavior = config.behavior {
        functionDeclaration.behavior = behavior
    }

    return Tool(functionDeclarations: [functionDeclaration])
}

/// Converts a list of MCP tools to a single Gemini tool with a list of function
/// declarations.
public func mcpToolsToGeminiTool(_ mcpTools: [McpTool], config: CallableToolConfig = CallableToolConfig()) throws -> Tool {
    var functionDeclarations: [FunctionDeclaration] = []
    var toolNames = Set<String>()
    for mcpTool in mcpTools {
        guard case .string(let mcpToolName) = mcpTool["name"] ?? .null else {
            throw GenAIError.invalidArgument("MCP tool is missing a name")
        }
        if toolNames.contains(mcpToolName) {
            throw GenAIError.invalidArgument(
                "Duplicate function name \(mcpToolName) found in MCP tools. Please ensure function names are unique."
            )
        }
        toolNames.insert(mcpToolName)
        let geminiTool = mcpToGeminiTool(mcpTool, config: config)
        if let decls = geminiTool.functionDeclarations {
            functionDeclarations.append(contentsOf: decls)
        }
    }
    return Tool(functionDeclarations: functionDeclarations)
}

// Transforms a source input into a BatchJobSource object with validation.
public func tBatchJobSource(client: ApiClient, src: BatchJobSourceUnion) throws -> BatchJobSource {
    var sourceObj: BatchJobSource

    switch src {
    case .string(let s):
        if client.isVertexAI() {
            if s.hasPrefix("gs://") {
                sourceObj = BatchJobSource(format: "jsonl", gcsUri: [s])
            } else if s.hasPrefix("bq://") {
                sourceObj = BatchJobSource(format: "bigquery", bigqueryUri: s)
            } else if _matchesVertexDatasetPattern(s) {
                sourceObj = BatchJobSource(format: "vertex-dataset", vertexDatasetName: s)
            } else {
                throw GenAIError.invalidArgument("Unsupported string source for Vertex AI: \(s)")
            }
        } else {
            // MLDEV
            if s.hasPrefix("files/") {
                sourceObj = BatchJobSource(fileName: s)
            } else {
                throw GenAIError.invalidArgument("Unsupported string source for Gemini API: \(s)")
            }
        }
    case .inlined(let arr):
        if client.isVertexAI() {
            throw GenAIError.invalidArgument("InlinedRequest[] is not supported in Vertex AI.")
        }
        sourceObj = BatchJobSource(inlinedRequests: arr)
    case .source(let s):
        sourceObj = s
    }

    // Validation logic
    var vertexSourcesCount = 0
    if let gcs = sourceObj.gcsUri, !gcs.isEmpty { vertexSourcesCount += 1 }
    if let bq = sourceObj.bigqueryUri, !bq.isEmpty { vertexSourcesCount += 1 }
    if let vd = sourceObj.vertexDatasetName, !vd.isEmpty { vertexSourcesCount += 1 }

    var mldevSourcesCount = 0
    if let inlined = sourceObj.inlinedRequests, !inlined.isEmpty { mldevSourcesCount += 1 }
    if let fn = sourceObj.fileName, !fn.isEmpty { mldevSourcesCount += 1 }

    if client.isVertexAI() {
        if mldevSourcesCount > 0 || vertexSourcesCount != 1 {
            throw GenAIError.invalidArgument(
                "Exactly one of `gcsUri`, `bigqueryUri`, or `vertexDatasetName` must be set for Vertex AI."
            )
        }
    } else {
        if vertexSourcesCount > 0 || mldevSourcesCount != 1 {
            throw GenAIError.invalidArgument(
                "Exactly one of `inlinedRequests`, `fileName`, must be set for Gemini API."
            )
        }
    }

    return sourceObj
}

private func _matchesVertexDatasetPattern(_ s: String) -> Bool {
    // /^projects\/[^/]+\/locations\/[^/]+\/datasets\/[^/]+$/
    guard let regex = try? NSRegularExpression(
        pattern: "^projects/[^/]+/locations/[^/]+/datasets/[^/]+$"
    ) else { return false }
    let range = NSRange(s.startIndex..<s.endIndex, in: s)
    return regex.firstMatch(in: s, range: range) != nil
}

public func tEmbeddingBatchJobSource(client: ApiClient, src: EmbeddingsBatchJobSource) throws -> EmbeddingsBatchJobSource {
    if client.isVertexAI() {
        throw GenAIError.unsupported("Embedding batch jobs are not supported in Vertex AI.")
    }

    let sourceObj = src
    var mldevSources = 0
    if sourceObj.inlinedRequests != nil { mldevSources += 1 }
    if let fn = sourceObj.fileName, !fn.isEmpty { mldevSources += 1 }

    if mldevSources != 1 {
        throw GenAIError.invalidArgument(
            "Exactly one of `inlinedRequests` or `fileName` must be set for Embedding Batch Jobs in the Gemini API."
        )
    }
    return sourceObj
}

public func tBatchJobDestination(_ dest: BatchJobDestinationUnion) throws -> BatchJobDestination {
    switch dest {
    case .destination(let d):
        return d
    case .string(let destString):
        if destString.hasPrefix("gs://") {
            return BatchJobDestination(format: "jsonl", gcsUri: destString)
        } else if destString.hasPrefix("bq://") {
            return BatchJobDestination(format: "bigquery", bigqueryUri: destString)
        } else {
            throw GenAIError.invalidArgument("Unsupported destination: \(destString)")
        }
    }
}

public func tRecvBatchJobDestination(_ dest: JSONValue) -> JSONValue {
    // Ensure dest is a non-null object before proceeding.
    guard case .object(var obj) = dest else {
        return .object([:])
    }

    // Safely access nested properties.
    guard case .object(let inlineResponsesObj) = obj["inlinedResponses"] ?? .null else {
        return dest
    }

    guard case .array(let responsesArray) = inlineResponsesObj["inlinedResponses"] ?? .null,
          !responsesArray.isEmpty else {
        return dest
    }

    // Check if any response has the 'embedding' property.
    var hasEmbedding = false
    for responseItem in responsesArray {
        guard case .object(let responseItemObj) = responseItem else { continue }
        guard case .object(let responseObj) = responseItemObj["response"] ?? .null else { continue }
        if responseObj["embedding"] != nil {
            hasEmbedding = true
            break
        }
    }

    if hasEmbedding {
        obj["inlinedEmbedContentResponses"] = obj["inlinedResponses"]
        obj.removeValue(forKey: "inlinedResponses")
    }

    return .object(obj)
}

public func tBatchJobName(apiClient: ApiClient, name: JSONValue) throws -> String {
    guard case .string(let nameString) = name else {
        throw GenAIError.invalidArgument("Invalid batch job name: not a string.")
    }
    return try tBatchJobName(apiClient: apiClient, name: nameString)
}

public func tBatchJobName(apiClient: ApiClient, name: String) throws -> String {
    let nameString = name
    if !apiClient.isVertexAI() {
        // /batches\/[^/]+$/
        guard let mldevRegex = try? NSRegularExpression(pattern: "batches/[^/]+$") else {
            throw GenAIError.runtime("Failed to compile mldev batch-name regex")
        }
        let range = NSRange(nameString.startIndex..<nameString.endIndex, in: nameString)
        if mldevRegex.firstMatch(in: nameString, range: range) != nil {
            return nameString.split(separator: "/").last.map(String.init) ?? nameString
        } else {
            throw GenAIError.invalidArgument("Invalid batch job name: \(nameString).")
        }
    }

    // /^projects\/[^/]+\/locations\/[^/]+\/batchPredictionJobs\/[^/]+$/
    guard let vertexRegex = try? NSRegularExpression(
        pattern: "^projects/[^/]+/locations/[^/]+/batchPredictionJobs/[^/]+$"
    ) else {
        throw GenAIError.runtime("Failed to compile vertex batch-name regex")
    }
    let range = NSRange(nameString.startIndex..<nameString.endIndex, in: nameString)
    if vertexRegex.firstMatch(in: nameString, range: range) != nil {
        return nameString.split(separator: "/").last.map(String.init) ?? nameString
    }

    // /^\d+$/
    guard let digitsRegex = try? NSRegularExpression(pattern: "^\\d+$") else {
        throw GenAIError.runtime("Failed to compile digits regex")
    }
    if digitsRegex.firstMatch(in: nameString, range: range) != nil {
        return nameString
    } else {
        throw GenAIError.invalidArgument("Invalid batch job name: \(nameString).")
    }
}

public func tJobState(_ state: JSONValue) -> String {
    guard case .string(let stateString) = state else { return "" }
    return tJobState(stateString)
}

public func tJobState(_ state: String) -> String {
    switch state {
    case "BATCH_STATE_UNSPECIFIED": return "JOB_STATE_UNSPECIFIED"
    case "BATCH_STATE_PENDING": return "JOB_STATE_PENDING"
    case "BATCH_STATE_RUNNING": return "JOB_STATE_RUNNING"
    case "BATCH_STATE_SUCCEEDED": return "JOB_STATE_SUCCEEDED"
    case "BATCH_STATE_FAILED": return "JOB_STATE_FAILED"
    case "BATCH_STATE_CANCELLED": return "JOB_STATE_CANCELLED"
    case "BATCH_STATE_EXPIRED": return "JOB_STATE_EXPIRED"
    default: return state
    }
}

public func tIsVertexEmbedContentModel(_ model: String) -> Bool {
    return (model.contains("gemini") && model != "gemini-embedding-001")
        || model.contains("maas")
}
