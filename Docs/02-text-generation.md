# Text generation

All single-shot text generation goes through `ai.models.generateContent(...)` and its streaming sibling `ai.models.generateContentStream(...)`.

## Plain request

```swift
let response = try await ai.models.generateContent(
    model: "gemini-2.5-flash",
    contents: "Summarize this in one sentence: ..."
)
print(response.text ?? "")
```

The Swift SDK gives you three convenience overloads matching the three TS `contents` shapes:

```swift
// 1. String (most common)
try await ai.models.generateContent(model: "...", contents: "Hello")

// 2. Single Content
try await ai.models.generateContent(
    model: "...",
    contents: Content(role: "user", parts: [Part(text: "Hello")])
)

// 3. Array of Content (multi-turn one-shot)
try await ai.models.generateContent(
    model: "...",
    contents: [
        Content(role: "user", parts: [Part(text: "I like dogs.")]),
        Content(role: "model", parts: [Part(text: "Got it.")]),
        Content(role: "user", parts: [Part(text: "What did I tell you I liked?")])
    ]
)
```

If you want the full verbose form (closer to the wire), use the `GenerateContentParameters` struct directly:

```swift
let r = try await ai.models.generateContent(GenerateContentParameters(
    model: "gemini-2.5-flash",
    contents: .part(.text("Hello")),
    config: nil
))
```

## Configuration

`GenerateContentConfig` controls model behavior. Everything is optional.

```swift
let config = GenerateContentConfig(
    systemInstruction: .part(.text("You are a terse, direct assistant.")),
    temperature: 0.2,
    topP: 0.95,
    topK: 40,
    candidateCount: 1,
    maxOutputTokens: 512,
    stopSequences: ["END"],
    responseMimeType: "text/plain",
    responseModalities: ["TEXT"],
    safetySettings: [
        SafetySetting(
            category: .harmCategoryHateSpeech,
            threshold: .blockMediumAndAbove
        )
    ],
    thinkingConfig: ThinkingConfig(thinkingLevel: .medium)
)

let r = try await ai.models.generateContent(
    model: "gemini-2.5-flash",
    contents: "Explain Kubernetes.",
    config: config
)
```

## Streaming

```swift
let stream = try await ai.models.generateContentStream(
    model: "gemini-2.5-flash",
    contents: "Write a haiku about Swift."
)

for try await chunk in stream {
    if let text = chunk.text {
        print(text, terminator: "")
    }
}
print()  // trailing newline
```

Each `chunk` is a full `GenerateContentResponse` with cumulative-friendly fields. Treat it as an SSE event: append `.text`, inspect `.candidates`, etc.

## Inspecting the response

```swift
let r = try await ai.models.generateContent(...)

// Convenience accessors:
r.text                 // concatenated text across all parts of candidate[0]
r.responseId           // server-assigned request id

// Or walk the parts directly:
for candidate in r.candidates ?? [] {
    for part in candidate.content?.parts ?? [] {
        if let t = part.text             { /* text */ }
        if let fc = part.functionCall    { /* function-call request */ }
        if let blob = part.inlineData    { /* inline file data */ }
        if let ec = part.executableCode  { /* code-execution tool */ }
        if let ecr = part.codeExecutionResult { /* its result */ }
    }
    if let finish = candidate.finishReason { /* stop / safety / etc. */ }
}

// Token usage:
r.usageMetadata?.promptTokenCount
r.usageMetadata?.candidatesTokenCount
r.usageMetadata?.totalTokenCount
```

## Embeddings

```swift
// Single text:
let r1 = try await ai.models.embedContent(
    model: "text-embedding-004",
    contents: "Some text to embed"
)
// r1.embeddings?.first?.values is [Double]

// Batch:
let r2 = try await ai.models.embedContent(
    model: "text-embedding-004",
    contents: ["doc 1", "doc 2", "doc 3"]
)
```

## Token counting

```swift
let r = try await ai.models.countTokens(
    model: "gemini-2.5-flash",
    contents: "How many tokens is this?"
)
print(r.totalTokens ?? 0)
```

`computeTokens` returns per-token info; see [`Sources/GoogleGenAI/ModelsModule.swift`](../Sources/GoogleGenAI/ModelsModule.swift) for the full surface.
