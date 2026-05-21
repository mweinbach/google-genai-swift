// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

public func audioTranscriptionConfigToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    let toObject: [String: JSONValue] = [:]

    if case .null = getValueByPath(.object(fromObject), ["languageCodes"]) {} else {
        throw GenAIError.runtime(
            "languageCodes parameter is only supported in Gemini Enterprise Agent Platform mode, not in Gemini Developer API mode."
        )
    }

    return toObject
}

public func liveClientContentToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromTurns = getValueByPath(.object(fromObject), ["turns"])
    if case .null = fromTurns {} else {
        var transformed: JSONValue = fromTurns
        if case .array(let arr) = fromTurns {
            var mapped: [JSONValue] = []
            for item in arr {
                if case .object(let itemObj) = item {
                    var dummy: [String: JSONValue] = [:]
                    let result = try contentToMldev(apiClient: apiClient, fromObject: itemObj, parentObject: &dummy)
                    mapped.append(.object(result))
                } else {
                    mapped.append(item)
                }
            }
            transformed = .array(mapped)
        }
        try setValueByPath(&toObject, ["turns"], transformed)
    }

    let fromTurnComplete = getValueByPath(.object(fromObject), ["turnComplete"])
    if case .null = fromTurnComplete {} else {
        try setValueByPath(&toObject, ["turnComplete"], fromTurnComplete)
    }

    return toObject
}

public func liveClientContentToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromTurns = getValueByPath(.object(fromObject), ["turns"])
    if case .null = fromTurns {} else {
        var transformed: JSONValue = fromTurns
        if case .array(let arr) = fromTurns {
            var mapped: [JSONValue] = []
            for item in arr {
                if case .object(let itemObj) = item {
                    var dummy: [String: JSONValue] = [:]
                    let result = try contentToVertex(apiClient: apiClient, fromObject: itemObj, parentObject: &dummy)
                    mapped.append(.object(result))
                } else {
                    mapped.append(item)
                }
            }
            transformed = .array(mapped)
        }
        try setValueByPath(&toObject, ["turns"], transformed)
    }

    let fromTurnComplete = getValueByPath(.object(fromObject), ["turnComplete"])
    if case .null = fromTurnComplete {} else {
        try setValueByPath(&toObject, ["turnComplete"], fromTurnComplete)
    }

    return toObject
}

public func liveClientMessageToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromSetup = getValueByPath(.object(fromObject), ["setup"])
    if case .object(let setupObj) = fromSetup {
        var dummy: [String: JSONValue] = [:]
        let result = try liveClientSetupToMldev(apiClient: apiClient, fromObject: setupObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["setup"], .object(result))
    }

    let fromClientContent = getValueByPath(.object(fromObject), ["clientContent"])
    if case .object(let ccObj) = fromClientContent {
        var dummy: [String: JSONValue] = [:]
        let result = try liveClientContentToMldev(apiClient: apiClient, fromObject: ccObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["clientContent"], .object(result))
    }

    let fromRealtimeInput = getValueByPath(.object(fromObject), ["realtimeInput"])
    if case .object(let rtObj) = fromRealtimeInput {
        var dummy: [String: JSONValue] = [:]
        let result = try liveClientRealtimeInputToMldev(apiClient: apiClient, fromObject: rtObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["realtimeInput"], .object(result))
    }

    let fromToolResponse = getValueByPath(.object(fromObject), ["toolResponse"])
    if case .null = fromToolResponse {} else {
        try setValueByPath(&toObject, ["toolResponse"], fromToolResponse)
    }

    return toObject
}

public func liveClientMessageToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromSetup = getValueByPath(.object(fromObject), ["setup"])
    if case .object(let setupObj) = fromSetup {
        var dummy: [String: JSONValue] = [:]
        let result = try liveClientSetupToVertex(apiClient: apiClient, fromObject: setupObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["setup"], .object(result))
    }

    let fromClientContent = getValueByPath(.object(fromObject), ["clientContent"])
    if case .object(let ccObj) = fromClientContent {
        var dummy: [String: JSONValue] = [:]
        let result = try liveClientContentToVertex(apiClient: apiClient, fromObject: ccObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["clientContent"], .object(result))
    }

    let fromRealtimeInput = getValueByPath(.object(fromObject), ["realtimeInput"])
    if case .object(let rtObj) = fromRealtimeInput {
        var dummy: [String: JSONValue] = [:]
        let result = try liveClientRealtimeInputToVertex(apiClient: apiClient, fromObject: rtObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["realtimeInput"], .object(result))
    }

    let fromToolResponse = getValueByPath(.object(fromObject), ["toolResponse"])
    if case .null = fromToolResponse {} else {
        try setValueByPath(&toObject, ["toolResponse"], fromToolResponse)
    }

    return toObject
}

public func liveClientRealtimeInputToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromMediaChunks = getValueByPath(.object(fromObject), ["mediaChunks"])
    if case .null = fromMediaChunks {} else {
        var transformed: JSONValue = fromMediaChunks
        if case .array(let arr) = fromMediaChunks {
            var mapped: [JSONValue] = []
            for item in arr {
                if case .object(let itemObj) = item {
                    var dummy: [String: JSONValue] = [:]
                    let result = try blobToMldev(apiClient: apiClient, fromObject: itemObj, parentObject: &dummy)
                    mapped.append(.object(result))
                } else {
                    mapped.append(item)
                }
            }
            transformed = .array(mapped)
        }
        try setValueByPath(&toObject, ["mediaChunks"], transformed)
    }

    let fromAudio = getValueByPath(.object(fromObject), ["audio"])
    if case .object(let audioObj) = fromAudio {
        var dummy: [String: JSONValue] = [:]
        let result = try blobToMldev(apiClient: apiClient, fromObject: audioObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["audio"], .object(result))
    }

    let fromAudioStreamEnd = getValueByPath(.object(fromObject), ["audioStreamEnd"])
    if case .null = fromAudioStreamEnd {} else {
        try setValueByPath(&toObject, ["audioStreamEnd"], fromAudioStreamEnd)
    }

    let fromVideo = getValueByPath(.object(fromObject), ["video"])
    if case .object(let videoObj) = fromVideo {
        var dummy: [String: JSONValue] = [:]
        let result = try blobToMldev(apiClient: apiClient, fromObject: videoObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["video"], .object(result))
    }

    let fromText = getValueByPath(.object(fromObject), ["text"])
    if case .null = fromText {} else {
        try setValueByPath(&toObject, ["text"], fromText)
    }

    let fromActivityStart = getValueByPath(.object(fromObject), ["activityStart"])
    if case .null = fromActivityStart {} else {
        try setValueByPath(&toObject, ["activityStart"], fromActivityStart)
    }

    let fromActivityEnd = getValueByPath(.object(fromObject), ["activityEnd"])
    if case .null = fromActivityEnd {} else {
        try setValueByPath(&toObject, ["activityEnd"], fromActivityEnd)
    }

    return toObject
}

public func liveClientRealtimeInputToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromMediaChunks = getValueByPath(.object(fromObject), ["mediaChunks"])
    if case .null = fromMediaChunks {} else {
        try setValueByPath(&toObject, ["mediaChunks"], fromMediaChunks)
    }

    let fromAudio = getValueByPath(.object(fromObject), ["audio"])
    if case .null = fromAudio {} else {
        try setValueByPath(&toObject, ["audio"], fromAudio)
    }

    if case .null = getValueByPath(.object(fromObject), ["audioStreamEnd"]) {} else {
        throw GenAIError.runtime(
            "audioStreamEnd parameter is only supported in Gemini Developer API mode, not in Gemini Enterprise Agent Platform mode."
        )
    }

    let fromVideo = getValueByPath(.object(fromObject), ["video"])
    if case .null = fromVideo {} else {
        try setValueByPath(&toObject, ["video"], fromVideo)
    }

    let fromText = getValueByPath(.object(fromObject), ["text"])
    if case .null = fromText {} else {
        try setValueByPath(&toObject, ["text"], fromText)
    }

    let fromActivityStart = getValueByPath(.object(fromObject), ["activityStart"])
    if case .null = fromActivityStart {} else {
        try setValueByPath(&toObject, ["activityStart"], fromActivityStart)
    }

    let fromActivityEnd = getValueByPath(.object(fromObject), ["activityEnd"])
    if case .null = fromActivityEnd {} else {
        try setValueByPath(&toObject, ["activityEnd"], fromActivityEnd)
    }

    return toObject
}

public func liveClientSetupToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromModel = getValueByPath(.object(fromObject), ["model"])
    if case .null = fromModel {} else {
        try setValueByPath(&toObject, ["model"], fromModel)
    }

    let fromGenerationConfig = getValueByPath(.object(fromObject), ["generationConfig"])
    if case .null = fromGenerationConfig {} else {
        try setValueByPath(&toObject, ["generationConfig"], fromGenerationConfig)
    }

    let fromSystemInstruction = getValueByPath(.object(fromObject), ["systemInstruction"])
    if case .null = fromSystemInstruction {} else {
        let contentObj = try tContent(fromSystemInstruction)
        var dummy: [String: JSONValue] = [:]
        let result = try contentToMldev(apiClient: apiClient, fromObject: contentObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["systemInstruction"], .object(result))
    }

    let fromTools = getValueByPath(.object(fromObject), ["tools"])
    if case .null = fromTools {} else {
        let transformedListRaw = try tTools(fromTools)
        var mapped: [JSONValue] = []
        if case .array(let arr) = transformedListRaw {
            for item in arr {
                let tool = try tTool(item)
                if case .object(let toolObj) = tool {
                    var dummy: [String: JSONValue] = [:]
                    let result = try toolToMldev(apiClient: apiClient, fromObject: toolObj, parentObject: &dummy)
                    mapped.append(.object(result))
                } else {
                    mapped.append(tool)
                }
            }
            try setValueByPath(&toObject, ["tools"], .array(mapped))
        } else {
            try setValueByPath(&toObject, ["tools"], transformedListRaw)
        }
    }

    let fromRealtimeInputConfig = getValueByPath(.object(fromObject), ["realtimeInputConfig"])
    if case .null = fromRealtimeInputConfig {} else {
        try setValueByPath(&toObject, ["realtimeInputConfig"], fromRealtimeInputConfig)
    }

    let fromSessionResumption = getValueByPath(.object(fromObject), ["sessionResumption"])
    if case .object(let srObj) = fromSessionResumption {
        var dummy: [String: JSONValue] = [:]
        let result = try sessionResumptionConfigToMldev(apiClient: apiClient, fromObject: srObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["sessionResumption"], .object(result))
    }

    let fromContextWindowCompression = getValueByPath(.object(fromObject), ["contextWindowCompression"])
    if case .null = fromContextWindowCompression {} else {
        try setValueByPath(&toObject, ["contextWindowCompression"], fromContextWindowCompression)
    }

    let fromInputAudioTranscription = getValueByPath(.object(fromObject), ["inputAudioTranscription"])
    if case .object(let iatObj) = fromInputAudioTranscription {
        var dummy: [String: JSONValue] = [:]
        let result = try audioTranscriptionConfigToMldev(apiClient: apiClient, fromObject: iatObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["inputAudioTranscription"], .object(result))
    }

    let fromOutputAudioTranscription = getValueByPath(.object(fromObject), ["outputAudioTranscription"])
    if case .object(let oatObj) = fromOutputAudioTranscription {
        var dummy: [String: JSONValue] = [:]
        let result = try audioTranscriptionConfigToMldev(apiClient: apiClient, fromObject: oatObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["outputAudioTranscription"], .object(result))
    }

    let fromProactivity = getValueByPath(.object(fromObject), ["proactivity"])
    if case .null = fromProactivity {} else {
        try setValueByPath(&toObject, ["proactivity"], fromProactivity)
    }

    if case .null = getValueByPath(.object(fromObject), ["explicitVadSignal"]) {} else {
        throw GenAIError.runtime(
            "explicitVadSignal parameter is only supported in Gemini Enterprise Agent Platform mode, not in Gemini Developer API mode."
        )
    }

    let fromAvatarConfig = getValueByPath(.object(fromObject), ["avatarConfig"])
    if case .null = fromAvatarConfig {} else {
        try setValueByPath(&toObject, ["avatarConfig"], fromAvatarConfig)
    }

    let fromSafetySettings = getValueByPath(.object(fromObject), ["safetySettings"])
    if case .null = fromSafetySettings {} else {
        var transformed: JSONValue = fromSafetySettings
        if case .array(let arr) = fromSafetySettings {
            var mapped: [JSONValue] = []
            for item in arr {
                if case .object(let itemObj) = item {
                    var dummy: [String: JSONValue] = [:]
                    let result = try safetySettingToMldev(apiClient: apiClient, fromObject: itemObj, parentObject: &dummy)
                    mapped.append(.object(result))
                } else {
                    mapped.append(item)
                }
            }
            transformed = .array(mapped)
        }
        try setValueByPath(&toObject, ["safetySettings"], transformed)
    }

    return toObject
}

public func liveClientSetupToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromModel = getValueByPath(.object(fromObject), ["model"])
    if case .null = fromModel {} else {
        try setValueByPath(&toObject, ["model"], fromModel)
    }

    let fromGenerationConfig = getValueByPath(.object(fromObject), ["generationConfig"])
    if case .object(let gcObj) = fromGenerationConfig {
        var dummy: [String: JSONValue] = [:]
        let result = try generationConfigToVertex(apiClient: apiClient, fromObject: gcObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["generationConfig"], .object(result))
    }

    let fromSystemInstruction = getValueByPath(.object(fromObject), ["systemInstruction"])
    if case .null = fromSystemInstruction {} else {
        let contentObj = try tContent(fromSystemInstruction)
        var dummy: [String: JSONValue] = [:]
        let result = try contentToVertex(apiClient: apiClient, fromObject: contentObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["systemInstruction"], .object(result))
    }

    let fromTools = getValueByPath(.object(fromObject), ["tools"])
    if case .null = fromTools {} else {
        let transformedListRaw = try tTools(fromTools)
        var mapped: [JSONValue] = []
        if case .array(let arr) = transformedListRaw {
            for item in arr {
                let tool = try tTool(item)
                if case .object(let toolObj) = tool {
                    var dummy: [String: JSONValue] = [:]
                    let result = try toolToVertex(apiClient: apiClient, fromObject: toolObj, parentObject: &dummy)
                    mapped.append(.object(result))
                } else {
                    mapped.append(tool)
                }
            }
            try setValueByPath(&toObject, ["tools"], .array(mapped))
        } else {
            try setValueByPath(&toObject, ["tools"], transformedListRaw)
        }
    }

    let fromRealtimeInputConfig = getValueByPath(.object(fromObject), ["realtimeInputConfig"])
    if case .null = fromRealtimeInputConfig {} else {
        try setValueByPath(&toObject, ["realtimeInputConfig"], fromRealtimeInputConfig)
    }

    let fromSessionResumption = getValueByPath(.object(fromObject), ["sessionResumption"])
    if case .null = fromSessionResumption {} else {
        try setValueByPath(&toObject, ["sessionResumption"], fromSessionResumption)
    }

    let fromContextWindowCompression = getValueByPath(.object(fromObject), ["contextWindowCompression"])
    if case .null = fromContextWindowCompression {} else {
        try setValueByPath(&toObject, ["contextWindowCompression"], fromContextWindowCompression)
    }

    let fromInputAudioTranscription = getValueByPath(.object(fromObject), ["inputAudioTranscription"])
    if case .null = fromInputAudioTranscription {} else {
        try setValueByPath(&toObject, ["inputAudioTranscription"], fromInputAudioTranscription)
    }

    let fromOutputAudioTranscription = getValueByPath(.object(fromObject), ["outputAudioTranscription"])
    if case .null = fromOutputAudioTranscription {} else {
        try setValueByPath(&toObject, ["outputAudioTranscription"], fromOutputAudioTranscription)
    }

    let fromProactivity = getValueByPath(.object(fromObject), ["proactivity"])
    if case .null = fromProactivity {} else {
        try setValueByPath(&toObject, ["proactivity"], fromProactivity)
    }

    let fromExplicitVadSignal = getValueByPath(.object(fromObject), ["explicitVadSignal"])
    if case .null = fromExplicitVadSignal {} else {
        try setValueByPath(&toObject, ["explicitVadSignal"], fromExplicitVadSignal)
    }

    let fromAvatarConfig = getValueByPath(.object(fromObject), ["avatarConfig"])
    if case .null = fromAvatarConfig {} else {
        try setValueByPath(&toObject, ["avatarConfig"], fromAvatarConfig)
    }

    let fromSafetySettings = getValueByPath(.object(fromObject), ["safetySettings"])
    if case .null = fromSafetySettings {} else {
        try setValueByPath(&toObject, ["safetySettings"], fromSafetySettings)
    }

    return toObject
}

public func liveConnectConfigToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    let toObject: [String: JSONValue] = [:]

    let fromGenerationConfig = getValueByPath(.object(fromObject), ["generationConfig"])
    if case .null = fromGenerationConfig {} else {
        try setValueByPath(&parentObject, ["setup", "generationConfig"], fromGenerationConfig)
    }

    let fromResponseModalities = getValueByPath(.object(fromObject), ["responseModalities"])
    if case .null = fromResponseModalities {} else {
        try setValueByPath(&parentObject, ["setup", "generationConfig", "responseModalities"], fromResponseModalities)
    }

    let fromTemperature = getValueByPath(.object(fromObject), ["temperature"])
    if case .null = fromTemperature {} else {
        try setValueByPath(&parentObject, ["setup", "generationConfig", "temperature"], fromTemperature)
    }

    let fromTopP = getValueByPath(.object(fromObject), ["topP"])
    if case .null = fromTopP {} else {
        try setValueByPath(&parentObject, ["setup", "generationConfig", "topP"], fromTopP)
    }

    let fromTopK = getValueByPath(.object(fromObject), ["topK"])
    if case .null = fromTopK {} else {
        try setValueByPath(&parentObject, ["setup", "generationConfig", "topK"], fromTopK)
    }

    let fromMaxOutputTokens = getValueByPath(.object(fromObject), ["maxOutputTokens"])
    if case .null = fromMaxOutputTokens {} else {
        try setValueByPath(&parentObject, ["setup", "generationConfig", "maxOutputTokens"], fromMaxOutputTokens)
    }

    let fromMediaResolution = getValueByPath(.object(fromObject), ["mediaResolution"])
    if case .null = fromMediaResolution {} else {
        try setValueByPath(&parentObject, ["setup", "generationConfig", "mediaResolution"], fromMediaResolution)
    }

    let fromSeed = getValueByPath(.object(fromObject), ["seed"])
    if case .null = fromSeed {} else {
        try setValueByPath(&parentObject, ["setup", "generationConfig", "seed"], fromSeed)
    }

    let fromSpeechConfig = getValueByPath(.object(fromObject), ["speechConfig"])
    if case .null = fromSpeechConfig {} else {
        let transformed = try tLiveSpeechConfig(fromSpeechConfig)
        try setValueByPath(&parentObject, ["setup", "generationConfig", "speechConfig"], transformed)
    }

    let fromThinkingConfig = getValueByPath(.object(fromObject), ["thinkingConfig"])
    if case .null = fromThinkingConfig {} else {
        try setValueByPath(&parentObject, ["setup", "generationConfig", "thinkingConfig"], fromThinkingConfig)
    }

    let fromEnableAffectiveDialog = getValueByPath(.object(fromObject), ["enableAffectiveDialog"])
    if case .null = fromEnableAffectiveDialog {} else {
        try setValueByPath(&parentObject, ["setup", "generationConfig", "enableAffectiveDialog"], fromEnableAffectiveDialog)
    }

    let fromSystemInstruction = getValueByPath(.object(fromObject), ["systemInstruction"])
    if case .null = fromSystemInstruction {} else {
        let contentObj = try tContent(fromSystemInstruction)
        var dummy: [String: JSONValue] = [:]
        let result = try contentToMldev(apiClient: apiClient, fromObject: contentObj, parentObject: &dummy)
        try setValueByPath(&parentObject, ["setup", "systemInstruction"], .object(result))
    }

    let fromTools = getValueByPath(.object(fromObject), ["tools"])
    if case .null = fromTools {} else {
        let transformedListRaw = try tTools(fromTools)
        var mapped: [JSONValue] = []
        if case .array(let arr) = transformedListRaw {
            for item in arr {
                let tool = try tTool(item)
                if case .object(let toolObj) = tool {
                    var dummy: [String: JSONValue] = [:]
                    let result = try toolToMldev(apiClient: apiClient, fromObject: toolObj, parentObject: &dummy)
                    mapped.append(.object(result))
                } else {
                    mapped.append(tool)
                }
            }
            try setValueByPath(&parentObject, ["setup", "tools"], .array(mapped))
        } else {
            try setValueByPath(&parentObject, ["setup", "tools"], transformedListRaw)
        }
    }

    let fromSessionResumption = getValueByPath(.object(fromObject), ["sessionResumption"])
    if case .object(let srObj) = fromSessionResumption {
        var dummy: [String: JSONValue] = [:]
        let result = try sessionResumptionConfigToMldev(apiClient: apiClient, fromObject: srObj, parentObject: &dummy)
        try setValueByPath(&parentObject, ["setup", "sessionResumption"], .object(result))
    }

    let fromInputAudioTranscription = getValueByPath(.object(fromObject), ["inputAudioTranscription"])
    if case .object(let iatObj) = fromInputAudioTranscription {
        var dummy: [String: JSONValue] = [:]
        let result = try audioTranscriptionConfigToMldev(apiClient: apiClient, fromObject: iatObj, parentObject: &dummy)
        try setValueByPath(&parentObject, ["setup", "inputAudioTranscription"], .object(result))
    }

    let fromOutputAudioTranscription = getValueByPath(.object(fromObject), ["outputAudioTranscription"])
    if case .object(let oatObj) = fromOutputAudioTranscription {
        var dummy: [String: JSONValue] = [:]
        let result = try audioTranscriptionConfigToMldev(apiClient: apiClient, fromObject: oatObj, parentObject: &dummy)
        try setValueByPath(&parentObject, ["setup", "outputAudioTranscription"], .object(result))
    }

    let fromRealtimeInputConfig = getValueByPath(.object(fromObject), ["realtimeInputConfig"])
    if case .null = fromRealtimeInputConfig {} else {
        try setValueByPath(&parentObject, ["setup", "realtimeInputConfig"], fromRealtimeInputConfig)
    }

    let fromContextWindowCompression = getValueByPath(.object(fromObject), ["contextWindowCompression"])
    if case .null = fromContextWindowCompression {} else {
        try setValueByPath(&parentObject, ["setup", "contextWindowCompression"], fromContextWindowCompression)
    }

    let fromProactivity = getValueByPath(.object(fromObject), ["proactivity"])
    if case .null = fromProactivity {} else {
        try setValueByPath(&parentObject, ["setup", "proactivity"], fromProactivity)
    }

    if case .null = getValueByPath(.object(fromObject), ["explicitVadSignal"]) {} else {
        throw GenAIError.runtime(
            "explicitVadSignal parameter is only supported in Gemini Enterprise Agent Platform mode, not in Gemini Developer API mode."
        )
    }

    let fromAvatarConfig = getValueByPath(.object(fromObject), ["avatarConfig"])
    if case .null = fromAvatarConfig {} else {
        try setValueByPath(&parentObject, ["setup", "avatarConfig"], fromAvatarConfig)
    }

    let fromSafetySettings = getValueByPath(.object(fromObject), ["safetySettings"])
    if case .null = fromSafetySettings {} else {
        var transformed: JSONValue = fromSafetySettings
        if case .array(let arr) = fromSafetySettings {
            var mapped: [JSONValue] = []
            for item in arr {
                if case .object(let itemObj) = item {
                    var dummy: [String: JSONValue] = [:]
                    let result = try safetySettingToMldev(apiClient: apiClient, fromObject: itemObj, parentObject: &dummy)
                    mapped.append(.object(result))
                } else {
                    mapped.append(item)
                }
            }
            transformed = .array(mapped)
        }
        try setValueByPath(&parentObject, ["setup", "safetySettings"], transformed)
    }

    let fromStreamTranslationConfig = getValueByPath(.object(fromObject), ["streamTranslationConfig"])
    if case .null = fromStreamTranslationConfig {} else {
        try setValueByPath(&parentObject, ["setup", "generationConfig", "streamTranslationConfig"], fromStreamTranslationConfig)
    }

    return toObject
}

public func liveConnectConfigToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    let toObject: [String: JSONValue] = [:]

    let fromGenerationConfig = getValueByPath(.object(fromObject), ["generationConfig"])
    if case .object(let gcObj) = fromGenerationConfig {
        var dummy: [String: JSONValue] = [:]
        let result = try generationConfigToVertex(apiClient: apiClient, fromObject: gcObj, parentObject: &dummy)
        try setValueByPath(&parentObject, ["setup", "generationConfig"], .object(result))
    }

    let fromResponseModalities = getValueByPath(.object(fromObject), ["responseModalities"])
    if case .null = fromResponseModalities {} else {
        try setValueByPath(&parentObject, ["setup", "generationConfig", "responseModalities"], fromResponseModalities)
    }

    let fromTemperature = getValueByPath(.object(fromObject), ["temperature"])
    if case .null = fromTemperature {} else {
        try setValueByPath(&parentObject, ["setup", "generationConfig", "temperature"], fromTemperature)
    }

    let fromTopP = getValueByPath(.object(fromObject), ["topP"])
    if case .null = fromTopP {} else {
        try setValueByPath(&parentObject, ["setup", "generationConfig", "topP"], fromTopP)
    }

    let fromTopK = getValueByPath(.object(fromObject), ["topK"])
    if case .null = fromTopK {} else {
        try setValueByPath(&parentObject, ["setup", "generationConfig", "topK"], fromTopK)
    }

    let fromMaxOutputTokens = getValueByPath(.object(fromObject), ["maxOutputTokens"])
    if case .null = fromMaxOutputTokens {} else {
        try setValueByPath(&parentObject, ["setup", "generationConfig", "maxOutputTokens"], fromMaxOutputTokens)
    }

    let fromMediaResolution = getValueByPath(.object(fromObject), ["mediaResolution"])
    if case .null = fromMediaResolution {} else {
        try setValueByPath(&parentObject, ["setup", "generationConfig", "mediaResolution"], fromMediaResolution)
    }

    let fromSeed = getValueByPath(.object(fromObject), ["seed"])
    if case .null = fromSeed {} else {
        try setValueByPath(&parentObject, ["setup", "generationConfig", "seed"], fromSeed)
    }

    let fromSpeechConfig = getValueByPath(.object(fromObject), ["speechConfig"])
    if case .null = fromSpeechConfig {} else {
        let transformed = try tLiveSpeechConfig(fromSpeechConfig)
        try setValueByPath(&parentObject, ["setup", "generationConfig", "speechConfig"], transformed)
    }

    let fromThinkingConfig = getValueByPath(.object(fromObject), ["thinkingConfig"])
    if case .null = fromThinkingConfig {} else {
        try setValueByPath(&parentObject, ["setup", "generationConfig", "thinkingConfig"], fromThinkingConfig)
    }

    let fromEnableAffectiveDialog = getValueByPath(.object(fromObject), ["enableAffectiveDialog"])
    if case .null = fromEnableAffectiveDialog {} else {
        try setValueByPath(&parentObject, ["setup", "generationConfig", "enableAffectiveDialog"], fromEnableAffectiveDialog)
    }

    let fromSystemInstruction = getValueByPath(.object(fromObject), ["systemInstruction"])
    if case .null = fromSystemInstruction {} else {
        let contentObj = try tContent(fromSystemInstruction)
        var dummy: [String: JSONValue] = [:]
        let result = try contentToVertex(apiClient: apiClient, fromObject: contentObj, parentObject: &dummy)
        try setValueByPath(&parentObject, ["setup", "systemInstruction"], .object(result))
    }

    let fromTools = getValueByPath(.object(fromObject), ["tools"])
    if case .null = fromTools {} else {
        let transformedListRaw = try tTools(fromTools)
        var mapped: [JSONValue] = []
        if case .array(let arr) = transformedListRaw {
            for item in arr {
                let tool = try tTool(item)
                if case .object(let toolObj) = tool {
                    var dummy: [String: JSONValue] = [:]
                    let result = try toolToVertex(apiClient: apiClient, fromObject: toolObj, parentObject: &dummy)
                    mapped.append(.object(result))
                } else {
                    mapped.append(tool)
                }
            }
            try setValueByPath(&parentObject, ["setup", "tools"], .array(mapped))
        } else {
            try setValueByPath(&parentObject, ["setup", "tools"], transformedListRaw)
        }
    }

    let fromSessionResumption = getValueByPath(.object(fromObject), ["sessionResumption"])
    if case .null = fromSessionResumption {} else {
        try setValueByPath(&parentObject, ["setup", "sessionResumption"], fromSessionResumption)
    }

    let fromInputAudioTranscription = getValueByPath(.object(fromObject), ["inputAudioTranscription"])
    if case .null = fromInputAudioTranscription {} else {
        try setValueByPath(&parentObject, ["setup", "inputAudioTranscription"], fromInputAudioTranscription)
    }

    let fromOutputAudioTranscription = getValueByPath(.object(fromObject), ["outputAudioTranscription"])
    if case .null = fromOutputAudioTranscription {} else {
        try setValueByPath(&parentObject, ["setup", "outputAudioTranscription"], fromOutputAudioTranscription)
    }

    let fromRealtimeInputConfig = getValueByPath(.object(fromObject), ["realtimeInputConfig"])
    if case .null = fromRealtimeInputConfig {} else {
        try setValueByPath(&parentObject, ["setup", "realtimeInputConfig"], fromRealtimeInputConfig)
    }

    let fromContextWindowCompression = getValueByPath(.object(fromObject), ["contextWindowCompression"])
    if case .null = fromContextWindowCompression {} else {
        try setValueByPath(&parentObject, ["setup", "contextWindowCompression"], fromContextWindowCompression)
    }

    let fromProactivity = getValueByPath(.object(fromObject), ["proactivity"])
    if case .null = fromProactivity {} else {
        try setValueByPath(&parentObject, ["setup", "proactivity"], fromProactivity)
    }

    let fromExplicitVadSignal = getValueByPath(.object(fromObject), ["explicitVadSignal"])
    if case .null = fromExplicitVadSignal {} else {
        try setValueByPath(&parentObject, ["setup", "explicitVadSignal"], fromExplicitVadSignal)
    }

    let fromAvatarConfig = getValueByPath(.object(fromObject), ["avatarConfig"])
    if case .null = fromAvatarConfig {} else {
        try setValueByPath(&parentObject, ["setup", "avatarConfig"], fromAvatarConfig)
    }

    let fromSafetySettings = getValueByPath(.object(fromObject), ["safetySettings"])
    if case .null = fromSafetySettings {} else {
        try setValueByPath(&parentObject, ["setup", "safetySettings"], fromSafetySettings)
    }

    if case .null = getValueByPath(.object(fromObject), ["streamTranslationConfig"]) {} else {
        throw GenAIError.runtime(
            "streamTranslationConfig parameter is only supported in Gemini Developer API mode, not in Gemini Enterprise Agent Platform mode."
        )
    }

    return toObject
}

public func liveConnectParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromModel = getValueByPath(.object(fromObject), ["model"])
    if case .null = fromModel {} else {
        let transformed = try tModel(apiClient: apiClient, model: fromModel)
        try setValueByPath(&toObject, ["setup", "model"], .string(transformed))
    }

    let fromConfig = getValueByPath(.object(fromObject), ["config"])
    if case .object(let configObj) = fromConfig {
        let result = try liveConnectConfigToMldev(apiClient: apiClient, fromObject: configObj, parentObject: &toObject)
        try setValueByPath(&toObject, ["config"], .object(result))
    }

    return toObject
}

public func liveConnectParametersToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromModel = getValueByPath(.object(fromObject), ["model"])
    if case .null = fromModel {} else {
        let transformed = try tModel(apiClient: apiClient, model: fromModel)
        try setValueByPath(&toObject, ["setup", "model"], .string(transformed))
    }

    let fromConfig = getValueByPath(.object(fromObject), ["config"])
    if case .object(let configObj) = fromConfig {
        let result = try liveConnectConfigToVertex(apiClient: apiClient, fromObject: configObj, parentObject: &toObject)
        try setValueByPath(&toObject, ["config"], .object(result))
    }

    return toObject
}

public func liveMusicClientMessageToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    let toObject: [String: JSONValue] = [:]

    if case .null = getValueByPath(.object(fromObject), ["setup"]) {} else {
        throw GenAIError.runtime(
            "setup parameter is only supported in Gemini Developer API mode, not in Gemini Enterprise Agent Platform mode."
        )
    }

    if case .null = getValueByPath(.object(fromObject), ["clientContent"]) {} else {
        throw GenAIError.runtime(
            "clientContent parameter is only supported in Gemini Developer API mode, not in Gemini Enterprise Agent Platform mode."
        )
    }

    if case .null = getValueByPath(.object(fromObject), ["musicGenerationConfig"]) {} else {
        throw GenAIError.runtime(
            "musicGenerationConfig parameter is only supported in Gemini Developer API mode, not in Gemini Enterprise Agent Platform mode."
        )
    }

    if case .null = getValueByPath(.object(fromObject), ["playbackControl"]) {} else {
        throw GenAIError.runtime(
            "playbackControl parameter is only supported in Gemini Developer API mode, not in Gemini Enterprise Agent Platform mode."
        )
    }

    return toObject
}

public func liveMusicConnectParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromModel = getValueByPath(.object(fromObject), ["model"])
    if case .null = fromModel {} else {
        try setValueByPath(&toObject, ["setup", "model"], fromModel)
    }

    let fromCallbacks = getValueByPath(.object(fromObject), ["callbacks"])
    if case .null = fromCallbacks {} else {
        try setValueByPath(&toObject, ["callbacks"], fromCallbacks)
    }

    return toObject
}

public func liveMusicConnectParametersToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    let toObject: [String: JSONValue] = [:]

    if case .null = getValueByPath(.object(fromObject), ["model"]) {} else {
        throw GenAIError.runtime(
            "model parameter is only supported in Gemini Developer API mode, not in Gemini Enterprise Agent Platform mode."
        )
    }

    if case .null = getValueByPath(.object(fromObject), ["callbacks"]) {} else {
        throw GenAIError.runtime(
            "callbacks parameter is only supported in Gemini Developer API mode, not in Gemini Enterprise Agent Platform mode."
        )
    }

    return toObject
}

public func liveMusicSetConfigParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromMusicGenerationConfig = getValueByPath(.object(fromObject), ["musicGenerationConfig"])
    if case .null = fromMusicGenerationConfig {} else {
        try setValueByPath(&toObject, ["musicGenerationConfig"], fromMusicGenerationConfig)
    }

    return toObject
}

public func liveMusicSetConfigParametersToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    let toObject: [String: JSONValue] = [:]

    if case .null = getValueByPath(.object(fromObject), ["musicGenerationConfig"]) {} else {
        throw GenAIError.runtime(
            "musicGenerationConfig parameter is only supported in Gemini Developer API mode, not in Gemini Enterprise Agent Platform mode."
        )
    }

    return toObject
}

public func liveMusicSetWeightedPromptsParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromWeightedPrompts = getValueByPath(.object(fromObject), ["weightedPrompts"])
    if case .null = fromWeightedPrompts {} else {
        try setValueByPath(&toObject, ["weightedPrompts"], fromWeightedPrompts)
    }

    return toObject
}

public func liveMusicSetWeightedPromptsParametersToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    let toObject: [String: JSONValue] = [:]

    if case .null = getValueByPath(.object(fromObject), ["weightedPrompts"]) {} else {
        throw GenAIError.runtime(
            "weightedPrompts parameter is only supported in Gemini Developer API mode, not in Gemini Enterprise Agent Platform mode."
        )
    }

    return toObject
}

public func liveSendRealtimeInputParametersToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromMedia = getValueByPath(.object(fromObject), ["media"])
    if case .null = fromMedia {} else {
        let transformedListRaw = try tBlobs(fromMedia)
        var mapped: [JSONValue] = []
        if case .array(let arr) = transformedListRaw {
            for item in arr {
                if case .object(let itemObj) = item {
                    var dummy: [String: JSONValue] = [:]
                    let result = try blobToMldev(apiClient: apiClient, fromObject: itemObj, parentObject: &dummy)
                    mapped.append(.object(result))
                } else {
                    mapped.append(item)
                }
            }
            try setValueByPath(&toObject, ["mediaChunks"], .array(mapped))
        } else {
            try setValueByPath(&toObject, ["mediaChunks"], transformedListRaw)
        }
    }

    let fromAudio = getValueByPath(.object(fromObject), ["audio"])
    if case .null = fromAudio {} else {
        let audioBlob = try tAudioBlob(fromAudio)
        if case .object(let blobObj) = audioBlob {
            var dummy: [String: JSONValue] = [:]
            let result = try blobToMldev(apiClient: apiClient, fromObject: blobObj, parentObject: &dummy)
            try setValueByPath(&toObject, ["audio"], .object(result))
        } else {
            try setValueByPath(&toObject, ["audio"], audioBlob)
        }
    }

    let fromAudioStreamEnd = getValueByPath(.object(fromObject), ["audioStreamEnd"])
    if case .null = fromAudioStreamEnd {} else {
        try setValueByPath(&toObject, ["audioStreamEnd"], fromAudioStreamEnd)
    }

    let fromVideo = getValueByPath(.object(fromObject), ["video"])
    if case .null = fromVideo {} else {
        let imageBlob = try tImageBlob(fromVideo)
        if case .object(let blobObj) = imageBlob {
            var dummy: [String: JSONValue] = [:]
            let result = try blobToMldev(apiClient: apiClient, fromObject: blobObj, parentObject: &dummy)
            try setValueByPath(&toObject, ["video"], .object(result))
        } else {
            try setValueByPath(&toObject, ["video"], imageBlob)
        }
    }

    let fromText = getValueByPath(.object(fromObject), ["text"])
    if case .null = fromText {} else {
        try setValueByPath(&toObject, ["text"], fromText)
    }

    let fromActivityStart = getValueByPath(.object(fromObject), ["activityStart"])
    if case .null = fromActivityStart {} else {
        try setValueByPath(&toObject, ["activityStart"], fromActivityStart)
    }

    let fromActivityEnd = getValueByPath(.object(fromObject), ["activityEnd"])
    if case .null = fromActivityEnd {} else {
        try setValueByPath(&toObject, ["activityEnd"], fromActivityEnd)
    }

    return toObject
}

public func liveSendRealtimeInputParametersToVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromMedia = getValueByPath(.object(fromObject), ["media"])
    if case .null = fromMedia {} else {
        let transformedListRaw = try tBlobs(fromMedia)
        try setValueByPath(&toObject, ["mediaChunks"], transformedListRaw)
    }

    let fromAudio = getValueByPath(.object(fromObject), ["audio"])
    if case .null = fromAudio {} else {
        let audioBlob = try tAudioBlob(fromAudio)
        try setValueByPath(&toObject, ["audio"], audioBlob)
    }

    let fromAudioStreamEnd = getValueByPath(.object(fromObject), ["audioStreamEnd"])
    if case .null = fromAudioStreamEnd {} else {
        try setValueByPath(&toObject, ["audioStreamEnd"], fromAudioStreamEnd)
    }

    let fromVideo = getValueByPath(.object(fromObject), ["video"])
    if case .null = fromVideo {} else {
        let imageBlob = try tImageBlob(fromVideo)
        try setValueByPath(&toObject, ["video"], imageBlob)
    }

    let fromText = getValueByPath(.object(fromObject), ["text"])
    if case .null = fromText {} else {
        try setValueByPath(&toObject, ["text"], fromText)
    }

    let fromActivityStart = getValueByPath(.object(fromObject), ["activityStart"])
    if case .null = fromActivityStart {} else {
        try setValueByPath(&toObject, ["activityStart"], fromActivityStart)
    }

    let fromActivityEnd = getValueByPath(.object(fromObject), ["activityEnd"])
    if case .null = fromActivityEnd {} else {
        try setValueByPath(&toObject, ["activityEnd"], fromActivityEnd)
    }

    return toObject
}

public func liveServerMessageFromMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromSetupComplete = getValueByPath(.object(fromObject), ["setupComplete"])
    if case .null = fromSetupComplete {} else {
        try setValueByPath(&toObject, ["setupComplete"], fromSetupComplete)
    }

    let fromServerContent = getValueByPath(.object(fromObject), ["serverContent"])
    if case .null = fromServerContent {} else {
        try setValueByPath(&toObject, ["serverContent"], fromServerContent)
    }

    let fromToolCall = getValueByPath(.object(fromObject), ["toolCall"])
    if case .null = fromToolCall {} else {
        try setValueByPath(&toObject, ["toolCall"], fromToolCall)
    }

    let fromToolCallCancellation = getValueByPath(.object(fromObject), ["toolCallCancellation"])
    if case .null = fromToolCallCancellation {} else {
        try setValueByPath(&toObject, ["toolCallCancellation"], fromToolCallCancellation)
    }

    let fromUsageMetadata = getValueByPath(.object(fromObject), ["usageMetadata"])
    if case .null = fromUsageMetadata {} else {
        try setValueByPath(&toObject, ["usageMetadata"], fromUsageMetadata)
    }

    let fromGoAway = getValueByPath(.object(fromObject), ["goAway"])
    if case .null = fromGoAway {} else {
        try setValueByPath(&toObject, ["goAway"], fromGoAway)
    }

    let fromSessionResumptionUpdate = getValueByPath(.object(fromObject), ["sessionResumptionUpdate"])
    if case .null = fromSessionResumptionUpdate {} else {
        try setValueByPath(&toObject, ["sessionResumptionUpdate"], fromSessionResumptionUpdate)
    }

    let fromVoiceActivityDetectionSignal = getValueByPath(.object(fromObject), ["voiceActivityDetectionSignal"])
    if case .null = fromVoiceActivityDetectionSignal {} else {
        try setValueByPath(&toObject, ["voiceActivityDetectionSignal"], fromVoiceActivityDetectionSignal)
    }

    let fromVoiceActivity = getValueByPath(.object(fromObject), ["voiceActivity"])
    if case .object(let vaObj) = fromVoiceActivity {
        var dummy: [String: JSONValue] = [:]
        let result = try voiceActivityFromMldev(apiClient: apiClient, fromObject: vaObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["voiceActivity"], .object(result))
    }

    return toObject
}

public func liveServerMessageFromVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromSetupComplete = getValueByPath(.object(fromObject), ["setupComplete"])
    if case .null = fromSetupComplete {} else {
        try setValueByPath(&toObject, ["setupComplete"], fromSetupComplete)
    }

    let fromServerContent = getValueByPath(.object(fromObject), ["serverContent"])
    if case .null = fromServerContent {} else {
        try setValueByPath(&toObject, ["serverContent"], fromServerContent)
    }

    let fromToolCall = getValueByPath(.object(fromObject), ["toolCall"])
    if case .null = fromToolCall {} else {
        try setValueByPath(&toObject, ["toolCall"], fromToolCall)
    }

    let fromToolCallCancellation = getValueByPath(.object(fromObject), ["toolCallCancellation"])
    if case .null = fromToolCallCancellation {} else {
        try setValueByPath(&toObject, ["toolCallCancellation"], fromToolCallCancellation)
    }

    let fromUsageMetadata = getValueByPath(.object(fromObject), ["usageMetadata"])
    if case .object(let umObj) = fromUsageMetadata {
        var dummy: [String: JSONValue] = [:]
        let result = try usageMetadataFromVertex(apiClient: apiClient, fromObject: umObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["usageMetadata"], .object(result))
    }

    let fromGoAway = getValueByPath(.object(fromObject), ["goAway"])
    if case .null = fromGoAway {} else {
        try setValueByPath(&toObject, ["goAway"], fromGoAway)
    }

    let fromSessionResumptionUpdate = getValueByPath(.object(fromObject), ["sessionResumptionUpdate"])
    if case .null = fromSessionResumptionUpdate {} else {
        try setValueByPath(&toObject, ["sessionResumptionUpdate"], fromSessionResumptionUpdate)
    }

    let fromVoiceActivityDetectionSignal = getValueByPath(.object(fromObject), ["voiceActivityDetectionSignal"])
    if case .null = fromVoiceActivityDetectionSignal {} else {
        try setValueByPath(&toObject, ["voiceActivityDetectionSignal"], fromVoiceActivityDetectionSignal)
    }

    let fromVoiceActivity = getValueByPath(.object(fromObject), ["voiceActivity"])
    if case .object(let vaObj) = fromVoiceActivity {
        var dummy: [String: JSONValue] = [:]
        let result = try voiceActivityFromVertex(apiClient: apiClient, fromObject: vaObj, parentObject: &dummy)
        try setValueByPath(&toObject, ["voiceActivity"], .object(result))
    }

    return toObject
}

public func sessionResumptionConfigToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromHandle = getValueByPath(.object(fromObject), ["handle"])
    if case .null = fromHandle {} else {
        try setValueByPath(&toObject, ["handle"], fromHandle)
    }

    if case .null = getValueByPath(.object(fromObject), ["transparent"]) {} else {
        throw GenAIError.runtime(
            "transparent parameter is only supported in Gemini Enterprise Agent Platform mode, not in Gemini Developer API mode."
        )
    }

    return toObject
}

public func usageMetadataFromVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromPromptTokenCount = getValueByPath(.object(fromObject), ["promptTokenCount"])
    if case .null = fromPromptTokenCount {} else {
        try setValueByPath(&toObject, ["promptTokenCount"], fromPromptTokenCount)
    }

    let fromCachedContentTokenCount = getValueByPath(.object(fromObject), ["cachedContentTokenCount"])
    if case .null = fromCachedContentTokenCount {} else {
        try setValueByPath(&toObject, ["cachedContentTokenCount"], fromCachedContentTokenCount)
    }

    let fromResponseTokenCount = getValueByPath(.object(fromObject), ["candidatesTokenCount"])
    if case .null = fromResponseTokenCount {} else {
        try setValueByPath(&toObject, ["responseTokenCount"], fromResponseTokenCount)
    }

    let fromToolUsePromptTokenCount = getValueByPath(.object(fromObject), ["toolUsePromptTokenCount"])
    if case .null = fromToolUsePromptTokenCount {} else {
        try setValueByPath(&toObject, ["toolUsePromptTokenCount"], fromToolUsePromptTokenCount)
    }

    let fromThoughtsTokenCount = getValueByPath(.object(fromObject), ["thoughtsTokenCount"])
    if case .null = fromThoughtsTokenCount {} else {
        try setValueByPath(&toObject, ["thoughtsTokenCount"], fromThoughtsTokenCount)
    }

    let fromTotalTokenCount = getValueByPath(.object(fromObject), ["totalTokenCount"])
    if case .null = fromTotalTokenCount {} else {
        try setValueByPath(&toObject, ["totalTokenCount"], fromTotalTokenCount)
    }

    let fromPromptTokensDetails = getValueByPath(.object(fromObject), ["promptTokensDetails"])
    if case .null = fromPromptTokensDetails {} else {
        try setValueByPath(&toObject, ["promptTokensDetails"], fromPromptTokensDetails)
    }

    let fromCacheTokensDetails = getValueByPath(.object(fromObject), ["cacheTokensDetails"])
    if case .null = fromCacheTokensDetails {} else {
        try setValueByPath(&toObject, ["cacheTokensDetails"], fromCacheTokensDetails)
    }

    let fromResponseTokensDetails = getValueByPath(.object(fromObject), ["candidatesTokensDetails"])
    if case .null = fromResponseTokensDetails {} else {
        try setValueByPath(&toObject, ["responseTokensDetails"], fromResponseTokensDetails)
    }

    let fromToolUsePromptTokensDetails = getValueByPath(.object(fromObject), ["toolUsePromptTokensDetails"])
    if case .null = fromToolUsePromptTokensDetails {} else {
        try setValueByPath(&toObject, ["toolUsePromptTokensDetails"], fromToolUsePromptTokensDetails)
    }

    let fromTrafficType = getValueByPath(.object(fromObject), ["trafficType"])
    if case .null = fromTrafficType {} else {
        try setValueByPath(&toObject, ["trafficType"], fromTrafficType)
    }

    return toObject
}

public func voiceActivityFromMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromVoiceActivityType = getValueByPath(.object(fromObject), ["type"])
    if case .null = fromVoiceActivityType {} else {
        try setValueByPath(&toObject, ["voiceActivityType"], fromVoiceActivityType)
    }

    return toObject
}

public func voiceActivityFromVertex(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue] {
    var toObject: [String: JSONValue] = [:]

    let fromVoiceActivityType = getValueByPath(.object(fromObject), ["type"])
    if case .null = fromVoiceActivityType {} else {
        try setValueByPath(&toObject, ["voiceActivityType"], fromVoiceActivityType)
    }

    return toObject
}
