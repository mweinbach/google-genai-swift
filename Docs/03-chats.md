# Chats

`ai.chats` creates `Chat` sessions that automatically maintain conversation history. Each `sendMessage` call appends to the history; the next call sends the entire context.

## Create a session

```swift
let chat = ai.chats.create(model: "gemini-2.5-flash")
```

You can pre-seed instructions and history:

```swift
let chat = ai.chats.create(
    model: "gemini-2.5-flash",
    config: GenerateContentConfig(
        systemInstruction: .part(.text("You speak in rhyming couplets."))
    ),
    history: [
        Content(role: "user", parts: [Part(text: "I love poetry.")]),
        Content(role: "model", parts: [Part(text: "Then verse upon verse, in lines that immerse, we'll trace.")])
    ]
)
```

## Send messages

```swift
let r1 = try await chat.sendMessage("My favorite color is teal.")
let r2 = try await chat.sendMessage("What did I just tell you?")
print(r2.text ?? "")  // → "You told me your favorite color is teal."
```

## Streaming

```swift
let stream = try await chat.sendMessageStream("Tell me a longer story.")
for try await chunk in stream {
    if let t = chunk.text { print(t, terminator: "") }
}
```

## Inspect history

```swift
let history = chat.getHistory(curated: false)  // every turn, including blocked/incomplete
let curated = chat.getHistory(curated: true)   // only successful turns
```

## Verbose form

The shorthand `chat.sendMessage("text")` delegates to the full struct form:

```swift
let r = try await chat.sendMessage(SendMessageParameters(
    message: .single(.text("Hi there")),
    config: GenerateContentConfig(temperature: 0.7)
))
```

You can attach a per-message config (overrides the chat-level config for that turn) or pass `.single` / `.many` part lists to send images alongside text:

```swift
let multimodal = SendMessageParameters(
    message: .many([
        .text("What is this?"),
        .part(Part(inlineData: .init(mimeType: "image/png", data: imageBase64)))
    ]),
    config: nil
)
let r = try await chat.sendMessage(multimodal)
```

## Concurrency safety

`Chat` serializes outbound messages internally — calling `sendMessage` twice in quick succession from different tasks will queue, not race. Use a fresh `Chat` per logical conversation.
