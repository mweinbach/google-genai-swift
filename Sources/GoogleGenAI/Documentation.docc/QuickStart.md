# Quick start

Five-minute tour from install to first generated response.

## 1. Install

In `Package.swift`:

```swift
.package(url: "https://github.com/mweinbach/google-genai-swift.git", from: "1.1.0")
```

Then add `.product(name: "GoogleGenAI", package: "google-genai-swift")` to your target's dependencies.

## 2. Get an API key

Visit [Google AI Studio](https://aistudio.google.com/apikey) and create one.

## 3. Initialize

```swift
import GoogleGenAI

let ai = try GoogleGenAI(apiKey: "YOUR_KEY")
```

Or read from `GOOGLE_API_KEY` / `GEMINI_API_KEY` in the environment:

```swift
let ai = try GoogleGenAI()  // env-driven
```

## 4. Generate

```swift
let response = try await ai.models.generateContent(
    model: "gemini-2.5-flash",
    contents: "Why is the sky blue?"
)
print(response.text ?? "")
```

## 5. Stream

```swift
let stream = try await ai.models.generateContentStream(
    model: "gemini-2.5-flash",
    contents: "Tell me a story."
)
for try await chunk in stream {
    if let text = chunk.text { print(text, terminator: "") }
}
```

## 6. Chat

```swift
let chat = ai.chats.create(model: "gemini-2.5-flash")
_ = try await chat.sendMessage("My favorite color is teal.")
let r = try await chat.sendMessage("What did I tell you?")
print(r.text ?? "")
```

## 7. Tools

Custom function:

```swift
let getWeather = FunctionDeclaration(
    description: "Look up weather.",
    name: "get_weather",
    parametersJsonSchema: .object([
        "type": .string("object"),
        "properties": .object(["location": .object(["type": .string("string")])]),
        "required": .array([.string("location")])
    ])
)
let config = GenerateContentConfig(
    tools: [.tool(Tool(functionDeclarations: [getWeather]))]
)
```

Built-in tool (Google Search grounding):

```swift
var tool = Tool()
tool.googleSearch = GoogleSearch()
let config = GenerateContentConfig(tools: [.tool(tool)])
```

## 8. Structured output

If you're on macOS 26+/iOS 26+, add `GoogleGenAIFoundationModels` and use Apple's `@Generable` macro:

```swift
import FoundationModels
import GoogleGenAIFoundationModels

@Generable struct Color {
    @Guide(description: "A short name") var name: String
    @Guide(description: "Hex code") var hex: String
}

let session = try GeminiLanguageModelSession(apiKey: "...")
let r = try await session.respond(to: "Invent a color.", generating: Color.self)
print(r.content.name, r.content.hex)
```

## Where to next

- Deep dives are in the [`Docs/`](https://github.com/mweinbach/google-genai-swift/tree/main/Docs) folder of the repo.
- Migrating from `@google/genai` (JavaScript)? See the migration guide.
- Curious how it all fits together? Read the architecture overview.
