// ignore_for_file: constant_identifier_names

part of '../models.dart';

// ============================================================================
// Send Parameters
// ============================================================================

/// Parameters for sending conversational turns to the session.
class LiveSendClientContentParameters {
  final List<Content>? turns;
  final bool turnComplete;

  LiveSendClientContentParameters({this.turns, this.turnComplete = true});
}

/// Parameters for sending realtime media or text input.
class LiveSendRealtimeInputParameters {
  final List<Blob>? mediaChunks;
  final Blob? audio;
  final Blob? video;
  final String? text;
  final bool? audioStreamEnd;
  final bool? activityStart;
  final bool? activityEnd;

  LiveSendRealtimeInputParameters({
    this.mediaChunks,
    this.audio,
    this.video,
    this.text,
    this.audioStreamEnd,
    this.activityStart,
    this.activityEnd,
  });
}

/// Parameters for sending tool results back to the model.
class LiveSendToolResponseParameters {
  final List<FunctionResponse> functionResponses;

  LiveSendToolResponseParameters({required this.functionResponses});
}

