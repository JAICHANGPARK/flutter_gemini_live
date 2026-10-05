// ignore_for_file: constant_identifier_names

part of '../models.dart';

// ============================================================================
// Live API Client Content Models
// ============================================================================

/// Client-authored conversation turns sent to the model.
class LiveClientContent {
  final List<Content>? turns;
  final bool? turnComplete;

  LiveClientContent({this.turns, this.turnComplete});

  factory LiveClientContent.fromJson(Map<String, dynamic> json) {
    final rawTurns = json['turns'] as List<dynamic>?;
    final turns = rawTurns
        ?.map((e) => Content.fromJson(e as Map<String, dynamic>))
        .toList();
    final turnComplete =
        (json['turnComplete'] ?? json['turn_complete']) as bool?;
    return LiveClientContent(turns: turns, turnComplete: turnComplete);
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (turns != null) {
      json['turns'] = turns!.map((e) => e.toJson()).toList();
    }
    if (turnComplete != null) {
      json['turnComplete'] = turnComplete;
      json['turn_complete'] = turnComplete;
    }
    return json;
  }
}

/// A signal that marks the start of explicit user activity.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class ActivityStart {
  /// Creates an activity-start marker.
  ActivityStart();

  /// Creates an [ActivityStart] from a JSON payload.
  factory ActivityStart.fromJson(Map<String, dynamic> json) =>
      _$ActivityStartFromJson(json);

  /// Converts this marker to a JSON payload.
  Map<String, dynamic> toJson() => _$ActivityStartToJson(this);
}

/// A signal that marks the end of explicit user activity.
@JsonSerializable(includeIfNull: false, fieldRename: FieldRename.snake)
class ActivityEnd {
  /// Creates an activity-end marker.
  ActivityEnd();

  /// Creates an [ActivityEnd] from a JSON payload.
  factory ActivityEnd.fromJson(Map<String, dynamic> json) =>
      _$ActivityEndFromJson(json);

  /// Converts this marker to a JSON payload.
  Map<String, dynamic> toJson() => _$ActivityEndToJson(this);
}

/// Realtime media or text input sent while a session is active.
class LiveClientRealtimeInput {
  final List<Blob>? mediaChunks;
  final Blob? audio;
  final Blob? video;
  final bool? audioStreamEnd;
  final String? text;
  final ActivityStart? activityStart;
  final ActivityEnd? activityEnd;

  LiveClientRealtimeInput({
    this.mediaChunks,
    this.audio,
    this.video,
    this.audioStreamEnd,
    this.text,
    this.activityStart,
    this.activityEnd,
  });

  factory LiveClientRealtimeInput.fromJson(Map<String, dynamic> json) {
    final rawChunks = json['mediaChunks'] ?? json['media_chunks'];
    final chunks = (rawChunks as List<dynamic>?)
        ?.map((e) => Blob.fromJson(e as Map<String, dynamic>))
        .toList();
    final audio = json['audio'] != null
        ? Blob.fromJson(json['audio'] as Map<String, dynamic>)
        : null;
    final video = json['video'] != null
        ? Blob.fromJson(json['video'] as Map<String, dynamic>)
        : null;
    final audioStreamEnd =
        (json['audioStreamEnd'] ?? json['audio_stream_end']) as bool?;
    final text = json['text'] as String?;
    final rawActStart = json['activityStart'] ?? json['activity_start'];
    final actStart = rawActStart != null
        ? ActivityStart.fromJson(rawActStart as Map<String, dynamic>)
        : null;
    final rawActEnd = json['activityEnd'] ?? json['activity_end'];
    final actEnd = rawActEnd != null
        ? ActivityEnd.fromJson(rawActEnd as Map<String, dynamic>)
        : null;
    return LiveClientRealtimeInput(
      mediaChunks: chunks,
      audio: audio,
      video: video,
      audioStreamEnd: audioStreamEnd,
      text: text,
      activityStart: actStart,
      activityEnd: actEnd,
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (audio != null) {
      json['audio'] = audio!.toJson();
    }
    if (video != null) {
      json['video'] = video!.toJson();
    }
    if (mediaChunks != null && mediaChunks!.isNotEmpty) {
      final list = mediaChunks!.map((e) => e.toJson()).toList();
      json['mediaChunks'] = list;
      json['media_chunks'] = list;
    }
    if (audioStreamEnd != null) {
      json['audioStreamEnd'] = audioStreamEnd;
      json['audio_stream_end'] = audioStreamEnd;
    }
    if (text != null) {
      json['text'] = text;
    }
    if (activityStart != null) {
      json['activityStart'] = activityStart!.toJson();
      json['activity_start'] = activityStart!.toJson();
    }
    if (activityEnd != null) {
      json['activityEnd'] = activityEnd!.toJson();
      json['activity_end'] = activityEnd!.toJson();
    }
    return json;
  }
}

/// A batch of tool results returned to the server.
class LiveClientToolResponse {
  final List<FunctionResponse>? functionResponses;

  LiveClientToolResponse({this.functionResponses});

  factory LiveClientToolResponse.fromJson(Map<String, dynamic> json) {
    final rawList = json['functionResponses'] ?? json['function_responses'];
    final list = (rawList as List<dynamic>?)
        ?.map((e) => FunctionResponse.fromJson(e as Map<String, dynamic>))
        .toList();
    return LiveClientToolResponse(functionResponses: list);
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (functionResponses != null) {
      final list = functionResponses!.map((e) => e.toJson()).toList();
      json['functionResponses'] = list;
      json['function_responses'] = list;
    }
    return json;
  }
}

/// A top-level client message sent over the Live API socket.
@JsonSerializable(includeIfNull: false)
class LiveClientMessage {
  final LiveClientSetup? setup;
  final LiveClientContent? clientContent;
  final LiveClientRealtimeInput? realtimeInput;
  final LiveClientToolResponse? toolResponse;

  LiveClientMessage({
    this.setup,
    this.clientContent,
    this.realtimeInput,
    this.toolResponse,
  });

  factory LiveClientMessage.fromJson(Map<String, dynamic> json) =>
      _$LiveClientMessageFromJson(json);

  Map<String, dynamic> toJson() => _$LiveClientMessageToJson(this);
}

