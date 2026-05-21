// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Webhook resource — mirrors `resources/webhooks.ts`.
open class BaseWebhooks: APIResource, @unchecked Sendable {
    public override class var _key: [String] { return ["webhooks"] }

    public func create(_ params: WebhookCreateParams, options: RequestOptions = RequestOptions()) throws -> APIPromise<JSONValue> {
        let apiVersion = params.api_version ?? _client.apiVersion
        let path = try pathTag(statics: ["/", "/webhooks"], params: [apiVersion])
        var opts = options
        opts.body = params.toBody()
        return _client.post(path, options: opts)
    }

    public func update(_ id: String, params: WebhookUpdateParams? = nil, options: RequestOptions = RequestOptions()) throws -> APIPromise<JSONValue> {
        let apiVersion = params?.api_version ?? _client.apiVersion
        let path = try pathTag(statics: ["/", "/webhooks/", ""], params: [apiVersion, id])
        var opts = options
        var query: [String: JSONValue] = [:]
        if let m = params?.update_mask { query["update_mask"] = .string(m) }
        if !query.isEmpty { opts.query = query }
        opts.body = params.map { $0.toBody() } ?? .object([:])
        return _client.patch(path, options: opts)
    }

    public func list(_ params: WebhookListParams? = nil, options: RequestOptions = RequestOptions()) throws -> APIPromise<JSONValue> {
        let apiVersion = params?.api_version ?? _client.apiVersion
        var query: [String: JSONValue] = [:]
        if let s = params?.page_size { query["page_size"] = .int(Int64(s)) }
        if let t = params?.page_token { query["page_token"] = .string(t) }
        let path = try pathTag(statics: ["/", "/webhooks"], params: [apiVersion])
        var opts = options
        opts.query = query
        return _client.get(path, options: opts)
    }

    public func delete(_ id: String, params: WebhookDeleteParams? = nil, options: RequestOptions = RequestOptions()) throws -> APIPromise<JSONValue> {
        let apiVersion = params?.api_version ?? _client.apiVersion
        let path = try pathTag(statics: ["/", "/webhooks/", ""], params: [apiVersion, id])
        return _client.delete(path, options: options)
    }

    public func get(_ id: String, params: WebhookGetParams? = nil, options: RequestOptions = RequestOptions()) throws -> APIPromise<JSONValue> {
        let apiVersion = params?.api_version ?? _client.apiVersion
        let path = try pathTag(statics: ["/", "/webhooks/", ""], params: [apiVersion, id])
        return _client.get(path, options: options)
    }

    public func ping(_ id: String, params: WebhookPingParams? = nil, options: RequestOptions = RequestOptions()) throws -> APIPromise<JSONValue> {
        let apiVersion = params?.api_version ?? _client.apiVersion
        let path = try pathTag(statics: ["/", "/webhooks/", ":ping"], params: [apiVersion, id])
        var opts = options
        opts.body = params?.body ?? .object([:])
        return _client.post(path, options: opts)
    }

    public func rotateSigningSecret(_ id: String, params: WebhookRotateSigningSecretParams? = nil, options: RequestOptions = RequestOptions()) throws -> APIPromise<JSONValue> {
        let apiVersion = params?.api_version ?? _client.apiVersion
        let path = try pathTag(statics: ["/", "/webhooks/", ":rotateSigningSecret"], params: [apiVersion, id])
        var opts = options
        opts.body = params?.toBody() ?? .object([:])
        return _client.post(path, options: opts)
    }
}

public final class Webhooks: BaseWebhooks, @unchecked Sendable {}

// MARK: - Webhook data types

public typealias SigningSecret = JSONValue
public typealias Webhook = JSONValue
public typealias WebhookListResponse = JSONValue
public typealias WebhookDeleteResponse = JSONValue
public typealias WebhookPingResponse = JSONValue
public typealias WebhookRotateSigningSecretResponse = JSONValue

public struct WebhookCreateParams: Sendable {
    public var api_version: String?
    public var subscribed_events: [String]
    public var uri: String
    public var name: String?

    public init(api_version: String? = nil, subscribed_events: [String], uri: String, name: String? = nil) {
        self.api_version = api_version
        self.subscribed_events = subscribed_events
        self.uri = uri
        self.name = name
    }

    func toBody() -> JSONValue {
        var obj: [String: JSONValue] = [:]
        obj["subscribed_events"] = .array(subscribed_events.map { .string($0) })
        obj["uri"] = .string(uri)
        if let n = name { obj["name"] = .string(n) }
        return .object(obj)
    }
}

public struct WebhookUpdateParams: Sendable {
    public var api_version: String?
    public var update_mask: String?
    public var name: String?
    public var state: String?
    public var subscribed_events: [String]?
    public var uri: String?

    public init(
        api_version: String? = nil,
        update_mask: String? = nil,
        name: String? = nil,
        state: String? = nil,
        subscribed_events: [String]? = nil,
        uri: String? = nil
    ) {
        self.api_version = api_version
        self.update_mask = update_mask
        self.name = name
        self.state = state
        self.subscribed_events = subscribed_events
        self.uri = uri
    }

    func toBody() -> JSONValue {
        var obj: [String: JSONValue] = [:]
        if let n = name { obj["name"] = .string(n) }
        if let s = state { obj["state"] = .string(s) }
        if let e = subscribed_events { obj["subscribed_events"] = .array(e.map { .string($0) }) }
        if let u = uri { obj["uri"] = .string(u) }
        return .object(obj)
    }
}

public struct WebhookListParams: Sendable {
    public var api_version: String?
    public var page_size: Int?
    public var page_token: String?
    public init(api_version: String? = nil, page_size: Int? = nil, page_token: String? = nil) {
        self.api_version = api_version
        self.page_size = page_size
        self.page_token = page_token
    }
}

public struct WebhookDeleteParams: Sendable {
    public var api_version: String?
    public init(api_version: String? = nil) { self.api_version = api_version }
}

public struct WebhookGetParams: Sendable {
    public var api_version: String?
    public init(api_version: String? = nil) { self.api_version = api_version }
}

public struct WebhookPingParams: Sendable {
    public var api_version: String?
    public var body: JSONValue?
    public init(api_version: String? = nil, body: JSONValue? = nil) {
        self.api_version = api_version
        self.body = body
    }
}

public struct WebhookRotateSigningSecretParams: Sendable {
    public var api_version: String?
    public var revocation_behavior: String?
    public init(api_version: String? = nil, revocation_behavior: String? = nil) {
        self.api_version = api_version
        self.revocation_behavior = revocation_behavior
    }
    func toBody() -> JSONValue {
        var obj: [String: JSONValue] = [:]
        if let r = revocation_behavior { obj["revocation_behavior"] = .string(r) }
        return .object(obj)
    }
}
