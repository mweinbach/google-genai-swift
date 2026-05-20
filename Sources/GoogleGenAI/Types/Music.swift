// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Message to be sent by the system when connecting to the API.
public struct LiveMusicClientSetup: Codable, Sendable {
    /// The model's resource name. Format: `models/{model}`.
    public var model: String?

    public init(model: String? = nil) {
        self.model = model
    }
}

/// Maps a prompt to a relative weight to steer music generation.
public struct WeightedPrompt: Codable, Sendable {
    /// Text prompt.
    public var text: String?
    /// Weight of the prompt. Higher weights are more important than lower weights.
    public var weight: Double?

    public init(text: String? = nil, weight: Double? = nil) {
        self.text = text
        self.weight = weight
    }
}

/// User input to start or steer the music.
public struct LiveMusicClientContent: Codable, Sendable {
    /// Weighted prompts as the model input.
    public var weightedPrompts: [WeightedPrompt]?

    public init(weightedPrompts: [WeightedPrompt]? = nil) {
        self.weightedPrompts = weightedPrompts
    }
}

/// Configuration for music generation.
public struct LiveMusicGenerationConfig: Codable, Sendable {
    /// Controls the variance in audio generation. Range is [0.0, 3.0].
    public var temperature: Double?
    /// Samples the topK tokens with the highest probabilities. Range is [1, 1000].
    public var topK: Double?
    /// Seeds audio generation.
    public var seed: Double?
    /// Controls how closely the model follows prompts. Range is [0.0, 6.0].
    public var guidance: Double?
    /// Beats per minute. Range is [60, 200].
    public var bpm: Double?
    /// Density of sounds. Range is [0.0, 1.0].
    public var density: Double?
    /// Brightness of the music. Range is [0.0, 1.0].
    public var brightness: Double?
    /// Scale of the generated music.
    public var scale: Scale?
    /// Whether the audio output should contain bass.
    public var muteBass: Bool?
    /// Whether the audio output should contain drums.
    public var muteDrums: Bool?
    /// Whether the audio output should contain only bass and drums.
    public var onlyBassAndDrums: Bool?
    /// The mode of music generation. Default mode is QUALITY.
    public var musicGenerationMode: MusicGenerationMode?

    public init(
        temperature: Double? = nil,
        topK: Double? = nil,
        seed: Double? = nil,
        guidance: Double? = nil,
        bpm: Double? = nil,
        density: Double? = nil,
        brightness: Double? = nil,
        scale: Scale? = nil,
        muteBass: Bool? = nil,
        muteDrums: Bool? = nil,
        onlyBassAndDrums: Bool? = nil,
        musicGenerationMode: MusicGenerationMode? = nil
    ) {
        self.temperature = temperature
        self.topK = topK
        self.seed = seed
        self.guidance = guidance
        self.bpm = bpm
        self.density = density
        self.brightness = brightness
        self.scale = scale
        self.muteBass = muteBass
        self.muteDrums = muteDrums
        self.onlyBassAndDrums = onlyBassAndDrums
        self.musicGenerationMode = musicGenerationMode
    }
}

/// Messages sent by the client in the LiveMusicClientMessage call.
public struct LiveMusicClientMessage: Codable, Sendable {
    /// Message to be sent in the first `LiveMusicClientMessage`.
    public var setup: LiveMusicClientSetup?
    /// User input to influence music generation.
    public var clientContent: LiveMusicClientContent?
    /// Configuration for music generation.
    public var musicGenerationConfig: LiveMusicGenerationConfig?
    /// Playback control signal for the music generation.
    public var playbackControl: LiveMusicPlaybackControl?

    public init(
        setup: LiveMusicClientSetup? = nil,
        clientContent: LiveMusicClientContent? = nil,
        musicGenerationConfig: LiveMusicGenerationConfig? = nil,
        playbackControl: LiveMusicPlaybackControl? = nil
    ) {
        self.setup = setup
        self.clientContent = clientContent
        self.musicGenerationConfig = musicGenerationConfig
        self.playbackControl = playbackControl
    }
}

/// Sent in response to a `LiveMusicClientSetup` message from the client.
public struct LiveMusicServerSetupComplete: Codable, Sendable {
    public init() {}
}

/// Prompts and config used for generating this audio chunk.
public struct LiveMusicSourceMetadata: Codable, Sendable {
    /// Weighted prompts for generating this audio chunk.
    public var clientContent: LiveMusicClientContent?
    /// Music generation config for generating this audio chunk.
    public var musicGenerationConfig: LiveMusicGenerationConfig?

    public init(
        clientContent: LiveMusicClientContent? = nil,
        musicGenerationConfig: LiveMusicGenerationConfig? = nil
    ) {
        self.clientContent = clientContent
        self.musicGenerationConfig = musicGenerationConfig
    }
}

/// Representation of an audio chunk.
public struct AudioChunk: Codable, Sendable {
    /// Raw bytes of audio data, encoded as base64 string.
    public var data: String?
    /// MIME type of the audio chunk.
    public var mimeType: String?
    /// Prompts and config used for generating this audio chunk.
    public var sourceMetadata: LiveMusicSourceMetadata?

    public init(
        data: String? = nil,
        mimeType: String? = nil,
        sourceMetadata: LiveMusicSourceMetadata? = nil
    ) {
        self.data = data
        self.mimeType = mimeType
        self.sourceMetadata = sourceMetadata
    }
}

/// Server update generated by the model in response to client messages.
public struct LiveMusicServerContent: Codable, Sendable {
    /// The audio chunks that the model has generated.
    public var audioChunks: [AudioChunk]?

    public init(audioChunks: [AudioChunk]? = nil) {
        self.audioChunks = audioChunks
    }
}

/// A prompt that was filtered with the reason.
public struct LiveMusicFilteredPrompt: Codable, Sendable {
    /// The text prompt that was filtered.
    public var text: String?
    /// The reason the prompt was filtered.
    public var filteredReason: String?

    public init(text: String? = nil, filteredReason: String? = nil) {
        self.text = text
        self.filteredReason = filteredReason
    }
}

/// Response message for the LiveMusicClientMessage call.
public final class LiveMusicServerMessage: Codable, @unchecked Sendable {
    /// Message sent in response to a `LiveMusicClientSetup` message from the client.
    public var setupComplete: LiveMusicServerSetupComplete?
    /// Content generated by the model in response to client messages.
    public var serverContent: LiveMusicServerContent?
    /// A prompt that was filtered with the reason.
    public var filteredPrompt: LiveMusicFilteredPrompt?

    public init(
        setupComplete: LiveMusicServerSetupComplete? = nil,
        serverContent: LiveMusicServerContent? = nil,
        filteredPrompt: LiveMusicFilteredPrompt? = nil
    ) {
        self.setupComplete = setupComplete
        self.serverContent = serverContent
        self.filteredPrompt = filteredPrompt
    }

    /// Returns the first audio chunk from the server content, if present.
    public var audioChunk: AudioChunk? {
        if let chunks = serverContent?.audioChunks, !chunks.isEmpty {
            return chunks[0]
        }
        return nil
    }
}

/// Callbacks for the realtime music API.
///
/// - Note: Not `Codable` — function-typed members can't be encoded/decoded.
public struct LiveMusicCallbacks: Sendable {
    /// Called when a message is received from the server.
    public var onMessage: @Sendable (LiveMusicServerMessage) -> Void
    /// Called when an error occurs.
    public var onError: (@Sendable (Error) -> Void)?
    /// Called when the websocket connection is closed.
    public var onClose: (@Sendable (Error?) -> Void)?

    public init(
        onMessage: @escaping @Sendable (LiveMusicServerMessage) -> Void,
        onError: (@Sendable (Error) -> Void)? = nil,
        onClose: (@Sendable (Error?) -> Void)? = nil
    ) {
        self.onMessage = onMessage
        self.onError = onError
        self.onClose = onClose
    }
}
