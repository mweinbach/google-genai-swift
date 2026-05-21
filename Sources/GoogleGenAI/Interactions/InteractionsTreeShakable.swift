// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Creates a client with a subset of the available resources. Mirrors
/// `createClient` in `tree-shakable.ts`.
///
/// In Swift the leaf `GeminiNextGenAPIClient` already lazily instantiates its
/// `interactions`, `webhooks`, and `agents` properties, so tree-shaking isn't
/// the same kind of concern as in JS. This function is provided for parity:
/// it returns a base client with the named resources eagerly initialized.
public func createClient(
    options: InteractionsClientOptions,
    resources: [APIResource.Type] = []
) -> BaseGeminiNextGenAPIClient {
    let client = BaseGeminiNextGenAPIClient(options)
    for ResourceClass in resources {
        _ = ResourceClass.init(client)
    }
    return client
}
