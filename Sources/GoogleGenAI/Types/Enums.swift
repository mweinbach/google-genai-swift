// Copyright 2025 Google LLC
// SPDX-License-Identifier: Apache-2.0

import Foundation

/// Programming language of the `code`.
public enum Language: String, Codable, Sendable {
    case languageUnspecified = "LANGUAGE_UNSPECIFIED"
    case python = "PYTHON"
}

/// Outcome of the code execution.
public enum Outcome: String, Codable, Sendable {
    case outcomeUnspecified = "OUTCOME_UNSPECIFIED"
    case outcomeOk = "OUTCOME_OK"
    case outcomeFailed = "OUTCOME_FAILED"
    case outcomeDeadlineExceeded = "OUTCOME_DEADLINE_EXCEEDED"
}

/// Specifies how the response should be scheduled in the conversation.
public enum FunctionResponseScheduling: String, Codable, Sendable {
    case schedulingUnspecified = "SCHEDULING_UNSPECIFIED"
    case silent = "SILENT"
    case whenIdle = "WHEN_IDLE"
    case interrupt = "INTERRUPT"
}

/// Data type of the schema field.
public enum `Type`: String, Codable, Sendable {
    case typeUnspecified = "TYPE_UNSPECIFIED"
    case string = "STRING"
    case number = "NUMBER"
    case integer = "INTEGER"
    case boolean = "BOOLEAN"
    case array = "ARRAY"
    case object = "OBJECT"
    case null = "NULL"
}

/// The environment being operated.
public enum Environment: String, Codable, Sendable {
    case environmentUnspecified = "ENVIRONMENT_UNSPECIFIED"
    case environmentBrowser = "ENVIRONMENT_BROWSER"
}

/// Type of auth scheme. This enum is not supported in Gemini API.
public enum AuthType: String, Codable, Sendable {
    case authTypeUnspecified = "AUTH_TYPE_UNSPECIFIED"
    case noAuth = "NO_AUTH"
    case apiKeyAuth = "API_KEY_AUTH"
    case httpBasicAuth = "HTTP_BASIC_AUTH"
    case googleServiceAccountAuth = "GOOGLE_SERVICE_ACCOUNT_AUTH"
    case oauth = "OAUTH"
    case oidcAuth = "OIDC_AUTH"
}

/// The location of the API key. This enum is not supported in Gemini API.
public enum HttpElementLocation: String, Codable, Sendable {
    case httpInUnspecified = "HTTP_IN_UNSPECIFIED"
    case httpInQuery = "HTTP_IN_QUERY"
    case httpInHeader = "HTTP_IN_HEADER"
    case httpInPath = "HTTP_IN_PATH"
    case httpInBody = "HTTP_IN_BODY"
    case httpInCookie = "HTTP_IN_COOKIE"
}

/// The API spec that the external API implements. This enum is not supported in Gemini API.
public enum ApiSpec: String, Codable, Sendable {
    case apiSpecUnspecified = "API_SPEC_UNSPECIFIED"
    case simpleSearch = "SIMPLE_SEARCH"
    case elasticSearch = "ELASTIC_SEARCH"
}

/// Sites with confidence level chosen & above this value will be blocked from the search results. This enum is not supported in Gemini API.
public enum PhishBlockThreshold: String, Codable, Sendable {
    case phishBlockThresholdUnspecified = "PHISH_BLOCK_THRESHOLD_UNSPECIFIED"
    case blockLowAndAbove = "BLOCK_LOW_AND_ABOVE"
    case blockMediumAndAbove = "BLOCK_MEDIUM_AND_ABOVE"
    case blockHighAndAbove = "BLOCK_HIGH_AND_ABOVE"
    case blockHigherAndAbove = "BLOCK_HIGHER_AND_ABOVE"
    case blockVeryHighAndAbove = "BLOCK_VERY_HIGH_AND_ABOVE"
    case blockOnlyExtremelyHigh = "BLOCK_ONLY_EXTREMELY_HIGH"
}

/// Specifies the function Behavior. Currently only non-blocking functions are supported. If not specified, the system keeps the current function call behavior. This field is currently only supported by the BidiGenerateContent method.
public enum Behavior: String, Codable, Sendable {
    case unspecified = "UNSPECIFIED"
    case blocking = "BLOCKING"
    case nonBlocking = "NON_BLOCKING"
}

/// The mode of the predictor to be used in dynamic retrieval.
public enum DynamicRetrievalConfigMode: String, Codable, Sendable {
    case modeUnspecified = "MODE_UNSPECIFIED"
    case modeDynamic = "MODE_DYNAMIC"
}

/// Function calling mode.
public enum FunctionCallingConfigMode: String, Codable, Sendable {
    case modeUnspecified = "MODE_UNSPECIFIED"
    case auto = "AUTO"
    case any = "ANY"
    case none = "NONE"
    case validated = "VALIDATED"
}

/// The number of thoughts tokens that the model should generate.
public enum ThinkingLevel: String, Codable, Sendable {
    case thinkingLevelUnspecified = "THINKING_LEVEL_UNSPECIFIED"
    case minimal = "MINIMAL"
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
}

/// Enum that controls the generation of people.
public enum PersonGeneration: String, Codable, Sendable {
    case dontAllow = "DONT_ALLOW"
    case allowAdult = "ALLOW_ADULT"
    case allowAll = "ALLOW_ALL"
}

/// Controls whether prominent people (celebrities) generation is allowed. If used with personGeneration, personGeneration enum would take precedence. For instance, if ALLOW_NONE is set, all person generation would be blocked. If this field is unspecified, the default behavior is to allow prominent people. This enum is not supported in Gemini API.
public enum ProminentPeople: String, Codable, Sendable {
    case prominentPeopleUnspecified = "PROMINENT_PEOPLE_UNSPECIFIED"
    case allowProminentPeople = "ALLOW_PROMINENT_PEOPLE"
    case blockProminentPeople = "BLOCK_PROMINENT_PEOPLE"
}

/// The harm category to be blocked.
public enum HarmCategory: String, Codable, Sendable {
    case harmCategoryUnspecified = "HARM_CATEGORY_UNSPECIFIED"
    case harmCategoryHarassment = "HARM_CATEGORY_HARASSMENT"
    case harmCategoryHateSpeech = "HARM_CATEGORY_HATE_SPEECH"
    case harmCategorySexuallyExplicit = "HARM_CATEGORY_SEXUALLY_EXPLICIT"
    case harmCategoryDangerousContent = "HARM_CATEGORY_DANGEROUS_CONTENT"
    case harmCategoryCivicIntegrity = "HARM_CATEGORY_CIVIC_INTEGRITY"
    case harmCategoryImageHate = "HARM_CATEGORY_IMAGE_HATE"
    case harmCategoryImageDangerousContent = "HARM_CATEGORY_IMAGE_DANGEROUS_CONTENT"
    case harmCategoryImageHarassment = "HARM_CATEGORY_IMAGE_HARASSMENT"
    case harmCategoryImageSexuallyExplicit = "HARM_CATEGORY_IMAGE_SEXUALLY_EXPLICIT"
    case harmCategoryJailbreak = "HARM_CATEGORY_JAILBREAK"
}

/// The method for blocking content. If not specified, the default behavior is to use the probability score. This enum is not supported in Gemini API.
public enum HarmBlockMethod: String, Codable, Sendable {
    case harmBlockMethodUnspecified = "HARM_BLOCK_METHOD_UNSPECIFIED"
    case severity = "SEVERITY"
    case probability = "PROBABILITY"
}

/// The threshold for blocking content. If the harm probability exceeds this threshold, the content will be blocked.
public enum HarmBlockThreshold: String, Codable, Sendable {
    case harmBlockThresholdUnspecified = "HARM_BLOCK_THRESHOLD_UNSPECIFIED"
    case blockLowAndAbove = "BLOCK_LOW_AND_ABOVE"
    case blockMediumAndAbove = "BLOCK_MEDIUM_AND_ABOVE"
    case blockOnlyHigh = "BLOCK_ONLY_HIGH"
    case blockNone = "BLOCK_NONE"
    case off = "OFF"
}

/// Output only. The reason why the model stopped generating tokens. If empty, the model has not stopped generating the tokens.
public enum FinishReason: String, Codable, Sendable {
    case finishReasonUnspecified = "FINISH_REASON_UNSPECIFIED"
    case stop = "STOP"
    case maxTokens = "MAX_TOKENS"
    case safety = "SAFETY"
    case recitation = "RECITATION"
    case language = "LANGUAGE"
    case other = "OTHER"
    case blocklist = "BLOCKLIST"
    case prohibitedContent = "PROHIBITED_CONTENT"
    case spii = "SPII"
    case malformedFunctionCall = "MALFORMED_FUNCTION_CALL"
    case imageSafety = "IMAGE_SAFETY"
    case unexpectedToolCall = "UNEXPECTED_TOOL_CALL"
    case imageProhibitedContent = "IMAGE_PROHIBITED_CONTENT"
    case noImage = "NO_IMAGE"
    case imageRecitation = "IMAGE_RECITATION"
    case imageOther = "IMAGE_OTHER"
}

/// Output only. The probability of harm for this category.
public enum HarmProbability: String, Codable, Sendable {
    case harmProbabilityUnspecified = "HARM_PROBABILITY_UNSPECIFIED"
    case negligible = "NEGLIGIBLE"
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
}

/// Output only. The severity of harm for this category. This enum is not supported in Gemini API.
public enum HarmSeverity: String, Codable, Sendable {
    case harmSeverityUnspecified = "HARM_SEVERITY_UNSPECIFIED"
    case harmSeverityNegligible = "HARM_SEVERITY_NEGLIGIBLE"
    case harmSeverityLow = "HARM_SEVERITY_LOW"
    case harmSeverityMedium = "HARM_SEVERITY_MEDIUM"
    case harmSeverityHigh = "HARM_SEVERITY_HIGH"
}

/// The status of the URL retrieval.
public enum UrlRetrievalStatus: String, Codable, Sendable {
    case urlRetrievalStatusUnspecified = "URL_RETRIEVAL_STATUS_UNSPECIFIED"
    case urlRetrievalStatusSuccess = "URL_RETRIEVAL_STATUS_SUCCESS"
    case urlRetrievalStatusError = "URL_RETRIEVAL_STATUS_ERROR"
    case urlRetrievalStatusPaywall = "URL_RETRIEVAL_STATUS_PAYWALL"
    case urlRetrievalStatusUnsafe = "URL_RETRIEVAL_STATUS_UNSAFE"
}

/// Output only. The reason why the prompt was blocked.
public enum BlockedReason: String, Codable, Sendable {
    case blockedReasonUnspecified = "BLOCKED_REASON_UNSPECIFIED"
    case safety = "SAFETY"
    case other = "OTHER"
    case blocklist = "BLOCKLIST"
    case prohibitedContent = "PROHIBITED_CONTENT"
    case imageSafety = "IMAGE_SAFETY"
    case modelArmor = "MODEL_ARMOR"
    case jailbreak = "JAILBREAK"
}

/// Output only. The traffic type for this request. This enum is not supported in Gemini API.
public enum TrafficType: String, Codable, Sendable {
    case trafficTypeUnspecified = "TRAFFIC_TYPE_UNSPECIFIED"
    case onDemand = "ON_DEMAND"
    case onDemandPriority = "ON_DEMAND_PRIORITY"
    case onDemandFlex = "ON_DEMAND_FLEX"
    case provisionedThroughput = "PROVISIONED_THROUGHPUT"
}

/// Server content modalities.
public enum Modality: String, Codable, Sendable {
    case modalityUnspecified = "MODALITY_UNSPECIFIED"
    case text = "TEXT"
    case image = "IMAGE"
    case audio = "AUDIO"
    case video = "VIDEO"
}

/// The stage of the underlying model. This enum is not supported in Vertex AI.
public enum ModelStage: String, Codable, Sendable {
    case modelStageUnspecified = "MODEL_STAGE_UNSPECIFIED"
    case unstableExperimental = "UNSTABLE_EXPERIMENTAL"
    case experimental = "EXPERIMENTAL"
    case preview = "PREVIEW"
    case stable = "STABLE"
    case legacy = "LEGACY"
    case deprecated = "DEPRECATED"
    case retired = "RETIRED"
}

/// The media resolution to use.
public enum MediaResolution: String, Codable, Sendable {
    case mediaResolutionUnspecified = "MEDIA_RESOLUTION_UNSPECIFIED"
    case mediaResolutionLow = "MEDIA_RESOLUTION_LOW"
    case mediaResolutionMedium = "MEDIA_RESOLUTION_MEDIUM"
    case mediaResolutionHigh = "MEDIA_RESOLUTION_HIGH"
}

/// Tuning mode. This enum is not supported in Gemini API.
public enum TuningMode: String, Codable, Sendable {
    case tuningModeUnspecified = "TUNING_MODE_UNSPECIFIED"
    case tuningModeFull = "TUNING_MODE_FULL"
    case tuningModePeftAdapter = "TUNING_MODE_PEFT_ADAPTER"
}

/// Adapter size for tuning. This enum is not supported in Gemini API.
public enum AdapterSize: String, Codable, Sendable {
    case adapterSizeUnspecified = "ADAPTER_SIZE_UNSPECIFIED"
    case adapterSizeOne = "ADAPTER_SIZE_ONE"
    case adapterSizeTwo = "ADAPTER_SIZE_TWO"
    case adapterSizeFour = "ADAPTER_SIZE_FOUR"
    case adapterSizeEight = "ADAPTER_SIZE_EIGHT"
    case adapterSizeSixteen = "ADAPTER_SIZE_SIXTEEN"
    case adapterSizeThirtyTwo = "ADAPTER_SIZE_THIRTY_TWO"
}

/// Job state.
public enum JobState: String, Codable, Sendable {
    case jobStateUnspecified = "JOB_STATE_UNSPECIFIED"
    case jobStateQueued = "JOB_STATE_QUEUED"
    case jobStatePending = "JOB_STATE_PENDING"
    case jobStateRunning = "JOB_STATE_RUNNING"
    case jobStateSucceeded = "JOB_STATE_SUCCEEDED"
    case jobStateFailed = "JOB_STATE_FAILED"
    case jobStateCancelling = "JOB_STATE_CANCELLING"
    case jobStateCancelled = "JOB_STATE_CANCELLED"
    case jobStatePaused = "JOB_STATE_PAUSED"
    case jobStateExpired = "JOB_STATE_EXPIRED"
    case jobStateUpdating = "JOB_STATE_UPDATING"
    case jobStatePartiallySucceeded = "JOB_STATE_PARTIALLY_SUCCEEDED"
}

/// Output only. The detail state of the tuning job (while the overall `JobState` is running). This enum is not supported in Gemini API.
public enum TuningJobState: String, Codable, Sendable {
    case tuningJobStateUnspecified = "TUNING_JOB_STATE_UNSPECIFIED"
    case tuningJobStateWaitingForQuota = "TUNING_JOB_STATE_WAITING_FOR_QUOTA"
    case tuningJobStateProcessingDataset = "TUNING_JOB_STATE_PROCESSING_DATASET"
    case tuningJobStateWaitingForCapacity = "TUNING_JOB_STATE_WAITING_FOR_CAPACITY"
    case tuningJobStateTuning = "TUNING_JOB_STATE_TUNING"
    case tuningJobStatePostProcessing = "TUNING_JOB_STATE_POST_PROCESSING"
}

/// Aggregation metric. This enum is not supported in Gemini API.
public enum AggregationMetric: String, Codable, Sendable {
    case aggregationMetricUnspecified = "AGGREGATION_METRIC_UNSPECIFIED"
    case average = "AVERAGE"
    case mode = "MODE"
    case standardDeviation = "STANDARD_DEVIATION"
    case variance = "VARIANCE"
    case minimum = "MINIMUM"
    case maximum = "MAXIMUM"
    case median = "MEDIAN"
    case percentileP90 = "PERCENTILE_P90"
    case percentileP95 = "PERCENTILE_P95"
    case percentileP99 = "PERCENTILE_P99"
}

/// Output only. Pairwise metric choice. This enum is not supported in Gemini API.
public enum PairwiseChoice: String, Codable, Sendable {
    case pairwiseChoiceUnspecified = "PAIRWISE_CHOICE_UNSPECIFIED"
    case baseline = "BASELINE"
    case candidate = "CANDIDATE"
    case tie = "TIE"
}

/// The tuning task. Either I2V or T2V. This enum is not supported in Gemini API.
public enum TuningTask: String, Codable, Sendable {
    case tuningTaskUnspecified = "TUNING_TASK_UNSPECIFIED"
    case tuningTaskI2v = "TUNING_TASK_I2V"
    case tuningTaskT2v = "TUNING_TASK_T2V"
    case tuningTaskR2v = "TUNING_TASK_R2V"
}

/// Output only. Current state of the `Document`. This enum is not supported in Vertex AI.
public enum DocumentState: String, Codable, Sendable {
    case stateUnspecified = "STATE_UNSPECIFIED"
    case statePending = "STATE_PENDING"
    case stateActive = "STATE_ACTIVE"
    case stateFailed = "STATE_FAILED"
}

/// The tokenization quality used for given media.
public enum PartMediaResolutionLevel: String, Codable, Sendable {
    case mediaResolutionUnspecified = "MEDIA_RESOLUTION_UNSPECIFIED"
    case mediaResolutionLow = "MEDIA_RESOLUTION_LOW"
    case mediaResolutionMedium = "MEDIA_RESOLUTION_MEDIUM"
    case mediaResolutionHigh = "MEDIA_RESOLUTION_HIGH"
    case mediaResolutionUltraHigh = "MEDIA_RESOLUTION_ULTRA_HIGH"
}

/// The type of tool in the function call.
public enum ToolType: String, Codable, Sendable {
    case toolTypeUnspecified = "TOOL_TYPE_UNSPECIFIED"
    case googleSearchWeb = "GOOGLE_SEARCH_WEB"
    case googleSearchImage = "GOOGLE_SEARCH_IMAGE"
    case urlContext = "URL_CONTEXT"
    case googleMaps = "GOOGLE_MAPS"
    case fileSearch = "FILE_SEARCH"
}

/// Resource scope.
public enum ResourceScope: String, Codable, Sendable {
    case collection = "COLLECTION"
}

/// Pricing and performance service tier.
public enum ServiceTier: String, Codable, Sendable {
    case unspecified = "unspecified"
    case flex = "flex"
    case standard = "standard"
    case priority = "priority"
}

/// Options for feature selection preference.
public enum FeatureSelectionPreference: String, Codable, Sendable {
    case featureSelectionPreferenceUnspecified = "FEATURE_SELECTION_PREFERENCE_UNSPECIFIED"
    case prioritizeQuality = "PRIORITIZE_QUALITY"
    case balanced = "BALANCED"
    case prioritizeCost = "PRIORITIZE_COST"
}

/// Enum representing the Gemini Enterprise Agent Platform embedding API to use.
public enum EmbeddingApiType: String, Codable, Sendable {
    case predict = "PREDICT"
    case embedContent = "EMBED_CONTENT"
}

/// Enum that controls the safety filter level for objectionable content.
public enum SafetyFilterLevel: String, Codable, Sendable {
    case blockLowAndAbove = "BLOCK_LOW_AND_ABOVE"
    case blockMediumAndAbove = "BLOCK_MEDIUM_AND_ABOVE"
    case blockOnlyHigh = "BLOCK_ONLY_HIGH"
    case blockNone = "BLOCK_NONE"
}

/// Enum that specifies the language of the text in the prompt.
public enum ImagePromptLanguage: String, Codable, Sendable {
    case auto = "auto"
    case en = "en"
    case ja = "ja"
    case ko = "ko"
    case hi = "hi"
    case zh = "zh"
    case pt = "pt"
    case es = "es"
}

/// Enum representing the mask mode of a mask reference image.
public enum MaskReferenceMode: String, Codable, Sendable {
    case maskModeDefault = "MASK_MODE_DEFAULT"
    case maskModeUserProvided = "MASK_MODE_USER_PROVIDED"
    case maskModeBackground = "MASK_MODE_BACKGROUND"
    case maskModeForeground = "MASK_MODE_FOREGROUND"
    case maskModeSemantic = "MASK_MODE_SEMANTIC"
}

/// Enum representing the control type of a control reference image.
public enum ControlReferenceType: String, Codable, Sendable {
    case controlTypeDefault = "CONTROL_TYPE_DEFAULT"
    case controlTypeCanny = "CONTROL_TYPE_CANNY"
    case controlTypeScribble = "CONTROL_TYPE_SCRIBBLE"
    case controlTypeFaceMesh = "CONTROL_TYPE_FACE_MESH"
}

/// Enum representing the subject type of a subject reference image.
public enum SubjectReferenceType: String, Codable, Sendable {
    case subjectTypeDefault = "SUBJECT_TYPE_DEFAULT"
    case subjectTypePerson = "SUBJECT_TYPE_PERSON"
    case subjectTypeAnimal = "SUBJECT_TYPE_ANIMAL"
    case subjectTypeProduct = "SUBJECT_TYPE_PRODUCT"
}

/// Enum representing the editing mode.
public enum EditMode: String, Codable, Sendable {
    case editModeDefault = "EDIT_MODE_DEFAULT"
    case editModeInpaintRemoval = "EDIT_MODE_INPAINT_REMOVAL"
    case editModeInpaintInsertion = "EDIT_MODE_INPAINT_INSERTION"
    case editModeOutpaint = "EDIT_MODE_OUTPAINT"
    case editModeControlledEditing = "EDIT_MODE_CONTROLLED_EDITING"
    case editModeStyle = "EDIT_MODE_STYLE"
    case editModeBgswap = "EDIT_MODE_BGSWAP"
    case editModeProductImage = "EDIT_MODE_PRODUCT_IMAGE"
}

/// Enum that represents the segmentation mode.
public enum SegmentMode: String, Codable, Sendable {
    case foreground = "FOREGROUND"
    case background = "BACKGROUND"
    case prompt = "PROMPT"
    case semantic = "SEMANTIC"
    case interactive = "INTERACTIVE"
}

/// Enum for the reference type of a video generation reference image.
public enum VideoGenerationReferenceType: String, Codable, Sendable {
    case asset = "ASSET"
    case style = "STYLE"
}

/// Enum for the mask mode of a video generation mask.
public enum VideoGenerationMaskMode: String, Codable, Sendable {
    case insert = "INSERT"
    case remove = "REMOVE"
    case removeStatic = "REMOVE_STATIC"
    case outpaint = "OUTPAINT"
}

/// Enum that controls the compression quality of the generated videos.
public enum VideoCompressionQuality: String, Codable, Sendable {
    case optimized = "OPTIMIZED"
    case lossless = "LOSSLESS"
}

/// Resize mode for the image input for video generation.
public enum ImageResizeMode: String, Codable, Sendable {
    case crop = "CROP"
    case pad = "PAD"
}

/// Enum representing the tuning method.
public enum TuningMethod: String, Codable, Sendable {
    case supervisedFineTuning = "SUPERVISED_FINE_TUNING"
    case preferenceTuning = "PREFERENCE_TUNING"
    case distillation = "DISTILLATION"
}

/// State for the lifecycle of a File.
public enum FileState: String, Codable, Sendable {
    case stateUnspecified = "STATE_UNSPECIFIED"
    case processing = "PROCESSING"
    case active = "ACTIVE"
    case failed = "FAILED"
}

/// Source of the File.
public enum FileSource: String, Codable, Sendable {
    case sourceUnspecified = "SOURCE_UNSPECIFIED"
    case uploaded = "UPLOADED"
    case generated = "GENERATED"
    case registered = "REGISTERED"
}

/// The reason why the turn is complete.
public enum TurnCompleteReason: String, Codable, Sendable {
    case turnCompleteReasonUnspecified = "TURN_COMPLETE_REASON_UNSPECIFIED"
    case malformedFunctionCall = "MALFORMED_FUNCTION_CALL"
    case responseRejected = "RESPONSE_REJECTED"
    case needMoreInput = "NEED_MORE_INPUT"
    case prohibitedInputContent = "PROHIBITED_INPUT_CONTENT"
    case imageProhibitedInputContent = "IMAGE_PROHIBITED_INPUT_CONTENT"
    case inputTextContainProminentPersonProhibited = "INPUT_TEXT_CONTAIN_PROMINENT_PERSON_PROHIBITED"
    case inputImageCelebrity = "INPUT_IMAGE_CELEBRITY"
    case inputImagePhotoRealisticChildProhibited = "INPUT_IMAGE_PHOTO_REALISTIC_CHILD_PROHIBITED"
    case inputTextNciiProhibited = "INPUT_TEXT_NCII_PROHIBITED"
    case inputOther = "INPUT_OTHER"
    case inputIpProhibited = "INPUT_IP_PROHIBITED"
    case blocklist = "BLOCKLIST"
    case unsafePromptForImageGeneration = "UNSAFE_PROMPT_FOR_IMAGE_GENERATION"
    case generatedImageSafety = "GENERATED_IMAGE_SAFETY"
    case generatedContentSafety = "GENERATED_CONTENT_SAFETY"
    case generatedAudioSafety = "GENERATED_AUDIO_SAFETY"
    case generatedVideoSafety = "GENERATED_VIDEO_SAFETY"
    case generatedContentProhibited = "GENERATED_CONTENT_PROHIBITED"
    case generatedContentBlocklist = "GENERATED_CONTENT_BLOCKLIST"
    case generatedImageProhibited = "GENERATED_IMAGE_PROHIBITED"
    case generatedImageCelebrity = "GENERATED_IMAGE_CELEBRITY"
    case generatedImageProminentPeopleDetectedByRewriter = "GENERATED_IMAGE_PROMINENT_PEOPLE_DETECTED_BY_REWRITER"
    case generatedImageIdentifiablePeople = "GENERATED_IMAGE_IDENTIFIABLE_PEOPLE"
    case generatedImageMinors = "GENERATED_IMAGE_MINORS"
    case outputImageIpProhibited = "OUTPUT_IMAGE_IP_PROHIBITED"
    case generatedOther = "GENERATED_OTHER"
    case maxRegenerationReached = "MAX_REGENERATION_REACHED"
}

/// Server content modalities.
public enum MediaModality: String, Codable, Sendable {
    case modalityUnspecified = "MODALITY_UNSPECIFIED"
    case text = "TEXT"
    case image = "IMAGE"
    case video = "VIDEO"
    case audio = "AUDIO"
    case document = "DOCUMENT"
}

/// The type of the VAD signal.
public enum VadSignalType: String, Codable, Sendable {
    case vadSignalTypeUnspecified = "VAD_SIGNAL_TYPE_UNSPECIFIED"
    case vadSignalTypeSos = "VAD_SIGNAL_TYPE_SOS"
    case vadSignalTypeEos = "VAD_SIGNAL_TYPE_EOS"
}

/// The type of the voice activity signal.
public enum VoiceActivityType: String, Codable, Sendable {
    case typeUnspecified = "TYPE_UNSPECIFIED"
    case activityStart = "ACTIVITY_START"
    case activityEnd = "ACTIVITY_END"
}

/// Start of speech sensitivity.
public enum StartSensitivity: String, Codable, Sendable {
    case startSensitivityUnspecified = "START_SENSITIVITY_UNSPECIFIED"
    case startSensitivityHigh = "START_SENSITIVITY_HIGH"
    case startSensitivityLow = "START_SENSITIVITY_LOW"
}

/// End of speech sensitivity.
public enum EndSensitivity: String, Codable, Sendable {
    case endSensitivityUnspecified = "END_SENSITIVITY_UNSPECIFIED"
    case endSensitivityHigh = "END_SENSITIVITY_HIGH"
    case endSensitivityLow = "END_SENSITIVITY_LOW"
}

/// The different ways of handling user activity.
public enum ActivityHandling: String, Codable, Sendable {
    case activityHandlingUnspecified = "ACTIVITY_HANDLING_UNSPECIFIED"
    case startOfActivityInterrupts = "START_OF_ACTIVITY_INTERRUPTS"
    case noInterruption = "NO_INTERRUPTION"
}

/// Options about which input is included in the user's turn.
public enum TurnCoverage: String, Codable, Sendable {
    case turnCoverageUnspecified = "TURN_COVERAGE_UNSPECIFIED"
    case turnIncludesOnlyActivity = "TURN_INCLUDES_ONLY_ACTIVITY"
    case turnIncludesAllInput = "TURN_INCLUDES_ALL_INPUT"
    case turnIncludesAudioActivityAndAllVideo = "TURN_INCLUDES_AUDIO_ACTIVITY_AND_ALL_VIDEO"
}

/// Scale of the generated music.
public enum Scale: String, Codable, Sendable {
    case scaleUnspecified = "SCALE_UNSPECIFIED"
    case cMajorAMinor = "C_MAJOR_A_MINOR"
    case dFlatMajorBFlatMinor = "D_FLAT_MAJOR_B_FLAT_MINOR"
    case dMajorBMinor = "D_MAJOR_B_MINOR"
    case eFlatMajorCMinor = "E_FLAT_MAJOR_C_MINOR"
    case eMajorDFlatMinor = "E_MAJOR_D_FLAT_MINOR"
    case fMajorDMinor = "F_MAJOR_D_MINOR"
    case gFlatMajorEFlatMinor = "G_FLAT_MAJOR_E_FLAT_MINOR"
    case gMajorEMinor = "G_MAJOR_E_MINOR"
    case aFlatMajorFMinor = "A_FLAT_MAJOR_F_MINOR"
    case aMajorGFlatMinor = "A_MAJOR_G_FLAT_MINOR"
    case bFlatMajorGMinor = "B_FLAT_MAJOR_G_MINOR"
    case bMajorAFlatMinor = "B_MAJOR_A_FLAT_MINOR"
}

/// The mode of music generation.
public enum MusicGenerationMode: String, Codable, Sendable {
    case musicGenerationModeUnspecified = "MUSIC_GENERATION_MODE_UNSPECIFIED"
    case quality = "QUALITY"
    case diversity = "DIVERSITY"
    case vocalization = "VOCALIZATION"
}

/// The playback control signal to apply to the music generation.
public enum LiveMusicPlaybackControl: String, Codable, Sendable {
    case playbackControlUnspecified = "PLAYBACK_CONTROL_UNSPECIFIED"
    case play = "PLAY"
    case pause = "PAUSE"
    case stop = "STOP"
    case resetContext = "RESET_CONTEXT"
}
