// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Base class for API resources. Concrete subclasses receive a reference to the parent
/// client and expose CRUD methods. Mirrors `APIResource` in `core/resource.ts`.
open class APIResource: @unchecked Sendable {
    /// The key path from the client. e.g. a resource at `client.foo.bar` would
    /// have `_key = ["foo", "bar"]`.
    open class var _key: [String] { return [] }

    public let _client: BaseGeminiNextGenAPIClient

    public required init(_ client: BaseGeminiNextGenAPIClient) {
        self._client = client
    }
}
