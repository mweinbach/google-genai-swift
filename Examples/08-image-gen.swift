// 08-image-gen.swift — generate an image with Imagen and write it to disk.

import Foundation
import GoogleGenAI

@main
struct ImageGenExample {
    static func main() async throws {
        let ai = try GoogleGenAI(apiKey: ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "")

        let r = try await ai.models.generateImages(
            model: "imagen-3.0-generate-002",
            prompt: "A serene mountain lake at dawn, photorealistic, 35mm",
            config: GenerateImagesConfig(
                numberOfImages: 1,
                aspectRatio: "16:9"
            )
        )

        guard let generated = r.generatedImages?.first,
              let b64 = generated.image?.imageBytes,
              let data = Data(base64Encoded: b64) else {
            print("No image bytes returned.")
            return
        }
        let outURL = URL(fileURLWithPath: "/tmp/imagen-output.png")
        try data.write(to: outURL)
        print("Wrote \(data.count) bytes to \(outURL.path)")
    }
}
