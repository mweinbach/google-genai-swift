// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Adapter to the parent API client instance (for accessing auth, project, location).
/// Mirrors `client-adapter.ts` `GeminiNextGenAPIClientAdapter` interface.
///
/// Note: A protocol with the same name (`GeminiNextGenAPIClientAdapter`) already exists in
/// `APIClient.swift` as an empty placeholder. We extend that contract here under the
/// distinct name `InteractionsClientAdapter` to avoid coupling.
public protocol InteractionsClientAdapter: Sendable {
    func isVertexAI() -> Bool
    func getProject() -> String?
    func getLocation() -> String?
    func getAuthHeaders() async throws -> [String: String]
}
