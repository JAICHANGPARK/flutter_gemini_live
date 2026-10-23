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
      final list = functionResponses!
          .map((e) => _encodeBinaryValues(e.toJson()) as Map<String, dynamic>)
          .toList();
      json['functionResponses'] = list;
      json['function_responses'] = list;
    }
    return json;
  }

  static Object? _encodeBinaryValues(Object? value) {
    if (value is Uint8List) {
      return base64Encode(value);
    }
    if (value is Map) {
      return value.map<String, dynamic>(
        (k, v) => MapEntry(k.toString(), _encodeBinaryValues(v)),
      );
    }
    if (value is List) {
      return value.map(_encodeBinaryValues).toList();
    }
    return value;
  }
}

/// A wrapper around the list of tools for in-session context updates.
///
/// This wrapper exists because a bare `repeated Tool` field cannot tell apart
/// "not sending a tools update" from "clearing all tools":
/// - `tools` field unset on [LiveClientContextUpdate]: no update; keep the
///   previously provided tools.
/// - `tools` field set (even with an empty list `[]`): replace the current
///   tools with the provided list, which may be empty to clear all tools.
class LiveClientContextUpdateTools {
  /// The list of tools the model may use to generate subsequent responses.
  final List<Tool>? tools;

  /// Creates a [LiveClientContextUpdateTools] wrapper.
  const LiveClientContextUpdateTools({this.tools});

  /// Creates a [LiveClientContextUpdateTools] from a JSON payload.
  factory LiveClientContextUpdateTools.fromJson(Map<String, dynamic> json) {
    final raw = json['tools'] as List<dynamic>?;
    return LiveClientContextUpdateTools(
      tools: raw
          ?.map((e) => e is Tool ? e : Tool.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Converts this wrapper to a JSON payload.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (tools != null) {
      json['tools'] = tools!.map((t) => t.toJson()).toList();
    }
    return json;
  }
}

/// Updates to the context (`systemInstruction` and/or `tools`) of the current
/// Live API session.
///
/// Only fields that are set will be updated. Updates are guaranteed to be
/// processed in order with the rest of the inputs.
class LiveClientContextUpdate {
  /// Updated system instruction for the model.
  ///
  /// Overrides `BidiGenerateContentSetup.system_instruction`. Because system
  /// instructions are part of the model preamble, updating them invalidates
  /// the prefix cache.
  final Content? systemInstruction;

  /// An updated list of tools the model may use to generate subsequent
  /// responses.
  ///
  /// Pass `LiveClientContextUpdateTools(tools: [])` (or `tools: <Tool>[]`)
  /// to clear all tools.
  final LiveClientContextUpdateTools? tools;

  /// Creates an in-session context update.
  ///
  /// [systemInstruction] accepts a [String], [Part], [Content], `List<Part>`,
  /// `List<String>`, or `Map<String, dynamic>`.
  /// [tools] accepts a [LiveClientContextUpdateTools], `List<Tool>`, or
  /// `List<Map<String, dynamic>>`.
  LiveClientContextUpdate({
    Object? systemInstruction,
    Object? tools,
  }) : systemInstruction = _parseContextSystemInstruction(systemInstruction),
       tools = _parseContextTools(tools);

  static Content? _parseContextSystemInstruction(Object? value) {
    if (value == null) return null;
    if (value is Content) return value;
    if (value is String) {
      return Content(parts: [Part(text: value)], role: 'user');
    }
    if (value is Part) {
      return Content(parts: [value], role: 'user');
    }
    if (value is Map<String, dynamic>) {
      if (value.containsKey('parts') || value.containsKey('role')) {
        return Content.fromJson(value);
      }
      return Content(parts: [Part.fromJson(value)], role: 'user');
    }
    if (value is List) {
      final parts = value.map<Part>((item) {
        if (item is Part) return item;
        if (item is String) return Part(text: item);
        if (item is Map<String, dynamic>) return Part.fromJson(item);
        throw ArgumentError.value(
          item,
          'systemInstruction',
          'Each part in systemInstruction must be a Part, String, or Map<String, dynamic>.',
        );
      }).toList();
      return Content(parts: parts, role: 'user');
    }
    throw ArgumentError.value(
      value,
      'systemInstruction',
      'Must be a String, Part, List<Part>, Map<String, dynamic>, or Content.',
    );
  }

  static LiveClientContextUpdateTools? _parseContextTools(Object? value) {
    if (value == null) return null;
    if (value is LiveClientContextUpdateTools) return value;
    if (value is List<Tool>) return LiveClientContextUpdateTools(tools: value);
    if (value is Map<String, dynamic>) {
      return LiveClientContextUpdateTools.fromJson(value);
    }
    if (value is List) {
      return LiveClientContextUpdateTools(
        tools: value.map<Tool>((item) {
          if (item is Tool) return item;
          if (item is Map<String, dynamic>) return Tool.fromJson(item);
          throw ArgumentError.value(
            item,
            'tools',
            'Each tool must be a Tool or Map<String, dynamic>.',
          );
        }).toList(),
      );
    }
    throw ArgumentError.value(
      value,
      'tools',
      'Must be a List<Tool> or LiveClientContextUpdateTools.',
    );
  }

  /// Creates a [LiveClientContextUpdate] from a JSON payload.
  factory LiveClientContextUpdate.fromJson(Map<String, dynamic> json) {
    final rawSys = json['systemInstruction'] ?? json['system_instruction'];
    final rawTools = json['tools'];
    return LiveClientContextUpdate(
      systemInstruction: rawSys == null
          ? null
          : (rawSys is Content
                ? rawSys
                : (rawSys is String
                      ? Content(parts: [Part(text: rawSys)], role: 'user')
                      : Content.fromJson(rawSys as Map<String, dynamic>))),
      tools: rawTools == null
          ? null
          : (rawTools is LiveClientContextUpdateTools
                ? rawTools
                : (rawTools is List
                      ? LiveClientContextUpdateTools(
                          tools: rawTools
                              .map(
                                (e) => e is Tool
                                    ? e
                                    : Tool.fromJson(e as Map<String, dynamic>),
                              )
                              .toList(),
                        )
                      : LiveClientContextUpdateTools.fromJson(
                          rawTools as Map<String, dynamic>,
                        ))),
    );
  }

  /// Converts this context update to a JSON payload.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (systemInstruction != null) {
      json['systemInstruction'] = systemInstruction!.toJson();
    }
    if (tools != null) {
      json['tools'] = tools!.toJson();
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

  /// Updates to the context (`systemInstruction` and/or `tools`) of the current session.
  final LiveClientContextUpdate? contextUpdate;

  LiveClientMessage({
    this.setup,
    this.clientContent,
    this.realtimeInput,
    this.toolResponse,
    this.contextUpdate,
  });

  factory LiveClientMessage.fromJson(Map<String, dynamic> json) =>
      _$LiveClientMessageFromJson({
        ...json,
        if (!json.containsKey('contextUpdate') &&
            json.containsKey('context_update'))
          'contextUpdate': json['context_update'],
      });

  Map<String, dynamic> toJson() => _$LiveClientMessageToJson(this);
}

