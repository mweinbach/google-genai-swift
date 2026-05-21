# Getting started

A 60-second tour of the Swift port. Assumes you already have an API key from [Google AI Studio](https://aistudio.google.com/apikey).

## 1. Install

In your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/mweinbach/google-genai-swift.git", from: "1.1.0")
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "GoogleGenAI", package: "google-genai-swift")
        ]
    )
]
```

In Xcode: **File → Add Package Dependencies…** → paste the URL → add `GoogleGenAI` to your target.

## 2. Initialize

```swift
import GoogleGenAI

let ai = try GoogleGenAI(apiKey: "GEMINI_API_KEY")
```

You can also pass `apiKey: nil` and set `GOOGLE_API_KEY` or `GEMINI_API_KEY` in the environment.

For Vertex AI / Gemini Enterprise:

```swift
let ai = try GoogleGenAI(
    enterprise: true,
    project: "your-project",
    location: "us-central1"
)
```

## 3. Your first call

```swift
let response = try await ai.models.generateContent(
    model: "gemini-2.5-flash",
    contents: "Why is the sky blue?"
)
print(response.text ?? "")
```

That's it. Same call shape as the JavaScript SDK:

```javascript
// JS equivalent
const ai = new GoogleGenAI({apiKey: 'GEMINI_API_KEY'});
const response = await ai.models.generateContent({
    model: 'gemini-2.5-flash',
    contents: 'Why is the sky blue?'
});
console.log(response.text);
```

## 4. Error handling

The SDK throws two error types you typically catch separately:

```swift
do {
    let r = try await ai.models.generateContent(model: "...", contents: "...")
} catch let err as ApiError {
    // Server returned a non-2xx status. err.status, err.message
} catch let err as GenAIError {
    // Local validation / unsupported feature / runtime issue.
} catch {
    // Anything else (URLSession, JSON decode, etc.)
}
```

## 5. Next steps

- [Text generation](02-text-generation.md) — streaming, config options, system instructions
- [Chats](03-chats.md) — multi-turn conversations
- [Tools](04-tools.md) — function calling and Google's built-in tools (Search, code exec, …)
- [Structured output](05-structured-output.md) — use Apple's `@Generable` macro with Gemini
- [Live](06-live.md) — realtime bidirectional WebSocket sessions

If you're coming from the JS SDK, [`10-migration-from-js.md`](10-migration-from-js.md) is the fastest way to map your existing code.
