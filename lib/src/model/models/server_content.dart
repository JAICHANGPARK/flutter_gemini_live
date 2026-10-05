// ignore_for_file: constant_identifier_names

part of '../models.dart';

// ============================================================================
// Live API Server Response Models
// ============================================================================

/// Acknowledgement payload returned after session setup completes.
@JsonSerializable(includeIfNull: false, createToJson: false)
class LiveServerSetupComplete {
  final String? sessionId;
  final VoiceConsentSignature? voiceConsentSignature;

  LiveServerSetupComplete({this.sessionId, this.voiceConsentSignature});

  factory LiveServerSetupComplete.fromJson(Map<String, dynamic> json) =>
      _$LiveServerSetupCompleteFromJson(json);
}

/// A transcription update for input or output audio.
@JsonSerializable(includeIfNull: false, createToJson: false)
class Transcription {
  final String? text;
  final bool? finished;

  /// The BCP-47 language code of the transcription.
  final String? languageCode;

  Transcription({this.text, this.finished, this.languageCode});

  factory Transcription.fromJson(Map<String, dynamic> json) =>
      _$TranscriptionFromJson(json);
}

/// Executable code emitted by the model.
@JsonSerializable(includeIfNull: false)
class ExecutableCode {
  final String? language;
  final String? code;
  final String? id;

  ExecutableCode({this.language, this.code, this.id});

  factory ExecutableCode.fromJson(Map<String, dynamic> json) =>
      _$ExecutableCodeFromJson(json);

  Map<String, dynamic> toJson() => _$ExecutableCodeToJson(this);
}

/// The result of model-executed code.
@JsonSerializable(includeIfNull: false)
class CodeExecutionResult {
  final String? outcome;
  final String? output;
  final String? id;

  CodeExecutionResult({this.outcome, this.output, this.id});

  factory CodeExecutionResult.fromJson(Map<String, dynamic> json) =>
      _$CodeExecutionResultFromJson(json);

  Map<String, dynamic> toJson() => _$CodeExecutionResultToJson(this);
}

/// Server-generated content and turn lifecycle updates.
@JsonSerializable(includeIfNull: false, createToJson: false)
class LiveServerContent {
  final Content? modelTurn;
  final bool? turnComplete;
  final bool? interrupted;
  final Map<String, dynamic>? groundingMetadata;
  final Transcription? inputTranscription;
  final Transcription? outputTranscription;
  final bool? generationComplete;
  final Map<String, dynamic>? urlContextMetadata;
  final TurnCompleteReason? turnCompleteReason;
  final bool? waitingForInput;

  /// Low-latency transcription updated while the user is speaking.
  final Transcription? interimInputTranscription;

  /// The current activity status of the live session. Always sent alongside `turn_complete`.
  final InteractionStatus? interactionStatus;

  LiveServerContent({
    this.modelTurn,
    this.turnComplete,
    this.interrupted,
    this.groundingMetadata,
    this.inputTranscription,
    this.outputTranscription,
    this.generationComplete,
    this.urlContextMetadata,
    this.turnCompleteReason,
    this.waitingForInput,
    this.interimInputTranscription,
    this.interactionStatus,
  });

  /// Whether the server content indicates that the interaction is complete.
  ///
  /// Synced with official Google GenAI SDK logic (`python-genai` 2.23.0):
  /// - If [interactionStatus] is present and not unspecified, returns `true`
  ///   only when it equals [InteractionStatus.IDLE].
  /// - Otherwise, falls back to [turnComplete] == `true`.
  bool get isInteractionComplete {
    if (interactionStatus != null &&
        interactionStatus != InteractionStatus.INTERACTION_STATUS_UNSPECIFIED) {
      return interactionStatus == InteractionStatus.IDLE;
    }
    return turnComplete ?? false;
  }

  factory LiveServerContent.fromJson(Map<String, dynamic> json) =>
      _$LiveServerContentFromJson(json);
}

/// A tool call request emitted by the server.
@JsonSerializable(includeIfNull: false, createToJson: false)
class LiveServerToolCall {
  final List<FunctionCall>? functionCalls;

  LiveServerToolCall({this.functionCalls});

  factory LiveServerToolCall.fromJson(Map<String, dynamic> json) =>
      _$LiveServerToolCallFromJson(json);
}

/// A cancellation notice for previously issued tool calls.
@JsonSerializable(includeIfNull: false, createToJson: false)
class LiveServerToolCallCancellation {
  final List<String>? ids;

  LiveServerToolCallCancellation({this.ids});

  factory LiveServerToolCallCancellation.fromJson(Map<String, dynamic> json) =>
      _$LiveServerToolCallCancellationFromJson(json);
}

/// A shutdown warning indicating when the session will expire.
@JsonSerializable(includeIfNull: false, createToJson: false)
class LiveServerGoAway {
  final String? timeLeft;
  final String? reason;

  LiveServerGoAway({this.timeLeft, this.reason});

  factory LiveServerGoAway.fromJson(Map<String, dynamic> json) =>
      _$LiveServerGoAwayFromJson(json);

  /// The remaining session lifetime in seconds when available.
  int? get timeRemaining {
    if (timeLeft == null) return null;
    final match = RegExp(r'^(\d+)s$').firstMatch(timeLeft!);
    if (match == null) return null;
    return int.tryParse(match.group(1)!);
  }
}

/// A session resumption token update from the server.
@JsonSerializable(includeIfNull: false, createToJson: false)
class LiveServerSessionResumptionUpdate {
  final String? newHandle;
  final bool? resumable;
  final String? lastConsumedClientMessageIndex;

  LiveServerSessionResumptionUpdate({
    this.newHandle,
    this.resumable,
    this.lastConsumedClientMessageIndex,
  });

  factory LiveServerSessionResumptionUpdate.fromJson(
    Map<String, dynamic> json,
  ) => _$LiveServerSessionResumptionUpdateFromJson(json);
}

/// A low-level VAD signal emitted by the server.
@JsonSerializable(includeIfNull: false, createToJson: false)
class VoiceActivityDetectionSignal {
  final VadSignalType? vadSignalType;

  VoiceActivityDetectionSignal({this.vadSignalType});

  factory VoiceActivityDetectionSignal.fromJson(Map<String, dynamic> json) =>
      _$VoiceActivityDetectionSignalFromJson(json);

  /// Whether this signal marks the start of speech.
  bool get start => vadSignalType == VadSignalType.VAD_SIGNAL_TYPE_SOS;

  /// Whether this signal marks the end of speech.
  bool get end => vadSignalType == VadSignalType.VAD_SIGNAL_TYPE_EOS;
}

/// A higher-level voice activity event emitted by the server.
@JsonSerializable(includeIfNull: false, createToJson: false)
class VoiceActivity {
  final VoiceActivityType? voiceActivityType;

  /// The time voice activity was detected, as a Duration string (e.g. "1.5s"),
  /// relative to the start of the audio stream.
  final String? audioOffset;

  VoiceActivity({this.voiceActivityType, this.audioOffset});

  factory VoiceActivity.fromJson(Map<String, dynamic> json) =>
      _$VoiceActivityFromJson(json);

  /// Whether speech is currently considered active.
  bool? get speechActive {
    if (voiceActivityType == VoiceActivityType.ACTIVITY_START) return true;
    if (voiceActivityType == VoiceActivityType.ACTIVITY_END) return false;
    return null;
  }
}

/// Token counts broken down by media modality.
@JsonSerializable(includeIfNull: false, createToJson: false)
class ModalityTokenCount {
  final MediaModality? modality;
  final int? tokenCount;

  ModalityTokenCount({this.modality, this.tokenCount});

  factory ModalityTokenCount.fromJson(Map<String, dynamic> json) =>
      _$ModalityTokenCountFromJson(json);
}

/// Usage statistics attached to a server response.
@JsonSerializable(includeIfNull: false, createToJson: false)
class UsageMetadata {
  final int? promptTokenCount;
  final int? cachedContentTokenCount;
  final int? responseTokenCount;
  final int? toolUsePromptTokenCount;
  final int? thoughtsTokenCount;
  final int? totalTokenCount;
  final List<ModalityTokenCount>? promptTokensDetails;
  final List<ModalityTokenCount>? cacheTokensDetails;
  final List<ModalityTokenCount>? responseTokensDetails;
  final List<ModalityTokenCount>? toolUsePromptTokensDetails;
  final TrafficType? trafficType;
  final ServiceTier? serviceTier;

  UsageMetadata({
    this.promptTokenCount,
    this.cachedContentTokenCount,
    this.responseTokenCount,
    this.toolUsePromptTokenCount,
    this.thoughtsTokenCount,
    this.totalTokenCount,
    this.promptTokensDetails,
    this.cacheTokensDetails,
    this.responseTokensDetails,
    this.toolUsePromptTokensDetails,
    this.trafficType,
    this.serviceTier,
  });

  factory UsageMetadata.fromJson(Map<String, dynamic> json) =>
      _$UsageMetadataFromJson(json);
}

/// An error returned by the Live API server.
@JsonSerializable(includeIfNull: false, createToJson: false)
class LiveServerError {
  final int? code;
  final String? message;
  final String? status;

  LiveServerError({this.code, this.message, this.status});

  factory LiveServerError.fromJson(Map<String, dynamic> json) =>
      _$LiveServerErrorFromJson(json);

  @override
  String toString() =>
      'LiveServerError(code: $code, status: $status, message: $message)';
}

/// A top-level server message received over the Live API socket.
@JsonSerializable(includeIfNull: false, createToJson: false)
class LiveServerMessage {
  final LiveServerSetupComplete? setupComplete;
  final LiveServerContent? serverContent;
  final UsageMetadata? usageMetadata;
  final LiveServerToolCall? toolCall;
  final LiveServerToolCallCancellation? toolCallCancellation;
  final LiveServerGoAway? goAway;
  final LiveServerSessionResumptionUpdate? sessionResumptionUpdate;
  final VoiceActivityDetectionSignal? voiceActivityDetectionSignal;
  final VoiceActivity? voiceActivity;
  final LiveServerError? error;

  LiveServerMessage({
    this.setupComplete,
    this.serverContent,
    this.usageMetadata,
    this.toolCall,
    this.toolCallCancellation,
    this.goAway,
    this.sessionResumptionUpdate,
    this.voiceActivityDetectionSignal,
    this.voiceActivity,
    this.error,
  });

  factory LiveServerMessage.fromJson(Map<String, dynamic> json) =>
      _$LiveServerMessageFromJson(json);

  /// The concatenated non-thought text emitted in the current server turn.
  String? get text {
    final parts = serverContent?.modelTurn?.parts;
    if (parts == null || parts.isEmpty) return null;
    final chunks = <String>[];
    for (final part in parts) {
      final text = part.text;
      if (text == null) continue;
      if (part.thought == true) continue;
      chunks.add(text);
    }
    return chunks.isEmpty ? null : chunks.join();
  }

  /// The concatenated inline binary payload emitted in the current server turn.
  String? get data {
    final parts = serverContent?.modelTurn?.parts;
    if (parts == null || parts.isEmpty) return null;
    final bytes = <int>[];
    for (final part in parts) {
      final inline = part.inlineData;
      if (inline?.data == null) continue;
      bytes.addAll(base64.decode(inline!.data));
    }
    return bytes.isNotEmpty ? base64Encode(bytes) : null;
  }
}

