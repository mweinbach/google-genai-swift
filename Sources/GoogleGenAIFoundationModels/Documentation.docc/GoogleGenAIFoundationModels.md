# ``GoogleGenAIFoundationModels``

Use Apple's `FoundationModels` API shape — `@Generable`, `LanguageModelSession`-style sessions, the `Tool` protocol — to talk to Google Gemini.

## Overview

`GoogleGenAIFoundationModels` is a thin adapter on top of ``GoogleGenAI``. It exposes a ``GeminiLanguageModelSession`` class whose surface mirrors Apple's `LanguageModelSession` — same initializers, same `respond(to:)` / `respond(to:generating:)` / `streamResponse(...)` methods, same `GenerationOptions`, same `Tool` integration.

This lets you write code targeting Apple's `@Generable` macro today but run it against Gemini's frontier models — and swap to Apple's on-device model later by changing one type.

```swift
import FoundationModels
import GoogleGenAIFoundationModels

@Generable struct ColorSwatch {
    @Guide(description: "A short, evocative name")
    var name: String
    @Guide(description: "Hex code, like #1A2B3C")
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

1. Reads Apple's `T.generationSchema` and converts it to JSON Schema.
2. Passes the schema to Gemini via `responseJsonSchema` + `responseMimeType: "application/json"`.
3. Decodes the JSON response into Apple's `GeneratedContent` value tree.
4. Initializes your `@Generable` type via `ConvertibleFromGeneratedContent.init(_:)`.

## Topics

### Essentials

- ``GeminiLanguageModelSession``
- ``Response``

### Errors

- ``GeminiFoundationModelsError``

### Type aliases

- ``FMTool``
