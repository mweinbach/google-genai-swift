// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Default maximum number of remote function-call iterations the SDK will run automatically.
public let DEFAULT_MAX_REMOTE_CALLS: Int = 10

/// Returns whether automatic function calling is disabled.
public func shouldDisableAfc(_ config: GenerateContentConfig?) -> Bool {
    if config?.automaticFunctionCalling?.disable == true {
        return true
    }

    var callableToolsPresent = false
    for tool in config?.tools ?? [] {
        if isCallableTool(tool) {
            callableToolsPresent = true
            break
        }
    }
    if !callableToolsPresent {
        return true
    }

    let maxCalls = config?.automaticFunctionCalling?.maximumRemoteCalls
    if let maxCalls = maxCalls, maxCalls <= 0 {
        // The TS version also warns on non-integer maxCalls — Swift's `Int` is already
        // integral so the only invalid value is "<= 0". Mirror the warn-and-disable behavior.
        FileHandle.standardError.write(Data(
            "Invalid maximumRemoteCalls value provided for automatic function calling. Disabled automatic function calling. Please provide a valid integer value greater than 0. maximumRemoteCalls provided: \(maxCalls)\n"
                .utf8
        ))
        return true
    }
    return false
}

/// Returns true if `tool` is a callable (Swift-side function) rather than a plain `Tool`.
public func isCallableTool(_ tool: ToolUnion) -> Bool {
    if case .callable = tool {
        return true
    }
    return false
}

/// Checks whether the list of tools contains any CallableTools.
public func hasCallableTools(_ params: GenerateContentParameters) -> Bool {
    guard let tools = params.config?.tools else { return false }
    return tools.contains(where: { isCallableTool($0) })
}

/// Returns the indexes of the tools that are not compatible with AFC.
public func findAfcIncompatibleToolIndexes(_ params: GenerateContentParameters?) -> [Int] {
    var afcIncompatibleToolIndexes: [Int] = []
    guard let tools = params?.config?.tools else {
        return afcIncompatibleToolIndexes
    }
    for (index, tool) in tools.enumerated() {
        if isCallableTool(tool) {
            continue
        }
        if case .tool(let geminiTool) = tool,
           let decls = geminiTool.functionDeclarations,
           !decls.isEmpty {
            afcIncompatibleToolIndexes.append(index)
        }
    }
    return afcIncompatibleToolIndexes
}

/// Returns whether to append automatic function calling history to the response.
public func shouldAppendAfcHistory(_ config: GenerateContentConfig?) -> Bool {
    return !(config?.automaticFunctionCalling?.ignoreCallHistory ?? false)
}
