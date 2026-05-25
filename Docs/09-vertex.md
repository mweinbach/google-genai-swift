# Vertex AI / Gemini Enterprise

The SDK supports the Vertex AI API (a.k.a. Gemini Enterprise Agent Platform) using the same surface as the Gemini Developer API — flip a flag at init time.

## Initialize

```swift
let ai = try GoogleGenAI(
    enterprise: true,
    project: "your-gcp-project",
    location: "us-central1"
)
```

`enterprise: true` is preferred; `vertexai: true` is the legacy alias and works identically.

You can also set `GOOGLE_GENAI_USE_ENTERPRISE=true`, `GOOGLE_CLOUD_PROJECT`, `GOOGLE_CLOUD_LOCATION` in the environment and call `try GoogleGenAI()` with no args.

## What changes vs. Developer API

The call shapes are identical, but several behaviors differ on the server side:

- **Model identifiers** prefix with `publishers/google/models/` automatically (the SDK adds this for you when needed).
- **Base URL** becomes `https://{location}-aiplatform.googleapis.com`.
- **Some types are Vertex-only** — for example `BatchJobSource.bigqueryUri`, `vertex-dataset` source format, `multimodalDataset` destinations.
- **Some types are Gemini-only** — ephemeral `auth_tokens/...` API keys are not honored.
- **Default `responseModalities`** for Live is `[.audio]` on Vertex; `[.text]` is opt-in.

The SDK detects `ai.vertexai == true` and routes through the correct converter (`...ToVertex` vs `...ToMldev`) for every method internally — your code doesn't change.

## Authentication

### API key (recommended for development)

```swift
let ai = try GoogleGenAI(
    enterprise: true,
    apiKey: "ya29.example-vertex-api-key",
    project: "your-project",
    location: "us-central1"
)
```

### Service account / ADC (Application Default Credentials)

The Swift SDK supports service-account authentication using `Security.framework` for RS256 JWT signing — no external dependencies required. This mirrors the JavaScript SDK's delegation to `google-auth-library`.

```swift
let ai = try GoogleGenAI(
    enterprise: true,
    project: "your-project",
    location: "us-central1",
    googleAuthOptions: GoogleAuthOptions(
        keyFile: "/path/to/service-account.json"
    )
)
```

Or provide the keyfile inline:

```swift
let keyData = try Data(contentsOf: URL(fileURLWithPath: "service-account.json"))
let ai = try GoogleGenAI(
    enterprise: true,
    project: "your-project",
    location: "us-central1",
    googleAuthOptions: GoogleAuthOptions(
        credentialsJSON: keyData
    )
)
```

Or set the `GOOGLE_APPLICATION_CREDENTIALS` environment variable to point to a service-account JSON keyfile:

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
export GOOGLE_GENAI_USE_ENTERPRISE=true
export GOOGLE_CLOUD_PROJECT=your-project
export GOOGLE_CLOUD_LOCATION=us-central1
```

```swift
let ai = try GoogleGenAI()
```

The SDK automatically:
1. Parses the service-account JSON keyfile (`client_email`, `private_key`, `token_uri`)
2. Constructs and signs a JWT using RS256 (RSA-SHA256) via `Security.framework`
3. Exchanges the JWT for an OAuth2 access token at the keyfile's `token_uri`
4. Caches the access token and refreshes it before the 1-hour expiry
5. Sets `Authorization: Bearer <token>` on every outgoing request

## Vertex-only features

### Tuning jobs

```swift
let op = try await ai.tunings.tune(CreateTuningJobParameters(
    baseModel: "gemini-2.5-flash",
    trainingDataset: TuningDataset(
        gcsUri: "gs://my-bucket/training.jsonl"
    ),
    config: CreateTuningJobConfig(
        tunedModelDisplayName: "support-bot-v1",
        epochCount: 3,
        learningRateMultiplier: 1.0
    )
))

// Poll
let job = try await ai.tunings.get(name: op.name)
```

### Batch inference

```swift
let job = try await ai.batches.create(CreateBatchJobParameters(
    model: "gemini-2.5-flash",
    src: .source(BatchJobSource(
        format: "bigquery",
        bigqueryUri: "bq://my-project.my-dataset.my-input-table"
    )),
    config: CreateBatchJobConfig(
        dest: .destination(BatchJobDestination(
            format: "bigquery",
            bigqueryUri: "bq://my-project.my-dataset.my-output-table"
        ))
    )
))

while job.state != .jobStateSucceeded && job.state != .jobStateFailed {
    try await Task.sleep(for: .seconds(30))
    let updated = try await ai.batches.get(GetBatchJobParameters(name: job.name ?? ""))
    if updated.state == .jobStateSucceeded { break }
}
```

### Enterprise web search grounding

```swift
var tool = Tool()
tool.enterpriseWebSearch = EnterpriseWebSearch()
let config = GenerateContentConfig(tools: [.tool(tool)])
```

### Vertex AI Search RAG

```swift
var tool = Tool()
tool.retrieval = Retrieval(vertexAiSearch: VertexAISearch(
    datastore: "projects/.../dataStores/your-datastore-id"
))
```
