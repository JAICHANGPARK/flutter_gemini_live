// API surface mirrors `package:firebase_ai` 4.x (Apache License 2.0,
// Copyright Google LLC) so that code can move between the two packages by
// swapping imports. The implementation delegates to the gemini_live core
// `LiveService` / `LiveSession`, which are not modified.

import 'dart:async';

import 'package:flutter/foundation.dart' show debugPrint, visibleForTesting;

import '../../google_genai.dart' as core;
import '../../utils/token_usage_tracker.dart';
import 'content.dart';
import 'converters.dart';
import 'live_api.dart';
import 'tool.dart';

/// Entry point mirroring `FirebaseAI` from `package:firebase_ai`.
///
/// Only the Live API is provided, and Firebase app setup is replaced by an
/// API key. Moving from firebase_ai means replacing `Firebase.initializeApp()`
/// with [FirebaseAI.initialize]; everything after `FirebaseAI.googleAI()`
/// stays the same.
///
/// ```dart
/// FirebaseAI.initialize(apiKey: 'YOUR_GEMINI_API_KEY');
/// final model = FirebaseAI.googleAI().liveGenerativeModel(
///   model: 'gemini-2.5-flash-native-audio-preview-12-2025',
///   liveGenerationConfig: LiveGenerationConfig(
///     responseModalities: [ResponseModalities.audio],
///   ),
/// );
/// final session = await model.connect();
/// ```
class FirebaseAI {
  FirebaseAI._(this._liveService);

  /// Builds an instance over a preconfigured core service, for tests.
  @visibleForTesting
  factory FirebaseAI.forTesting(core.LiveService liveService) =>
      FirebaseAI._(liveService);

  static String? _defaultApiKey;
  static String? _defaultApiVersion;

  final core.LiveService _liveService;

  /// Sets the API key used by [googleAI] when none is passed.
  ///
  /// This replaces `Firebase.initializeApp()`. Ephemeral tokens
  /// (`auth_tokens/...`) are accepted and default to the `v1alpha` API.
  static void initialize({required String apiKey, String? apiVersion}) {
    _defaultApiKey = apiKey;
    _defaultApiVersion = apiVersion;
  }

  /// Returns an instance that talks to the Gemini Developer API.
  ///
  /// [apiKey] and [apiVersion] override the values given to [initialize].
  static FirebaseAI googleAI({String? apiKey, String? apiVersion}) {
    final key = apiKey ?? _defaultApiKey;
    if (key == null || key.isEmpty) {
      throw StateError(
        'No API key. Call FirebaseAI.initialize(apiKey: ...) first, '
        'or pass FirebaseAI.googleAI(apiKey: ...).',
      );
    }
    final version = apiVersion ??
        _defaultApiVersion ??
        (key.startsWith('auth_tokens/') ? 'v1alpha' : 'v1beta');
    return FirebaseAI._(core.LiveService(apiKey: key, apiVersion: version));
  }

  /// Create a [LiveGenerativeModel] for real-time interaction.
  LiveGenerativeModel liveGenerativeModel({
    required String model,
    LiveGenerationConfig? liveGenerationConfig,
    List<Tool>? tools,
    Content? systemInstruction,
  }) =>
      LiveGenerativeModel._(
        _liveService,
        model: model,
        liveGenerationConfig: liveGenerationConfig,
        tools: tools,
        systemInstruction: systemInstruction,
      );
}

/// A live, generative AI model for real-time interaction.
final class LiveGenerativeModel {
  LiveGenerativeModel._(
    this._liveService, {
    required String model,
    LiveGenerationConfig? liveGenerationConfig,
    List<Tool>? tools,
    Content? systemInstruction,
  })  : _model = model,
        _liveGenerationConfig = liveGenerationConfig,
        _tools = tools,
        _systemInstruction = systemInstruction;

  final core.LiveService _liveService;
  final String _model;
  final LiveGenerationConfig? _liveGenerationConfig;
  final List<Tool>? _tools;
  final Content? _systemInstruction;

  /// Establishes a connection to a live generation service.
  ///
  /// [sessionResumption] starts a resumable session, or resumes one when it
  /// was created with [SessionResumptionConfig.resume].
  Future<LiveSession> connect(
      {SessionResumptionConfig? sessionResumption}) async {
    final config = _liveGenerationConfig;
    if (config?.presencePenalty != null || config?.frequencyPenalty != null) {
      debugPrint('gemini_live: LiveGenerationConfig.presencePenalty and '
          'frequencyPenalty are not sent to the server yet and are ignored.');
    }
    final session = LiveSession._(this);
    await session._open(sessionResumption);
    return session;
  }

  core.LiveConnectParameters _parameters(
    core.LiveCallbacks callbacks,
    SessionResumptionConfig? sessionResumption,
  ) {
    final config = _liveGenerationConfig;
    return core.LiveConnectParameters(
      model: _model,
      callbacks: callbacks,
      config: config == null ? null : toCoreGenerationConfig(config),
      systemInstruction: _systemInstruction == null
          ? null
          : toCoreContent(_systemInstruction),
      tools: _tools?.map(toCoreTool).toList(),
      realtimeInputConfig:
          toCoreRealtimeInputConfig(config?.realtimeInputConfig),
      sessionResumption: toCoreSessionResumption(sessionResumption),
      contextWindowCompression:
          toCoreContextWindowCompression(config?.contextWindowCompression),
      inputAudioTranscription:
          toCoreTranscription(config?.inputAudioTranscription),
      outputAudioTranscription:
          toCoreTranscription(config?.outputAudioTranscription),
    );
  }
}

/// Thrown when sending on a session whose WebSocket is closed.
final class LiveWebSocketClosedException implements Exception {
  // ignore: public_member_api_docs
  LiveWebSocketClosedException(this.message);

  /// Message of the exception.
  final String message;

  @override
  String toString() {
    if (message.contains('DEADLINE_EXCEEDED')) {
      return 'The current live session has expired. Please start a new session.';
    } else if (message.contains('RESOURCE_EXHAUSTED')) {
      return 'You have exceeded the maximum number of concurrent sessions. '
          'Please close other sessions and try again later.';
    }
    return message;
  }
}

/// Responses received before anyone listens to [LiveSession.receive] are
/// held, up to this many, instead of being dropped.
const int _maxPendingResponses = 256;

/// Raw core messages behind each [LiveServerResponse], for
/// [GeminiLiveResponseExtras.rawMessage].
final Expando<core.LiveServerMessage> _rawMessages =
    Expando('gemini_live raw message');

/// Manages asynchronous communication with Gemini model over a WebSocket
/// connection.
class LiveSession {
  LiveSession._(this._model)
      : _tokenTracker = GeminiTokenUsageTracker(model: _model._model) {
    _controller = StreamController<LiveServerResponse>.broadcast(
      onListen: _flushPending,
    );
  }

  final LiveGenerativeModel _model;
  final GeminiTokenUsageTracker _tokenTracker;
  late final StreamController<LiveServerResponse> _controller;
  final List<LiveServerResponse> _pending = [];
  bool _hadListener = false;
  bool _closed = false;

  late core.LiveSession _core;
  int? _closeCode;
  String? _closeReason;

  /// Incremented on every (re)connect and on close, so callbacks from a
  /// replaced or closed core session are ignored.
  int _generation = 0;

  Future<void> _open(SessionResumptionConfig? sessionResumption) async {
    final generation = ++_generation;
    bool isCurrent() => generation == _generation && !_closed;

    _core = await _model._liveService.connect(
      _model._parameters(
        core.LiveCallbacks(
          onMessage: (message) {
            if (isCurrent()) _handleMessage(message);
          },
          onError: (error, stackTrace) {
            if (!isCurrent()) return;
            _addError(error, stackTrace);
            // The core subscription uses cancelOnError, so onClose may never
            // come after a socket error. Close the stream if the socket is
            // gone so `await for (... in receive())` can finish.
            Future<void>(() {
              if (isCurrent() && _core.isClosed) _closeController();
            });
          },
          onClose: (code, reason) {
            if (!isCurrent()) return;
            _closeCode = code;
            _closeReason = reason;
            _closeController();
          },
        ),
        sessionResumption,
      ),
    );
  }

  void _handleMessage(core.LiveServerMessage message) {
    _tokenTracker.recordMessage(message);
    for (final converted in fromCoreServerMessage(message)) {
      final response = LiveServerResponse(message: converted);
      _rawMessages[response] = message;
      _emit(response);
    }
  }

  void _emit(LiveServerResponse response) {
    if (_controller.isClosed) return;
    if (!_hadListener) {
      if (_pending.length == _maxPendingResponses) _pending.removeAt(0);
      _pending.add(response);
      return;
    }
    _controller.add(response);
  }

  void _addError(Object error, StackTrace stackTrace) {
    if (!_controller.isClosed && _controller.hasListener) {
      _controller.addError(error, stackTrace);
    }
  }

  void _flushPending() {
    _hadListener = true;
    for (final response in _pending) {
      _controller.add(response);
    }
    _pending.clear();
  }

  void _closeController() {
    if (!_controller.isClosed) _controller.close();
  }

  void _checkWsStatus() {
    if (_closed || _core.isClosed) {
      throw LiveWebSocketClosedException(
        'WebSocket Closed, closeCode: $_closeCode, closeReason: $_closeReason',
      );
    }
  }

  void _sendRealtimeInput(core.LiveClientRealtimeInput input) =>
      _core.sendMessage(core.LiveClientMessage(realtimeInput: input));

  /// Routes a media chunk to the `audio` / `video` realtime fields, which
  /// replace the deprecated `mediaChunks` field on the wire.
  void _sendMediaChunk(InlineDataPart chunk) {
    final blob = toCoreBlob(chunk);
    if (chunk.mimeType.startsWith('audio/')) {
      _sendRealtimeInput(core.LiveClientRealtimeInput(audio: blob));
    } else if (chunk.mimeType.startsWith('image/') ||
        chunk.mimeType.startsWith('video/')) {
      _sendRealtimeInput(core.LiveClientRealtimeInput(video: blob));
    } else {
      _sendRealtimeInput(core.LiveClientRealtimeInput(mediaChunks: [blob]));
    }
  }

  /// Resumes an existing live session with the server.
  ///
  /// This closes the current WebSocket connection and establishes a new one
  /// with the same configuration. The [receive] stream stays the same.
  Future<void> resumeSession(
      {SessionResumptionConfig? sessionResumption}) async {
    final previous = _core;
    _generation++;
    await previous.close().timeout(const Duration(seconds: 2),
        onTimeout: () {});
    await _open(sessionResumption);
  }

  /// Sends content to the server.
  ///
  /// [input] (optional): The content to send.
  /// [turnComplete] (optional): Indicates if the turn is complete. Defaults
  /// to false.
  Future<void> send({Content? input, bool turnComplete = false}) async {
    _checkWsStatus();
    _core.sendClientContent(
      turns: input == null ? null : [toCoreContent(input)],
      turnComplete: turnComplete,
    );
  }

  /// Sends tool responses for function calling to the server.
  Future<void> sendToolResponse(
      List<FunctionResponse>? functionResponses) async {
    _checkWsStatus();
    _core.sendMessage(
      core.LiveClientMessage(
        toolResponse: core.LiveClientToolResponse(
          functionResponses:
              functionResponses?.map(toCoreFunctionResponse).toList(),
        ),
      ),
    );
  }

  /// Sends audio data to the server in realtime.
  Future<void> sendAudioRealtime(InlineDataPart audio) async {
    _checkWsStatus();
    _sendRealtimeInput(core.LiveClientRealtimeInput(audio: toCoreBlob(audio)));
  }

  /// Sends video data to the server in realtime.
  Future<void> sendVideoRealtime(InlineDataPart video) async {
    _checkWsStatus();
    _sendRealtimeInput(core.LiveClientRealtimeInput(video: toCoreBlob(video)));
  }

  /// Sends text data to the server in realtime.
  Future<void> sendTextRealtime(String text) async {
    _checkWsStatus();
    _sendRealtimeInput(core.LiveClientRealtimeInput(text: text));
  }

  /// Manually marks the start of user activity, using the realtime API.
  ///
  /// Only required when automatic activity detection is disabled via
  /// [RealtimeInputConfig].
  Future<void> sendStartActivityRealtime() async {
    _checkWsStatus();
    _sendRealtimeInput(
        core.LiveClientRealtimeInput(activityStart: core.ActivityStart()));
  }

  /// Manually marks the end of user activity, using the realtime API.
  Future<void> sendStopActivityRealtime() async {
    _checkWsStatus();
    _sendRealtimeInput(
        core.LiveClientRealtimeInput(activityEnd: core.ActivityEnd()));
  }

  /// Sends realtime input (media chunks) to the server.
  @Deprecated(
      'Use sendAudioRealtime, sendVideoRealtime, or sendTextRealtime instead')
  Future<void> sendMediaChunks({
    required List<InlineDataPart> mediaChunks,
  }) async {
    _checkWsStatus();
    mediaChunks.forEach(_sendMediaChunk);
  }

  /// Starts streaming media chunks to the server from the provided
  /// [mediaChunkStream].
  ///
  /// The returned future completes when [mediaChunkStream] ends, so listen to
  /// [receive] before awaiting this (or do not await it).
  @Deprecated('Use sendAudio, sendVideo, or sendText with a stream instead')
  Future<void> sendMediaStream(Stream<InlineDataPart> mediaChunkStream) async {
    _checkWsStatus();
    try {
      await for (final chunk in mediaChunkStream) {
        _sendMediaChunk(chunk);
      }
    } catch (e) {
      throw FirebaseAISdkException(e.toString());
    }
  }

  /// Receives messages from the server.
  ///
  /// Messages that arrive before the first listener subscribes are buffered
  /// and delivered to it.
  Stream<LiveServerResponse> receive() {
    // Checked at call time: an async* body would only run on a later
    // microtask, after a socket that was open at the call may have closed.
    try {
      _checkWsStatus();
    } on LiveWebSocketClosedException catch (e, st) {
      return Stream.error(e, st);
    }
    return _controller.stream;
  }

  /// Closes the WebSocket connection.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _generation++;
    try {
      await _core.close().timeout(const Duration(seconds: 1),
          onTimeout: () {});
    } finally {
      _closeController();
    }
  }
}

/// Features that only gemini_live provides.
///
/// These do not exist in `package:firebase_ai`. Code that uses them must be
/// changed before moving back to firebase_ai.
extension GeminiLiveSessionExtras on LiveSession {
  /// Running token usage and cost for this session, fed by the server's
  /// usage metadata.
  GeminiTokenUsageTracker get tokenTracker => _tokenTracker;

  /// The underlying gemini_live core session, for features outside the
  /// firebase_ai API (for example `sendAudioStreamEnd`).
  core.LiveSession get rawSession => _core;
}

/// Features that only gemini_live provides. See [GeminiLiveSessionExtras].
extension GeminiLiveResponseExtras on LiveServerResponse {
  /// The full core message this response was converted from, including
  /// fields firebase_ai drops (usage metadata, grounding, voice activity).
  core.LiveServerMessage? get rawMessage => _rawMessages[this];
}
