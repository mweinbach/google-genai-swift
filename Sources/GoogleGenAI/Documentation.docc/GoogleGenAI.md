# ``GoogleGenAI``

Native Swift SDK for the Google Gen AI API (Gemini Developer API + Vertex AI / Gemini Enterprise Agent Platform).

## Overview

`GoogleGenAI` is a 1:1 Swift port of `@google/genai`, Google's official JavaScript SDK. Same call shapes, same models, same module structure — written natively against Foundation, with full Swift 6 strict-concurrency support.

```swift
import GoogleGenAI

let ai = try GoogleGenAI(apiKey: "GEMINI_API_KEY")

let response = try await ai.models.generateContent(
    model: "gemini-2.5-flash",
    contents: "Why is the sky blue?"
)
print(response.text ?? "")
```

For structured output using Apple's `@Generable` macro, also import the companion library ``GoogleGenAIFoundationModels``.

## Topics

### Essentials

- ``GoogleGenAI/GoogleGenAI``
- ``GoogleGenAIOptions``
- ``GoogleGenAIError``
- ``ApiError``
- ``GenAIError``

### Resource modules

- ``Models``
- ``Chats``
- ``Live``
- ``Batches``
- ``Caches``
- ``Files``
- ``FileSearchStores``
- ``Documents``
- ``Operations``
- ``Tokens``
- ``Tunings``
- ``Music``

### Content & conversation

- ``Content``
- ``Part``
- ``ContentUnion``
- ``ContentListUnion``
- ``PartUnion``
- ``PartListUnion``
- ``createUserContent(_:)``
- ``createModelContent(_:)``
- ``createPartFromText(_:)``
- ``createPartFromUri(fileUri:mimeType:)``
- ``createPartFromBase64(data:mimeType:)``

### Generation

- ``GenerateContentParameters``
- ``GenerateContentConfig``
- ``GenerateContentResponse``
- ``Candidate``
- ``FinishReason``
- ``UsageMetadata``
- ``HttpOptions``
- ``SafetySetting``
- ``ThinkingConfig``

### Tools

- ``Tool``
- ``ToolUnion``
- ``ToolListUnion``
- ``FunctionDeclaration``
- ``FunctionCall``
- ``FunctionResponse``
- ``CallableTool``
- ``GoogleSearch``
- ``ToolCodeExecution``
- ``UrlContext``
- ``GoogleSearchRetrieval``
- ``EnterpriseWebSearch``
- ``VertexAISearch``
- ``FileSearch``

### Streaming & realtime

- ``LiveConnectParameters``
- ``LiveConnectConfig``
- ``LiveCallbacks``
- ``LiveServerMessage``
- ``LiveSendClientContentParameters``
- ``LiveSendRealtimeInputParameters``
- ``LiveSendToolResponseParameters``
- ``WebSocketClient``
- ``URLSessionWebSocket``

### Files & media

- ``UploadFileConfig``
- ``UploadFileParameters``
- ``DownloadFileConfig``
- ``GenerateImagesParameters``
- ``GenerateImagesResponse``
- ``GenerateVideosParameters``
- ``GenerateVideosResponse``
- ``EditImageParameters``
- ``UpscaleImageParameters``
- ``Image``
- ``Video``
- ``Blob``

### Embeddings, tokens, batches

- ``EmbedContentParameters``
- ``EmbedContentResponse``
- ``CountTokensParameters``
- ``CountTokensResponse``
- ``ComputeTokensParameters``
- ``CreateBatchJobParameters``
- ``BatchJob``

### Schemas (structured output)

- ``Schema``
- ``SchemaUnion``
- ``Type``

### Authentication

- ``Auth``
- ``DefaultAuth``
- ``DefaultAuthOptions``
- ``GoogleAuthOptions``

### Internals

- ``ApiClient``
- ``Pager``
- ``PagedItem``
- ``BaseModule``
- ``JSONValue``
