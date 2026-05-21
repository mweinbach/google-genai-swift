// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Pagers for the GenAI List APIs.

/// Enumerates the kinds of paged items supported by `Pager`.
public enum PagedItem: String, Sendable {
    case batchJobs = "batchJobs"
    case models = "models"
    case tuningJobs = "tuningJobs"
    case files = "files"
    case cachedContents = "cachedContents"
    case fileSearchStores = "fileSearchStores"
    case documents = "documents"
}

/// Pager class for iterating through paginated results.
///
/// Mirrors the JS `Pager<T>` AsyncIterable: holds a typed page, page-size, request callback,
/// and supports `for await` iteration over all pages.
public final class Pager<T: Sendable>: AsyncSequence, @unchecked Sendable {
    public typealias Element = T

    private let lock = NSLock()
    private var nameInternal: PagedItem
    private var pageInternal: [T] = []
    private var paramsInternal: Any
    private var pageInternalSize: Int = 0
    private var sdkHttpResponseInternal: HttpResponse?
    private let requestInternal: @Sendable (Any) async throws -> Any
    private var idxInternal: Int = 0

    public init(
        _ name: PagedItem,
        _ request: @escaping @Sendable (Any) async throws -> Any,
        _ response: Any,
        _ params: Any
    ) {
        self.nameInternal = name
        self.requestInternal = request
        self.paramsInternal = params
        self.initState(name: name, response: response, params: params)
    }

    private func initState(name: PagedItem, response: Any, params: Any) {
        self.nameInternal = name

        // Extract the items list and metadata from the response.
        let (items, nextPageToken, httpResponse) = Pager.extractPage(name: name, response: response)
        self.pageInternal = items
        self.sdkHttpResponseInternal = httpResponse
        self.idxInternal = 0

        // Compute the request params for the next page.
        var requestParams = params
        if !Pager.hasKeys(params) {
            requestParams = Pager.makeEmptyConfigParams()
        }
        // Set pageToken on the contained config.
        requestParams = Pager.withPageToken(requestParams, token: nextPageToken)
        self.paramsInternal = requestParams

        if let configuredPageSize = Pager.pageSize(of: requestParams) {
            self.pageInternalSize = configuredPageSize
        } else {
            self.pageInternalSize = self.pageInternal.count
        }
    }

    private func initNextPage(response: Any) {
        self.initState(name: self.nameInternal, response: response, params: self.paramsInternal)
    }

    /// Returns the current page, which is a list of items.
    ///
    /// The first page is retrieved when the pager is created. The returned list of
    /// items could be a subset of the entire list.
    public var page: [T] {
        lock.lock(); defer { lock.unlock() }
        return pageInternal
    }

    /// Returns the type of paged item (for example, ``batchJobs``).
    public var name: PagedItem {
        lock.lock(); defer { lock.unlock() }
        return nameInternal
    }

    /// Returns the length of the page fetched each time by this pager.
    ///
    /// The number of items in the page is less than or equal to the page length.
    public var pageSize: Int {
        lock.lock(); defer { lock.unlock() }
        return pageInternalSize
    }

    /// Returns the headers of the API response.
    public var sdkHttpResponse: HttpResponse? {
        lock.lock(); defer { lock.unlock() }
        return sdkHttpResponseInternal
    }

    /// Returns the parameters when making the API request for the next page.
    public var params: Any {
        lock.lock(); defer { lock.unlock() }
        return paramsInternal
    }

    /// Returns the total number of items in the current page.
    public var pageLength: Int {
        lock.lock(); defer { lock.unlock() }
        return pageInternal.count
    }

    /// Returns the item at the given index.
    public func getItem(_ index: Int) -> T {
        lock.lock(); defer { lock.unlock() }
        return pageInternal[index]
    }

    /// Returns an async iterator that supports iterating through all items
    /// retrieved from the API.
    ///
    /// The iterator will automatically fetch the next page if there are more items
    /// to fetch from the API.
    public func makeAsyncIterator() -> AsyncIterator {
        return AsyncIterator(pager: self)
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        let pager: Pager<T>

        public mutating func next() async throws -> T? {
            let (idx, length) = pager.readIndexAndLength()

            if idx >= length {
                if pager.hasNextPage() {
                    _ = try await pager.nextPage()
                } else {
                    return nil
                }
            }
            return pager.advanceAndRead()
        }
    }

    /// Fetches the next page of items. This makes a new API request.
    ///
    /// - Throws: `GenAIError.runtime` if there are no more pages to fetch.
    @discardableResult
    public func nextPage() async throws -> [T] {
        if !self.hasNextPage() {
            throw GenAIError.runtime("No more pages to fetch.")
        }
        let response = try await self.requestInternal(self.params)
        return self.applyNextPage(response: response)
    }

    internal func readIndexAndLength() -> (Int, Int) {
        lock.lock(); defer { lock.unlock() }
        return (idxInternal, pageInternal.count)
    }

    internal func advanceAndRead() -> T {
        lock.lock(); defer { lock.unlock() }
        let item = pageInternal[idxInternal]
        idxInternal += 1
        return item
    }

    internal func applyNextPage(response: Any) -> [T] {
        lock.lock(); defer { lock.unlock() }
        self.initNextPage(response: response)
        return pageInternal
    }

    /// Returns true if there are more pages to fetch from the API.
    public func hasNextPage() -> Bool {
        lock.lock(); defer { lock.unlock() }
        return Pager.pageToken(of: paramsInternal) != nil
    }

    // MARK: - Reflection helpers (Any-typed responses/params)

    /// Extracts the page items, next page token, and SDK HttpResponse from a response.
    /// Supports both typed (e.g. `ListBatchJobsResponse`) and `[String: JSONValue]`-shaped payloads.
    private static func extractPage(
        name: PagedItem,
        response: Any
    ) -> (items: [T], nextPageToken: String?, httpResponse: HttpResponse?) {
        // Convert the response to a JSON dictionary by encoding/decoding via JSONEncoder when possible.
        var dict: [String: JSONValue] = [:]
        if let asDict = response as? [String: JSONValue] {
            dict = asDict
        } else if let encodable = response as? Encodable {
            if let data = try? JSONEncoder().encode(AnyEncodable(encodable)),
               let decoded = try? JSONDecoder().decode(JSONValue.self, from: data),
               case .object(let obj) = decoded {
                dict = obj
            }
        }

        // Extract the field for this paged item.
        var items: [T] = []
        if case .array(let arr) = dict[name.rawValue] ?? .null {
            // First, try directly casting; if T is JSONValue this is direct.
            if let direct = arr as? [T] {
                items = direct
            } else {
                // Try decoding via JSONDecoder when T conforms to Decodable.
                items = arr.compactMap { element -> T? in
                    if let casted = element as? T { return casted }
                    if let data = try? JSONEncoder().encode(element) {
                        if let decoder = T.self as? Decodable.Type {
                            if let decoded = try? JSONDecoder().decode(decoder, from: data) as? T {
                                return decoded
                            }
                        }
                    }
                    return nil
                }
            }
        }

        var nextPageToken: String? = nil
        if case .string(let s) = dict["nextPageToken"] ?? .null {
            nextPageToken = s
        }

        var httpResponse: HttpResponse? = nil
        if let direct = (response as? HasSDKHttpResponse)?.sdkHttpResponseValue {
            httpResponse = direct
        } else if case .object(_) = dict["sdkHttpResponse"] ?? .null {
            if let data = try? JSONEncoder().encode(dict["sdkHttpResponse"] ?? .null) {
                httpResponse = try? JSONDecoder().decode(HttpResponse.self, from: data)
            }
        }
        return (items, nextPageToken, httpResponse)
    }

    /// Returns true if `params` appears to carry any configured field.
    /// Mirrors the TS check `Object.keys(params).length === 0`.
    private static func hasKeys(_ params: Any) -> Bool {
        if let mirror = Optional(Mirror(reflecting: params)),
           mirror.displayStyle == .struct || mirror.displayStyle == .class {
            for child in mirror.children {
                if let _ = child.label {
                    if !Pager.isOptionalNil(child.value) {
                        return true
                    }
                }
            }
            return false
        }
        return true
    }

    private static func isOptionalNil(_ value: Any) -> Bool {
        let m = Mirror(reflecting: value)
        if m.displayStyle == .optional {
            return m.children.count == 0
        }
        return false
    }

    private static func makeEmptyConfigParams() -> Any {
        return EmptyPagedParams()
    }

    /// Returns a copy of `params` with `config.pageToken` set to `token`.
    private static func withPageToken(_ params: Any, token: String?) -> Any {
        if var p = params as? AnyPagedParams {
            p.setPageToken(token)
            return p
        }
        // Fallback for params that don't implement AnyPagedParams: wrap them.
        var wrapper = AnyPagedParamsWrapper(underlying: params)
        wrapper.setPageToken(token)
        return wrapper
    }

    private static func pageToken(of params: Any) -> String? {
        if let p = params as? AnyPagedParams {
            return p.getPageToken()
        }
        if let wrapper = params as? AnyPagedParamsWrapper {
            return wrapper.getPageToken()
        }
        return nil
    }

    private static func pageSize(of params: Any) -> Int? {
        if let p = params as? AnyPagedParams {
            return p.getPageSize()
        }
        if let wrapper = params as? AnyPagedParamsWrapper {
            return wrapper.getPageSize()
        }
        return nil
    }
}

/// Marker protocol allowing the `Pager` to recover the SDK HTTP response from a typed page response.
public protocol HasSDKHttpResponse {
    var sdkHttpResponseValue: HttpResponse? { get }
}

/// Conformance allowing the `Pager` to read/write the contained config token/page size on
/// a typed parameters struct (e.g. `ListBatchJobsParameters`). Sibling slices may opt in.
public protocol AnyPagedParams {
    mutating func setPageToken(_ token: String?)
    func getPageToken() -> String?
    func getPageSize() -> Int?
}

/// Default empty params used when no params were supplied.
public struct EmptyPagedParams: AnyPagedParams, Sendable {
    public init() {}
    public var pageToken: String?
    public var pageSize: Int?
    public mutating func setPageToken(_ token: String?) { self.pageToken = token }
    public func getPageToken() -> String? { self.pageToken }
    public func getPageSize() -> Int? { self.pageSize }
}

/// Fallback wrapper that records a pageToken alongside an arbitrary `underlying`
/// parameters value. Used when the caller-supplied params struct does not conform
/// to `AnyPagedParams`.
public struct AnyPagedParamsWrapper: AnyPagedParams, @unchecked Sendable {
    public var underlying: Any
    public var pageToken: String?
    public var pageSize: Int?
    public mutating func setPageToken(_ token: String?) { self.pageToken = token }
    public func getPageToken() -> String? { self.pageToken }
    public func getPageSize() -> Int? { self.pageSize }
}

// MARK: - Internal AnyEncodable

/// Type-erased `Encodable` wrapper.
internal struct AnyEncodable: Encodable {
    let value: Encodable

    init(_ value: Encodable) {
        self.value = value
    }

    func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}
