# Live realtime sessions

`ai.live` provides bidirectional WebSocket sessions for audio in / audio out, video frames in, low-latency tool calls, and interruptible turn-taking. Built on `URLSessionWebSocketTask`.

## Connect

```swift
let callbacks = LiveCallbacks(
    onMessage: { msg in
        // LiveServerMessage — inspect msg.serverContent, msg.toolCall, msg.text, …
    },
    onError: { err in print("error:", err) },
    onOpen: { print("connected") },
    onClose: { closeErr in print("closed:", closeErr ?? "ok") }
)

let session = try await ai.live.connect(LiveConnectParameters(
    model: "models/gemini-2.5-flash-native-audio-latest",
    callbacks: callbacks,
    config: LiveConnectConfig(
        responseModalities: [.audio]
    )
))
```

Models that support `bidiGenerateContent` vary by tier — call `ai.models.list()` and filter for `supportedGenerationMethods.contains("bidiGenerateContent")` to discover what your key has access to. As of 2026, the public-API options include:

- `models/gemini-2.5-flash-native-audio-latest` (audio modality)
- `models/gemini-2.5-flash-native-audio-preview-12-2025`
- `models/gemini-3.1-flash-live-preview` (text modality, preview)

## Send

```swift
// Send a text turn
try session.sendClientContent(LiveSendClientContentParameters(
    turns: .part(.text("What's the weather like today?")),
    turnComplete: true
))

// Send raw audio (PCM bytes)
try session.sendRealtimeInput(LiveSendRealtimeInputParameters(
    media: Blob(mimeType: "audio/pcm;rate=16000", data: audioBase64)
))

// Send tool execution results
try session.sendToolResponse(LiveSendToolResponseParameters(
    functionResponses: [FunctionResponse(name: "get_weather", response: [...])]
))
```

## Receive

Messages arrive on the `onMessage` callback. Each `LiveServerMessage` may contain any combination of:

```swift
{ msg in
    if let setup = msg.setupComplete           { /* server ready */ }
    if let content = msg.serverContent {
        if content.turnComplete == true        { /* model finished a turn */ }
        if let modelTurn = content.modelTurn   { /* text / audio parts */ }
        if let interrupted = content.interrupted { /* model was cut off */ }
        if let transcription = content.outputTranscription { /* live STT */ }
    }
    if let toolCall = msg.toolCall             { /* model wants a tool */ }
    if let goAway = msg.goAway                 { /* server requests reconnect */ }
}
```

## Close

```swift
session.close()
```

## Audio practicalities

The native-audio models expect 16 kHz mono PCM. To stream microphone input:

1. Capture via `AVAudioEngine` at 16 kHz mono.
2. Base64-encode each chunk and wrap in `Blob(mimeType: "audio/pcm;rate=16000", data: ...)`.
3. Call `session.sendRealtimeInput(...)` every few hundred ms.
4. Receive audio responses as `Part.inlineData` blobs and play them back through `AVAudioPlayerNode`.

A full audio pipeline is outside the SDK's scope — see Apple's [`AVAudioEngine`](https://developer.apple.com/documentation/avfaudio/avaudioengine) docs.

## Music (`LiveMusicSession`)

`ai.music` (or instantiate `Music` directly) exposes the same WebSocket plumbing for the Lyria music-gen models:

```swift
let music = Music(/* ... */)
let session = try await music.connect(/* parameters */)
try await session.setWeightedPrompts(...)
try await session.setMusicGenerationConfig(...)
try await session.play()
```

## Known quirks

- The Swift `URLSessionWebSocketTask` fires `didOpenWithProtocol` after the HTTP upgrade completes; the SDK gates the first `send()` on that callback. If you see "Socket is not connected" right after `onOpen`, the SDK already protects you, but `URLSession.shared` does NOT — always use the SDK's transport.
- Server-side close codes are surfaced via `onClose(Error?)` — code 1011 ("Internal error") typically indicates a malformed setup message or a model that doesn't support your requested modality.
