# js-genai → swift-genai porting conventions

Source of truth: `../js-genai/src/` (114 `.ts` files, ~45k LOC).

## Filename mapping

| TypeScript                          | Swift                                        |
|-------------------------------------|----------------------------------------------|
| `errors.ts`                         | `Errors.swift`                               |
| `_api_client.ts`                    | `APIClient.swift` (drop leading `_`)         |
| `_base_url.ts`                      | `BaseURL.swift`                              |
| `converters/_models_converters.ts`  | `Converters/ModelsConverters.swift`          |
| `interactions/internal/utils/base64.ts` | `Interactions/Internal/Utils/Base64.swift` |

Leading `_` in TS marks internal — replaced by Swift `internal` access modifier.
Snake/lowercase filenames become `PascalCase.swift`.

## Directory mapping

| TypeScript path        | Swift path                                              |
|------------------------|---------------------------------------------------------|
| `src/`                 | `Sources/GoogleGenAI/`                                  |
| `src/converters/`      | `Sources/GoogleGenAI/Converters/`                       |
| `src/interactions/`    | `Sources/GoogleGenAI/Interactions/`                     |
| `src/cross/`           | `Sources/GoogleGenAI/Cross/`                            |
| `src/mcp/`             | `Sources/GoogleGenAI/MCP/`                              |
| `src/tokenizer/`       | `Sources/GoogleGenAI/Tokenizer/`                        |
| `src/vertex_internal/` | `Sources/GoogleGenAI/VertexInternal/`                   |
| `src/node/`            | **collapsed** — Foundation implementation lives in the matching abstract file |
| `src/web/`             | **collapsed** — same as above                           |

js-genai splits platform code (`node/_node_websocket.ts`, `web/_browser_websocket.ts`) to satisfy both runtimes; Apple platforms share Foundation, so we keep one implementation in `WebSocket.swift` itself.

## Type & idiom mapping

| TypeScript                                | Swift                                              |
|-------------------------------------------|----------------------------------------------------|
| `interface Foo { ... }`                   | `public struct Foo: Codable, Sendable`             |
| `enum Foo { BAR = 'BAR' }`                | `public enum Foo: String, Codable, Sendable { case bar = "BAR" }` |
| `Promise<T>`                              | `async throws -> T`                                |
| `AsyncIterator<T>`                        | `AsyncThrowingStream<T, Error>` / `AsyncSequence`  |
| `class Foo extends Error`                 | `public struct Foo: Error` (or enum cases)         |
| `Record<string, unknown>`                 | `[String: JSONValue]` (custom Codable JSON type)   |
| `unknown` / `any`                         | `JSONValue` (define once in `Common.swift`)        |
| `fetch(...)`                              | `URLSession.shared.data(for:)`                     |
| `WebSocket` (node `ws` / browser)         | `URLSessionWebSocketTask`                          |
| `Buffer` / `Uint8Array`                   | `Data`                                             |
| ESM `import {x} from './foo.js'`          | nothing — single Swift module, just reference `x`  |

## API surface

All public types/functions are `public` and `Sendable` where possible. The library targets Swift 6 strict concurrency.

## Open questions deferred to ports

- `sentencepiece_model.pb.d.ts` is a protobuf typings file — Swift equivalent will use `swift-protobuf` if/when needed by the tokenizer port. Defer.
- `mcp/_mcp.ts` depends on the `@modelcontextprotocol/sdk` JS package — Swift has no first-party MCP SDK yet; port the surface and stub the transport.

## Previously known gaps (now closed)

- **Vertex AI service-account ADC auth** — implemented via `ServiceAccountCredential.swift` using `Security.framework`'s `SecKeyCreateSignature` for RS256 JWT signing + OAuth2 token exchange + automatic caching/refresh. No external JWT library needed.
- **SSE decoder byte- not codepoint-streaming** — replaced the all-or-nothing `String(data:encoding:.utf8)` approach in `APIClient.processStreamResponse` with `StreamingUTF8Decoder` (mirrors `TextDecoder({stream: true})`), which returns complete characters immediately and buffers only incomplete trailing multi-byte sequences.
