# GoogleGenAI for Swift

Native Swift port of [`@google/genai`](https://github.com/googleapis/js-genai), the official Google Gen AI SDK. Same call shape, ~34k LOC, Swift 6 strict concurrency.

## Requirements

- Swift 6.0+
- macOS 15+, iOS 18+, tvOS 18+, watchOS 11+, visionOS 2+

## Install

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/<you>/swift-genai.git", branch: "main")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "GoogleGenAI", package: "swift-genai")
        ]
    )
]
```

Or, in Xcode: **File → Add Package Dependencies…** and paste the repo URL.

## Quick start

```swift
import GoogleGenAI

let ai = try GoogleGenAI(apiKey: "GEMINI_API_KEY")

let response = try await ai.models.generateContent(
    model: "gemini-2.5-flash",
    contents: "Why is the sky blue?"
)
print(response.text ?? "")
```

The Swift call shape mirrors `@google/genai`'s JavaScript API 1:1 — `new GoogleGenAI({apiKey})` → `try GoogleGenAI(apiKey:)`, `ai.models.generateContent({model, contents})` → `try await ai.models.generateContent(model:contents:)`, and so on.

### Vertex AI / Gemini Enterprise

```swift
let ai = try GoogleGenAI(
    enterprise: true,
    project: "your-project",
    location: "us-central1"
)
```

### Environment variables

Calling `GoogleGenAI()` with no args reads from the same env vars as the JS SDK:

- `GOOGLE_API_KEY` / `GEMINI_API_KEY`
- `GOOGLE_GENAI_USE_ENTERPRISE` / `GOOGLE_GENAI_USE_VERTEXAI`
- `GOOGLE_CLOUD_PROJECT`, `GOOGLE_CLOUD_LOCATION`

## Module surface

The `GoogleGenAI` entry-point exposes the same 10 resource modules as the JS SDK:

```swift
ai.models           // Models — generateContent, embedContent, generateImages, generateVideos, …
ai.live             // Live — connect() → realtime websocket Session
ai.chats            // Chats — create(model:) → multi-turn Chat session
ai.batches          // Batches
ai.caches           // Caches
ai.files            // Files
ai.fileSearchStores // FileSearchStores
ai.operations       // Operations
ai.authTokens       // Tokens (ephemeral auth tokens for Live)
ai.tunings          // Tunings
```

## Foundation Models–shaped API (`GoogleGenAIFoundationModels`)

A second library product, `GoogleGenAIFoundationModels`, provides a wrapper that mirrors Apple's [`FoundationModels`](https://developer.apple.com/documentation/foundationmodels) framework — `LanguageModelSession`-style sessions, `@Generable` structured output, the `Tool` protocol — but routes the inference to Gemini.

Available on macOS 26+, iOS 26+, iPadOS 26+, and visionOS 26+ (anywhere Apple's `FoundationModels` is available).

```swift
import FoundationModels
import GoogleGenAIFoundationModels

@Generable struct ColorSwatch {
    @Guide(description: "A short, evocative name for the color")
    var name: String
    @Guide(description: "The color's hex code, like #1A2B3C")
    var hex: String
}

let session = try GeminiLanguageModelSession(
    apiKey: "GEMINI_API_KEY",
    instructions: "You generate small color palettes."
)
let response = try await session.respond(
    to: "Invent one new color swatch inspired by an autumn forest at dusk.",
    generating: ColorSwatch.self
)
print(response.content.name, response.content.hex)
```

The adapter:

- Converts Apple's `GenerationSchema` to JSON Schema and feeds it to Gemini via `responseJsonSchema` + `responseMimeType: "application/json"`.
- Round-trips Gemini's JSON response through Apple's `GeneratedContent` so any `@Generable` type decodes natively (including `Codable`-incompatible Apple-only types).
- Bridges `GenerationOptions` → `GenerateContentConfig` (temperature, top-k/p, max output tokens, seed).
- Accepts `FoundationModels.Tool` conforming types and exposes them to Gemini as function declarations.

Add to your target the same way as the main library:

```swift
.product(name: "GoogleGenAIFoundationModels", package: "google-genai-swift")
```

## Features

- **Custom tools (function calling)** — declare `FunctionDeclaration`s, pass via `Tool(functionDeclarations: [...])` in `config.tools`
- **Built-in tools** — `GoogleSearch`, `ToolCodeExecution`, `UrlContext`, `GoogleSearchRetrieval`, `EnterpriseWebSearch`, `VertexAISearch`, `FileSearch`, `WebSearch`, `GoogleMaps`, `ComputerUse`
- **Streaming** — `generateContentStream` returns an `AsyncThrowingStream<GenerateContentResponse, Error>`
- **Multi-turn chat** — `ai.chats.create(model:)` returns a `Chat` with `sendMessage(_:)` / `sendMessageStream(_:)`
- **Live realtime** — `ai.live.connect(...)` returns a `Session` for bidirectional audio/text streaming over `URLSessionWebSocketTask`
- **Live music** — `Music` / `MusicSession`
- **MCP tools** — `mcpToTool(_:config:)` for the Model Context Protocol (bring-your-own `McpClient`)
- **Tokenizer** — vendored cross-platform SentencePiece tokenizer (`Cross/Tokenizer`, `Cross/SentencePiece`)

## Run the smoke test

The repo ships with a `SmokeTest` executable that exercises all seven major surfaces against the live Gemini API:

```bash
GEMINI_API_KEY=... swift run SmokeTest
```

## Layout

- `Sources/GoogleGenAI/` — main library (109 files)
  - `Types/` — request/response schema (ported from js-genai's `types.ts`)
  - `Converters/` — wire-format converters
  - `Interactions/` — vendored streaming/HTTP/agents subsystem
  - `Cross/SentencePiece/` + `Cross/Tokenizer/` — tokenizers
  - `MCP/`, `VertexInternal/` — opt-in surfaces
- `Sources/SmokeTest/` — executable e2e test
- `Tests/GoogleGenAITests/` — shape pinning + smoke

See [`PORTING.md`](PORTING.md) for js-genai → Swift mapping conventions and limitations.

## License

Apache-2.0, matching the upstream `googleapis/js-genai`.
