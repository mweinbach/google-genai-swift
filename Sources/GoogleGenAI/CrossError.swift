// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Mirrors `crossError()` from `cross/_cross_error.ts`. Returns a uniform error used
/// to signal that a code path needs a platform-specific implementation in the JS SDK.
/// In the Swift port this is rarely thrown (everything is Foundation-native), but it is
/// kept so behaviour parity with TS tests can be preserved when needed.
public func crossError() -> Error {
    return GenAIError.unsupported(
        """
        This feature requires a platform-specific implementation. In the Swift SDK \
        every supported codepath is Foundation-native — if you reach this error you \
        are likely on a build that has not yet ported the feature.
        """
    )
}
