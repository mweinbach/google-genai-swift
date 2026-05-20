// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Optional parameters for the `tunings.get` method.
public struct GetTuningJobConfig: Codable, Sendable {
    /// Used to override HTTP request options.
    public var httpOptions: HttpOptions?
    /// Abort signal which can be used to cancel the request.
    public var abortSignal: AbortSignal?

    public init(httpOptions: HttpOptions? = nil, abortSignal: AbortSignal? = nil) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

/// Parameters for the get method.
public struct GetTuningJobParameters: Codable, Sendable {
    public var name: String
    /// Optional parameters for the request.
    public var config: GetTuningJobConfig?

    public init(name: String, config: GetTuningJobConfig? = nil) {
        self.name = name
        self.config = config
    }
}

/// `TunedModelCheckpoint` for the Tuned Model of a Tuning Job.
public struct TunedModelCheckpoint: Codable, Sendable {
    /// The ID of the checkpoint.
    public var checkpointId: String?
    /// The epoch of the checkpoint.
    public var epoch: String?
    /// The step of the checkpoint.
    public var step: String?
    /// The Endpoint resource name that the checkpoint is deployed to.
    /// Format: `projects/{project}/locations/{location}/endpoints/{endpoint}`.
    public var endpoint: String?

    public init(
        checkpointId: String? = nil,
        epoch: String? = nil,
        step: String? = nil,
        endpoint: String? = nil
    ) {
        self.checkpointId = checkpointId
        self.epoch = epoch
        self.step = step
        self.endpoint = endpoint
    }
}

/// `TunedModel` for the Tuned Model of a Tuning Job.
public struct TunedModel: Codable, Sendable {
    /// Output only. The resource name of the TunedModel.
    public var model: String?
    /// Output only. A resource name of an Endpoint.
    public var endpoint: String?
    /// The checkpoints associated with this TunedModel.
    public var checkpoints: [TunedModelCheckpoint]?

    public init(
        model: String? = nil,
        endpoint: String? = nil,
        checkpoints: [TunedModelCheckpoint]? = nil
    ) {
        self.model = model
        self.endpoint = endpoint
        self.checkpoints = checkpoints
    }
}

/// Hyperparameters for SFT. This data type is not supported in Gemini API.
public struct SupervisedHyperParameters: Codable, Sendable {
    /// Optional. Adapter size for tuning.
    public var adapterSize: AdapterSize?
    /// Optional. Batch size for tuning. This feature is only available for open source models.
    public var batchSize: String?
    /// Optional. Number of complete passes the model makes over the entire training dataset during training.
    public var epochCount: String?
    /// Optional. Learning rate for tuning. Mutually exclusive with `learning_rate_multiplier`. This feature is only available for open source models.
    public var learningRate: Double?
    /// Optional. Multiplier for adjusting the default learning rate. Mutually exclusive with `learning_rate`. This feature is only available for 1P models.
    public var learningRateMultiplier: Double?

    public init(
        adapterSize: AdapterSize? = nil,
        batchSize: String? = nil,
        epochCount: String? = nil,
        learningRate: Double? = nil,
        learningRateMultiplier: Double? = nil
    ) {
        self.adapterSize = adapterSize
        self.batchSize = batchSize
        self.epochCount = epochCount
        self.learningRate = learningRate
        self.learningRateMultiplier = learningRateMultiplier
    }
}

/// Supervised tuning spec for tuning.
public struct SupervisedTuningSpec: Codable, Sendable {
    /// Optional. If set to true, disable intermediate checkpoints for SFT and only the last checkpoint will be exported.
    public var exportLastCheckpointOnly: Bool?
    /// Optional. Hyperparameters for SFT.
    public var hyperParameters: SupervisedHyperParameters?
    /// Required. Training dataset used for tuning.
    public var trainingDatasetUri: String?
    /// Tuning mode.
    public var tuningMode: TuningMode?
    /// Optional. Validation dataset used for tuning.
    public var validationDatasetUri: String?

    public init(
        exportLastCheckpointOnly: Bool? = nil,
        hyperParameters: SupervisedHyperParameters? = nil,
        trainingDatasetUri: String? = nil,
        tuningMode: TuningMode? = nil,
        validationDatasetUri: String? = nil
    ) {
        self.exportLastCheckpointOnly = exportLastCheckpointOnly
        self.hyperParameters = hyperParameters
        self.trainingDatasetUri = trainingDatasetUri
        self.tuningMode = tuningMode
        self.validationDatasetUri = validationDatasetUri
    }
}

/// Hyperparameters for Preference Optimization. This data type is not supported in Gemini API.
public struct PreferenceOptimizationHyperParameters: Codable, Sendable {
    /// Optional. Adapter size for preference optimization.
    public var adapterSize: AdapterSize?
    /// Optional. Weight for KL Divergence regularization.
    public var beta: Double?
    /// Optional. Number of complete passes the model makes over the entire training dataset during training.
    public var epochCount: String?
    /// Optional. Multiplier for adjusting the default learning rate.
    public var learningRateMultiplier: Double?

    public init(
        adapterSize: AdapterSize? = nil,
        beta: Double? = nil,
        epochCount: String? = nil,
        learningRateMultiplier: Double? = nil
    ) {
        self.adapterSize = adapterSize
        self.beta = beta
        self.epochCount = epochCount
        self.learningRateMultiplier = learningRateMultiplier
    }
}

/// Preference optimization tuning spec for tuning.
public struct PreferenceOptimizationSpec: Codable, Sendable {
    /// Optional. If set to true, disable intermediate checkpoints for Preference Optimization.
    public var exportLastCheckpointOnly: Bool?
    /// Optional. Hyperparameters for Preference Optimization.
    public var hyperParameters: PreferenceOptimizationHyperParameters?
    /// Required. Cloud Storage path to file containing training dataset for preference optimization tuning.
    public var trainingDatasetUri: String?
    /// Optional. Cloud Storage path to file containing validation dataset for preference optimization tuning.
    public var validationDatasetUri: String?

    public init(
        exportLastCheckpointOnly: Bool? = nil,
        hyperParameters: PreferenceOptimizationHyperParameters? = nil,
        trainingDatasetUri: String? = nil,
        validationDatasetUri: String? = nil
    ) {
        self.exportLastCheckpointOnly = exportLastCheckpointOnly
        self.hyperParameters = hyperParameters
        self.trainingDatasetUri = trainingDatasetUri
        self.validationDatasetUri = validationDatasetUri
    }
}

/// Hyperparameters for distillation.
public struct DistillationHyperParameters: Codable, Sendable {
    /// Optional. Adapter size for distillation.
    public var adapterSize: AdapterSize?
    /// Optional. Number of complete passes the model makes over the entire training dataset during training.
    public var epochCount: String?
    /// Optional. Multiplier for adjusting the default learning rate.
    public var learningRateMultiplier: Double?
    /// The batch size hyperparameter for tuning. OSS models only.
    public var batchSize: Double?
    /// The learning rate for tuning. OSS models only.
    public var learningRate: Double?

    public init(
        adapterSize: AdapterSize? = nil,
        epochCount: String? = nil,
        learningRateMultiplier: Double? = nil,
        batchSize: Double? = nil,
        learningRate: Double? = nil
    ) {
        self.adapterSize = adapterSize
        self.epochCount = epochCount
        self.learningRateMultiplier = learningRateMultiplier
        self.batchSize = batchSize
        self.learningRate = learningRate
    }
}

/// Distillation tuning spec for tuning.
public struct DistillationSpec: Codable, Sendable {
    /// The GCS URI of the prompt dataset to use during distillation.
    public var promptDatasetUri: String?
    /// The base teacher model that is being distilled.
    public var baseTeacherModel: String?
    /// Optional. Hyperparameters for Distillation.
    public var hyperParameters: DistillationHyperParameters?
    /// Deprecated. A path in a Cloud Storage bucket, treated as the root output directory of the distillation pipeline.
    public var pipelineRootDirectory: String?
    /// The student model that is being tuned. Deprecated. Use base_model instead.
    public var studentModel: String?
    /// Deprecated. Cloud Storage path to file containing training dataset for tuning.
    public var trainingDatasetUri: String?
    /// The resource name of the Tuned teacher model.
    public var tunedTeacherModelSource: String?
    /// Optional. Cloud Storage path to file containing validation dataset for tuning.
    public var validationDatasetUri: String?
    /// Tuning mode for tuning.
    public var tuningMode: TuningMode?

    public init(
        promptDatasetUri: String? = nil,
        baseTeacherModel: String? = nil,
        hyperParameters: DistillationHyperParameters? = nil,
        pipelineRootDirectory: String? = nil,
        studentModel: String? = nil,
        trainingDatasetUri: String? = nil,
        tunedTeacherModelSource: String? = nil,
        validationDatasetUri: String? = nil,
        tuningMode: TuningMode? = nil
    ) {
        self.promptDatasetUri = promptDatasetUri
        self.baseTeacherModel = baseTeacherModel
        self.hyperParameters = hyperParameters
        self.pipelineRootDirectory = pipelineRootDirectory
        self.studentModel = studentModel
        self.trainingDatasetUri = trainingDatasetUri
        self.tunedTeacherModelSource = tunedTeacherModelSource
        self.validationDatasetUri = validationDatasetUri
        self.tuningMode = tuningMode
    }
}

/// The `Status` type defines a logical error model. This data type is not supported in Gemini API.
public struct GoogleRpcStatus: Codable, Sendable {
    /// The status code.
    public var code: Double?
    /// A list of messages that carry the error details.
    public var details: [[String: JSONValue]]?
    /// A developer-facing error message.
    public var message: String?

    public init(
        code: Double? = nil,
        details: [[String: JSONValue]]? = nil,
        message: String? = nil
    ) {
        self.code = code
        self.details = details
        self.message = message
    }
}

/// A pre-tuned model for continuous tuning. This data type is not supported in Gemini API.
public struct PreTunedModel: Codable, Sendable {
    /// Output only. The name of the base model this PreTunedModel was tuned from.
    public var baseModel: String?
    /// Optional. The source checkpoint id.
    public var checkpointId: String?
    /// The resource name of the Model.
    public var tunedModelName: String?

    public init(
        baseModel: String? = nil,
        checkpointId: String? = nil,
        tunedModelName: String? = nil
    ) {
        self.baseModel = baseModel
        self.checkpointId = checkpointId
        self.tunedModelName = tunedModelName
    }
}

/// Dataset bucket used to create a histogram for the distribution given a population of values. This data type is not supported in Gemini API.
public struct DatasetDistributionDistributionBucket: Codable, Sendable {
    /// Output only. Number of values in the bucket.
    public var count: String?
    /// Output only. Left bound of the bucket.
    public var left: Double?
    /// Output only. Right bound of the bucket.
    public var right: Double?

    public init(count: String? = nil, left: Double? = nil, right: Double? = nil) {
        self.count = count
        self.left = left
        self.right = right
    }
}

/// Distribution computed over a tuning dataset. This data type is not supported in Gemini API.
public struct DatasetDistribution: Codable, Sendable {
    /// Output only. Defines the histogram bucket.
    public var buckets: [DatasetDistributionDistributionBucket]?
    /// Output only. The maximum of the population values.
    public var max: Double?
    /// Output only. The arithmetic mean of the values in the population.
    public var mean: Double?
    /// Output only. The median of the values in the population.
    public var median: Double?
    /// Output only. The minimum of the population values.
    public var min: Double?
    /// Output only. The 5th percentile of the values in the population.
    public var p5: Double?
    /// Output only. The 95th percentile of the values in the population.
    public var p95: Double?
    /// Output only. Sum of a given population of values.
    public var sum: Double?

    public init(
        buckets: [DatasetDistributionDistributionBucket]? = nil,
        max: Double? = nil,
        mean: Double? = nil,
        median: Double? = nil,
        min: Double? = nil,
        p5: Double? = nil,
        p95: Double? = nil,
        sum: Double? = nil
    ) {
        self.buckets = buckets
        self.max = max
        self.mean = mean
        self.median = median
        self.min = min
        self.p5 = p5
        self.p95 = p95
        self.sum = sum
    }
}

/// Statistics computed over a tuning dataset. This data type is not supported in Gemini API.
public struct DatasetStats: Codable, Sendable {
    /// Output only. A partial sample of the indices (starting from 1) of the dropped examples.
    public var droppedExampleIndices: [String]?
    /// Output only. For each index in `dropped_example_indices`, the user-facing reason why the example was dropped.
    public var droppedExampleReasons: [String]?
    /// Output only. Number of billable characters in the tuning dataset.
    public var totalBillableCharacterCount: String?
    /// Output only. Number of tuning characters in the tuning dataset.
    public var totalTuningCharacterCount: String?
    /// Output only. Number of examples in the tuning dataset.
    public var tuningDatasetExampleCount: String?
    /// Output only. Number of tuning steps for this Tuning Job.
    public var tuningStepCount: String?
    /// Output only. Sample user messages in the training dataset uri.
    public var userDatasetExamples: [Content]?
    /// Output only. Dataset distributions for the user input tokens.
    public var userInputTokenDistribution: DatasetDistribution?
    /// Output only. Dataset distributions for the messages per example.
    public var userMessagePerExampleDistribution: DatasetDistribution?
    /// Output only. Dataset distributions for the user output tokens.
    public var userOutputTokenDistribution: DatasetDistribution?

    public init(
        droppedExampleIndices: [String]? = nil,
        droppedExampleReasons: [String]? = nil,
        totalBillableCharacterCount: String? = nil,
        totalTuningCharacterCount: String? = nil,
        tuningDatasetExampleCount: String? = nil,
        tuningStepCount: String? = nil,
        userDatasetExamples: [Content]? = nil,
        userInputTokenDistribution: DatasetDistribution? = nil,
        userMessagePerExampleDistribution: DatasetDistribution? = nil,
        userOutputTokenDistribution: DatasetDistribution? = nil
    ) {
        self.droppedExampleIndices = droppedExampleIndices
        self.droppedExampleReasons = droppedExampleReasons
        self.totalBillableCharacterCount = totalBillableCharacterCount
        self.totalTuningCharacterCount = totalTuningCharacterCount
        self.tuningDatasetExampleCount = tuningDatasetExampleCount
        self.tuningStepCount = tuningStepCount
        self.userDatasetExamples = userDatasetExamples
        self.userInputTokenDistribution = userInputTokenDistribution
        self.userMessagePerExampleDistribution = userMessagePerExampleDistribution
        self.userOutputTokenDistribution = userOutputTokenDistribution
    }
}

/// Statistics for distillation prompt dataset. This data type is not supported in Gemini API.
public struct DistillationDataStats: Codable, Sendable {
    /// Output only. Statistics computed for the training dataset.
    public var trainingDatasetStats: DatasetStats?

    public init(trainingDatasetStats: DatasetStats? = nil) {
        self.trainingDatasetStats = trainingDatasetStats
    }
}

/// Completion and its preference score. This data type is not supported in Gemini API.
public struct GeminiPreferenceExampleCompletion: Codable, Sendable {
    /// Single turn completion for the given prompt.
    public var completion: Content?
    /// The score for the given completion.
    public var score: Double?

    public init(completion: Content? = nil, score: Double? = nil) {
        self.completion = completion
        self.score = score
    }
}

/// Input example for preference optimization. This data type is not supported in Gemini API.
public struct GeminiPreferenceExample: Codable, Sendable {
    /// List of completions for a given prompt.
    public var completions: [GeminiPreferenceExampleCompletion]?
    /// Multi-turn contents that represents the Prompt.
    public var contents: [Content]?

    public init(
        completions: [GeminiPreferenceExampleCompletion]? = nil,
        contents: [Content]? = nil
    ) {
        self.completions = completions
        self.contents = contents
    }
}

/// Statistics computed for datasets used for preference optimization. This data type is not supported in Gemini API.
public struct PreferenceOptimizationDataStats: Codable, Sendable {
    public var droppedExampleIndices: [String]?
    public var droppedExampleReasons: [String]?
    public var scoreVariancePerExampleDistribution: DatasetDistribution?
    public var scoresDistribution: DatasetDistribution?
    public var totalBillableTokenCount: String?
    public var tuningDatasetExampleCount: String?
    public var tuningStepCount: String?
    public var userDatasetExamples: [GeminiPreferenceExample]?
    public var userInputTokenDistribution: DatasetDistribution?
    public var userOutputTokenDistribution: DatasetDistribution?

    public init(
        droppedExampleIndices: [String]? = nil,
        droppedExampleReasons: [String]? = nil,
        scoreVariancePerExampleDistribution: DatasetDistribution? = nil,
        scoresDistribution: DatasetDistribution? = nil,
        totalBillableTokenCount: String? = nil,
        tuningDatasetExampleCount: String? = nil,
        tuningStepCount: String? = nil,
        userDatasetExamples: [GeminiPreferenceExample]? = nil,
        userInputTokenDistribution: DatasetDistribution? = nil,
        userOutputTokenDistribution: DatasetDistribution? = nil
    ) {
        self.droppedExampleIndices = droppedExampleIndices
        self.droppedExampleReasons = droppedExampleReasons
        self.scoreVariancePerExampleDistribution = scoreVariancePerExampleDistribution
        self.scoresDistribution = scoresDistribution
        self.totalBillableTokenCount = totalBillableTokenCount
        self.tuningDatasetExampleCount = tuningDatasetExampleCount
        self.tuningStepCount = tuningStepCount
        self.userDatasetExamples = userDatasetExamples
        self.userInputTokenDistribution = userInputTokenDistribution
        self.userOutputTokenDistribution = userOutputTokenDistribution
    }
}

/// Dataset bucket used to create a histogram for the distribution given a population of values. This data type is not supported in Gemini API.
public struct SupervisedTuningDatasetDistributionDatasetBucket: Codable, Sendable {
    public var count: Double?
    public var left: Double?
    public var right: Double?

    public init(count: Double? = nil, left: Double? = nil, right: Double? = nil) {
        self.count = count
        self.left = left
        self.right = right
    }
}

/// Dataset distribution for Supervised Tuning. This data type is not supported in Gemini API.
public struct SupervisedTuningDatasetDistribution: Codable, Sendable {
    public var billableSum: String?
    public var buckets: [SupervisedTuningDatasetDistributionDatasetBucket]?
    public var max: Double?
    public var mean: Double?
    public var median: Double?
    public var min: Double?
    public var p5: Double?
    public var p95: Double?
    public var sum: String?

    public init(
        billableSum: String? = nil,
        buckets: [SupervisedTuningDatasetDistributionDatasetBucket]? = nil,
        max: Double? = nil,
        mean: Double? = nil,
        median: Double? = nil,
        min: Double? = nil,
        p5: Double? = nil,
        p95: Double? = nil,
        sum: String? = nil
    ) {
        self.billableSum = billableSum
        self.buckets = buckets
        self.max = max
        self.mean = mean
        self.median = median
        self.min = min
        self.p5 = p5
        self.p95 = p95
        self.sum = sum
    }
}

/// Tuning data statistics for Supervised Tuning. This data type is not supported in Gemini API.
public struct SupervisedTuningDataStats: Codable, Sendable {
    public var droppedExampleReasons: [String]?
    public var totalBillableCharacterCount: String?
    public var totalBillableTokenCount: String?
    public var totalTruncatedExampleCount: String?
    public var totalTuningCharacterCount: String?
    public var truncatedExampleIndices: [String]?
    public var tuningDatasetExampleCount: String?
    public var tuningStepCount: String?
    public var userDatasetExamples: [Content]?
    public var userInputTokenDistribution: SupervisedTuningDatasetDistribution?
    public var userMessagePerExampleDistribution: SupervisedTuningDatasetDistribution?
    public var userOutputTokenDistribution: SupervisedTuningDatasetDistribution?

    public init(
        droppedExampleReasons: [String]? = nil,
        totalBillableCharacterCount: String? = nil,
        totalBillableTokenCount: String? = nil,
        totalTruncatedExampleCount: String? = nil,
        totalTuningCharacterCount: String? = nil,
        truncatedExampleIndices: [String]? = nil,
        tuningDatasetExampleCount: String? = nil,
        tuningStepCount: String? = nil,
        userDatasetExamples: [Content]? = nil,
        userInputTokenDistribution: SupervisedTuningDatasetDistribution? = nil,
        userMessagePerExampleDistribution: SupervisedTuningDatasetDistribution? = nil,
        userOutputTokenDistribution: SupervisedTuningDatasetDistribution? = nil
    ) {
        self.droppedExampleReasons = droppedExampleReasons
        self.totalBillableCharacterCount = totalBillableCharacterCount
        self.totalBillableTokenCount = totalBillableTokenCount
        self.totalTruncatedExampleCount = totalTruncatedExampleCount
        self.totalTuningCharacterCount = totalTuningCharacterCount
        self.truncatedExampleIndices = truncatedExampleIndices
        self.tuningDatasetExampleCount = tuningDatasetExampleCount
        self.tuningStepCount = tuningStepCount
        self.userDatasetExamples = userDatasetExamples
        self.userInputTokenDistribution = userInputTokenDistribution
        self.userMessagePerExampleDistribution = userMessagePerExampleDistribution
        self.userOutputTokenDistribution = userOutputTokenDistribution
    }
}

/// The tuning data statistic values for TuningJob. This data type is not supported in Gemini API.
public struct TuningDataStats: Codable, Sendable {
    /// Output only. Statistics for distillation prompt dataset.
    public var distillationDataStats: DistillationDataStats?
    /// Output only. Statistics for preference optimization.
    public var preferenceOptimizationDataStats: PreferenceOptimizationDataStats?
    /// The SFT Tuning data stats.
    public var supervisedTuningDataStats: SupervisedTuningDataStats?

    public init(
        distillationDataStats: DistillationDataStats? = nil,
        preferenceOptimizationDataStats: PreferenceOptimizationDataStats? = nil,
        supervisedTuningDataStats: SupervisedTuningDataStats? = nil
    ) {
        self.distillationDataStats = distillationDataStats
        self.preferenceOptimizationDataStats = preferenceOptimizationDataStats
        self.supervisedTuningDataStats = supervisedTuningDataStats
    }
}

/// Represents a customer-managed encryption key specification. This data type is not supported in Gemini API.
public struct EncryptionSpec: Codable, Sendable {
    /// Required. Resource name of the Cloud KMS key used to protect the resource.
    public var kmsKeyName: String?

    public init(kmsKeyName: String? = nil) {
        self.kmsKeyName = kmsKeyName
    }
}

/// Tuning spec for Partner models. This data type is not supported in Gemini API.
public struct PartnerModelTuningSpec: Codable, Sendable {
    /// Hyperparameters for tuning.
    public var hyperParameters: [String: JSONValue]?
    /// Required. Cloud Storage path to file containing training dataset for tuning.
    public var trainingDatasetUri: String?
    /// Optional. Cloud Storage path to file containing validation dataset for tuning.
    public var validationDatasetUri: String?

    public init(
        hyperParameters: [String: JSONValue]? = nil,
        trainingDatasetUri: String? = nil,
        validationDatasetUri: String? = nil
    ) {
        self.hyperParameters = hyperParameters
        self.trainingDatasetUri = trainingDatasetUri
        self.validationDatasetUri = validationDatasetUri
    }
}

/// Bleu metric value for an instance. This data type is not supported in Gemini API.
public struct BleuMetricValue: Codable, Sendable {
    /// Output only. Bleu score.
    public var score: Double?

    public init(score: Double? = nil) {
        self.score = score
    }
}

/// Result for custom code execution metric. This data type is not supported in Gemini API.
public struct CustomCodeExecutionResult: Codable, Sendable {
    /// Output only. Custom code execution score.
    public var score: Double?

    public init(score: Double? = nil) {
        self.score = score
    }
}

/// Exact match metric value for an instance. This data type is not supported in Gemini API.
public struct ExactMatchMetricValue: Codable, Sendable {
    /// Output only. Exact match score.
    public var score: Double?

    public init(score: Double? = nil) {
        self.score = score
    }
}

/// Raw output. This data type is not supported in Gemini API.
public struct RawOutput: Codable, Sendable {
    /// Output only. Raw output string.
    public var rawOutput: [String]?

    public init(rawOutput: [String]? = nil) {
        self.rawOutput = rawOutput
    }
}

/// Spec for custom output. This data type is not supported in Gemini API.
public struct CustomOutput: Codable, Sendable {
    /// Output only. List of raw output strings.
    public var rawOutputs: RawOutput?

    public init(rawOutputs: RawOutput? = nil) {
        self.rawOutputs = rawOutputs
    }
}

/// Spec for pairwise metric result. This data type is not supported in Gemini API.
public struct PairwiseMetricResult: Codable, Sendable {
    public var customOutput: CustomOutput?
    public var explanation: String?
    public var pairwiseChoice: PairwiseChoice?

    public init(
        customOutput: CustomOutput? = nil,
        explanation: String? = nil,
        pairwiseChoice: PairwiseChoice? = nil
    ) {
        self.customOutput = customOutput
        self.explanation = explanation
        self.pairwiseChoice = pairwiseChoice
    }
}

/// Spec for pointwise metric result. This data type is not supported in Gemini API.
public struct PointwiseMetricResult: Codable, Sendable {
    public var customOutput: CustomOutput?
    public var explanation: String?
    public var score: Double?

    public init(
        customOutput: CustomOutput? = nil,
        explanation: String? = nil,
        score: Double? = nil
    ) {
        self.customOutput = customOutput
        self.explanation = explanation
        self.score = score
    }
}

/// Rouge metric value for an instance. This data type is not supported in Gemini API.
public struct RougeMetricValue: Codable, Sendable {
    /// Output only. Rouge score.
    public var score: Double?

    public init(score: Double? = nil) {
        self.score = score
    }
}

/// The aggregation result for a single metric. This data type is not supported in Gemini API.
public struct AggregationResult: Codable, Sendable {
    public var aggregationMetric: AggregationMetric?
    public var bleuMetricValue: BleuMetricValue?
    public var customCodeExecutionResult: CustomCodeExecutionResult?
    public var exactMatchMetricValue: ExactMatchMetricValue?
    public var pairwiseMetricResult: PairwiseMetricResult?
    public var pointwiseMetricResult: PointwiseMetricResult?
    public var rougeMetricValue: RougeMetricValue?

    public init(
        aggregationMetric: AggregationMetric? = nil,
        bleuMetricValue: BleuMetricValue? = nil,
        customCodeExecutionResult: CustomCodeExecutionResult? = nil,
        exactMatchMetricValue: ExactMatchMetricValue? = nil,
        pairwiseMetricResult: PairwiseMetricResult? = nil,
        pointwiseMetricResult: PointwiseMetricResult? = nil,
        rougeMetricValue: RougeMetricValue? = nil
    ) {
        self.aggregationMetric = aggregationMetric
        self.bleuMetricValue = bleuMetricValue
        self.customCodeExecutionResult = customCodeExecutionResult
        self.exactMatchMetricValue = exactMatchMetricValue
        self.pairwiseMetricResult = pairwiseMetricResult
        self.pointwiseMetricResult = pointwiseMetricResult
        self.rougeMetricValue = rougeMetricValue
    }
}

/// The BigQuery location for the input content. This data type is not supported in Gemini API.
public struct BigQuerySource: Codable, Sendable {
    /// Required. BigQuery URI to a table.
    public var inputUri: String?

    public init(inputUri: String? = nil) {
        self.inputUri = inputUri
    }
}

/// The Google Cloud Storage location for the input content. This data type is not supported in Gemini API.
public struct GcsSource: Codable, Sendable {
    /// Required. Google Cloud Storage URI(-s) to the input file(s).
    public var uris: [String]?

    public init(uris: [String]? = nil) {
        self.uris = uris
    }
}

/// The dataset used for evaluation. This data type is not supported in Gemini API.
public struct EvaluationDataset: Codable, Sendable {
    public var bigquerySource: BigQuerySource?
    public var gcsSource: GcsSource?

    public init(bigquerySource: BigQuerySource? = nil, gcsSource: GcsSource? = nil) {
        self.bigquerySource = bigquerySource
        self.gcsSource = gcsSource
    }
}

/// The aggregation result for the entire dataset and all metrics. This data type is not supported in Gemini API.
public struct AggregationOutput: Codable, Sendable {
    public var aggregationResults: [AggregationResult]?
    public var dataset: EvaluationDataset?

    public init(
        aggregationResults: [AggregationResult]? = nil,
        dataset: EvaluationDataset? = nil
    ) {
        self.aggregationResults = aggregationResults
        self.dataset = dataset
    }
}

/// Describes the info for output of EvaluationService. This data type is not supported in Gemini API.
public struct OutputInfo: Codable, Sendable {
    /// Output only. The full path of the Cloud Storage directory created.
    public var gcsOutputDirectory: String?

    public init(gcsOutputDirectory: String? = nil) {
        self.gcsOutputDirectory = gcsOutputDirectory
    }
}

/// The results from an evaluation run performed by the EvaluationService. This data type is not supported in Gemini API.
public final class EvaluateDatasetResponse: Codable, @unchecked Sendable {
    /// Output only. Aggregation statistics derived from results of EvaluationService.
    public var aggregationOutput: AggregationOutput?
    /// Output only. Output info for EvaluationService.
    public var outputInfo: OutputInfo?

    public init(
        aggregationOutput: AggregationOutput? = nil,
        outputInfo: OutputInfo? = nil
    ) {
        self.aggregationOutput = aggregationOutput
        self.outputInfo = outputInfo
    }
}

/// Evaluate Dataset Run Result for Tuning Job. This data type is not supported in Gemini API.
public struct EvaluateDatasetRun: Codable, Sendable {
    public var checkpointId: String?
    public var error: GoogleRpcStatus?
    public var evaluateDatasetResponse: EvaluateDatasetResponse?
    public var evaluationRun: String?
    public var operationName: String?

    public init(
        checkpointId: String? = nil,
        error: GoogleRpcStatus? = nil,
        evaluateDatasetResponse: EvaluateDatasetResponse? = nil,
        evaluationRun: String? = nil,
        operationName: String? = nil
    ) {
        self.checkpointId = checkpointId
        self.error = error
        self.evaluateDatasetResponse = evaluateDatasetResponse
        self.evaluationRun = evaluationRun
        self.operationName = operationName
    }
}

/// Tuning Spec for Full Fine Tuning. This data type is not supported in Gemini API.
public struct FullFineTuningSpec: Codable, Sendable {
    /// Optional. Hyperparameters for Full Fine Tuning.
    public var hyperParameters: SupervisedHyperParameters?
    /// Required. Training dataset used for tuning.
    public var trainingDatasetUri: String?
    /// Optional. Validation dataset used for tuning.
    public var validationDatasetUri: String?

    public init(
        hyperParameters: SupervisedHyperParameters? = nil,
        trainingDatasetUri: String? = nil,
        validationDatasetUri: String? = nil
    ) {
        self.hyperParameters = hyperParameters
        self.trainingDatasetUri = trainingDatasetUri
        self.validationDatasetUri = validationDatasetUri
    }
}

/// Hyperparameters for Veo. This data type is not supported in Gemini API.
public struct VeoHyperParameters: Codable, Sendable {
    public var epochCount: String?
    public var learningRateMultiplier: Double?
    public var tuningTask: TuningTask?
    public var veoDataMixtureRatio: Double?

    public init(
        epochCount: String? = nil,
        learningRateMultiplier: Double? = nil,
        tuningTask: TuningTask? = nil,
        veoDataMixtureRatio: Double? = nil
    ) {
        self.epochCount = epochCount
        self.learningRateMultiplier = learningRateMultiplier
        self.tuningTask = tuningTask
        self.veoDataMixtureRatio = veoDataMixtureRatio
    }
}

/// Tuning Spec for Veo Model Tuning. This data type is not supported in Gemini API.
public struct VeoTuningSpec: Codable, Sendable {
    public var hyperParameters: VeoHyperParameters?
    public var trainingDatasetUri: String?
    public var validationDatasetUri: String?

    public init(
        hyperParameters: VeoHyperParameters? = nil,
        trainingDatasetUri: String? = nil,
        validationDatasetUri: String? = nil
    ) {
        self.hyperParameters = hyperParameters
        self.trainingDatasetUri = trainingDatasetUri
        self.validationDatasetUri = validationDatasetUri
    }
}

/// Spec for creating a distilled dataset in Vertex Dataset. This data type is not supported in Gemini API.
public struct DistillationSamplingSpec: Codable, Sendable {
    public var baseTeacherModel: String?
    public var tunedTeacherModelSource: String?
    public var validationDatasetUri: String?

    public init(
        baseTeacherModel: String? = nil,
        tunedTeacherModelSource: String? = nil,
        validationDatasetUri: String? = nil
    ) {
        self.baseTeacherModel = baseTeacherModel
        self.tunedTeacherModelSource = tunedTeacherModelSource
        self.validationDatasetUri = validationDatasetUri
    }
}

/// Tuning job metadata. This data type is not supported in Gemini API.
public struct TuningJobMetadata: Codable, Sendable {
    /// Output only. The number of epochs that have been completed.
    public var completedEpochCount: String?
    /// Output only. The number of steps that have been completed. Set for Multi-Step RL.
    public var completedStepCount: String?

    public init(
        completedEpochCount: String? = nil,
        completedStepCount: String? = nil
    ) {
        self.completedEpochCount = completedEpochCount
        self.completedStepCount = completedStepCount
    }
}

/// A tuning job.
public struct TuningJob: Codable, Sendable {
    /// Used to retain the full HTTP response.
    public var sdkHttpResponse: HttpResponse?
    /// Output only. Identifier. Resource name of a TuningJob.
    public var name: String?
    /// Output only. The detailed state of the job.
    public var state: JobState?
    /// Output only. Time when the TuningJob was created.
    public var createTime: String?
    /// Output only. Time when the TuningJob first entered the running state.
    public var startTime: String?
    /// Output only. Time when the TuningJob entered a terminal state.
    public var endTime: String?
    /// Output only. Time when the TuningJob was most recently updated.
    public var updateTime: String?
    /// Output only. Only populated when job's state is failed or cancelled.
    public var error: GoogleRpcStatus?
    /// Optional. The description of the TuningJob.
    public var description: String?
    /// The base model that is being tuned.
    public var baseModel: String?
    /// Output only. The tuned model resources associated with this TuningJob.
    public var tunedModel: TunedModel?
    /// The pre-tuned model for continuous tuning.
    public var preTunedModel: PreTunedModel?
    /// Tuning Spec for Supervised Fine Tuning.
    public var supervisedTuningSpec: SupervisedTuningSpec?
    /// Tuning Spec for Preference Optimization.
    public var preferenceOptimizationSpec: PreferenceOptimizationSpec?
    /// Tuning Spec for Distillation.
    public var distillationSpec: DistillationSpec?
    /// Output only. The tuning data statistics associated with this TuningJob.
    public var tuningDataStats: TuningDataStats?
    /// Customer-managed encryption key options for a TuningJob.
    public var encryptionSpec: EncryptionSpec?
    /// Tuning Spec for open sourced and third party Partner models.
    public var partnerModelTuningSpec: PartnerModelTuningSpec?
    /// Optional. The user-provided path to custom model weights.
    public var customBaseModel: String?
    /// Output only. Evaluation runs for the Tuning Job.
    public var evaluateDatasetRuns: [EvaluateDatasetRun]?
    /// Output only. The Experiment associated with this TuningJob.
    public var experiment: String?
    /// Tuning Spec for Full Fine Tuning.
    public var fullFineTuningSpec: FullFineTuningSpec?
    /// Optional. The labels with user-defined metadata to organize TuningJob.
    public var labels: [String: String]?
    /// Optional. Cloud Storage path to the directory where tuning job outputs are written to.
    public var outputUri: String?
    /// Output only. The resource name of the PipelineJob associated with the TuningJob.
    public var pipelineJob: String?
    /// The service account that the tuningJob workload runs as.
    public var serviceAccount: String?
    /// Optional. The display name of the TunedModel.
    public var tunedModelDisplayName: String?
    /// Output only. The detail state of the tuning job.
    public var tuningJobState: TuningJobState?
    /// Tuning Spec for Veo Tuning.
    public var veoTuningSpec: VeoTuningSpec?
    /// Optional. Spec for creating a distillation dataset.
    public var distillationSamplingSpec: DistillationSamplingSpec?
    /// Output only. Tuning Job metadata.
    public var tuningJobMetadata: TuningJobMetadata?

    public init(
        sdkHttpResponse: HttpResponse? = nil,
        name: String? = nil,
        state: JobState? = nil,
        createTime: String? = nil,
        startTime: String? = nil,
        endTime: String? = nil,
        updateTime: String? = nil,
        error: GoogleRpcStatus? = nil,
        description: String? = nil,
        baseModel: String? = nil,
        tunedModel: TunedModel? = nil,
        preTunedModel: PreTunedModel? = nil,
        supervisedTuningSpec: SupervisedTuningSpec? = nil,
        preferenceOptimizationSpec: PreferenceOptimizationSpec? = nil,
        distillationSpec: DistillationSpec? = nil,
        tuningDataStats: TuningDataStats? = nil,
        encryptionSpec: EncryptionSpec? = nil,
        partnerModelTuningSpec: PartnerModelTuningSpec? = nil,
        customBaseModel: String? = nil,
        evaluateDatasetRuns: [EvaluateDatasetRun]? = nil,
        experiment: String? = nil,
        fullFineTuningSpec: FullFineTuningSpec? = nil,
        labels: [String: String]? = nil,
        outputUri: String? = nil,
        pipelineJob: String? = nil,
        serviceAccount: String? = nil,
        tunedModelDisplayName: String? = nil,
        tuningJobState: TuningJobState? = nil,
        veoTuningSpec: VeoTuningSpec? = nil,
        distillationSamplingSpec: DistillationSamplingSpec? = nil,
        tuningJobMetadata: TuningJobMetadata? = nil
    ) {
        self.sdkHttpResponse = sdkHttpResponse
        self.name = name
        self.state = state
        self.createTime = createTime
        self.startTime = startTime
        self.endTime = endTime
        self.updateTime = updateTime
        self.error = error
        self.description = description
        self.baseModel = baseModel
        self.tunedModel = tunedModel
        self.preTunedModel = preTunedModel
        self.supervisedTuningSpec = supervisedTuningSpec
        self.preferenceOptimizationSpec = preferenceOptimizationSpec
        self.distillationSpec = distillationSpec
        self.tuningDataStats = tuningDataStats
        self.encryptionSpec = encryptionSpec
        self.partnerModelTuningSpec = partnerModelTuningSpec
        self.customBaseModel = customBaseModel
        self.evaluateDatasetRuns = evaluateDatasetRuns
        self.experiment = experiment
        self.fullFineTuningSpec = fullFineTuningSpec
        self.labels = labels
        self.outputUri = outputUri
        self.pipelineJob = pipelineJob
        self.serviceAccount = serviceAccount
        self.tunedModelDisplayName = tunedModelDisplayName
        self.tuningJobState = tuningJobState
        self.veoTuningSpec = veoTuningSpec
        self.distillationSamplingSpec = distillationSamplingSpec
        self.tuningJobMetadata = tuningJobMetadata
    }
}

/// Configuration for the list tuning jobs method.
public struct ListTuningJobsConfig: Codable, Sendable {
    public var httpOptions: HttpOptions?
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

/// Parameters for the list tuning jobs method.
public struct ListTuningJobsParameters: Codable, Sendable {
    public var config: ListTuningJobsConfig?

    public init(config: ListTuningJobsConfig? = nil) {
        self.config = config
    }
}

/// Response for the list tuning jobs method.
public final class ListTuningJobsResponse: Codable, @unchecked Sendable {
    public var sdkHttpResponse: HttpResponse?
    public var nextPageToken: String?
    /// The tuning jobs that match the request.
    public var tuningJobs: [TuningJob]?

    public init(
        sdkHttpResponse: HttpResponse? = nil,
        nextPageToken: String? = nil,
        tuningJobs: [TuningJob]? = nil
    ) {
        self.sdkHttpResponse = sdkHttpResponse
        self.nextPageToken = nextPageToken
        self.tuningJobs = tuningJobs
    }
}

/// Optional parameters for `tunings.cancel` method.
public struct CancelTuningJobConfig: Codable, Sendable {
    public var httpOptions: HttpOptions?
    public var abortSignal: AbortSignal?

    public init(httpOptions: HttpOptions? = nil, abortSignal: AbortSignal? = nil) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
    }
}

/// Parameters for the cancel method.
public struct CancelTuningJobParameters: Codable, Sendable {
    /// The resource name of the tuning job.
    public var name: String
    /// Optional parameters for the request.
    public var config: CancelTuningJobConfig?

    public init(name: String, config: CancelTuningJobConfig? = nil) {
        self.name = name
        self.config = config
    }
}

/// Empty response for `tunings.cancel` method.
public final class CancelTuningJobResponse: Codable, @unchecked Sendable {
    public var sdkHttpResponse: HttpResponse?

    public init(sdkHttpResponse: HttpResponse? = nil) {
        self.sdkHttpResponse = sdkHttpResponse
    }
}

/// A single example for tuning. This data type is not supported in Vertex AI.
public struct TuningExample: Codable, Sendable {
    /// Required. The expected model output.
    public var output: String?
    /// Optional. Text model input.
    public var textInput: String?

    public init(output: String? = nil, textInput: String? = nil) {
        self.output = output
        self.textInput = textInput
    }
}

/// Supervised fine-tuning training dataset.
public struct TuningDataset: Codable, Sendable {
    /// GCS URI of the file containing training dataset in JSONL format.
    public var gcsUri: String?
    /// The resource name of the Vertex Multimodal Dataset used as the training dataset.
    public var vertexDatasetResource: String?
    /// Inline examples with simple input/output text.
    public var examples: [TuningExample]?

    public init(
        gcsUri: String? = nil,
        vertexDatasetResource: String? = nil,
        examples: [TuningExample]? = nil
    ) {
        self.gcsUri = gcsUri
        self.vertexDatasetResource = vertexDatasetResource
        self.examples = examples
    }
}

public struct TuningValidationDataset: Codable, Sendable {
    /// GCS URI of the file containing validation dataset in JSONL format.
    public var gcsUri: String?
    /// The resource name of the Vertex Multimodal Dataset used as the validation dataset.
    public var vertexDatasetResource: String?

    public init(gcsUri: String? = nil, vertexDatasetResource: String? = nil) {
        self.gcsUri = gcsUri
        self.vertexDatasetResource = vertexDatasetResource
    }
}

/// Fine-tuning job creation request - optional fields.
public struct CreateTuningJobConfig: Codable, Sendable {
    public var httpOptions: HttpOptions?
    public var abortSignal: AbortSignal?
    /// The method to use for tuning.
    public var method: TuningMethod?
    /// Validation dataset for tuning.
    public var validationDataset: TuningValidationDataset?
    /// The display name of the tuned Model.
    public var tunedModelDisplayName: String?
    /// The description of the TuningJob.
    public var description: String?
    /// Number of complete passes the model makes over the entire training dataset during training.
    public var epochCount: Double?
    /// Multiplier for adjusting the default learning rate. 1P models only.
    public var learningRateMultiplier: Double?
    /// If set to true, disable intermediate checkpoints and only the last checkpoint will be exported.
    public var exportLastCheckpointOnly: Bool?
    /// The optional checkpoint id of the pre-tuned model.
    public var preTunedModelCheckpointId: String?
    /// Adapter size for tuning.
    public var adapterSize: AdapterSize?
    /// Tuning mode for tuning.
    public var tuningMode: TuningMode?
    /// Custom base model for tuning.
    public var customBaseModel: String?
    /// The batch size hyperparameter for tuning. OSS models only.
    public var batchSize: Double?
    /// The learning rate for tuning. OSS models only.
    public var learningRate: Double?
    /// Optional. The labels with user-defined metadata.
    public var labels: [String: String]?
    /// Weight for KL Divergence regularization, Preference Optimization tuning only.
    public var beta: Double?
    /// The base teacher model that is being distilled. Distillation only.
    public var baseTeacherModel: String?
    /// The resource name of the Tuned teacher model. Distillation only.
    public var tunedTeacherModelSource: String?
    /// Multiplier for adjusting the weight of the SFT loss. Distillation only.
    public var sftLossWeightMultiplier: Double?
    /// The Google Cloud Storage location where the tuning job outputs are written.
    public var outputUri: String?
    /// The encryption spec of the tuning job.
    public var encryptionSpec: EncryptionSpec?

    public init(
        httpOptions: HttpOptions? = nil,
        abortSignal: AbortSignal? = nil,
        method: TuningMethod? = nil,
        validationDataset: TuningValidationDataset? = nil,
        tunedModelDisplayName: String? = nil,
        description: String? = nil,
        epochCount: Double? = nil,
        learningRateMultiplier: Double? = nil,
        exportLastCheckpointOnly: Bool? = nil,
        preTunedModelCheckpointId: String? = nil,
        adapterSize: AdapterSize? = nil,
        tuningMode: TuningMode? = nil,
        customBaseModel: String? = nil,
        batchSize: Double? = nil,
        learningRate: Double? = nil,
        labels: [String: String]? = nil,
        beta: Double? = nil,
        baseTeacherModel: String? = nil,
        tunedTeacherModelSource: String? = nil,
        sftLossWeightMultiplier: Double? = nil,
        outputUri: String? = nil,
        encryptionSpec: EncryptionSpec? = nil
    ) {
        self.httpOptions = httpOptions
        self.abortSignal = abortSignal
        self.method = method
        self.validationDataset = validationDataset
        self.tunedModelDisplayName = tunedModelDisplayName
        self.description = description
        self.epochCount = epochCount
        self.learningRateMultiplier = learningRateMultiplier
        self.exportLastCheckpointOnly = exportLastCheckpointOnly
        self.preTunedModelCheckpointId = preTunedModelCheckpointId
        self.adapterSize = adapterSize
        self.tuningMode = tuningMode
        self.customBaseModel = customBaseModel
        self.batchSize = batchSize
        self.learningRate = learningRate
        self.labels = labels
        self.beta = beta
        self.baseTeacherModel = baseTeacherModel
        self.tunedTeacherModelSource = tunedTeacherModelSource
        self.sftLossWeightMultiplier = sftLossWeightMultiplier
        self.outputUri = outputUri
        self.encryptionSpec = encryptionSpec
    }
}

/// Fine-tuning job creation parameters - optional fields.
internal struct CreateTuningJobParametersPrivate: Codable, Sendable {
    /// The base model that is being tuned, e.g., "gemini-2.5-flash".
    public var baseModel: String?
    /// The PreTunedModel that is being tuned.
    public var preTunedModel: PreTunedModel?
    /// Cloud Storage path to file containing training dataset for tuning.
    public var trainingDataset: TuningDataset
    /// Configuration for the tuning job.
    public var config: CreateTuningJobConfig?

    public init(
        baseModel: String? = nil,
        preTunedModel: PreTunedModel? = nil,
        trainingDataset: TuningDataset,
        config: CreateTuningJobConfig? = nil
    ) {
        self.baseModel = baseModel
        self.preTunedModel = preTunedModel
        self.trainingDataset = trainingDataset
        self.config = config
    }
}

/// A long-running operation.
public struct TuningOperation: Codable, Sendable {
    /// Used to retain the full HTTP response.
    public var sdkHttpResponse: HttpResponse?
    /// The server-assigned name.
    public var name: String?
    /// Service-specific metadata associated with the operation.
    public var metadata: [String: JSONValue]?
    /// If the value is `false`, the operation is still in progress.
    public var done: Bool?
    /// The error result of the operation in case of failure or cancellation.
    public var error: [String: JSONValue]?

    public init(
        sdkHttpResponse: HttpResponse? = nil,
        name: String? = nil,
        metadata: [String: JSONValue]? = nil,
        done: Bool? = nil,
        error: [String: JSONValue]? = nil
    ) {
        self.sdkHttpResponse = sdkHttpResponse
        self.name = name
        self.metadata = metadata
        self.done = done
        self.error = error
    }
}
