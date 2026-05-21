// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

// Internal APIs for Vertex libraries.
//
// **WARNING: INTERNAL API — DO NOT USE DIRECTLY**
//
// This file is intended for internal use by Vertex libraries only. It is not
// part of the public API and may change without following semantic versioning.
//
// In TypeScript this is a re-export module (`src/vertex_internal/index.ts`)
// that re-exposes `ApiClient`, `Auth`, `BaseModule`, `Downloader`, `Uploader`,
// `NodeAuth`, `NodeDownloader`, `NodeUploader`, and `_common.ts` symbols. In
// Swift, those types are already public in the `GoogleGenAI` module — there is
// no sub-module to gate access. This file exists to document the intent.
//
// If you depend on these types from outside the SDK, please raise an issue —
// stability is not guaranteed.

import Foundation
