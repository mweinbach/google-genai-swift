# Tools

Gemini supports two kinds of tools: **custom tools** you declare in code (a.k.a. function calling), and **built-in tools** the server hosts (Google Search, code execution, etc.). Both are passed via `config.tools: ToolListUnion`.

## Custom tools (function calling)

### 1. Declare the function

```swift
let getWeather = FunctionDeclaration(
    description: "Look up the current weather for a city.",
    name: "get_current_weather",
    parametersJsonSchema: .object([
        "type": .string("object"),
        "properties": .object([
            "location": .object([
                "type": .string("string"),
                "description": .string("The city, e.g. San Francisco")
            ]),
            "unit": .object([
                "type": .string("string"),
                "enum": .array([.string("celsius"), .string("fahrenheit")])
            ])
        ]),
        "required": .array([.string("location")])
    ])
)
```

### 2. Pass it in `config.tools`

```swift
let tool = Tool(functionDeclarations: [getWeather])
let config = GenerateContentConfig(tools: [.tool(tool)])

let response = try await ai.models.generateContent(
    model: "gemini-2.5-flash",
    contents: "What's the weather in Paris?",
    config: config
)
```

### 3. Inspect and respond to function calls

```swift
for part in response.candidates?.first?.content?.parts ?? [] {
    if let call = part.functionCall {
        print("model wants:", call.name ?? "", "args:", call.args ?? [:])

        // Execute the function locally
        let result = lookupWeather(call.args)  // your code

        // Send the result back to the model in the next turn
        var responsePart = Part()
        responsePart.functionResponse = FunctionResponse(
            name: call.name,
            response: ["temperature": .double(22.5), "conditions": .string("clear")]
        )
        // (chat.sendMessage with this part, or generateContent multi-turn)
    }
}
```

### Higher-level: Apple `Tool` protocol

If you're on macOS 26+ / iOS 26+, the [`GoogleGenAIFoundationModels`](05-structured-output.md) library lets you implement Apple's `Tool` protocol — with strongly-typed `@Generable` arguments — and the adapter handles the call/response loop:

```swift
struct GetWeather: Tool {
    let name = "get_current_weather"
    let description = "Look up the current weather for a city."

    @Generable struct Arguments {
        @Guide(description: "The city, e.g. San Francisco") var location: String
    }
    func call(arguments: Arguments) async throws -> String {
        return "22°C, clear"
    }
}

let session = try GeminiLanguageModelSession(
    apiKey: "...",
    tools: [GetWeather()]
)
```

## Built-in tools

Add any of these fields to a `Tool` — Gemini hosts the execution server-side.

| Field on `Tool` | What it does |
|---|---|
| `googleSearch` | Grounds responses with current web search results |
| `googleSearchRetrieval` | Older grounding API (Gemini 1.5 / 2.0) |
| `codeExecution` | Lets the model run Python and return the result |
| `urlContext` | Lets the model fetch URLs and reference their content |
| `enterpriseWebSearch` | Vertex Enterprise grounded search |
| `vertexAiSearch` | RAG against your Vertex Search corpus |
| `fileSearch` | RAG against a file-search store you populated |
| `webSearch` / `imageSearch` | Additional grounded-search variants |
| `googleMaps` | Maps + places lookup |
| `computerUse` | Desktop/web automation (preview) |

### Google Search grounding

```swift
var tool = Tool()
tool.googleSearch = GoogleSearch()
let config = GenerateContentConfig(tools: [.tool(tool)])

let r = try await ai.models.generateContent(
    model: "gemini-2.5-flash",
    contents: "What major news event happened today? Cite a source.",
    config: config
)

// Sources are attached to the response:
let chunks = r.candidates?.first?.groundingMetadata?.groundingChunks ?? []
for chunk in chunks {
    print(chunk.web?.uri ?? "", chunk.web?.title ?? "")
}
```

### Code execution

```swift
var tool = Tool()
tool.codeExecution = ToolCodeExecution()
let config = GenerateContentConfig(tools: [.tool(tool)])

let r = try await ai.models.generateContent(
    model: "gemini-2.5-flash",
    contents: "Compute the 20th Fibonacci number using Python.",
    config: config
)

for part in r.candidates?.first?.content?.parts ?? [] {
    if let code = part.executableCode {
        print("Python code:\n\(code.code ?? "")")
    }
    if let result = part.codeExecutionResult {
        print("Outcome: \(result.outcome ?? .outcomeUnspecified)")
        print("Output:\n\(result.output ?? "")")
    }
}
```

### Combining tools

```swift
var tool = Tool(functionDeclarations: [getWeather])
tool.googleSearch = GoogleSearch()
let config = GenerateContentConfig(tools: [.tool(tool)])
```

## MCP (Model Context Protocol)

The Swift port includes the same MCP integration surface as the JS SDK, but **bring-your-own-client**: there's no first-party Swift MCP SDK, so consumers implement `McpClient`:

```swift
public protocol McpClient: Sendable {
    func listTools(cursor: String?) async throws -> McpListToolsResult
    func callTool(name: String, arguments: [String: JSONValue]?, requestOptions: McpRequestOptions?) async throws -> McpCallToolResult
}
```

Then:

```swift
let callable = try await mcpToTool([yourMcpClient])
let config = GenerateContentConfig(tools: [.callable(callable)])
```

The adapter resolves callable tools to plain `Tool` values before encoding (so the model only sees the tool surface, not the implementation).
