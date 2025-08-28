// Copyright 2024 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:json_annotation/json_annotation.dart';

import '../schema.dart';

part 'google_models.g.dart';

/// Structured representation of a function declaration as defined by the
/// [OpenAPI 3.03 specification](https://spec.openapis.org/oas/v3.0.3).
///
/// Included in this declaration are the function name and parameters. This
/// FunctionDeclaration is a representation of a block of code that can be used
/// as a `Tool` by the model and executed by the client.
@JsonSerializable(
  includeIfNull: false,
  fieldRename: FieldRename.snake,
  createFactory: false,
  createToJson: false,
)
final class FunctionDeclaration {
  FunctionDeclaration(
    this.name,
    this.description, {
    required Map<String, Schema> parameters,
    List<String> optionalParameters = const [],
  }) : _schemaObject = Schema.object(
         properties: parameters,
         optionalProperties: optionalParameters,
       );

  /// The name of the function.
  ///
  /// Must be a-z, A-Z, 0-9, or contain underscores and dashes, with a maximum
  /// length of 63.
  final String name;

  /// A brief description of the function.
  final String description;

  final Schema _schemaObject;

  /// Convert to json object.
  Map<String, Object?> toJson() => {
    'name': name,
    'description': description,
    'parameters': _schemaObject.toJson(),
  };

  factory FunctionDeclaration.fromJson(Map<String, dynamic> json) {
    return FunctionDeclaration(
      json["name"],
      json["description"],
      parameters: json["parameters"],
    );
  }
}

/// A predicted `FunctionCall` returned from the model that contains
/// a string representing the `FunctionDeclaration.name` with the
/// arguments and their values.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
final class FunctionCall {
  /// The name of the function to call.
  final String name;

  /// The function parameters and values.
  final Map<String, Object?> args;

  /// The unique id of the function call.
  ///
  /// If populated, the client to execute the [FunctionCall]
  /// and return the response with the matching [id].
  final String? id;

  FunctionCall({required this.name, required this.args, this.id});

  factory FunctionCall.fromJson(Map<String, dynamic> json) =>
      _$FunctionCallFromJson(json);

  Map<String, dynamic> toJson() => _$FunctionCallToJson(this);
}

/// The response class for [FunctionCall]
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
final class FunctionResponse {
  /// The name of the function that was called.
  final String name;

  /// The function response.
  ///
  /// The values must be JSON compatible types; `String`, `num`, `bool`, `List`
  /// of JSON compatible types, or `Map` from String to JSON compatible types.
  final Map<String, Object?> response;

  /// The id of the function call this response is for.
  ///
  /// Populated by the client to match the corresponding [FunctionCall.id].
  final String? id;

  FunctionResponse({required this.name, required this.response, this.id});

  factory FunctionResponse.fromJson(Map<String, dynamic> json) =>
      _$FunctionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$FunctionResponseToJson(this);
}

/// Client generated response to a `ToolCall` received from the server.
///
/// Individual `FunctionResponse` objects are matched to the respective
/// `FunctionCall` objects by the `id` field.
///
/// Note that in the unary and server-streaming GenerateContent APIs function
/// calling happens by exchanging the `Content` parts, while in the bidi
/// GenerateContent APIs function calling happens over this dedicated set of
/// messages.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
final class LiveClientToolResponse {
  /// The response to the function calls.
  final List<FunctionResponse> functionResponses;

  LiveClientToolResponse({this.functionResponses = const []});

  factory LiveClientToolResponse.fromJson(Map<String, dynamic> json) =>
      _$LiveClientToolResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LiveClientToolResponseToJson(this);
}

/// Marks the start of user activity.
///
/// This can only be sent if automatic (i.e. server-side) activity detection is
/// disabled.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
final class ActivityStart {
  ActivityStart();

  factory ActivityStart.fromJson(Map<String, dynamic> json) =>
      _$ActivityStartFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityStartToJson(this);
}

/// Marks the end of user activity.
///
/// This can only be sent if automatic (i.e. server-side) activity detection is
/// disabled.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
final class ActivityEnd {
  ActivityEnd();

  factory ActivityEnd.fromJson(Map<String, dynamic> json) =>
      _$ActivityEndFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityEndToJson(this);
}

/// Start of speech sensitivity.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum StartSensitivity {
  /// The default is START_SENSITIVITY_LOW.
  startSensitivityUnspecified,

  /// Automatic detection will detect the start of speech more often.
  startSensitivityHigh,

  /// Automatic detection will detect the start of speech less often.
  startSensitivityLow,
}

/// End of speech sensitivity.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum EndSensitivity {
  /// The default is END_SENSITIVITY_LOW.
  endSensitivityUnspecified,

  /// Automatic detection ends speech more often.
  endSensitivityHigh,

  /// Automatic detection ends speech less often.
  endSensitivityLow,
}

/// Configures automatic detection of activity.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
final class AutomaticActivityDetection {
  /// If enabled, detected voice and text input count as activity.
  /// If disabled, the client must send activity signals.
  final bool? disabled;

  /// Determines how likely speech is to be detected.
  final StartSensitivity? startOfSpeechSensitivity;

  /// Determines how likely detected speech is ended.
  final EndSensitivity? endOfSpeechSensitivity;

  /// The required duration of detected speech before start-of-speech is committed.
  /// The lower this value the more sensitive the start-of-speech detection is
  /// and the shorter speech can be recognized. However,
  /// this also increases the probability of false positives.
  final num? prefixPaddingMs;

  /// The required duration of detected non-speech (e.g. silence)
  /// before end-of-speech is committed.
  /// The larger this value, the longer speech gaps can be without interrupting
  /// the user's activity but this will increase the model's latency.
  final num? silenceDurationMs;

  AutomaticActivityDetection({
    this.disabled,
    this.startOfSpeechSensitivity,
    this.endOfSpeechSensitivity,
    this.prefixPaddingMs,
    this.silenceDurationMs,
  });

  factory AutomaticActivityDetection.fromJson(Map<String, dynamic> json) =>
      _$AutomaticActivityDetectionFromJson(json);

  Map<String, dynamic> toJson() => _$AutomaticActivityDetectionToJson(this);
}

@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
final class RealtimeInputConfig {
  /// If not set, automatic activity detection is enabled by default.
  /// If automatic voice detection is disabled,
  /// the client must send activity signals.
  final AutomaticActivityDetection? automaticActivityDetection;

  /// Defines what effect activity has.
  final ActivityHandling? activityHandling;

  /// Defines which input is included in the user's turn.
  final TurnCoverage? turnCoverage;

  RealtimeInputConfig({
    this.automaticActivityDetection,
    this.activityHandling,
    this.turnCoverage,
  });

  factory RealtimeInputConfig.fromJson(Map<String, dynamic> json) =>
      _$RealtimeInputConfigFromJson(json);

  Map<String, dynamic> toJson() => _$RealtimeInputConfigToJson(this);
}

/// The different ways of handling user activity.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum ActivityHandling {
  /// If unspecified, the default behavior is `START_OF_ACTIVITY_INTERRUPTS`.
  activityHandlingUnspecified,

  /// If true, start of activity will interrupt the model's response
  /// (also called "barge in"). The model's current response will be cut-off
  /// in the moment of the interruption. This is the default behavior.
  startOfActivityInterrupts,

  /// The model's response will not be interrupted.
  noInterruption,
}

/// Options about which input is included in the user's turn.
@JsonEnum(fieldRename: FieldRename.screamingSnake)
enum TurnCoverage {
  /// If unspecified, the default behavior is `TURN_INCLUDES_ONLY_ACTIVITY`.
  turnCoverageUnspecified,

  /// The users turn only includes activity since the last turn,
  /// excluding inactivity (e.g. silence on the audio stream).
  /// This is the default behavior.
  turnIncludesOnlyActivity,

  /// The users turn includes all realtime input since the last turn,
  /// including inactivity (e.g. silence on the audio stream).
  turnIncludesAllInput,
}

/// Notification for the client that a previously issued `ToolCallMessage`
/// with the specified `id`s should have been not executed and should be cancelled.
///
/// If there were side-effects to those tool calls, clients may attempt to undo
/// the tool calls. This message occurs only in cases where the clients interrupt
/// server turns.
@JsonSerializable(includeIfNull: false, createToJson: false)
final class LiveServerToolCallCancellation {
  /// The ids of the tool calls to be cancelled.
  final List<String> ids;

  LiveServerToolCallCancellation({this.ids = const []});

  factory LiveServerToolCallCancellation.fromJson(Map<String, dynamic> json) =>
      _$LiveServerToolCallCancellationFromJson(json);
}

/// Server will not be able to service client soon.
@JsonSerializable(includeIfNull: false, createToJson: false)
final class LiveServerGoAway {
  /// The remaining time before the connection will be terminated as ABORTED.
  /// The minimal time returned here is specified differently together with
  /// the rate limits for a given model.
  final String? timeLeft;

  LiveServerGoAway({this.timeLeft});

  factory LiveServerGoAway.fromJson(Map<String, dynamic> json) =>
      _$LiveServerGoAwayFromJson(json);
}

/// Update of the session resumption state.
///
/// Only sent if `session_resumption` was set in the connection config.
@JsonSerializable(includeIfNull: false, createToJson: false)
final class LiveServerSessionResumptionUpdate {
  /// New handle that represents state that can be resumed.
  /// Empty if `resumable`=false.
  final String? newHandle;

  /// True if session can be resumed at this point.
  /// It might be not possible to resume session at some points.
  /// In that case we send update empty new_handle and resumable=false.
  /// Example of such case could be model executing function calls or just generating.
  /// Resuming session (using previous session token) in such state will result
  /// in some data loss.
  final bool? resumable;

  /// Index of last message sent by client that is included in state represented
  /// by this SessionResumptionToken. Only sent when
  /// `SessionResumptionConfig.transparent` is set.
  ///
  /// Presence of this index allows users to transparently reconnect and avoid
  /// issue of losing some part of realtime audio input/video. If client wishes
  /// to temporarily disconnect (for example as result of receiving GoAway)
  /// they can do it without losing state by buffering messages sent since
  /// last `SessionResmumptionTokenUpdate`. This field will enable them to limit
  /// buffering (avoid keeping all requests in RAM).
  ///
  /// Note: This should not be used for when resuming a session at some time
  /// later -- in those cases partial audio and video frames arelikely not needed.
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

/// Configuration of session resumption mechanism.
///
/// Included in `LiveConnectConfig.session_resumption`. If included server
/// will send `LiveServerSessionResumptionUpdate` messages.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
final class SessionResumptionConfig {
  /// Session resumption handle of previous session (session to restore).
  ///
  /// If not present new session will be started.
  final String? handle;

  /// If set the server will send `last_consumed_client_message_index` in the
  /// `session_resumption_update` messages to allow for transparent reconnections.
  final bool? transparent;

  SessionResumptionConfig({this.handle, this.transparent});

  factory SessionResumptionConfig.fromJson(Map<String, dynamic> json) =>
      _$SessionResumptionConfigFromJson(json);

  Map<String, dynamic> toJson() => _$SessionResumptionConfigToJson(this);
}

/// Context window will be truncated by keeping only suffix of it.
///
/// Context window will always be cut at start of USER role turn. System
/// instructions and `BidiGenerateContentSetup.prefix_turns` will not be
/// subject to the sliding window mechanism, they will always stay at the
/// beginning of context window.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
final class SlidingWindow {
  /// Session reduction target -- how many tokens we should keep.
  /// Window shortening operation has some latency costs,
  /// so we should avoid running it on every turn. Should be < trigger_tokens.
  /// If not set, trigger_tokens/2 is assumed.
  final String? targetTokens;

  SlidingWindow({this.targetTokens});

  factory SlidingWindow.fromJson(Map<String, dynamic> json) =>
      _$SlidingWindowFromJson(json);

  Map<String, dynamic> toJson() => _$SlidingWindowToJson(this);
}

/// Enables context window compression -- mechanism managing
/// model context window so it does not exceed given length.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
final class ContextWindowCompressionConfig {
  /// Number of tokens (before running turn) that triggers
  /// context window compression mechanism.
  final String? triggerTokens;

  /// Sliding window compression mechanism.
  final SlidingWindow? slidingWindow;

  ContextWindowCompressionConfig({this.triggerTokens, this.slidingWindow});

  Map<String, dynamic> toJson() => _$ContextWindowCompressionConfigToJson(this);

  factory ContextWindowCompressionConfig.fromJson(Map<String, dynamic> json) =>
      _$ContextWindowCompressionConfigFromJson(json);
}

/// The audio transcription configuration in Setup.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
final class AudioTranscriptionConfig {
  AudioTranscriptionConfig();

  Map<String, dynamic> toJson() => _$AudioTranscriptionConfigToJson(this);

  factory AudioTranscriptionConfig.fromJson(Map<String, dynamic> json) =>
      _$AudioTranscriptionConfigFromJson(json);
}

/// Config for proactivity features.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
final class ProactivityConfig {
  /// If enabled, the model can reject responding to the last prompt. For
  /// example, this allows the model to ignore out of context speech or to stay
  /// silent if the user did not make a request, yet.
  final bool? proactiveAudio;

  ProactivityConfig({this.proactiveAudio});

  factory ProactivityConfig.fromJson(Map<String, dynamic> json) =>
      _$ProactivityConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ProactivityConfigToJson(this);
}
