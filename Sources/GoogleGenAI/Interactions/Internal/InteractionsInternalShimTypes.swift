// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

// Mirrors `internal/shim-types.ts`.
//
// The TS file defines a `ReadableStream<R>` alias that resolves either to
// DOM `ReadableStream` or Node `stream/web ReadableStream`. In Swift the
// equivalent of a pull-based byte stream is `AsyncThrowingStream<Data, Error>`.

/// A readable byte stream. Mirrors `ReadableStream`.
public typealias InteractionsReadableStream = AsyncThrowingStream<Data, Error>
