# Images and videos

## Image generation (Imagen)

```swift
let r = try await ai.models.generateImages(
    model: "imagen-3.0-generate-002",
    prompt: "A serene mountain lake at dawn, photorealistic",
    config: GenerateImagesConfig(
        numberOfImages: 4,
        aspectRatio: "16:9",
        safetyFilterLevel: .blockLowAndAbove,
        personGeneration: .allowAdult
    )
)

for generated in r.generatedImages ?? [] {
    if let bytes = generated.image?.imageBytes {
        // bytes is base64-encoded; decode and write to disk
        let data = Data(base64Encoded: bytes)
        try? data?.write(to: URL(fileURLWithPath: "/tmp/out.png"))
    }
}
```

### Edit / upscale / segment / recontext

```swift
// Inpainting / outpainting via reference images
let edit = try await ai.models.editImage(EditImageParameters(
    model: "imagen-3.0-edit-001",
    prompt: "Replace the sky with a vivid sunset",
    referenceImages: [
        RawReferenceImage(referenceImage: Image(imageBytes: srcBytes), referenceId: 0),
        MaskReferenceImage(referenceImage: Image(imageBytes: maskBytes), referenceId: 1, config: MaskReferenceConfig(maskMode: .userProvided))
    ],
    config: EditImageConfig(numberOfImages: 1)
))

// 2x / 4x upscale
let up = try await ai.models.upscaleImage(UpscaleImageParameters(
    model: "imagen-3.0-generate-002",
    image: Image(imageBytes: srcBytes),
    upscaleFactor: "x2"
))

// Style/control/subject-conditioned generation
let rc = try await ai.models.recontextImage(/* RecontextImageParameters */)

// Segmentation
let seg = try await ai.models.segmentImage(/* SegmentImageParameters */)
```

## Video generation (Veo)

Video generation is a long-running operation: kick it off, poll until done.

```swift
let op = try await ai.models.generateVideos(GenerateVideosParameters(
    model: "veo-2.0-generate-001",
    prompt: "A cat surfing on a giant wave, cinematic lighting",
    config: GenerateVideosConfig(
        numberOfVideos: 1,
        durationSeconds: 5,
        aspectRatio: "16:9"
    )
))

// Poll the operation
var current = op
while current.done != true {
    try await Task.sleep(for: .seconds(5))
    current = try await ai.operations.getVideosOperation(.init(operation: current))
}

// Fetch the result
if let video = current.response?.generatedVideos?.first?.video,
   let uri = video.uri {
    try await ai.files.download(
        file: .string(uri),
        downloadPath: URL(fileURLWithPath: "/tmp/cat.mp4")
    )
}
```

### Image-to-video

Provide an initial image in `GenerateVideosSource`:

```swift
let op = try await ai.models.generateVideos(GenerateVideosParameters(
    model: "veo-2.0-generate-001",
    prompt: "make the cat ride toward the camera",
    source: GenerateVideosSource(image: Image(imageBytes: catImageBytes))
))
```

### Reference-conditioned video

Use `referenceImages` with `VideoGenerationReferenceImage` for fine-grained subject/style control. See [`Sources/GoogleGenAI/Types/Videos.swift`](../Sources/GoogleGenAI/Types/Videos.swift) for the full type surface.

## Multimodal input to text models

Generate-content can take any of the file types directly:

```swift
let r = try await ai.models.generateContent(
    model: "gemini-2.5-flash",
    contents: Content(parts: [
        Part(text: "What's in this image?"),
        Part(inlineData: Blob(mimeType: "image/png", data: pngBase64))
    ])
)
```

For larger files (>20 MB or audio/video), upload via `ai.files.upload` first and reference by URI:

```swift
Part(fileData: FileData(fileUri: file.uri, mimeType: "video/mp4"))
```
