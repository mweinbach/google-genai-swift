# Structured output

Two ways to make Gemini return JSON-shaped data:

1. **Apple `@Generable`** (recommended on macOS 26+ / iOS 26+) — write a type with `@Generable`, get a typed Swift value back.
2. **Manual schema** — set `responseMimeType: "application/json"` and `responseSchema` (or `responseJsonSchema`) yourself, then decode.

## Apple `@Generable` (via `GoogleGenAIFoundationModels`)

Add the library to your target dependencies:

```swift
.product(name: "GoogleGenAIFoundationModels", package: "google-genai-swift")
```

Then write code as if you were using Apple's on-device model:

```swift
import FoundationModels
import GoogleGenAIFoundationModels

@Generable struct ColorSwatch {
    @Guide(description: "A short, evocative name")
    var name: String
    @Guide(description: "Hex code, like #1A2B3C")
    var hex: String
    @Guide(description: "A 1-sentence description of the mood")
    var mood: String
}

let session = try GeminiLanguageModelSession(
    apiKey: "GEMINI_API_KEY",
    instructions: "You generate small color palettes."
)
let response = try await session.respond(
    to: "Invent a color inspired by an autumn forest at dusk.",
    generating: ColorSwatch.self
)
let swatch = response.content  // ColorSwatch (typed!)
print(swatch.name, swatch.hex)
```

### How it works

The adapter:

1. Reads `T.generationSchema` (a `FoundationModels.GenerationSchema`, which is `Encodable`).
2. Encodes that schema to JSON Schema and passes it to Gemini via `responseJsonSchema`.
3. Sets `responseMimeType: "application/json"`.
4. Decodes Gemini's JSON response back into Apple's `GeneratedContent` value tree.
5. Calls `T(generatedContent)` (via `ConvertibleFromGeneratedContent`) to produce the typed Swift value.

So `@Generable`-annotated types you can already use with Apple's on-device `LanguageModelSession` work unchanged against Gemini.

### Streaming structured output

```swift
let stream = session.streamResponse(
    to: "List five Swift HTTP libraries with one-sentence descriptions.",
    generating: [Library].self
)
for try await partial in stream {
    // Each yield is a best-effort decode of the JSON received so far —
    // you'll see the array grow in real time as Gemini emits chunks.
    print(partial.count, "libraries so far")
}
```

### `GenerationOptions`

```swift
let options = GenerationOptions(
    sampling: .random(top: 40, seed: 42),
    temperature: 0.3,
    maximumResponseTokens: 1024
)
let r = try await session.respond(to: "...", options: options)
```

Maps to Gemini's `GenerateContentConfig.temperature` / `topK` / `topP` / `maxOutputTokens` / `seed`.

### Tools

`GeminiLanguageModelSession` accepts Apple's `Tool` protocol:

```swift
struct FindContacts: Tool {
    let name = "findContacts"
    let description = "Finds contacts by name"

    @Generable struct Arguments {
        @Guide(description: "The name to search for") var query: String
    }
    func call(arguments: Arguments) async throws -> [String] {
        // ... lookup contacts ...
        return ["Alice", "Bob"]
    }
}

let session = try GeminiLanguageModelSession(
    apiKey: "...",
    tools: [FindContacts()]
)
```

The adapter converts each tool's `Arguments.generationSchema` into a Gemini `FunctionDeclaration`. When the model invokes the tool, the adapter parses the args, calls your `call(arguments:)`, and feeds the result back as a `FunctionResponse`.

### Swap to Apple's on-device model later

The session type is the only line you need to change. The rest of your `@Generable` types and call sites work as-is:

```swift
// Today (Gemini):
let session = try GeminiLanguageModelSession(apiKey: "...")
// Future (Apple on-device, also requires macOS 26+):
let session = LanguageModelSession(instructions: "...")
```

## Manual schema (no Apple framework needed)

If you can't or don't want to depend on `FoundationModels`, you can use Gemini's native response-schema feature directly.

### Option A: typed Swift schema

```swift
let schema = Schema(
    type: .object,
    properties: [
        "name": Schema(type: .string),
        "hex": Schema(type: .string, description: "Hex code like #1A2B3C")
    ],
    required: ["name", "hex"]
)

let config = GenerateContentConfig(
    responseMimeType: "application/json",
    responseSchema: .schema(schema)
)
let r = try await ai.models.generateContent(
    model: "gemini-2.5-flash",
    contents: "Invent a color.",
    config: config
)
// r.text is a JSON string — decode with JSONDecoder into your Codable type.
```

### Option B: raw JSON Schema dict

```swift
let jsonSchema: JSONValue = .object([
    "type": .string("object"),
    "properties": .object([
        "name": .object(["type": .string("string")]),
        "hex": .object(["type": .string("string")])
    ]),
    "required": .array([.string("name"), .string("hex")])
])

let config = GenerateContentConfig(
    responseMimeType: "application/json",
    responseJsonSchema: jsonSchema
)
```

Use `responseJsonSchema` when your schema includes features not modeled by `Schema` (custom `$ref`, advanced `oneOf`, etc.).
