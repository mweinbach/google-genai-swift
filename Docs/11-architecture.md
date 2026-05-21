# Architecture

A tour of how the Swift port is organized, the conventions it follows, and where to look when you want to extend or debug something.

## Package layout

```
swift-genai/
├── Package.swift                  # SwiftPM manifest — 2 library products, 1 exec, 1 test target
├── README.md
├── PORTING.md                     # TS → Swift conventions (file/type/idiom maps)
├── Docs/                          # This directory — topic guides
├── Sources/
│   ├── GoogleGenAI/               # Main SDK library (109 .swift files)
│   │   ├── Client.swift           # GoogleGenAI class — public entry point
│   │   ├── APIClient.swift        # HTTP transport, retry, auth header injection
│   │   ├── Auth.swift             # Auth protocol + DefaultAuth (API key / GoogleAuth stub)
│   │   ├── BaseURL.swift          # Base URL resolution + actor-isolated defaults
│   │   ├── Transformers.swift     # tContent / tTool / tBlobs / etc. (TS _transformers.ts)
│   │   ├── *Module.swift          # Resource modules: Models, Batches, Caches, Files, Live
│   │   ├── Chats.swift, Tunings.swift, Tokens.swift, ... # other resources
│   │   ├── Uploader.swift, Downloader.swift, WebSocket.swift # Foundation-backed transports
│   │   ├── Pagers.swift           # Pager<T>: AsyncSequence for paginated list responses
│   │   ├── AFC.swift              # Automatic function calling helpers
│   │   ├── Common.swift           # JSONValue, GenAIError, JSON-path helpers, jsonObject helpers
│   │   ├── Errors.swift           # ApiError (server-returned)
│   │   ├── Index.swift            # Public-surface anchor (typealiases)
│   │   ├── InternalTypes.swift    # ReferenceImageAPIInternal & friends
│   │   ├── Types/                 # 17 files — all schema enums, structs, classes from types.ts
│   │   ├── Converters/            # 11 files — wire-format converters per resource
│   │   ├── Interactions/          # 42 files — vendored streaming/HTTP/agents subsystem
│   │   ├── Cross/SentencePiece/   # Inline protobuf decoder + BPE/unigram tokenizer
│   │   ├── Cross/Tokenizer/       # Tokenizer protocol, loader, accumulator
│   │   ├── MCP/                   # Model Context Protocol surface (bring-your-own client)
│   │   └── VertexInternal/        # Internal Vertex re-exports (documented; no-op in Swift)
│   ├── GoogleGenAIFoundationModels/  # Apple FoundationModels-shaped adapter
│   │   ├── GeminiLanguageModelSession.swift
│   │   └── Bridging.swift         # GenerationSchema ↔ JSON, GeneratedContent ↔ JSONValue, etc.
│   └── SmokeTest/main.swift       # Live-API end-to-end test (exec target)
└── Tests/GoogleGenAITests/        # Shape-pinning + placeholder tests
```

## Conventions

### File naming

- TS `errors.ts` → Swift `Errors.swift`
- TS `_api_client.ts` → Swift `APIClient.swift` (the leading `_` drops; the rest is PascalCased)
- TS subdirs preserved as Swift subdirs (`Converters/`, `Interactions/`, etc.)
- Filename collisions with `Types/*.swift` were resolved by suffixing the resource-module file with `Module` (e.g., `BatchesModule.swift` for `Batches`-the-resource-class vs `Types/Batches.swift` for batch schema types). The class names inside stayed bare.

### Type idiom map

See [`PORTING.md`](../PORTING.md) for the full table. Summary:

- `interface Foo` → `public struct Foo: Codable, Sendable`
- `class Foo` w/ methods → `public final class Foo: Codable, @unchecked Sendable`
- `enum Foo { BAR = 'BAR' }` → `public enum Foo: String, Codable, Sendable { case bar = "BAR" }`
- TS union → Swift indirect enum w/ custom Codable
- `Record<string, unknown>` / `unknown` → `JSONValue`

### Converters (`Converters/*.swift`)

Pure dict-to-dict functions translating SDK-shape JSON to the MLDev or Vertex wire format. Each has a canonical signature:

```swift
public func fooToMldev(
    apiClient: ApiClient,
    fromObject: [String: JSONValue],
    parentObject: inout [String: JSONValue]
) throws -> [String: JSONValue]
```

Resource modules use the `jsonObject(_:)` / `jsonDecode(_:from:)` helpers in `Common.swift` to bridge strongly-typed Swift values ↔ these dict converters.

### Resource modules

Every public resource class:

- Subclasses `BaseModule` (a marker `open class` in `Common.swift`)
- Is `@unchecked Sendable` (mutable lock-protected state where needed; mostly stateless)
- Exposes the same method names as the JS SDK's resource class
- Plus convenience overloads — e.g. `Models.generateContent(model:contents:config:)` over the verbose `Models.generateContent(GenerateContentParameters)` form

### Transport

- HTTP: `URLSession.data(for:)` for unary, `URLSession.bytes(for:)` for streaming (SSE)
- WebSocket: `URLSessionWebSocketTask` via `URLSessionWebSocketDelegate` (handshake-gated send)
- Upload: hand-rolled resumable-upload protocol (`X-Goog-Upload-Command` flow)
- Retry: hand-rolled `withRetry` helper, exponential backoff + jitter, matches the JS `p-retry` retryable-status-codes set

### Concurrency

- Swift 6 strict concurrency (`swiftLanguageModes: [.v6]`)
- Module-level mutable state is behind actors (`BaseURL.swift`, `MCP.swift`)
- Resource modules use NSLock + sync helper-method patterns when they need shared mutable state from async contexts (e.g., `Pagers.swift`, `Chats.swift`'s send serializer, `McpCallableTool` in `MCP/MCP.swift`)

## How a call flows

`ai.models.generateContent(model:, contents:)` →

1. Convenience overload builds a `GenerateContentParameters` struct.
2. `Models.generateContent(_:)` (in `ModelsModule.swift`) is invoked.
3. Strong-typed `GenerateContentParameters` is encoded to `[String: JSONValue]` via `jsonObject(_:)`.
4. The appropriate converter — `generateContentParametersToMldev` or `...ToVertex` — is called (lives in `Converters/ModelsConvertersPart1.swift` / `Part2.swift`).
5. The converter strips out `_url` / `_query` meta-keys and returns the wire-format body.
6. `ApiClient.request(...)` builds an `URLRequest`, attaches auth headers via the `Auth` protocol, sends, and retries on retryable HTTP codes.
7. The response body comes back as JSON; `Models` runs it through the response converter (`generateContentResponseFromMldev/Vertex`) and decodes the resulting dict to a strong-typed `GenerateContentResponse`.

## Extending the SDK

### Add a new convenience overload

Open the matching `*Module.swift` (e.g. `ModelsModule.swift`), find the `extension Models { ... }` block at the bottom, and add your overload. Delegate to the existing param-struct method.

### Bump the Gemini API version

Pass `apiVersion:` to `GoogleGenAI(...)`, or set `httpOptions.apiVersion`. The default is `v1beta`.

### Add a new built-in tool field

Edit `Types/Tools.swift` — add the new field to the `Tool` struct. The converters in `Converters/ModelsConvertersPart1.swift` / `Part2.swift` already pass unknown fields through `setValueByPath`; you only need a new field if you want strong-typed access.

### Plug in a custom transport (testing)

`URLSessionUploader` and `URLSessionDownloader` are the default impls of the `Uploader` / `Downloader` protocols. Conform your own and pass via the (currently-private) `ApiClientInitOptions` constructor. The public `GoogleGenAI(apiKey:)` init always uses the URLSession-backed ones.

## Smoke testing changes

Run `GEMINI_API_KEY=... swift run SmokeTest` to verify the 8 surfaces (text, streaming, chat, custom tools, Google Search, code execution, Live, FoundationModels adapter) still work end-to-end against the live API.

The non-network shape tests in `Tests/GoogleGenAITests/PublicAPIShapeTests.swift` pin the public API against the JS SDK — if you accidentally change a method signature, those fail at compile time.
