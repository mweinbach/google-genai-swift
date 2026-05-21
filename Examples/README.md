# Examples

Copy-paste-ready snippets that demonstrate one feature at a time. Each file is self-contained — drop it into a Swift script (`swift Examples/01-hello.swift`) after replacing the placeholder API key, or into a SwiftPM `.executableTarget`.

| File | What it shows |
|---|---|
| [`01-hello.swift`](01-hello.swift) | The minimum viable call — init + `generateContent` |
| [`02-streaming.swift`](02-streaming.swift) | Token streaming with `AsyncThrowingStream` |
| [`03-chat.swift`](03-chat.swift) | Multi-turn conversation with history |
| [`04-function-call.swift`](04-function-call.swift) | Custom tool / function calling |
| [`05-google-search.swift`](05-google-search.swift) | Grounded responses with web search |
| [`06-code-execution.swift`](06-code-execution.swift) | Built-in Python sandbox |
| [`07-structured-output.swift`](07-structured-output.swift) | `@Generable` via the FoundationModels adapter |
| [`08-image-gen.swift`](08-image-gen.swift) | Generate an image with Imagen |

For a single file that exercises everything at once against the live API, see `Sources/SmokeTest/main.swift` at the repo root.
