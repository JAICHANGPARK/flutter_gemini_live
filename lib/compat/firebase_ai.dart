/// Drop-in replacement for the Live API of `package:firebase_ai`.
///
/// Exposes the same class names and signatures as firebase_ai 4.x, backed by
/// the gemini_live WebSocket engine, without Firebase setup. Moving between
/// the two packages takes two edits:
///
/// ```dart
/// // firebase_ai
/// import 'package:firebase_ai/firebase_ai.dart';
/// await Firebase.initializeApp();
///
/// // gemini_live
/// import 'package:gemini_live/compat/firebase_ai.dart';
/// FirebaseAI.initialize(apiKey: 'YOUR_GEMINI_API_KEY');
/// ```
///
/// Everything from `FirebaseAI.googleAI().liveGenerativeModel(...)` onward is
/// shared. Members of [GeminiLiveSessionExtras] and [GeminiLiveResponseExtras]
/// are gemini_live only.
///
/// This library does not export the core `package:gemini_live/gemini_live.dart`
/// API, whose `Content`, `Part`, `Tool` and `LiveSession` types differ. Import
/// that library with a prefix if both are needed in one file.
library;

export '../src/compat/firebase_ai/content.dart'
    show
        CodeExecutionResultPart,
        Content,
        ExecutableCodePart,
        FileData,
        FunctionCall,
        FunctionResponse,
        InlineDataPart,
        Part,
        TextPart,
        UnknownPart;
export '../src/compat/firebase_ai/live_api.dart'
    show
        ActivityDetectionConfig,
        ActivityHandling,
        AudioTranscriptionConfig,
        ContextWindowCompressionConfig,
        FirebaseAIException,
        FirebaseAISdkException,
        GoingAwayNotice,
        InvalidApiKey,
        LiveGenerationConfig,
        LiveServerContent,
        LiveServerMessage,
        LiveServerResponse,
        LiveServerToolCall,
        LiveServerToolCallCancellation,
        MediaResolution,
        MultiSpeakerVoiceConfig,
        QuotaExceeded,
        RealtimeInputConfig,
        ResponseModalities,
        Sensitivity,
        ServerException,
        ServiceApiNotEnabled,
        SessionResumptionConfig,
        SessionResumptionUpdate,
        SlidingWindow,
        SpeakerVoiceConfig,
        SpeechConfig,
        Transcription,
        TurnCoverage,
        UnsupportedUserLocation;
export '../src/compat/firebase_ai/live_session.dart'
    show
        FirebaseAI,
        GeminiLiveResponseExtras,
        GeminiLiveSessionExtras,
        LiveGenerativeModel,
        LiveSession;
export '../src/compat/firebase_ai/schema.dart'
    show JSONSchema, Schema, SchemaType;
export '../src/compat/firebase_ai/tool.dart'
    show
        AutoFunctionDeclaration,
        CodeExecution,
        FunctionDeclaration,
        GoogleMaps,
        GoogleSearch,
        Tool,
        UrlContext;
export '../src/utils/token_usage_tracker.dart' show GeminiTokenUsageTracker;
export '../src/model/models.dart' show GeminiLiveVoice;
