// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Parameters for setting the base URLs for the Gemini API and Vertex AI API.
public struct BaseUrlParameters: Sendable {
    public var geminiUrl: String?
    public var vertexUrl: String?

    public init(geminiUrl: String? = nil, vertexUrl: String? = nil) {
        self.geminiUrl = geminiUrl
        self.vertexUrl = vertexUrl
    }
}

/// Actor that owns the process-wide default base URLs. Replaces the module-level mutable
/// variables in `_base_url.ts` (Swift 6 strict concurrency forbids cross-actor mutation of
/// global vars without isolation).
private actor DefaultBaseUrls {
    static let shared = DefaultBaseUrls()

    private var geminiUrl: String?
    private var vertexUrl: String?

    func set(_ params: BaseUrlParameters) {
        self.geminiUrl = params.geminiUrl
        self.vertexUrl = params.vertexUrl
    }

    func get() -> BaseUrlParameters {
        BaseUrlParameters(geminiUrl: geminiUrl, vertexUrl: vertexUrl)
    }
}

/// Overrides the base URLs for the Gemini API and Vertex AI API.
///
/// This function should be called before initializing the SDK. If the base URLs are set after
/// initializing the SDK, the base URLs will not be updated. Base URLs provided in the
/// `HttpOptions` will also take precedence over URLs set here.
public func setDefaultBaseUrls(_ baseUrlParams: BaseUrlParameters) async {
    await DefaultBaseUrls.shared.set(baseUrlParams)
}

/// Returns the default base URLs for the Gemini API and Vertex AI API.
public func getDefaultBaseUrls() async -> BaseUrlParameters {
    await DefaultBaseUrls.shared.get()
}

/// Returns the default base URL based on the following priority:
///   1. Base URLs set via `HttpOptions`.
///   2. Base URLs set via the latest call to `setDefaultBaseUrls`.
///   3. Base URLs set via environment variables.
public func getBaseUrl(
    httpOptions: HttpOptions?,
    vertexai: Bool?,
    vertexBaseUrlFromEnv: String?,
    geminiBaseUrlFromEnv: String?
) async -> String? {
    if let baseUrl = httpOptions?.baseUrl, !baseUrl.isEmpty {
        return baseUrl
    }
    let defaults = await getDefaultBaseUrls()
    if vertexai == true {
        return defaults.vertexUrl ?? vertexBaseUrlFromEnv
    } else {
        return defaults.geminiUrl ?? geminiBaseUrlFromEnv
    }
}
