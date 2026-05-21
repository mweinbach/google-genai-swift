# Migrating from `@google/genai` (JavaScript)

If you have an existing app using the JavaScript SDK, the Swift port is a near-mechanical translation. Same module surface, same method names, same parameter shapes.

## Init

```javascript
// JS
import { GoogleGenAI } from '@google/genai';
const ai = new GoogleGenAI({apiKey: 'X'});
```

```swift
// Swift
import GoogleGenAI
let ai = try GoogleGenAI(apiKey: "X")
```

## Methods

`{model, contents}` object-literal arg → labeled params:

```javascript
const r = await ai.models.generateContent({
    model: 'gemini-2.5-flash',
    contents: 'Hello'
});
console.log(r.text);
```

```swift
let r = try await ai.models.generateContent(
    model: "gemini-2.5-flash",
    contents: "Hello"
)
print(r.text ?? "")
```

If you'd rather use the verbose param-struct form (closer to the wire):

```swift
let r = try await ai.models.generateContent(GenerateContentParameters(
    model: "gemini-2.5-flash",
    contents: .part(.text("Hello"))
))
```

## Type translations

| TypeScript | Swift |
|---|---|
| `Promise<T>` | `async throws -> T` |
| `AsyncIterable<T>` / `AsyncGenerator<T>` | `AsyncThrowingStream<T, Error>` |
| `string` | `String` |
| `number` | `Double` (default) or `Int` when context is clearly integer |
| `boolean` | `Bool` |
| `Uint8Array` / `Buffer` | `Data` |
| `Record<string, unknown>` | `[String: JSONValue]` |
| `unknown` / `any` | `JSONValue` |
| `interface Foo { x?: string }` | `public struct Foo: Codable, Sendable { var x: String? }` |
| `enum Foo { BAR = 'BAR' }` | `public enum Foo: String, Codable, Sendable { case bar = "BAR" }` |
| Union: `type T = A \| B` | `public enum T { case a(A); case b(B) }` (custom Codable) |
| Class with methods | `public final class Foo: @unchecked Sendable` |

## Module surface (1:1)

| JS | Swift |
|---|---|
| `ai.models` | `ai.models` (`Models`) |
| `ai.chats` | `ai.chats` (`Chats`) |
| `ai.batches` | `ai.batches` (`Batches`) |
| `ai.caches` | `ai.caches` (`Caches`) |
| `ai.files` | `ai.files` (`Files`) |
| `ai.fileSearchStores` | `ai.fileSearchStores` (`FileSearchStores`) |
| `ai.operations` | `ai.operations` (`Operations`) |
| `ai.authTokens` | `ai.authTokens` (`Tokens`) |
| `ai.tunings` | `ai.tunings` (`Tunings`) |
| `ai.live` | `ai.live` (`Live`) |

## Method-by-method examples

### Streaming

```javascript
const stream = await ai.models.generateContentStream({...});
for await (const chunk of stream) console.log(chunk.text);
```

```swift
let stream = try await ai.models.generateContentStream(...)
for try await chunk in stream { print(chunk.text ?? "") }
```

### Chats

```javascript
const chat = ai.chats.create({model: 'gemini-2.5-flash'});
await chat.sendMessage({message: 'hi'});
```

```swift
let chat = ai.chats.create(model: "gemini-2.5-flash")
_ = try await chat.sendMessage("hi")
```

### Function calling

```javascript
const config = {
    tools: [{functionDeclarations: [{name: 'foo', description: '...', parameters: {...}}]}]
};
```

```swift
let config = GenerateContentConfig(
    tools: [.tool(Tool(functionDeclarations: [
        FunctionDeclaration(description: "...", name: "foo", parametersJsonSchema: ...)
    ]))]
)
```

### Built-in tools

```javascript
const config = {tools: [{googleSearch: {}}]};
```

```swift
var t = Tool()
t.googleSearch = GoogleSearch()
let config = GenerateContentConfig(tools: [.tool(t)])
```

### Live

```javascript
const session = await ai.live.connect({
    model: '...',
    callbacks: { onmessage: m => {}, ... },
    config: { responseModalities: ['AUDIO'] }
});
```

```swift
let session = try await ai.live.connect(LiveConnectParameters(
    model: "...",
    callbacks: LiveCallbacks(onMessage: { m in }),
    config: LiveConnectConfig(responseModalities: [.audio])
))
```

## Idiom translations

| JS pattern | Swift equivalent |
|---|---|
| `JSON.stringify(x)` | `JSONEncoder().encode(x)` then `String(data:encoding:)` |
| `JSON.parse(s)` | `JSONDecoder().decode(T.self, from: s.data(using: .utf8)!)` |
| `throw new Error('msg')` | `throw GenAIError.runtime("msg")` or `.invalidArgument(...)` |
| `console.warn(...)` | `print(...)` or `FileHandle.standardError.write(...)` |
| `AbortController` / `AbortSignal` | `Task.cancel()` / `Task.checkCancellation()` |
| `setTimeout(f, ms)` | `Task { try await Task.sleep(for: .milliseconds(ms)); f() }` |
| `fetch(url)` | `URLSession.shared.data(for: URLRequest(url: url))` |
| `Headers` (DOM/node) | `[String: String]` |

## Things that work differently

| Feature | JS | Swift |
|---|---|---|
| Auth | API key, ADC (service account), browser key | API key only (Developer API). Vertex ADC is on the roadmap — bring your own access token via `apiKey:` for now |
| Node platform module | `import {GoogleGenAI} from '@google/genai'` (auto-detects node) | Single Foundation-based runtime; no node/web split |
| MCP | Uses `@modelcontextprotocol/sdk` | No first-party Swift MCP SDK; bring your own `McpClient` |
| `tools: [callable]` w/ async resolution | Auto-resolves to `Tool` during request encoding | Same — `ToolUnion.callable` is resolved via `await callable.tool()` before serializing |
| Streaming buffering | `TextDecoder({stream: true})` (Unicode-safe per codepoint) | Byte-buffered (partial codepoints may defer); affects only edge cases at chunk boundaries |
| Browser API key | Identical surface | Not applicable; iOS/macOS use the same surface as the server-side variant |

## What's in the same place

- All type names match: `GenerateContentParameters`, `GenerateContentResponse`, `Content`, `Part`, `FunctionDeclaration`, `FunctionCall`, `FunctionResponse`, `Tool`, `Schema`, `HttpOptions`, `GenerateImagesParameters`, `BatchJob`, `TuningJob`, etc.
- All enum cases: TS `OUTCOME_OK` → Swift `.outcomeOk`. `OUTCOME_FAILED` → `.outcomeFailed`. (PascalCase prefix preserved; underscores become camelCase.)
- All built-in tools: `GoogleSearch`, `GoogleSearchRetrieval`, `ToolCodeExecution`, `UrlContext`, `EnterpriseWebSearch`, `VertexAISearch`, `FileSearch`, `WebSearch`, `ImageSearch`, `GoogleMaps`, `ComputerUse`.
