// 04-function-call.swift — custom tool (function calling).

import Foundation
import GoogleGenAI

@main
struct FunctionCallExample {
    static func main() async throws {
        let ai = try GoogleGenAI(apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")

        let getWeather = FunctionDeclaration(
            description: "Look up the current weather for a city.",
            name: "get_current_weather",
            parametersJsonSchema: .object([
                "type": .string("object"),
                "properties": .object([
                    "location": .object([
                        "type": .string("string"),
                        "description": .string("The city, e.g. San Francisco")
                    ])
                ]),
                "required": .array([.string("location")])
            ])
        )

        let config = GenerateContentConfig(
            tools: [.tool(Tool(functionDeclarations: [getWeather]))]
        )
        let r = try await ai.models.generateContent(
            model: "gemini-2.5-flash",
            contents: "What's the weather in Paris right now?",
            config: config
        )

        // Inspect the call:
        for part in r.candidates?.first?.content?.parts ?? [] {
            if let call = part.functionCall {
                print("Model wants: \(call.name ?? "?")")
                print("Args: \(call.args ?? [:])")

                // ... actually look up the weather here (your code) ...
                // Then send the result back in a follow-up message:
                //
                // var responsePart = Part()
                // responsePart.functionResponse = FunctionResponse(
                //     name: call.name,
                //     response: ["temperature": .double(22.5), "conditions": .string("clear")]
                // )
                // _ = try await ai.models.generateContent(GenerateContentParameters(...))
            }
        }
    }
}
