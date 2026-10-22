// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import './platform/web_socket_service_stub.dart'
    if (dart.library.io) './platform/web_socket_service_io.dart'
    if (dart.library.html) './platform/web_socket_service_web.dart'
    as ws_connector;
import './platform/runtime_info_stub.dart'
    if (dart.library.io) './platform/runtime_info_io.dart'
    if (dart.library.html) './platform/runtime_info_web.dart'
    as runtime_info;

import 'model/models.dart';
import 'music_service.dart';

/// Signature for establishing a WebSocket channel to [uri] with [headers].
typedef WebSocketConnector =
    Future<WebSocketChannel> Function(Uri uri, Map<String, dynamic> headers);

// ============================================================================
// Live API Callbacks
// ============================================================================

/// Callbacks for Live API WebSocket lifecycle and message events.
class LiveCallbacks {
  /// Callback invoked when the WebSocket connection opens.
  final void Function()? onOpen;

  /// Callback invoked when a [LiveServerMessage] is received from the server.
  final void Function(LiveServerMessage message)? onMessage;

  /// Callback invoked when a connection or message parsing error occurs.
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// Callback invoked when the WebSocket connection closes.
  final void Function(int? closeCode, String? closeReason)? onClose;

  /// Creates a set of [LiveCallbacks] for a Live API session.
  const LiveCallbacks({this.onOpen, this.onMessage, this.onError, this.onClose});
}

// ============================================================================
// Live Connect Parameters
// ============================================================================

/// Parameters for establishing a Live API connection.
///
/// Use [LiveModels.gemini38Live] for default low-latency voice interactions,
/// or [LiveModels.gemini38LiveExtendedThinking] for high-reasoning tasks.
class LiveConnectParameters {
  /// The target Gemini Live model identifier.
  final String model;

  /// Lifecycle and message callbacks for the session.
  final LiveCallbacks callbacks;

  /// Optional nested generation configuration.
  final GenerationConfig? config;

  /// System instruction guiding the model's persona and behavior.
  final Content? systemInstruction;

  /// Tools and function declarations available to the model.
  final List<Tool>? tools;

  /// Configuration for realtime audio/video input and voice activity detection.
  final RealtimeInputConfig? realtimeInputConfig;

  /// Configuration for session resumption across reconnects.
  final SessionResumptionConfig? sessionResumption;

  /// Configuration for sliding-window context compression in long sessions.
  final ContextWindowCompressionConfig? contextWindowCompression;

  /// Configuration for user input audio transcription.
  final AudioTranscriptionConfig? inputAudioTranscription;

  /// Configuration for model output audio transcription.
  final AudioTranscriptionConfig? outputAudioTranscription;

  /// Proactivity configuration controlling when the model speaks up.
  final ProactivityConfig? proactivity;

  /// Whether explicit voice activity detection signals are enabled.
  final bool? explicitVadSignal;

  /// Avatar configuration for visual avatar streaming.
  final AvatarConfig? avatarConfig;

  /// Safety settings applied to model generation.
  final List<SafetySetting>? safetySettings;

  /// Configuration for exchanging prior conversation history with the server.
  ///
  /// See [HistoryConfig] for details.
  final HistoryConfig? historyConfig;

  /// User-defined metadata labels for tracking or billing categorization.
  final Map<String, String>? labels;

  /// Optional translation configuration for realtime bidirectional translation.
  final TranslationConfig? translationConfig;

  /// Requested response modalities (defaults to `[Modality.AUDIO]`).
  final List<Modality>? responseModalities;

  /// Sampling temperature controlling randomness in generation.
  final double? temperature;

  /// Nucleus sampling probability threshold.
  final double? topP;

  /// Top-K sampling token count threshold.
  final int? topK;

  /// Maximum number of output tokens per turn.
  final int? maxOutputTokens;

  /// Media resolution used when tokenizing visual inputs.
  final MediaResolution? mediaResolution;

  /// Random seed for deterministic generation.
  final int? seed;

  /// Speech synthesis and voice persona configuration.
  final SpeechConfig? speechConfig;

  /// Extended thinking and reasoning budget configuration.
  final ThinkingConfig? thinkingConfig;

  /// Whether affective dialog (emotion-aware prosody) is enabled.
  final bool? enableAffectiveDialog;

  /// Creates [LiveConnectParameters] for a Gemini Live session.
  LiveConnectParameters({
    required this.model,
    this.callbacks = const LiveCallbacks(),
    this.config,
    Object? systemInstruction,
    this.tools,
    this.realtimeInputConfig,
    this.sessionResumption,
    this.contextWindowCompression,
    this.inputAudioTranscription,
    this.outputAudioTranscription,
    this.proactivity,
    this.explicitVadSignal,
    this.avatarConfig,
    this.safetySettings,
    this.historyConfig,
    this.labels,
    this.translationConfig,
    this.responseModalities,
    this.temperature,
    this.topP,
    this.topK,
    this.maxOutputTokens,
    this.mediaResolution,
    this.seed,
    Object? speechConfig,
    this.thinkingConfig,
    this.enableAffectiveDialog,
  }) : systemInstruction = _parseSystemInstruction(systemInstruction),
       speechConfig = _parseSpeechConfig(speechConfig);

  static Content? _parseSystemInstruction(Object? value) {
    if (value == null) return null;
    if (value is Content) return value;
    if (value is String) {
      return Content(parts: [Part(text: value)], role: 'user');
    }
    if (value is Part) {
      return Content(parts: [value], role: 'user');
    }
    if (value is List<Part>) {
      return Content(parts: value, role: 'user');
    }
    if (value is Map<String, dynamic>) {
      if (value.containsKey('parts') || value.containsKey('role')) {
        return Content.fromJson(value);
      }
      return Content(parts: [Part.fromJson(value)], role: 'user');
    }
    throw ArgumentError.value(
      value,
      'systemInstruction',
      'Must be a Content, String, Part, List<Part>, or Map<String, dynamic>.',
    );
  }

  static SpeechConfig? _parseSpeechConfig(Object? value) {
    if (value == null) return null;
    if (value is SpeechConfig) return value;
    if (value is String) {
      return SpeechConfig(
        voiceConfig: VoiceConfig(
          prebuiltVoiceConfig: PrebuiltVoiceConfig(voiceName: value),
        ),
      );
    }
    if (value is Map<String, dynamic>) {
      return SpeechConfig.fromJson(value);
    }
    throw ArgumentError.value(
      value,
      'speechConfig',
      'Must be a SpeechConfig, String (voiceName), or Map<String, dynamic>.',
    );
  }
}

// ============================================================================
// Live Service
// ============================================================================

/// Service for connecting to the Gemini Live API via WebSocket.
class LiveService {
  static const _sdkVersion = '2.32.0';

  /// The Gemini Developer API key or ephemeral client auth token.
  final String apiKey;

  /// The target API version path segment (defaults to `'v1beta'`).
  final String apiVersion;
  static const _functionResponseRequiresId =
      'FunctionResponse request must have an `id` field from the response of a ToolCall.functionCalls in Gemini Live.';

  static UnsupportedError _unsupportedSafetyMethodError() {
    return UnsupportedError(
      'SafetySetting.method parameter is not supported in Gemini API.',
    );
  }

  final WebSocketConnector _connector;
  final Duration _setupTimeout;
  final String Function() _dartVersionProvider;

  /// Optional logger for WebSocket traffic.
  ///
  /// When `null` (default), logging is disabled. Set to `print` to log raw
  /// WebSocket frames.
  final void Function(String message)? logger;

  /// Service for generating realtime music streams (Lyria Live).
  late final LiveMusicService music;

  /// Creates a [LiveService] client configured with [apiKey] and [apiVersion].
  LiveService({
    required this.apiKey,
    this.apiVersion = 'v1beta',
    this.logger,
    WebSocketConnector? connector,
    Duration setupTimeout = const Duration(seconds: 10),
    String Function()? dartVersionProvider,
  }) : _connector = connector ?? ws_connector.connect,
       _setupTimeout = setupTimeout,
       _dartVersionProvider = dartVersionProvider ?? dartVersion {
    music = LiveMusicService(
      apiKey: apiKey,
      apiVersion: 'v1alpha',
      logger: logger,
      connector: _connector,
      setupTimeout: _setupTimeout,
      dartVersionProvider: _dartVersionProvider,
    );
  }

  /// Returns the current Dart runtime version string.
  static String dartVersion() {
    return runtime_info.dartVersion();
  }

  static GenerationConfig _normalizeGenerationConfig(
    LiveConnectParameters params,
  ) {
    final config = params.config;
    final effectiveTranslationConfig =
        params.translationConfig ?? config?.translationConfig;
    final effectiveSpeechConfig = params.speechConfig ?? config?.speechConfig;
    if (effectiveSpeechConfig?.multiSpeakerVoiceConfig != null) {
      throw UnsupportedError(
        'multiSpeakerVoiceConfig is not supported in the live API.',
      );
    }

    final responseModalities =
        params.responseModalities ?? config?.responseModalities;

    return GenerationConfig(
      temperature: params.temperature ?? config?.temperature,
      topK: params.topK ?? config?.topK,
      topP: params.topP ?? config?.topP,
      maxOutputTokens: params.maxOutputTokens ?? config?.maxOutputTokens,
      responseModalities:
          (responseModalities != null && responseModalities.isNotEmpty)
          ? responseModalities
          : const [Modality.AUDIO],
      mediaResolution: params.mediaResolution ?? config?.mediaResolution,
      seed: params.seed ?? config?.seed,
      speechConfig: effectiveSpeechConfig,
      thinkingConfig: params.thinkingConfig ?? config?.thinkingConfig,
      enableAffectiveDialog:
          params.enableAffectiveDialog ?? config?.enableAffectiveDialog,
      translationConfig: effectiveTranslationConfig,
      audioTranscriptionConfig: config?.audioTranscriptionConfig,
      labels: config?.labels,
    );
  }

  /// Normalizes and validates a model identifier matching upstream `tModel`.
  static String normalizeModelName(String model) {
    if (model.isEmpty) {
      throw ArgumentError('model is required and must be a non-empty string');
    }
    if (model.contains('..') || model.contains('?') || model.contains('&')) {
      throw ArgumentError('invalid model parameter');
    }
    if (model.startsWith('models/') || model.startsWith('tunedModels/')) {
      return model;
    }
    return 'models/$model';
  }

  /// Builds and validates the initial [LiveClientMessage] setup payload for [params].
  static LiveClientMessage buildSetupMessage(LiveConnectParameters params) {
    if (params.sessionResumption?.transparent == true) {
      throw UnsupportedError(
        'transparent parameter is not supported in Gemini API.',
      );
    }

    if (params.explicitVadSignal != null) {
      throw UnsupportedError(
        'explicitVadSignal parameter is not supported in Gemini API.',
      );
    }

    if ((params.safetySettings ?? const <SafetySetting>[]).any(
      (setting) => setting.method != null,
    )) {
      throw _unsupportedSafetyMethodError();
    }

    validateTools(params.tools);

    final modelName = normalizeModelName(params.model);

    return LiveClientMessage(
      setup: LiveClientSetup(
        model: modelName,
        generationConfig: _normalizeGenerationConfig(params),
        systemInstruction: params.systemInstruction,
        tools: params.tools,
        realtimeInputConfig: params.realtimeInputConfig,
        sessionResumption: params.sessionResumption,
        contextWindowCompression: params.contextWindowCompression,
        inputAudioTranscription: params.inputAudioTranscription,
        outputAudioTranscription: params.outputAudioTranscription,
        proactivity: params.proactivity,
        avatarConfig: params.avatarConfig,
        safetySettings: params.safetySettings,
        historyConfig: params.historyConfig,
        labels: params.labels ?? params.config?.labels,
      ),
    );
  }

  /// Validates that [tools] do not use Vertex/Enterprise-only search parameters
  /// unsupported in the Gemini Developer API.
  static void validateTools(List<Tool>? tools) {
    final list = tools ?? const <Tool>[];
    if (list.any((tool) => tool.retrieval != null)) {
      throw UnsupportedError(
        'retrieval parameter is not supported in Gemini API.',
      );
    }
    if (list.any((tool) => tool.enterpriseWebSearch != null)) {
      throw UnsupportedError(
        'enterpriseWebSearch parameter is not supported in Gemini API.',
      );
    }
    if (list.any((tool) => tool.exaAiSearch != null)) {
      throw UnsupportedError(
        'exaAiSearch parameter is not supported in Gemini API.',
      );
    }
    if (list.any((tool) => tool.parallelAiSearch != null)) {
      throw UnsupportedError(
        'parallelAiSearch parameter is not supported in Gemini API.',
      );
    }
  }

  /// Validates that every item in [functionResponses] has a non-empty `name`,
  /// `response`, and `id`.
  static List<FunctionResponse> validateFunctionResponses(
    List<FunctionResponse> functionResponses,
  ) {
    if (functionResponses.isEmpty) {
      throw ArgumentError('functionResponses is required.');
    }

    for (final functionResponse in functionResponses) {
      if (functionResponse.name == null || functionResponse.name!.isEmpty) {
        throw ArgumentError('Each function response must include a name.');
      }
      if (functionResponse.response == null) {
        throw ArgumentError('Each function response must include a response.');
      }
      if (functionResponse.id == null || functionResponse.id!.isEmpty) {
        throw ArgumentError(_functionResponseRequiresId);
      }
    }

    return functionResponses;
  }

  /// Validates that [blob] has a MIME type starting with [expectedPrefix].
  static void validateRealtimeBlob(
    Blob blob, {
    required String expectedPrefix,
  }) {
    if (!blob.mimeType.startsWith(expectedPrefix)) {
      throw ArgumentError('Unsupported mime type: ${blob.mimeType}');
    }
  }

  /// Handles incoming WebSocket data and converts it to LiveServerMessage.
  ///
  /// Parse errors and unexpected data types are reported to
  /// [LiveCallbacks.onError]. When a message parses successfully it is
  /// dispatched via [onMessage] if provided, otherwise to
  /// [LiveCallbacks.onMessage].
  void _handleWebSocketData(
    dynamic data,
    LiveCallbacks callbacks, {
    void Function(LiveServerMessage message)? onMessage,
  }) {
    String jsonData;
    if (data is String) {
      jsonData = data;
    } else if (data is List<int>) {
      jsonData = utf8.decode(data);
    } else {
      callbacks.onError?.call(
        Exception(
          'Received unexpected data type from WebSocket: ${data.runtimeType}',
        ),
        StackTrace.current,
      );
      return;
    }

    try {
      final json = jsonDecode(jsonData);
      logger?.call('📥 Received JSON: $jsonData');
      final message = LiveServerMessage.fromJson(json);
      if (message.error != null) {
        final err = message.error!;
        logger?.call('🔴 Live Server returned error: [${err.code} / ${err.status}] ${err.message}');
        callbacks.onError?.call(
          Exception('Live API Error ${err.code ?? ""} (${err.status ?? ""}): ${err.message ?? jsonData}'),
          StackTrace.current,
        );
      }
      final dispatch = onMessage ?? callbacks.onMessage;
      dispatch?.call(message);
    } catch (e, st) {
      logger?.call('🚨 JSON parse / message processing error: $e');
      callbacks.onError?.call(e, st);
    }
  }

  /// Processes incoming WebSocket [data] through [callbacks] for unit testing.
  void handleWebSocketDataForTesting(dynamic data, LiveCallbacks callbacks) {
    _handleWebSocketData(data, callbacks);
  }

  /// Establishes a WebSocket connection to the Live API using [params].
  Future<LiveSession> connect(LiveConnectParameters params) async {
    final usesEphemeralToken = apiKey.startsWith('auth_tokens/');
    if (usesEphemeralToken && apiVersion != 'v1alpha') {
      logger?.call(
        '⚠️ Warning: Ephemeral token support is only available on v1alpha. Current apiVersion: $apiVersion',
      );
    }

    final method = usesEphemeralToken
        ? 'BidiGenerateContentConstrained'
        : 'BidiGenerateContent';
    final keyName = usesEphemeralToken ? 'access_token' : 'key';

    final websocketUri = Uri(
      scheme: 'wss',
      host: 'generativelanguage.googleapis.com',
      path:
          '/ws/google.ai.generativelanguage.$apiVersion.GenerativeService.$method',
      queryParameters: {keyName: apiKey},
    );

    final userAgent =
        'google-genai-sdk/$_sdkVersion dart/${_dartVersionProvider()}';
    final hasMcpTools = (params.tools ?? const <Tool>[]).any(
      (tool) => tool.mcpServers != null && tool.mcpServers!.isNotEmpty,
    );
    final apiClientHeader = hasMcpTools
        ? '$userAgent mcp_used/unknown'
        : userAgent;

    logger?.call('🔌 Connecting to WebSocket at $websocketUri');

    try {
      final headers = {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
        'x-goog-api-client': apiClientHeader,
        'user-agent': userAgent,
      };
      final channel = await _connector(websocketUri, headers);
      final session = LiveSession._(channel, logger: logger);
      final setupCompleter = Completer<void>();

      // Until connect() resolves, successfully parsed messages (including the
      // setupComplete message itself) are queued instead of being forwarded to
      // callbacks.onMessage. Once resolved, the queue is flushed in arrival
      // order and subsequent messages flow directly to callbacks.onMessage.
      var sessionResolved = false;
      final messageQueue = <LiveServerMessage>[];

      StreamSubscription? streamSubscription;
      streamSubscription = channel.stream.listen(
        (data) {
          _handleWebSocketData(
            data,
            params.callbacks,
            onMessage: (message) {
              if (message.setupComplete != null &&
                  session.setupComplete == null) {
                session.setupComplete = message.setupComplete;
                if (!setupCompleter.isCompleted) {
                  setupCompleter.complete();
                }
              }
              if (sessionResolved) {
                params.callbacks.onMessage?.call(message);
              } else {
                messageQueue.add(message);
              }
            },
          );
        },
        onError: (error, stackTrace) {
          logger?.call('🚨 WebSocket stream error: $error');
          if (!setupCompleter.isCompleted) {
            setupCompleter.completeError(error, stackTrace);
          }
          params.callbacks.onError?.call(error, stackTrace);
        },
        onDone: () {
          logger?.call(
            '🔒 WebSocket connection closed (code: ${channel.closeCode}, reason: ${channel.closeReason})',
          );
          params.callbacks.onClose?.call(
            channel.closeCode,
            channel.closeReason,
          );
          streamSubscription?.cancel();
        },
        cancelOnError: true,
      );

      params.callbacks.onOpen?.call();
      final setupMessage = LiveService.buildSetupMessage(params);
      session.sendMessage(setupMessage);

      await setupCompleter.future.timeout(
        _setupTimeout,
        onTimeout: () {
          throw TimeoutException(
            'WebSocket setup timed out after $_setupTimeout.',
          );
        },
      );

      sessionResolved = true;
      for (final message in messageQueue) {
        params.callbacks.onMessage?.call(message);
      }
      messageQueue.clear();

      return session;
    } catch (e) {
      logger?.call("Failed to connect or setup WebSocket: $e");
      rethrow;
    }
  }
}

/// Exception thrown when a Live API operation exceeds its timeout.
class TimeoutException implements Exception {
  /// Description of the timeout failure.
  final String message;

  /// Creates a [TimeoutException] with the given [message].
  TimeoutException(this.message);

  @override
  String toString() => "TimeoutException: $message";
}

// ============================================================================
// Live Session
// ============================================================================

/// Represents an active Live API WebSocket session.
class LiveSession {
  final WebSocketChannel _channel;
  final void Function(String)? _logger;

  /// The setup acknowledgement returned by the server.
  ///
  /// Populated once the initial `setupComplete` message arrives during
  /// [LiveService.connect].
  LiveServerSetupComplete? setupComplete;

  LiveSession._(this._channel, {void Function(String)? logger})
    : _logger = logger;

  /// Creates a [LiveSession] backed by [channel] for unit testing.
  factory LiveSession.forTesting(WebSocketChannel channel) =>
      LiveSession._(channel);

  /// Sends a raw [LiveClientMessage] over the WebSocket channel.
  void sendMessage(LiveClientMessage message) {
    if (_channel.closeCode != null) {
      _logger?.call(
        '⚠️ Warning: Attempted to send a message on a closed WebSocket channel.',
      );
      return;
    }
    final jsonString = jsonEncode(message.toJson());
    _logger?.call('📤 Sending: $jsonString');
    _channel.sink.add(jsonString);
  }

  /// Sends a user text turn with [text] and marks the turn complete.
  void sendText(String text) {
    final message = LiveClientMessage(
      clientContent: LiveClientContent(
        turns: [
          Content(parts: [Part(text: text)]),
        ],
        turnComplete: true,
      ),
    );
    sendMessage(message);
  }

  /// Sends 16-bit PCM [audioBytes] to the server as realtime audio input.
  void sendAudio(List<int> audioBytes) {
    final base64Audio = base64Encode(audioBytes);
    final blob = Blob(mimeType: 'audio/pcm', data: base64Audio);
    final message = LiveClientMessage(
      realtimeInput: LiveClientRealtimeInput(
        audio: blob,
      ),
    );
    sendMessage(message);
  }

  /// Sends encoded image frame [videoBytes] with [mimeType] as realtime video input.
  void sendVideo(List<int> videoBytes, {String mimeType = 'image/jpeg'}) {
    final base64Video = base64Encode(videoBytes);
    final blob = Blob(mimeType: mimeType, data: base64Video);
    LiveService.validateRealtimeBlob(
      blob,
      expectedPrefix: 'image/',
    );
    final message = LiveClientMessage(
      realtimeInput: LiveClientRealtimeInput(
        video: blob,
      ),
    );
    sendMessage(message);
  }

  /// Sends client content with optional turns and turn completion flag.
  ///
  /// [turns] accepts a [String], [Part], [Content], or a `List` of any of
  /// those types (matching `ContentListUnion` in the reference JS/Python SDKs).
  void sendClientContent({Object? turns, bool turnComplete = true}) {
    final normalizedTurns = _normalizeTurns(turns);
    final message = LiveClientMessage(
      clientContent: LiveClientContent(
        turns: normalizedTurns,
        turnComplete: turnComplete,
      ),
    );
    sendMessage(message);
  }

  static void _validateRawPart(Part part) {
    if (part.functionCall != null || part.functionResponse != null) {
      throw ArgumentError(
        'To specify functionCall or functionResponse parts, please wrap them in a Content object, specifying the role for them',
      );
    }
  }

  static List<Content>? _normalizeTurns(Object? turns) {
    if (turns == null) return null;
    if (turns is List<Content>) return turns;
    if (turns is Content) return [turns];
    if (turns is String) {
      return [
        Content(role: 'user', parts: [Part(text: turns)]),
      ];
    }
    if (turns is Part) {
      _validateRawPart(turns);
      return [
        Content(role: 'user', parts: [turns]),
      ];
    }
    if (turns is Map<String, dynamic>) {
      if (turns.containsKey('parts') || turns.containsKey('role')) {
        return [Content.fromJson(turns)];
      }
      final part = Part.fromJson(turns);
      _validateRawPart(part);
      return [
        Content(role: 'user', parts: [part]),
      ];
    }
    if (turns is List) {
      if (turns.isEmpty) return <Content>[];
      var hasContent = false;
      var hasPart = false;
      final contents = <Content>[];
      final accumulatedParts = <Part>[];

      for (final item in turns) {
        if (item is Content) {
          hasContent = true;
          contents.add(item);
        } else if (item is String) {
          hasPart = true;
          accumulatedParts.add(Part(text: item));
        } else if (item is Part) {
          hasPart = true;
          _validateRawPart(item);
          accumulatedParts.add(item);
        } else if (item is Map<String, dynamic>) {
          if (item.containsKey('parts') || item.containsKey('role')) {
            hasContent = true;
            contents.add(Content.fromJson(item));
          } else {
            hasPart = true;
            final part = Part.fromJson(item);
            _validateRawPart(part);
            accumulatedParts.add(part);
          }
        } else {
          throw ArgumentError.value(
            item,
            'turns',
            'Each turn must be a Content, Part, String, or Map<String, dynamic>.',
          );
        }

        if (hasContent && hasPart) {
          throw ArgumentError(
            'Mixing Content and Parts is not supported, please group the parts into the appropriate Content objects and specify the roles for them',
          );
        }
      }

      if (hasPart) {
        return [Content(role: 'user', parts: accumulatedParts)];
      }
      return contents;
    }
    throw ArgumentError.value(
      turns,
      'turns',
      'Must be a Content, Part, String, or List.',
    );
  }

  static Blob _parseBlob(Object value, String argumentName) {
    if (value is Blob) return value;
    if (value is Map<String, dynamic>) return Blob.fromJson(value);
    throw ArgumentError.value(
      value,
      argumentName,
      'Must be a Blob or Map<String, dynamic>.',
    );
  }

  /// Sends realtime input with various media types.
  ///
  /// [media] accepts a single [Blob] (or `Map<String, dynamic>`) or
  /// `List<Blob>` (mapped to `mediaChunks` on the wire, matching
  /// `sendRealtimeInput({media})` in the reference SDKs).
  /// [audio] and [video] accept a [Blob] or `Map<String, dynamic>`.
  /// [activityStart] and [activityEnd] accept `true`, `{}` (`Map`), or an
  /// [ActivityStart] / [ActivityEnd] instance.
  void sendRealtimeInput({
    Object? media,
    List<Blob>? mediaChunks,
    Object? audio,
    Object? video,
    String? text,
    bool? audioStreamEnd,
    Object? activityStart,
    Object? activityEnd,
  }) {
    final resolvedAudio = audio != null ? _parseBlob(audio, 'audio') : null;
    final resolvedVideo = video != null ? _parseBlob(video, 'video') : null;
    if (resolvedAudio != null) {
      LiveService.validateRealtimeBlob(resolvedAudio, expectedPrefix: 'audio/');
    }
    if (resolvedVideo != null) {
      LiveService.validateRealtimeBlob(resolvedVideo, expectedPrefix: 'image/');
    }

    List<Blob>? resolvedChunks = mediaChunks;
    if (media != null) {
      final List<Blob> mediaList;
      if (media is Blob) {
        mediaList = <Blob>[media];
      } else if (media is Map<String, dynamic>) {
        mediaList = <Blob>[Blob.fromJson(media)];
      } else if (media is List<Blob>) {
        mediaList = media;
      } else if (media is List) {
        mediaList = media
            .map<Blob>((item) => _parseBlob(item as Object, 'media'))
            .toList();
      } else {
        throw ArgumentError.value(
          media,
          'media',
          'Must be a Blob, Map<String, dynamic>, or List<Blob>.',
        );
      }
      resolvedChunks = resolvedChunks == null
          ? mediaList
          : <Blob>[...resolvedChunks, ...mediaList];
    }

    final resolvedActivityStart = activityStart is ActivityStart
        ? activityStart
        : ((activityStart == true || activityStart is Map)
              ? ActivityStart()
              : null);
    final resolvedActivityEnd = activityEnd is ActivityEnd
        ? activityEnd
        : ((activityEnd == true || activityEnd is Map) ? ActivityEnd() : null);

    LiveClientRealtimeInput? realtimeInput;

    if (resolvedChunks != null ||
        resolvedAudio != null ||
        resolvedVideo != null ||
        text != null ||
        audioStreamEnd != null ||
        resolvedActivityStart != null ||
        resolvedActivityEnd != null) {
      realtimeInput = LiveClientRealtimeInput(
        mediaChunks: resolvedChunks,
        audio: resolvedAudio,
        video: resolvedVideo,
        text: text,
        audioStreamEnd: audioStreamEnd,
        activityStart: resolvedActivityStart,
        activityEnd: resolvedActivityEnd,
      );
    }

    if (realtimeInput != null) {
      final message = LiveClientMessage(realtimeInput: realtimeInput);
      sendMessage(message);
    }
  }

  /// Sends [mediaChunks] for realtime input.
  void sendMediaChunks(List<Blob> mediaChunks) {
    final message = LiveClientMessage(
      realtimeInput: LiveClientRealtimeInput(mediaChunks: mediaChunks),
    );
    sendMessage(message);
  }

  /// Sends a signal indicating the end of the audio stream.
  void sendAudioStreamEnd() {
    final message = LiveClientMessage(
      realtimeInput: LiveClientRealtimeInput(audioStreamEnd: true),
    );
    sendMessage(message);
  }

  /// Sends realtime [text] input over the session.
  void sendRealtimeText(String text) {
    final message = LiveClientMessage(
      realtimeInput: LiveClientRealtimeInput(text: text),
    );
    sendMessage(message);
  }

  /// Marks the start of user speech activity when automatic VAD is disabled.
  void sendActivityStart() {
    final message = LiveClientMessage(
      realtimeInput: LiveClientRealtimeInput(activityStart: ActivityStart()),
    );
    sendMessage(message);
  }

  /// Marks the end of user speech activity when automatic VAD is disabled.
  void sendActivityEnd() {
    final message = LiveClientMessage(
      realtimeInput: LiveClientRealtimeInput(activityEnd: ActivityEnd()),
    );
    sendMessage(message);
  }

  /// Sends a tool response to the server.
  ///
  /// [functionResponses] accepts a single [FunctionResponse], a
  /// `Map<String, dynamic>`, or a `List` of [FunctionResponse] /
  /// `Map<String, dynamic>`, matching the reference JS and Python SDKs.
  void sendToolResponse({required Object functionResponses}) {
    final List<FunctionResponse> list;
    if (functionResponses is FunctionResponse) {
      list = [functionResponses];
    } else if (functionResponses is Map<String, dynamic>) {
      list = [FunctionResponse.fromJson(functionResponses)];
    } else if (functionResponses is List<FunctionResponse>) {
      list = functionResponses;
    } else if (functionResponses is List) {
      list = functionResponses.map<FunctionResponse>((item) {
        if (item is FunctionResponse) return item;
        if (item is Map<String, dynamic>) {
          return FunctionResponse.fromJson(item);
        }
        throw ArgumentError.value(
          item,
          'functionResponses',
          'Each item must be a FunctionResponse or Map<String, dynamic>.',
        );
      }).toList();
    } else {
      throw ArgumentError.value(
        functionResponses,
        'functionResponses',
        'Must be a FunctionResponse, Map<String, dynamic>, or List.',
      );
    }
    final validatedResponses = LiveService.validateFunctionResponses(list);
    final message = LiveClientMessage(
      toolResponse: LiveClientToolResponse(
        functionResponses: validatedResponses,
      ),
    );
    sendMessage(message);
  }

  /// Sends a single function response with [id], [name], and [response].
  void sendFunctionResponse({
    required String id,
    required String name,
    required Map<String, dynamic> response,
  }) {
    sendToolResponse(
      functionResponses: [
        FunctionResponse(id: id, name: name, response: response),
      ],
    );
  }

  /// Sends an in-session context update (`systemInstruction` and/or `tools`)
  /// over the established WebSocket connection.
  ///
  /// Only fields that are set will be updated, and updates are guaranteed to
  /// be processed in order with the rest of the session inputs.
  ///
  /// Pass either an explicit [update] ([LiveClientContextUpdate]) or named
  /// [systemInstruction] ([String] or [Content]) and/or [tools] ([List<Tool>]
  /// or [LiveClientContextUpdateTools]). Pass `tools: const <Tool>[]` to clear
  /// all previously registered tools.
  void sendContextUpdate({
    LiveClientContextUpdate? update,
    Object? systemInstruction,
    Object? tools,
  }) {
    final resolved =
        update ??
        LiveClientContextUpdate(
          systemInstruction: systemInstruction,
          tools: tools,
        );
    if (resolved.systemInstruction == null && resolved.tools == null) {
      throw ArgumentError(
        'At least one of `systemInstruction` or `tools` must be set.',
      );
    }
    LiveService.validateTools(resolved.tools?.tools);
    sendMessage(LiveClientMessage(contextUpdate: resolved));
  }

  /// Closes the WebSocket connection.
  Future<void> close() async {
    await _channel.sink.close();
  }

  /// Whether the WebSocket connection is closed.
  bool get isClosed => _channel.closeCode != null;
}
