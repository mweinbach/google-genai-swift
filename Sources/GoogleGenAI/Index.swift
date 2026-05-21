// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

// Public surface index, mirroring src/index.ts.
//
// In TypeScript this file re-exports the public API. Swift has no
// per-file re-export mechanism — `public` types declared anywhere in the
// `GoogleGenAI` module are already part of the module's public surface.
//
// This file documents the intended public surface for readers diffing the
// Swift port against the JS SDK. It declares no new symbols.

import Foundation

/// Alias for `Tool` (the GoogleGenAI wire-format struct), useful when
/// importing GoogleGenAI alongside Apple's `FoundationModels`, which exports
/// its own `Tool` protocol that would otherwise create ambiguity.
public typealias GoogleGenAITool = Tool

// Re-exported in TS as `export * from './batches'` etc:
//   - GoogleGenAI (Client.swift)
//   - Batches, Caches, Chats, Files, FileSearchStores, Documents, Models,
//     Music (LiveMusicSession), Operations, Tokens, Tunings, Live
//   - Pager, PagedItem
//   - All Types/ entries: enums, interfaces, classes
//   - errors: ApiError, ApiErrorInfo
//   - setDefaultBaseUrls, BaseUrlParameters
//   - mcpToTool
//   - Interactions (vendored subsystem)

// Re-exported in `src/vertex_internal/index.ts` for internal Vertex use:
//   - ApiClient, ApiClientInitOptions, HttpRequest
//   - Auth, BaseModule
//   - Downloader, Uploader
//   - DefaultAuth (collapses NodeAuth + WebAuth)
//   - URLSessionUploader, URLSessionDownloader
