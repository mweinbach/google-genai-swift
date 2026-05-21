// 06-code-execution.swift — let the model write and run Python.

import Foundation
import GoogleGenAI

@main
struct CodeExecutionExample {
    static func main() async throws {
        let ai = try GoogleGenAI(apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")

        var tool = Tool()
        tool.codeExecution = ToolCodeExecution()
        let config = GenerateContentConfig(tools: [.tool(tool)])

        let r = try await ai.models.generateContent(
            model: "gemini-2.5-flash",
            contents: "Use Python to compute the 30th Fibonacci number. Print only the answer.",
            config: config
        )

        for part in r.candidates?.first?.content?.parts ?? [] {
            if let code = part.executableCode {
                print("--- Python the model wrote ---")
                print(code.code ?? "")
            }
            if let result = part.codeExecutionResult {
                print("--- result ---")
                print("outcome:", result.outcome ?? .outcomeUnspecified)
                print(result.output ?? "")
            }
        }
        print("--- answer ---")
        print(r.text ?? "")
    }
}
