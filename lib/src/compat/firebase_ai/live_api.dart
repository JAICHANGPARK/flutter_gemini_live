// API surface mirrors `package:firebase_ai` 4.x (Apache License 2.0,
// Copyright Google LLC) so that code can move between the two packages by
// swapping imports.

import '../../model/models.dart' show GeminiLiveVoice;
import 'content.dart';

// ============================================================================
// Generation config
// ============================================================================

/// The available response modalities.
enum ResponseModalities {
  /// Text response modality.
  text('TEXT'),

  /// Image response modality.
  image('IMAGE'),

  /// Audio response modality.
  audio('AUDIO');

  const ResponseModalities(this._jsonString);
  final String _jsonString;

  /// Convert this [ResponseModalities] to json format.
  String toJson() => _jsonString;
}

/// Media resolution for the input media.
enum MediaResolution {
  /// Media resolution has not been set.
  unspecified('MEDIA_RESOLUTION_UNSPECIFIED'),

  /// Media resolution set to low (64 tokens).
  low('MEDIA_RESOLUTION_LOW'),

  /// Media resolution set to medium (256 tokens).
  medium('MEDIA_RESOLUTION_MEDIUM'),

  /// Media resolution set to high (zoomed reframing with 256 tokens).
  high('MEDIA_RESOLUTION_HIGH'),

  /// Media resolution set to ultra high. Only supported on individual media
  /// parts.
  ultraHigh('MEDIA_RESOLUTION_ULTRA_HIGH');

  const MediaResolution(this._jsonString);
  final String _jsonString;

  /// Parse a media resolution from a JSON value.
  static MediaResolution parseValue(String value) => switch (value) {
        'MEDIA_RESOLUTION_LOW' => MediaResolution.low,
        'MEDIA_RESOLUTION_MEDIUM' => MediaResolution.medium,
        'MEDIA_RESOLUTION_HIGH' => MediaResolution.high,
        'MEDIA_RESOLUTION_ULTRA_HIGH' => MediaResolution.ultraHigh,
        _ => MediaResolution.unspecified,
      };

  /// Convert to json format.
  String toJson() => _jsonString;
}

/// Speech configuration class for setting the voice of the model.
class SpeechConfig {
  /// Creates a [SpeechConfig] instance for a single speaker.
  SpeechConfig({this.voiceName, this.languageCode})
      : multiSpeakerVoiceConfig = null;

  /// Creates a [SpeechConfig] instance from a [GeminiLiveVoice] enum.
  SpeechConfig.fromLiveVoice(GeminiLiveVoice voice, {this.languageCode})
      : voiceName = voice.voiceName,
        multiSpeakerVoiceConfig = null;

  /// Creates a [SpeechConfig] instance from a voice name, custom voice ID, or [GeminiLiveVoice].
  factory SpeechConfig.fromVoice(Object voice, {String? languageCode}) {
    final name = voice is GeminiLiveVoice ? voice.voiceName : voice.toString();
    return SpeechConfig(voiceName: name, languageCode: languageCode);
  }

  /// Creates a [SpeechConfig] instance for multiple speakers.
  SpeechConfig.multiSpeaker(
      {required this.multiSpeakerVoiceConfig, this.languageCode})
      : voiceName = null;

  /// The name of the voice to be used for the speech output.
  final String? voiceName;

  /// The configuration for multi-speaker setup.
  final MultiSpeakerVoiceConfig? multiSpeakerVoiceConfig;

  /// The language code (BCP-47) of the speech output.
  final String? languageCode;

  /// Returns the corresponding [GeminiLiveVoice] enum if matched.
  GeminiLiveVoice? get liveVoice => GeminiLiveVoice.fromName(voiceName);
}

/// The configuration for the multi-speaker setup.
class MultiSpeakerVoiceConfig {
  // ignore: public_member_api_docs
  MultiSpeakerVoiceConfig({required this.speakerVoiceConfigs});

  /// The configuration for each speaker.
  final List<SpeakerVoiceConfig> speakerVoiceConfigs;
}

/// The configuration for a single speaker in a multi speaker setup.
class SpeakerVoiceConfig {
  // ignore: public_member_api_docs
  SpeakerVoiceConfig({required this.speaker, required this.voiceName});

  /// The name of the speaker to use. Should be the same as in the prompt.
  final String speaker;

  /// The name of the voice to use.
  final String voiceName;
}

/// The audio transcription configuration.
class AudioTranscriptionConfig {
  // ignore: public_member_api_docs
  Map<String, Object?> toJson() => {};
}

/// Configures the sliding window context compression mechanism.
class SlidingWindow {
  /// Creates a [SlidingWindow] instance.
  SlidingWindow({this.targetTokens});

  /// The session reduction target, i.e., how many tokens we should keep.
  final int? targetTokens;
}

/// Enables context window compression to manage the model's context window.
class ContextWindowCompressionConfig {
  /// Creates a [ContextWindowCompressionConfig] instance.
  ContextWindowCompressionConfig({this.triggerTokens, this.slidingWindow});

  /// The number of tokens (before running a turn) that triggers the context
  /// window compression.
  final int? triggerTokens;

  /// The sliding window compression mechanism.
  final SlidingWindow? slidingWindow;
}

/// Configuration for the session resumption mechanism.
class SessionResumptionConfig {
  /// Creates a [SessionResumptionConfig] to start a new resumable session.
  SessionResumptionConfig() : handle = null;

  /// Creates a [SessionResumptionConfig] to resume a previous session.
  SessionResumptionConfig.resume(String this.handle);

  /// The session resumption handle of the previous session to restore.
  final String? handle;
}

/// Configures the realtime input behavior of the model.
final class RealtimeInputConfig {
  /// Creates a [RealtimeInputConfig] instance.
  RealtimeInputConfig({
    this.automaticActivityDetection,
    this.activityHandling,
    this.turnCoverage,
  });

  /// Configures automatic activity detection on the model.
  final ActivityDetectionConfig? automaticActivityDetection;

  /// Defines how the model treats user input activity.
  final ActivityHandling? activityHandling;

  /// Defines which input is included in the user's turn.
  final TurnCoverage? turnCoverage;
}

/// Configures automatic detection of user activity.
final class ActivityDetectionConfig {
  /// Creates an [ActivityDetectionConfig] instance.
  ActivityDetectionConfig({
    this.startSensitivity,
    this.endSensitivity,
    this.prefixPaddingMS,
    this.silenceDurationMS,
  }) : disabled = null;

  ActivityDetectionConfig._disabled()
      : startSensitivity = null,
        endSensitivity = null,
        prefixPaddingMS = null,
        silenceDurationMS = null,
        disabled = true;

  /// Disables automatic activity detection.
  factory ActivityDetectionConfig.disabled() =>
      ActivityDetectionConfig._disabled();

  /// Determines how likely the start of speech is detected.
  final Sensitivity? startSensitivity;

  /// Determines how likely the end of speech is detected.
  final Sensitivity? endSensitivity;

  /// How long detected speech should be present before start-of-speech is
  /// committed.
  final int? prefixPaddingMS;

  /// How long silence (or non-speech) should be present before end-of-speech
  /// is committed.
  final int? silenceDurationMS;

  /// Whether automatic activity detection is disabled.
  final bool? disabled;
}

/// The different ways of handling user activity.
enum ActivityHandling {
  /// The model's current response is cut off when user activity starts.
  interrupt('START_OF_ACTIVITY_INTERRUPTS'),

  /// The model keeps its current response when user activity starts.
  noInterrupt('NO_INTERRUPTION');

  const ActivityHandling(this.value);

  /// The JSON wire string value.
  final String value;
}

/// Options about which input is included in the user's turn.
enum TurnCoverage {
  /// The model excludes inactivity from the user's input.
  onlyActivity('TURN_INCLUDES_ONLY_ACTIVITY'),

  /// The model includes all input since the last turn.
  allInput('TURN_INCLUDES_ALL_INPUT'),

  /// Includes audio activity and all video since the last turn.
  audioActivityAndAllVideo('TURN_INCLUDES_AUDIO_ACTIVITY_AND_ALL_VIDEO');

  const TurnCoverage(this.value);

  /// The JSON wire string value.
  final String value;
}

/// Sensitivity of the automatic activity detection.
enum Sensitivity {
  /// The model will detect speech less often.
  low('SENSITIVITY_LOW'),

  /// The model will detect speech more often.
  high('SENSITIVITY_HIGH');

  const Sensitivity(this.value);

  /// The JSON wire string value.
  final String value;
}

/// Configuration options for live content generation.
final class LiveGenerationConfig {
  // ignore: public_member_api_docs
  LiveGenerationConfig({
    this.speechConfig,
    this.inputAudioTranscription,
    this.outputAudioTranscription,
    this.contextWindowCompression,
    this.realtimeInputConfig,
    this.responseModalities,
    this.maxOutputTokens,
    this.temperature,
    this.topP,
    this.topK,
    this.presencePenalty,
    this.frequencyPenalty,
    this.mediaResolution,
  }) : assert(mediaResolution != MediaResolution.ultraHigh,
            'MediaResolution.ultraHigh is only supported on individual media parts.');

  /// The speech configuration.
  final SpeechConfig? speechConfig;

  /// The transcription of the input aligns with the input audio language.
  final AudioTranscriptionConfig? inputAudioTranscription;

  /// The transcription of the output aligns with the language code specified
  /// for the output audio.
  final AudioTranscriptionConfig? outputAudioTranscription;

  /// The context window compression configuration.
  final ContextWindowCompressionConfig? contextWindowCompression;

  /// The realtime input configuration for voice activity detection and
  /// handling.
  final RealtimeInputConfig? realtimeInputConfig;

  /// The list of desired response modalities.
  final List<ResponseModalities>? responseModalities;

  /// The maximum number of tokens to include in a candidate.
  final int? maxOutputTokens;

  /// Controls the randomness of the output.
  final double? temperature;

  /// The maximum cumulative probability of tokens to consider when sampling.
  final double? topP;

  /// The maximum number of tokens to consider when sampling.
  final int? topK;

  /// Presence penalty.
  ///
  /// Accepted for source compatibility, but not sent yet: the gemini_live core
  /// `GenerationConfig` has no field for it.
  final double? presencePenalty;

  /// Frequency penalty.
  ///
  /// Accepted for source compatibility, but not sent yet: the gemini_live core
  /// `GenerationConfig` has no field for it.
  final double? frequencyPenalty;

  /// The media resolution for input images and video.
  final MediaResolution? mediaResolution;
}

// ============================================================================
// Server messages
// ============================================================================

/// An abstract class representing a message received from a live server.
sealed class LiveServerMessage {}

/// A message indicating that the live server setup is complete.
class LiveServerSetupComplete implements LiveServerMessage {}

/// Audio transcription message.
class Transcription {
  // ignore: public_member_api_docs
  const Transcription({this.text, this.finished});

  /// Transcription text.
  final String? text;

  /// Whether this is the end of the transcription.
  final bool? finished;
}

/// Content generated by the model in a live stream.
class LiveServerContent implements LiveServerMessage {
  /// Creates a [LiveServerContent] instance.
  LiveServerContent(
      {this.modelTurn,
      this.turnComplete,
      this.interrupted,
      this.inputTranscription,
      this.outputTranscription});

  /// The content generated by the model.
  final Content? modelTurn;

  /// Whether the turn is complete.
  final bool? turnComplete;

  /// Whether generation was interrupted by a client message.
  final bool? interrupted;

  /// The input transcription.
  final Transcription? inputTranscription;

  /// The output transcription.
  final Transcription? outputTranscription;
}

/// A tool call in a live stream.
class LiveServerToolCall implements LiveServerMessage {
  /// Creates a [LiveServerToolCall] instance.
  LiveServerToolCall({this.functionCalls});

  /// The list of function calls to be executed.
  final List<FunctionCall>? functionCalls;
}

/// A tool call cancellation in a live stream.
class LiveServerToolCallCancellation implements LiveServerMessage {
  /// Creates a [LiveServerToolCallCancellation] instance.
  LiveServerToolCallCancellation({this.functionIds});

  /// The list of [FunctionCall.id] to cancel.
  final List<String>? functionIds;
}

/// A server message indicating that the server will not be able to service
/// the client soon.
class GoingAwayNotice implements LiveServerMessage {
  /// Creates a [GoingAwayNotice] instance.
  const GoingAwayNotice({this.timeLeft});

  /// The remaining time before the connection will be terminated as ABORTED.
  final String? timeLeft;
}

/// An update of the session resumption state.
class SessionResumptionUpdate implements LiveServerMessage {
  /// Creates a [SessionResumptionUpdate] instance.
  SessionResumptionUpdate(
      {this.newHandle, this.resumable, this.lastConsumedClientMessageIndex});

  /// The new handle that represents the state that can be resumed.
  final String? newHandle;

  /// Indicates if the session can be resumed at this point.
  final bool? resumable;

  /// The index of the last client message that is included in the state
  /// represented by this update.
  final int? lastConsumedClientMessageIndex;
}

/// A single response chunk received during a live content generation.
class LiveServerResponse {
  // ignore: public_member_api_docs
  LiveServerResponse({required this.message});

  /// The server message generated by the live model.
  final LiveServerMessage message;
}

// ============================================================================
// Exceptions
// ============================================================================

/// Exception thrown when generating content fails.
final class FirebaseAIException implements Exception {
  // ignore: public_member_api_docs
  FirebaseAIException(this.message);

  /// Message of the exception.
  final String message;

  @override
  String toString() => 'FirebaseAIException: $message';
}

/// Exception thrown when the server failed to generate content.
final class ServerException implements FirebaseAIException {
  // ignore: public_member_api_docs
  ServerException(this.message);

  @override
  final String message;

  @override
  String toString() => message;
}

/// Exception thrown when the API key is invalid.
final class InvalidApiKey implements FirebaseAIException {
  // ignore: public_member_api_docs
  InvalidApiKey(this.message);

  @override
  final String message;

  @override
  String toString() => message;
}

/// Exception thrown when the user location is unsupported.
final class UnsupportedUserLocation implements FirebaseAIException {
  static const _message = 'User location is not supported for the API use.';

  @override
  String get message => _message;
}

/// Exception thrown when the Firebase AI Logic API is not enabled.
///
/// Kept so that `on ServiceApiNotEnabled` clauses written for firebase_ai
/// still compile; gemini_live never throws it.
final class ServiceApiNotEnabled implements FirebaseAIException {
  // ignore: public_member_api_docs
  ServiceApiNotEnabled(this._projectId);

  final String _projectId;

  @override
  String get message => 'The API is not enabled for project $_projectId.';

  @override
  String toString() => message;
}

/// Exception thrown when the quota is exceeded.
final class QuotaExceeded implements FirebaseAIException {
  // ignore: public_member_api_docs
  QuotaExceeded(this.message);

  @override
  final String message;

  @override
  String toString() => message;
}

/// Exception indicating a stale package version or implementation bug.
final class FirebaseAISdkException implements Exception {
  // ignore: public_member_api_docs
  FirebaseAISdkException(this.message);

  /// Message of the exception.
  final String message;

  @override
  String toString() => message;
}
