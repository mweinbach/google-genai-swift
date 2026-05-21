# Files

`ai.files` uploads documents, images, audio, and video for the model to reference. Uploaded files persist for ~48 hours (Gemini Developer API) and are referenced by URI in subsequent prompts.

## Upload

```swift
// From a local file path
let file = try await ai.files.upload(
    file: .path(URL(fileURLWithPath: "/path/to/doc.pdf")),
    config: UploadFileConfig(
        mimeType: "application/pdf",
        displayName: "Quarterly report"
    )
)
print(file.uri ?? "")
// → "https://generativelanguage.googleapis.com/v1beta/files/abc123"

// From in-memory Data
let file2 = try await ai.files.upload(
    file: .data(myDataBlob),
    config: UploadFileConfig(mimeType: "image/png")
)
```

The Swift uploader implements Gemini's resumable-upload protocol (`X-Goog-Upload-Command: start / upload / finalize`) with 8 MiB chunks and exponential backoff.

## Reference an uploaded file in a prompt

```swift
let r = try await ai.models.generateContent(
    model: "gemini-2.5-flash",
    contents: Content(parts: [
        Part(text: "Summarize this PDF in one paragraph."),
        Part(fileData: FileData(fileUri: file.uri, mimeType: "application/pdf"))
    ])
)
```

## List / get / delete

```swift
// Paginated list
let pager = try await ai.files.list()
for try await file in pager {
    print(file.name ?? "", file.displayName ?? "")
}

// Get one
let f = try await ai.files.get(name: "files/abc123")

// Delete
try await ai.files.delete(name: "files/abc123")
```

## Download generated media

For generated videos / images that come back with `gcs:` or signed URLs:

```swift
let r = try await ai.models.generateVideos(/* … */)
let op = try await ai.operations.getVideosOperation(.init(operation: r))
guard let video = op.response?.generatedVideos?.first?.video,
      let uri = video.uri else { return }

try await ai.files.download(
    file: .string(uri),
    downloadPath: URL(fileURLWithPath: "/tmp/generated.mp4")
)
```

## File search stores (RAG)

For chunked indexed retrieval (RAG), use `ai.fileSearchStores`:

```swift
let store = try await ai.fileSearchStores.create(CreateFileSearchStoreParameters(
    displayName: "Product docs"
))
try await ai.fileSearchStores.uploadToFileSearchStore(UploadToFileSearchStoreParameters(
    fileSearchStoreName: store.name ?? "",
    file: .path(URL(fileURLWithPath: "docs.pdf")),
    config: UploadToFileSearchStoreConfig(
        chunkingConfig: ChunkingConfig(maxTokensPerChunk: 512)
    )
))

// Then query against it via the fileSearch built-in tool:
var tool = Tool()
tool.fileSearch = FileSearch(fileSearchStoreNames: [store.name ?? ""])
let config = GenerateContentConfig(tools: [.tool(tool)])
let r = try await ai.models.generateContent(
    model: "gemini-2.5-flash",
    contents: "What does the product handbook say about returns?",
    config: config
)
```

## Documents

`ai.fileSearchStores.documents` (or `ai.documents` if you constructed one directly) manages individual document records inside a store:

```swift
let docs = try await ai.fileSearchStores.documents.list(/* params */)
let doc = try await ai.fileSearchStores.documents.get(name: docName)
try await ai.fileSearchStores.documents.delete(name: docName)
```
