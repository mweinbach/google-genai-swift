// 05-google-search.swift — grounded response via the Google Search built-in tool.

import Foundation
import GoogleGenAI

@main
struct GoogleSearchExample {
    static func main() async throws {
        let ai = try GoogleGenAI(apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")

        var tool = Tool()
        tool.googleSearch = GoogleSearch()
        let config = GenerateContentConfig(tools: [.tool(tool)])

        let r = try await ai.models.generateContent(
            model: "gemini-2.5-flash",
            contents: "What major news event happened in the last 24 hours? Cite a source.",
            config: config
        )

        print(r.text ?? "")

        print("\n--- sources ---")
        for chunk in r.candidates?.first?.groundingMetadata?.groundingChunks ?? [] {
            if let web = chunk.web {
                print("•", web.title ?? "(untitled)", "—", web.uri ?? "")
            }
        }
    }
}
