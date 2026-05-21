// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

public let MCP_LABEL = "mcp_used/unknown"

private actor McpUsageTracker {
    static let shared = McpUsageTracker()
    var fromMcpToTool = false
    func set(_ v: Bool) { fromMcpToTool = v }
    func get() -> Bool { fromMcpToTool }
}

/// Minimal protocol an MCP client must satisfy. The js-genai uses
/// `@modelcontextprotocol/sdk` directly; Swift has no first-party Swift MCP SDK
/// yet, so this protocol captures only the methods `McpCallableTool` needs.
public protocol McpClient: Sendable {
    func listTools(cursor: String?) async throws -> McpListToolsResult
    func callTool(name: String, arguments: [String: JSONValue]?, requestOptions: McpRequestOptions?) async throws -> McpCallToolResult
}

public struct McpRequestOptions: Sendable {
    public var timeout: Double?
    public init(timeout: Double? = nil) {
        self.timeout = timeout
    }
}

public struct McpListToolsResult: Sendable {
    public var tools: [McpTool]
    public var nextCursor: String?
    public init(tools: [McpTool], nextCursor: String? = nil) {
        self.tools = tools
        self.nextCursor = nextCursor
    }
}

public struct McpTool: Sendable, Codable {
    public var name: String
    public var description: String?
    public var inputSchema: JSONValue?
    public init(name: String, description: String? = nil, inputSchema: JSONValue? = nil) {
        self.name = name
        self.description = description
        self.inputSchema = inputSchema
    }
}

public struct McpCallToolResult: Sendable, Codable {
    public var isError: Bool?
    public var content: JSONValue?
    public init(isError: Bool? = nil, content: JSONValue? = nil) {
        self.isError = isError
        self.content = content
    }
}

/// Returns true if the list of tools contains any MCP-derived tool.
public func hasMcpToolUsage(_ tools: ToolListUnion) async -> Bool {
    for tool in tools {
        if case .callable(let c) = tool, c is McpCallableTool {
            return true
        }
        if case .tool(let t) = tool, t.functionDeclarations?.first(where: { _ in false }) != nil {
            // Heuristic placeholder — TS checks for `inputSchema` on the tool
            // object which is an MCP-only field. Swift Tool struct does not
            // carry an inputSchema, so this branch is currently unreachable.
            return true
        }
    }
    return await McpUsageTracker.shared.get()
}

/// Appends the MCP label to the Google API client header.
public func setMcpUsageHeader(_ headers: inout [String: String]) {
    let existing = headers[GOOGLE_API_CLIENT_HEADER] ?? ""
    headers[GOOGLE_API_CLIENT_HEADER] = (existing + " \(MCP_LABEL)")
        .trimmingCharacters(in: .whitespaces)
}

/// `McpCallableTool` adapts one or more MCP clients to the GenAI `CallableTool`
/// protocol so MCP-exposed tools can participate in Gemini's automatic
/// function-calling loop.
public final class McpCallableTool: CallableTool, @unchecked Sendable {
    private let mcpClients: [any McpClient]
    private let config: CallableToolConfig
    private let lock = NSLock()
    private var initialized = false
    private var mcpTools: [McpTool] = []
    private var functionNameToMcpClient: [String: any McpClient] = [:]

    private init(mcpClients: [any McpClient], config: CallableToolConfig) {
        self.mcpClients = mcpClients
        self.config = config
    }

    public static func create(_ mcpClients: [any McpClient], config: CallableToolConfig) -> McpCallableTool {
        McpCallableTool(mcpClients: mcpClients, config: config)
    }

    public func initialize() async throws {
        let alreadyInit = readInit()
        if alreadyInit { return }
        var functionMap: [String: any McpClient] = [:]
        var tools: [McpTool] = []
        for client in mcpClients {
            var cursor: String? = nil
            var count = 0
            while count < 100 {
                let result = try await client.listTools(cursor: cursor)
                for tool in result.tools {
                    tools.append(tool)
                    if functionMap[tool.name] != nil {
                        throw GenAIError.invalidArgument(
                            "Duplicate function name \(tool.name) found in MCP tools. Please ensure function names are unique."
                        )
                    }
                    functionMap[tool.name] = client
                    count += 1
                }
                guard let next = result.nextCursor else { break }
                cursor = next
            }
        }
        writeInit(tools: tools, map: functionMap)
    }

    private func readInit() -> Bool {
        lock.lock(); defer { lock.unlock() }
        return initialized
    }

    private func writeInit(tools: [McpTool], map: [String: any McpClient]) {
        lock.lock(); defer { lock.unlock() }
        mcpTools = tools
        functionNameToMcpClient = map
        initialized = true
    }

    private func readMcpTools() -> [McpTool] {
        lock.lock(); defer { lock.unlock() }
        return mcpTools
    }

    private func readClient(for functionName: String) -> (any McpClient)? {
        lock.lock(); defer { lock.unlock() }
        return functionNameToMcpClient[functionName]
    }

    public func tool() async throws -> Tool {
        try await initialize()
        return try mcpToolsToGeminiTool(readMcpTools(), config: config)
    }

    public func callTool(functionCalls: [FunctionCall]) async throws -> [Part] {
        try await initialize()
        var responses: [Part] = []
        for call in functionCalls {
            guard let name = call.name, let client = readClient(for: name) else { continue }
            let requestOptions = config.timeout.map { McpRequestOptions(timeout: $0) }
            let result = try await client.callTool(name: name, arguments: call.args, requestOptions: requestOptions)
            let responseDict: [String: JSONValue]
            if result.isError == true {
                responseDict = ["error": .object([
                    "isError": .bool(true),
                    "content": result.content ?? .null
                ])]
            } else {
                if case .object(let obj) = result.content ?? .null {
                    responseDict = obj
                } else {
                    responseDict = ["content": result.content ?? .null]
                }
            }
            let funcResponse = FunctionResponse(
                name: call.name,
                response: responseDict
            )
            var part = Part()
            part.functionResponse = funcResponse
            responses.append(part)
        }
        return responses
    }
}

/// Creates an `McpCallableTool` from one or more MCP clients and an optional
/// config. Marks MCP usage for telemetry.
///
/// - Experimental: Built-in MCP support is an experimental feature and may
///   change in future versions.
public func mcpToTool(_ clients: [any McpClient], config: CallableToolConfig = CallableToolConfig()) async throws -> any CallableTool {
    await McpUsageTracker.shared.set(true)
    if clients.isEmpty {
        throw GenAIError.invalidArgument("No MCP clients provided")
    }
    return McpCallableTool.create(clients, config: config)
}

public func setMcpToolUsageFromMcpToTool(_ usage: Bool) async {
    await McpUsageTracker.shared.set(usage)
}
