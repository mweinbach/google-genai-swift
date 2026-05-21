// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Agent resource — mirrors `resources/agents.ts`.
open class BaseAgents: APIResource, @unchecked Sendable {
    public override class var _key: [String] { return ["agents"] }

    /// Creates a new Agent.
    public func create(_ params: AgentCreateParams? = nil, options: RequestOptions = RequestOptions()) throws -> APIPromise<JSONValue> {
        let apiVersion = params?.api_version ?? _client.apiVersion
        let body = params.map { $0.toBody() } ?? .object([:])
        let path = try pathTag(statics: ["/", "/agents"], params: [apiVersion])
        var opts = options
        opts.body = body
        return _client.post(path, options: opts)
    }

    /// Lists all Agents.
    public func list(_ params: AgentListParams? = nil, options: RequestOptions = RequestOptions()) throws -> APIPromise<JSONValue> {
        let apiVersion = params?.api_version ?? _client.apiVersion
        var query: [String: JSONValue] = [:]
        if let s = params?.pageSize { query["pageSize"] = .int(Int64(s)) }
        if let t = params?.pageToken { query["pageToken"] = .string(t) }
        if let p = params?.parent { query["parent"] = .string(p) }
        let path = try pathTag(statics: ["/", "/agents"], params: [apiVersion])
        var opts = options
        opts.query = query
        return _client.get(path, options: opts)
    }

    /// Deletes an Agent.
    public func delete(_ id: String, params: AgentDeleteParams? = nil, options: RequestOptions = RequestOptions()) throws -> APIPromise<JSONValue> {
        let apiVersion = params?.api_version ?? _client.apiVersion
        let path = try pathTag(statics: ["/", "/agents/", ""], params: [apiVersion, id])
        return _client.delete(path, options: options)
    }

    /// Gets a specific Agent.
    public func get(_ id: String, params: AgentGetParams? = nil, options: RequestOptions = RequestOptions()) throws -> APIPromise<JSONValue> {
        let apiVersion = params?.api_version ?? _client.apiVersion
        let path = try pathTag(statics: ["/", "/agents/", ""], params: [apiVersion, id])
        return _client.get(path, options: options)
    }
}

/// Agent resource — public leaf class. Mirrors `Agents` in `resources/agents.ts`.
public final class Agents: BaseAgents, @unchecked Sendable {}

// MARK: - Agent data types

/// An Agent.
public typealias Agent = JSONValue

/// Response type for `Agents.list`. Mirrors `AgentListResponse`.
public typealias AgentListResponse = JSONValue

/// Response type for `Agents.delete`. Mirrors `AgentDeleteResponse`.
public typealias AgentDeleteResponse = JSONValue

/// Parameters for `Agents.create`. Mirrors `AgentCreateParams`.
public struct AgentCreateParams: Sendable {
    public var api_version: String?
    public var id: String?
    public var base_agent: String?
    public var base_environment: JSONValue?
    public var description: String?
    public var system_instruction: String?
    public var tools: [JSONValue]?

    public init(
        api_version: String? = nil,
        id: String? = nil,
        base_agent: String? = nil,
        base_environment: JSONValue? = nil,
        description: String? = nil,
        system_instruction: String? = nil,
        tools: [JSONValue]? = nil
    ) {
        self.api_version = api_version
        self.id = id
        self.base_agent = base_agent
        self.base_environment = base_environment
        self.description = description
        self.system_instruction = system_instruction
        self.tools = tools
    }

    func toBody() -> JSONValue {
        var obj: [String: JSONValue] = [:]
        if let id = id { obj["id"] = .string(id) }
        if let b = base_agent { obj["base_agent"] = .string(b) }
        if let e = base_environment { obj["base_environment"] = e }
        if let d = description { obj["description"] = .string(d) }
        if let s = system_instruction { obj["system_instruction"] = .string(s) }
        if let t = tools { obj["tools"] = .array(t) }
        return .object(obj)
    }
}

/// Parameters for `Agents.list`. Mirrors `AgentListParams`.
public struct AgentListParams: Sendable {
    public var api_version: String?
    public var pageSize: Int?
    public var pageToken: String?
    public var parent: String?
    public init(api_version: String? = nil, pageSize: Int? = nil, pageToken: String? = nil, parent: String? = nil) {
        self.api_version = api_version
        self.pageSize = pageSize
        self.pageToken = pageToken
        self.parent = parent
    }
}

public struct AgentDeleteParams: Sendable {
    public var api_version: String?
    public init(api_version: String? = nil) { self.api_version = api_version }
}

public struct AgentGetParams: Sendable {
    public var api_version: String?
    public init(api_version: String? = nil) { self.api_version = api_version }
}
