# GoogleGenAI for Swift

Native Swift port of [`@google/genai`](https://github.com/googleapis/js-genai) — the official JavaScript Google Gen AI SDK. Same call shapes, same models, ~34,000 LOC of pure Swift. No network bridge, no JS runtime.

Two libraries ship in this package:

- **`GoogleGenAI`** — the main SDK. Mirrors the JS `@google/genai` surface 1:1. Works on macOS 15+, iOS 18+, tvOS 18+, watchOS 11+, visionOS 2+.
- **`GoogleGenAIFoundationModels`** — opt-in adapter that mirrors Apple's [`FoundationModels`](https://developer.apple.com/documentation/foundationmodels) framework — `@Generable`, `LanguageModelSession`-style sessions, the `Tool` protocol — but routes inference to Gemini. Available on macOS 26+, iOS 26+, iPadOS 26+, visionOS 26+.

```swift
import GoogleGenAI

let ai = try GoogleGenAI(apiKey: "GEMINI_API_KEY")

let response = try await ai.models.generateContent(
    model: "gemini-2.5-flash",
    contents: "Why is the sky blue?"
)
print(response.text ?? "")
```

[**→ Full guides in `Docs/`**](Docs/) · [**JS→Swift migration**](Docs/10-migration-from-js.md) · [**Architecture**](Docs/11-architecture.md)

---

## Install

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/mweinbach/google-genai-swift.git", from: "1.1.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "GoogleGenAI", package: "google-genai-swift"),
            // Optional — Apple FoundationModels-shaped adapter:
            .product(name: "GoogleGenAIFoundationModels", package: "google-genai-swift"),
        ]
    )
]
```

### Xcode

**File → Add Package Dependencies…** → paste `https://github.com/mweinbach/google-genai-swift` → add either or both library products to your target.

---

## Initialize

### Gemini Developer API (API key)

```swift
let ai = try GoogleGenAI(apiKey: "YOUR_API_KEY")
```

### Vertex AI / Gemini Enterprise Agent Platform

```swift
let ai = try GoogleGenAI(
    enterprise: true,
    project: "your-gcp-project",
    location: "us-central1"
)
```

### Environment variables

`try GoogleGenAI()` with no args reads from the same env vars as the JS SDK:

| Variable | Maps to |
|---|---|
| `GOOGLE_API_KEY` | `apiKey` (preferred over `GEMINI_API_KEY` if both set) |
| `GEMINI_API_KEY` | `apiKey` |
| `GOOGLE_GENAI_USE_ENTERPRISE` | `enterprise` (boolean) |
| `GOOGLE_GENAI_USE_VERTEXAI` | `vertexai` (boolean) |
| `GOOGLE_CLOUD_PROJECT` | `project` |
| `GOOGLE_CLOUD_LOCATION` | `location` |
| `GOOGLE_APPLICATION_CREDENTIALS` | Path to service-account JSON keyfile (used when `enterprise: true` and no API key) |

---

## What you can do

### Text generation

```swift
// Plain
let r = try await ai.models.generateContent(
    model: "gemini-2.5-flash",
    contents: "Explain quantum entanglement in one sentence."
)
print(r.text ?? "")

// Streaming
let stream = try await ai.models.generateContentStream(
    model: "gemini-2.5-flash",
    contents: "Write a short poem about Swift."
)
for try await chunk in stream {
    if let text = chunk.text { print(text, terminator: "") }
}
```

[→ `Docs/02-text-generation.md`](Docs/02-text-generation.md)

### Multi-turn chat

```swift
let chat = ai.chats.create(model: "gemini-2.5-flash")
_ = try await chat.sendMessage("My favorite color is teal. Remember that.")
let r = try await chat.sendMessage("What did I tell you my favorite color was?")
print(r.text ?? "")  // → "You told me your favorite color is teal."
```

[→ `Docs/03-chats.md`](Docs/03-chats.md)

### Custom tools (function calling)

```swift
let getWeather = FunctionDeclaration(
    description: "Look up the current weather for a city.",
    name: "get_current_weather",
    parametersJsonSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "location": .object([
                "type": .string("string"),
                "description": .string("The city, e.g. San Francisco")
            ])
        ]),
        "required": .array([.string("location")])
    ])
)
let tools: ToolListUnion = [.tool(Tool(functionDeclarations: [getWeather]))]
let config = GenerateContentConfig(tools: tools)

let r = try await ai.models.generateContent(
    model: "gemini-2.5-flash",
    contents: "What's the weather in Paris?",
    config: config
)
// Inspect r.candidates?.first?.content?.parts for `functionCall`
```

[→ `Docs/04-tools.md`](Docs/04-tools.md)

### Built-in tools

Add any of these straight to `Tool`: `googleSearch`, `googleSearchRetrieval`, `codeExecution`, `urlContext`, `enterpriseWebSearch`, `vertexAiSearch`, `fileSearch`, `webSearch`, `imageSearch`, `googleMaps`, `computerUse`.

```swift
var tool = Tool()
tool.googleSearch = GoogleSearch()        // grounded with web search
tool.codeExecution = ToolCodeExecution()  // model can run Python
let config = GenerateContentConfig(tools: [.tool(tool)])
```

### Structured output via Apple `@Generable`

The `GoogleGenAIFoundationModels` library lets you use Apple's `@Generable` macro to get strongly-typed Swift values back from Gemini:

```swift
import FoundationModels
import GoogleGenAIFoundationModels

@Generable struct ColorSwatch {
    @Guide(description: "A short, evocative name") var name: String
    @Guide(description: "Hex code, like #1A2B3C")  var hex: String
}

let session = try GeminiLanguageModelSession(apiKey: "...")
let r = try await session.respond(
    to: "Invent a color for an autumn forest at dusk.",
    generating: ColorSwatch.self
)
print(r.content.name, r.content.hex)  // typed!
```

[→ `Docs/05-structured-output.md`](Docs/05-structured-output.md)

### Live realtime (audio / video / text bidirectional)

```swift
let session = try await ai.live.connect(LiveConnectParameters(
    model: "models/gemini-2.5-flash-native-audio-latest",
    callbacks: LiveCallbacks(
        onMessage: { msg in print("recv:", msg) },
        onOpen: { print("connected") }
    ),
    config: LiveConnectConfig(responseModalities: [.audio])
))
try session.sendClientContent(LiveSendClientContentParameters(
    turns: .part(.text("Say hello.")),
    turnComplete: true
))
```

[→ `Docs/06-live.md`](Docs/06-live.md)

### Files, images, videos

```swift
// Upload a file for use in prompts
let file = try await ai.files.upload(...)

// Generate an image
let imageResp = try await ai.models.generateImages(
    model: "imagen-3.0-generate-002",
    prompt: "A serene mountain lake at dawn"
)

// Generate a video (long-running operation)
let op = try await ai.models.generateVideos(GenerateVideosParameters(
    model: "veo-2.0-generate-001",
    prompt: "A cat surfing on a wave"
))
let done = try await ai.operations.getVideosOperation(.init(operation: op))
```

[→ `Docs/07-files.md`](Docs/07-files.md) · [→ `Docs/08-images-videos.md`](Docs/08-images-videos.md)

### Vertex AI / Gemini Enterprise

[→ `Docs/09-vertex.md`](Docs/09-vertex.md)

---

## Module surface

`GoogleGenAI` exposes the same 10 resource modules as the JS SDK — accessible via `ai.<module>`:

| Property | Type | What it does |
|---|---|---|
| `ai.models` | `Models` | Text, images, videos, embeddings, token counting |
| `ai.chats` | `Chats` | Multi-turn conversations with auto history |
| `ai.live` | `Live` | Realtime bidirectional WebSocket sessions |
| `ai.batches` | `Batches` | Batch inference jobs |
| `ai.caches` | `Caches` | Cached content for context reuse |
| `ai.files` | `Files` | Upload/manage files referenced from prompts |
| `ai.fileSearchStores` | `FileSearchStores` | RAG-style file-search corpus management |
| `ai.operations` | `Operations` | Poll long-running operations (videos, tuning) |
| `ai.authTokens` | `Tokens` | Ephemeral auth tokens for Live API |
| `ai.tunings` | `Tunings` | Fine-tuning job lifecycle |

---

## Docs index

| Guide | What's in it |
|---|---|
| [`01-getting-started.md`](Docs/01-getting-started.md) | Install, init, first call |
| [`02-text-generation.md`](Docs/02-text-generation.md) | `generateContent`, streaming, config options |
| [`03-chats.md`](Docs/03-chats.md) | Multi-turn chat sessions and history |
| [`04-tools.md`](Docs/04-tools.md) | Custom function calls, built-in tools, MCP |
| [`05-structured-output.md`](Docs/05-structured-output.md) | `@Generable` adapter, response schemas |
| [`06-live.md`](Docs/06-live.md) | Realtime WebSocket — audio in/out, video, tool calls |
| [`07-files.md`](Docs/07-files.md) | File upload, lifecycle, referencing in prompts |
| [`08-images-videos.md`](Docs/08-images-videos.md) | `generateImages`, `generateVideos`, edit/upscale |
| [`09-vertex.md`](Docs/09-vertex.md) | Vertex AI / Enterprise mode, auth |
| [`10-migration-from-js.md`](Docs/10-migration-from-js.md) | JS → Swift translation table |
| [`11-architecture.md`](Docs/11-architecture.md) | Package layout, conventions, contributing |

---

## Run the live smoke test

```bash
GEMINI_API_KEY=... swift run SmokeTest
```

Exercises eight major surfaces end-to-end against the live API (generateContent, streaming, chats, custom tools, Google Search grounding, code execution, Live realtime, and the FoundationModels adapter).

---

## Compatibility

- **Swift**: 6.0+ (uses strict concurrency)
- **`GoogleGenAI` library**: macOS 15+, iOS 18+, tvOS 18+, watchOS 11+, visionOS 2+
- **`GoogleGenAIFoundationModels` library**: macOS 26+, iOS 26+, iPadOS 26+, visionOS 26+ (anywhere Apple's `FoundationModels` is available)

## License

Apache-2.0, matching the upstream [`googleapis/js-genai`](https://github.com/googleapis/js-genai).

## Status

- ✅ All 9 porting waves complete (`Wave 1`…`Wave 9`); see commit history
- ✅ Verified end-to-end against the live Gemini API (`swift run SmokeTest`)
