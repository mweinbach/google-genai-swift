// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Config for `inlined_responses` parameter.
public final class InlinedResponse: Codable, @unchecked Sendable {
    /// The response to the request.
    public var response: GenerateContentResponse?
    /// The metadata to be associated with the request.
    public var metadata: [String: String]?
    /// The error encountered while processing the request.
    public var error: JobError?

    public init(
        response: GenerateContentResponse? = nil,
        metadata: [String: String]? = nil,
        error: JobError? = nil
    ) {
        self.response = response
        self.metadata = metadata
        self.error = error
    }
}

public final class SingleEmbedContentResponse: Codable, @unchecked Sendable {
    /// The response to the request.
    public var embedding: ContentEmbedding?
    /// The error encountered while processing the request.
    public var tokenCount: String?

    public init(embedding: ContentEmbedding? = nil, tokenCount: String? = nil) {
        self.embedding = embedding
        self.tokenCount = tokenCount
    }
}

/// Config for `inlined_embedding_responses` parameter.
public final class InlinedEmbedContentResponse: Codable, @unchecked Sendable {
    /// Output only. The response to the request.
    public var response: SingleEmbedContentResponse?
    /// Output only. The error encountered while processing the request.
    public var error: JobError?
    /// Output only. The metadata associated with the request.
    public var metadata: [String: JSONValue]?

    public init(
        response: SingleEmbedContentResponse? = nil,
        error: JobError? = nil,
        metadata: [String: JSONValue]? = nil
    ) {
        self.response = response
        self.error = error
        self.metadata = metadata
    }
}

/// Config for `des` parameter.
public struct BatchJobDestination: Codable, Sendable {
    /// Storage format of the output files. Must be one of:
    /// 'jsonl', 'bigquery', 'vertex-dataset'.
    public var format: String?
    /// The Google Cloud Storage URI to the output file.
    public var gcsUri: String?
    /// The BigQuery URI to the output table.
    public var bigqueryUri: String?
    /// The Gemini Developer API's file resource name of the output data
    /// (e.g. "files/12345"). The file will be a JSONL file with a single
    /// response per line. The responses will be GenerateContentResponse
    /// messages formatted as JSON. The responses will be written in the same
    /// order as the input requests.
    public var fileName: String?
    /// The responses to the requests in the batch. Returned when the batch
    /// was built using inlined requests. The responses will be in the same
    /// order as the input requests.
    public var inlinedResponses: [InlinedResponse]?
    /// The responses to the requests in the batch. Returned when the batch
    /// was built using inlined requests. The responses will be in the same
    /// order as the input requests.
    public var inlinedEmbedContentResponses: [InlinedEmbedContentResponse]?
    /// This field is experimental and may change in future versions. The
    /// Vertex AI dataset destination.
    public var vertexDataset: VertexMultimodalDatasetDestination?

    public init(
        format: String? = nil,
        gcsUri: String? = nil,
        bigqueryUri: String? = nil,
        fileName: String? = nil,
        inlinedResponses: [InlinedResponse]? = nil,
        inlinedEmbedContentResponses: [InlinedEmbedContentResponse]? = nil,
        vertexDataset: VertexMultimodalDatasetDestination? = nil
    ) {
        self.format = format
        self.gcsUri = gcsUri
        self.bigqueryUri = bigqueryUri
        self.fileName = fileName
        self.inlinedResponses = inlinedResponses
        self.inlinedEmbedContentResponses = inlinedEmbedContentResponses
        self.vertexDataset = vertexDataset
    }
}

/// Config for optional parameters.
public struct CreateBatchJobConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    ///
    /// NOTE: AbortSignal is a client-only operation. Using it to cancel an
    /// operation will not cancel the request in the service. You will still
    /// be charged usage for any applicable operations.
    public var abortSignal: AbortSignal?
    /// The user-defined name of this BatchJob.
    public var displayName: String?
    /// GCS or BigQuery URI prefix for the output predictions. Example:
    /// "gs://path/to/output/data" or "bq://projectId.bqDatasetId.bqTableId".
    public var dest: BatchJobDestinationUnion?
    /// Webhook configuration for receiving notifications when the batch
    /// operation completes.
    public var webhookConfig: WebhookConfig?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        displayName: String? = nil,
        dest: BatchJobDestinationUnion? = nil,
        webhookConfig: WebhookConfig? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.displayName = displayName
        self.dest = dest
        self.webhookConfig = webhookConfig
    }
}

/// Config for batches.create parameters.
public struct CreateBatchJobParameters: Codable, Sendable {
    /// The name of the model to produces the predictions via the BatchJob.
    public var model: String?
    /// GCS URI(-s) or BigQuery URI to your input data to run batch job.
    /// Example: "gs://path/to/input/data" or
    /// "bq://projectId.bqDatasetId.bqTableId".
    public var src: BatchJobSourceUnion
    /// Optional parameters for creating a BatchJob.
    public var config: CreateBatchJobConfig?

    public init(
        model: String? = nil,
        src: BatchJobSourceUnion,
        config: CreateBatchJobConfig? = nil
    ) {
        self.model = model
        self.src = src
        self.config = config
    }
}

/// Represents the `output_info` field in batch jobs.
public struct BatchJobOutputInfo: Codable, Sendable {
    /// This field is experimental and may change in future versions. The
    /// Vertex AI dataset name containing the output data.
    public var vertexMultimodalDatasetName: String?
    /// The full path of the Cloud Storage directory created, into which the
    /// prediction output is written.
    public var gcsOutputDirectory: String?
    /// The name of the BigQuery table created, in `predictions_TIMESTAMP`
    /// format, into which the prediction output is written.
    public var bigqueryOutputTable: String?

    public init(
        vertexMultimodalDatasetName: String? = nil,
        gcsOutputDirectory: String? = nil,
        bigqueryOutputTable: String? = nil
    ) {
        self.vertexMultimodalDatasetName = vertexMultimodalDatasetName
        self.gcsOutputDirectory = gcsOutputDirectory
        self.bigqueryOutputTable = bigqueryOutputTable
    }
}

/// Success and error statistics of processing multiple entities (for example,
/// DataItems or structured data rows) in batch. This data type is not supported
/// in Gemini API.
public struct CompletionStats: Codable, Sendable {
    /// Output only. The number of entities for which any error was
    /// encountered.
    public var failedCount: String?
    /// Output only. In cases when enough errors are encountered a job,
    /// pipeline, or operation may be failed as a whole. Below is the number
    /// of entities for which the processing had not been finished (either in
    /// successful or failed state). Set to -1 if the number is unknown (for
    /// example, the operation failed before the total entity number could be
    /// collected).
    public var incompleteCount: String?
    /// Output only. The number of entities that had been processed
    /// successfully.
    public var successfulCount: String?
    /// Output only. The number of the successful forecast points that are
    /// generated by the forecasting model. This is ONLY used by the
    /// forecasting batch prediction.
    public var successfulForecastPointCount: String?

    public init(
        failedCount: String? = nil,
        incompleteCount: String? = nil,
        successfulCount: String? = nil,
        successfulForecastPointCount: String? = nil
    ) {
        self.failedCount = failedCount
        self.incompleteCount = incompleteCount
        self.successfulCount = successfulCount
        self.successfulForecastPointCount = successfulForecastPointCount
    }
}

/// Config for batches.create return value.
public struct BatchJob: Codable, Sendable {
    /// The resource name of the BatchJob. Output only.
    public var name: String?
    /// The display name of the BatchJob.
    public var displayName: String?
    /// The state of the BatchJob.
    public var state: JobState?
    /// Output only. Only populated when the job's state is JOB_STATE_FAILED
    /// or JOB_STATE_CANCELLED.
    public var error: JobError?
    /// The time when the BatchJob was created.
    public var createTime: String?
    /// Output only. Time when the Job for the first time entered the
    /// `JOB_STATE_RUNNING` state.
    public var startTime: String?
    /// The time when the BatchJob was completed. This field is for Gemini
    /// Enterprise Agent Platform only.
    public var endTime: String?
    /// The time when the BatchJob was last updated.
    public var updateTime: String?
    /// The name of the model that produces the predictions via the BatchJob.
    public var model: String?
    /// Configuration for the input data. This field is for Gemini Enterprise
    /// Agent Platform only.
    public var src: BatchJobSource?
    /// Configuration for the output data.
    public var dest: BatchJobDestination?
    /// Statistics on completed and failed prediction instances. This field
    /// is for Gemini Enterprise Agent Platform only.
    public var completionStats: CompletionStats?
    /// Information further describing the output of this job. Output only.
    public var outputInfo: BatchJobOutputInfo?

    public init(
        name: String? = nil,
        displayName: String? = nil,
        state: JobState? = nil,
        error: JobError? = nil,
        createTime: String? = nil,
        startTime: String? = nil,
        endTime: String? = nil,
        updateTime: String? = nil,
        model: String? = nil,
        src: BatchJobSource? = nil,
        dest: BatchJobDestination? = nil,
        completionStats: CompletionStats? = nil,
        outputInfo: BatchJobOutputInfo? = nil
    ) {
        self.name = name
        self.displayName = displayName
        self.state = state
        self.error = error
        self.createTime = createTime
        self.startTime = startTime
        self.endTime = endTime
        self.updateTime = updateTime
        self.model = model
        self.src = src
        self.dest = dest
        self.completionStats = completionStats
        self.outputInfo = outputInfo
    }
}

/// Parameters for the embed_content method.
public struct EmbedContentBatch: Codable, Sendable {
    /// The content to embed. Only the `parts.text` fields will be counted.
    public var contents: ContentListUnion?
    /// Configuration that contains optional parameters.
    public var config: EmbedContentConfig?

    public init(contents: ContentListUnion? = nil, config: EmbedContentConfig? = nil) {
        self.contents = contents
        self.config = config
    }
}

public struct EmbeddingsBatchJobSource: Codable, Sendable {
    /// The Gemini Developer API's file resource name of the input data
    /// (e.g. "files/12345").
    public var fileName: String?
    /// The Gemini Developer API's inlined input data to run batch job.
    public var inlinedRequests: EmbedContentBatch?

    public init(fileName: String? = nil, inlinedRequests: EmbedContentBatch? = nil) {
        self.fileName = fileName
        self.inlinedRequests = inlinedRequests
    }
}

/// Config for optional parameters.
public struct CreateEmbeddingsBatchJobConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    ///
    /// NOTE: AbortSignal is a client-only operation. Using it to cancel an
    /// operation will not cancel the request in the service. You will still
    /// be charged usage for any applicable operations.
    public var abortSignal: AbortSignal?
    /// The user-defined name of this BatchJob.
    public var displayName: String?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        displayName: String? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.displayName = displayName
    }
}

/// Config for batches.create parameters.
public struct CreateEmbeddingsBatchJobParameters: Codable, Sendable {
    /// The name of the model to produces the predictions via the BatchJob.
    public var model: String?
    /// input data to run batch job.
    public var src: EmbeddingsBatchJobSource
    /// Optional parameters for creating a BatchJob.
    public var config: CreateEmbeddingsBatchJobConfig?

    public init(
        model: String? = nil,
        src: EmbeddingsBatchJobSource,
        config: CreateEmbeddingsBatchJobConfig? = nil
    ) {
        self.model = model
        self.src = src
        self.config = config
    }
}

/// Optional parameters.
public struct GetBatchJobConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    ///
    /// NOTE: AbortSignal is a client-only operation. Using it to cancel an
    /// operation will not cancel the request in the service. You will still
    /// be charged usage for any applicable operations.
    public var abortSignal: AbortSignal?

    public init(httpOptions: HttpOptions? = nil, abortSignal: AbortSignal? = nil) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

/// Config for batches.get parameters.
public struct GetBatchJobParameters: Codable, Sendable {
    /// A fully-qualified BatchJob resource name or ID.
    /// Example: "projects/.../locations/.../batchPredictionJobs/456"
    /// or "456" when project and location are initialized in the client.
    public var name: String
    /// Optional parameters for the request.
    public var config: GetBatchJobConfig?

    public init(name: String, config: GetBatchJobConfig? = nil) {
        self.name = name
        self.config = config
    }
}

/// Optional parameters.
public struct CancelBatchJobConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    ///
    /// NOTE: AbortSignal is a client-only operation. Using it to cancel an
    /// operation will not cancel the request in the service. You will still
    /// be charged usage for any applicable operations.
    public var abortSignal: AbortSignal?

    public init(httpOptions: HttpOptions? = nil, abortSignal: AbortSignal? = nil) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

/// Config for batches.cancel parameters.
public struct CancelBatchJobParameters: Codable, Sendable {
    /// A fully-qualified BatchJob resource name or ID.
    /// Example: "projects/.../locations/.../batchPredictionJobs/456"
    /// or "456" when project and location are initialized in the client.
    public var name: String
    /// Optional parameters for the request.
    public var config: CancelBatchJobConfig?

    public init(name: String, config: CancelBatchJobConfig? = nil) {
        self.name = name
        self.config = config
    }
}

/// Config for optional parameters.
public struct ListBatchJobsConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    ///
    /// NOTE: AbortSignal is a client-only operation. Using it to cancel an
    /// operation will not cancel the request in the service. You will still
    /// be charged usage for any applicable operations.
    public var abortSignal: AbortSignal?
    public var pageSize: Double?
    public var pageToken: String?
    public var filter: String?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        pageSize: Double? = nil,
        pageToken: String? = nil,
        filter: String? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.pageSize = pageSize
        self.pageToken = pageToken
        self.filter = filter
    }
}

/// Config for batches.list parameters.
public struct ListBatchJobsParameters: Codable, Sendable {
    public var config: ListBatchJobsConfig?

    public init(config: ListBatchJobsConfig? = nil) {
        self.config = config
    }
}

/// Config for batches.list return value.
public final class ListBatchJobsResponse: Codable, @unchecked Sendable {
    /// Used to retain the full HTTP response.
    public var sdkHttpResponse: HttpResponse?
    public var nextPageToken: String?
    public var batchJobs: [BatchJob]?

    public init(
        sdkHttpResponse: HttpResponse? = nil,
        nextPageToken: String? = nil,
        batchJobs: [BatchJob]? = nil
    ) {
        self.sdkHttpResponse = sdkHttpResponse
        self.nextPageToken = nextPageToken
        self.batchJobs = batchJobs
    }
}

/// Optional parameters for models.get method.
public struct DeleteBatchJobConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    ///
    /// NOTE: AbortSignal is a client-only operation. Using it to cancel an
    /// operation will not cancel the request in the service. You will still
    /// be charged usage for any applicable operations.
    public var abortSignal: AbortSignal?

    public init(httpOptions: HttpOptions? = nil, abortSignal: AbortSignal? = nil) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

/// Config for batches.delete parameters.
public struct DeleteBatchJobParameters: Codable, Sendable {
    /// A fully-qualified BatchJob resource name or ID.
    /// Example: "projects/.../locations/.../batchPredictionJobs/456"
    /// or "456" when project and location are initialized in the client.
    public var name: String
    /// Optional parameters for the request.
    public var config: DeleteBatchJobConfig?

    public init(name: String, config: DeleteBatchJobConfig? = nil) {
        self.name = name
        self.config = config
    }
}

/// The return value of delete operation.
public struct DeleteResourceJob: Codable, Sendable {
    /// Used to retain the full HTTP response.
    public var sdkHttpResponse: HttpResponse?
    public var name: String?
    public var done: Bool?
    public var error: JobError?

    public init(
        sdkHttpResponse: HttpResponse? = nil,
        name: String? = nil,
        done: Bool? = nil,
        error: JobError? = nil
    ) {
        self.sdkHttpResponse = sdkHttpResponse
        self.name = name
        self.done = done
        self.error = error
    }
}

public struct GetOperationConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    ///
    /// NOTE: AbortSignal is a client-only operation. Using it to cancel an
    /// operation will not cancel the request in the service. You will still
    /// be charged usage for any applicable operations.
    public var abortSignal: AbortSignal?

    public init(httpOptions: HttpOptions? = nil, abortSignal: AbortSignal? = nil) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

/// Parameters for the GET method.
public struct GetOperationParameters: Codable, Sendable {
    /// The server-assigned name for the operation.
    public var operationName: String
    /// Used to override the default configuration.
    public var config: GetOperationConfig?

    public init(operationName: String, config: GetOperationConfig? = nil) {
        self.operationName = operationName
        self.config = config
    }
}

public struct FetchPredictOperationConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    ///
    /// NOTE: AbortSignal is a client-only operation. Using it to cancel an
    /// operation will not cancel the request in the service. You will still
    /// be charged usage for any applicable operations.
    public var abortSignal: AbortSignal?

    public init(httpOptions: HttpOptions? = nil, abortSignal: AbortSignal? = nil) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

/// Parameters for the fetchPredictOperation method.
public struct FetchPredictOperationParameters: Codable, Sendable {
    /// The server-assigned name for the operation.
    public var operationName: String
    public var resourceName: String
    /// Used to override the default configuration.
    public var config: FetchPredictOperationConfig?

    public init(
        operationName: String,
        resourceName: String,
        config: FetchPredictOperationConfig? = nil
    ) {
        self.operationName = operationName
        self.resourceName = resourceName
        self.config = config
    }
}
