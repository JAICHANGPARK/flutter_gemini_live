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

typedef WebSocketConnector =
    Future<WebSocketChannel> Function(Uri uri, Map<String, dynamic> headers);

// ============================================================================
// Live API Callbacks
// ============================================================================

/// Callbacks for Live API events
class LiveCallbacks {
  final void Function()? onOpen;
  final void Function(LiveServerMessage message)? onMessage;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final void Function(int? closeCode, String? closeReason)? onClose;

  LiveCallbacks({this.onOpen, this.onMessage, this.onError, this.onClose});
}

// ============================================================================
// Live Connect Parameters
// ============================================================================

/// Parameters for establishing a Live API connection
class LiveConnectParameters {
  final String model;
  final LiveCallbacks callbacks;
  final GenerationConfig? config;
  final Content? systemInstruction;
  final List<Tool>? tools;

  // New configuration options
  final RealtimeInputConfig? realtimeInputConfig;
  final SessionResumptionConfig? sessionResumption;
  final ContextWindowCompressionConfig? contextWindowCompression;
  final AudioTranscriptionConfig? inputAudioTranscription;
  final AudioTranscriptionConfig? outputAudioTranscription;
  final ProactivityConfig? proactivity;
  final bool? explicitVadSignal;
  final AvatarConfig? avatarConfig;
  final List<SafetySetting>? safetySettings;

  LiveConnectParameters({
    required this.model,
    required this.callbacks,
    this.config,
    this.systemInstruction,
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
  });
}

// ============================================================================
// Live Service
// ============================================================================

/// Service for connecting to the Gemini Live API via WebSocket
class LiveService {
  static const _sdkVersion = '1.50.1';
  final String apiKey;
  final String apiVersion;
  static const _functionResponseRequiresId =
      'FunctionResponse request must have an `id` field from the response of a ToolCall.functionCalls in Gemini Live.';

  static UnsupportedError _unsupportedAudioTranscriptionLanguageCodesError() {
    return UnsupportedError(
      'languageCodes parameter is not supported in Gemini API.',
    );
  }

  static UnsupportedError _unsupportedSafetyMethodError() {
    return UnsupportedError(
      'SafetySetting.method parameter is not supported in Gemini API.',
    );
  }

  final WebSocketConnector _connector;
  final Duration _setupTimeout;
  final String Function() _dartVersionProvider;

  /// Optional logger for WebSocket traffic. When null (default), logging is
  /// disabled. Set to `print` to restore the previous verbose behavior.
  final void Function(String message)? logger;

  LiveService({
    required this.apiKey,
    this.apiVersion = 'v1beta',
    this.logger,
    WebSocketConnector? connector,
    Duration setupTimeout = const Duration(seconds: 10),
    String Function()? dartVersionProvider,
  }) : _connector = connector ?? ws_connector.connect,
       _setupTimeout = setupTimeout,
       _dartVersionProvider = dartVersionProvider ?? dartVersion;

  /// Returns the current Dart version
  static String dartVersion() {
    return runtime_info.dartVersion();
  }

  static GenerationConfig _normalizeGenerationConfig(GenerationConfig? config) {
    final responseModalities = config?.responseModalities;
    if (responseModalities != null && responseModalities.isNotEmpty) {
      return config!;
    }

    return GenerationConfig(
      temperature: config?.temperature,
      topK: config?.topK,
      topP: config?.topP,
      maxOutputTokens: config?.maxOutputTokens,
      responseModalities: const [Modality.AUDIO],
      mediaResolution: config?.mediaResolution,
      seed: config?.seed,
      speechConfig: config?.speechConfig,
      thinkingConfig: config?.thinkingConfig,
      enableAffectiveDialog: config?.enableAffectiveDialog,
    );
  }

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

    if (params.inputAudioTranscription?.languageCodes != null) {
      throw _unsupportedAudioTranscriptionLanguageCodesError();
    }

    if (params.outputAudioTranscription?.languageCodes != null) {
      throw _unsupportedAudioTranscriptionLanguageCodesError();
    }

    if ((params.safetySettings ?? const <SafetySetting>[]).any(
      (setting) => setting.method != null,
    )) {
      throw _unsupportedSafetyMethodError();
    }

    final modelName = params.model.startsWith('models/')
        ? params.model
        : 'models/${params.model}';

    return LiveClientMessage(
      setup: LiveClientSetup(
        model: modelName,
        generationConfig: _normalizeGenerationConfig(params.config),
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
      ),
    );
  }

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

  static void validateRealtimeBlob(
    Blob blob, {
    required String expectedPrefix,
  }) {
    if (!blob.mimeType.startsWith(expectedPrefix)) {
      throw ArgumentError('Unsupported mime type: ${blob.mimeType}');
    }
  }

  /// Handles incoming WebSocket data and converts it to LiveServerMessage
  void _handleWebSocketData(dynamic data, LiveCallbacks callbacks) {
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
      callbacks.onMessage?.call(message);
    } catch (e, st) {
      callbacks.onError?.call(e, st);
    }
  }

  void handleWebSocketDataForTesting(dynamic data, LiveCallbacks callbacks) {
    _handleWebSocketData(data, callbacks);
  }

  /// Establishes a WebSocket connection to the Live API
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

    logger?.call('🔌 Connecting to WebSocket at $websocketUri');

    try {
      final headers = {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
        'x-goog-api-client': userAgent,
        'user-agent': userAgent,
      };
      final channel = await _connector(websocketUri, headers);
      final session = LiveSession._(channel, logger: logger);
      final setupCompleter = Completer<void>();

      StreamSubscription? streamSubscription;
      streamSubscription = channel.stream.listen(
        (data) {
          final jsonData = data is String
              ? data
              : utf8.decode(data as List<int>);
          logger?.call('📥 Received: $jsonData');

          if (!setupCompleter.isCompleted) {
            try {
              setupCompleter.complete();
            } catch (e) {
              // Ignore parsing errors during setup
            }
          }
          _handleWebSocketData(data, params.callbacks);
        },
        onError: (error, stackTrace) {
          if (!setupCompleter.isCompleted) {
            setupCompleter.completeError(error, stackTrace);
          }
          params.callbacks.onError?.call(error, stackTrace);
        },
        onDone: () {
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

      return session;
    } catch (e) {
      logger?.call("Failed to connect or setup WebSocket: $e");
      rethrow;
    }
  }
}

/// Exception for timeout errors
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => "TimeoutException: $message";
}

// ============================================================================
// Live Session
// ============================================================================

/// Represents an active Live API session
class LiveSession {
  final WebSocketChannel _channel;
  final void Function(String)? _logger;

  LiveSession._(this._channel, {void Function(String)? logger}) : _logger = logger;

  factory LiveSession.forTesting(WebSocketChannel channel) =>
      LiveSession._(channel);

  /// Sends a message to the server
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

  /// Sends text content to the server
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

  /// Sends audio data to the server
  void sendAudio(List<int> audioBytes) {
    final base64Audio = base64Encode(audioBytes);
    final message = LiveClientMessage(
      realtimeInput: LiveClientRealtimeInput(
        audio: Blob(mimeType: 'audio/pcm', data: base64Audio),
      ),
    );
    sendMessage(message);
  }

  /// Sends video data to the server
  void sendVideo(List<int> videoBytes, {String mimeType = 'image/jpeg'}) {
    final base64Video = base64Encode(videoBytes);
    LiveService.validateRealtimeBlob(
      Blob(mimeType: mimeType, data: base64Video),
      expectedPrefix: 'image/',
    );
    final message = LiveClientMessage(
      realtimeInput: LiveClientRealtimeInput(
        video: Blob(mimeType: mimeType, data: base64Video),
      ),
    );
    sendMessage(message);
  }

  /// Sends client content with optional turns and turn completion flag
  void sendClientContent({List<Content>? turns, bool turnComplete = true}) {
    final message = LiveClientMessage(
      clientContent: LiveClientContent(
        turns: turns,
        turnComplete: turnComplete,
      ),
    );
    sendMessage(message);
  }

  /// Sends realtime input with various media types
  void sendRealtimeInput({
    List<Blob>? mediaChunks,
    Blob? audio,
    Blob? video,
    String? text,
    bool? audioStreamEnd,
    bool? activityStart,
    bool? activityEnd,
  }) {
    if (audio != null) {
      LiveService.validateRealtimeBlob(audio, expectedPrefix: 'audio/');
    }
    if (video != null) {
      LiveService.validateRealtimeBlob(video, expectedPrefix: 'image/');
    }

    LiveClientRealtimeInput? realtimeInput;

    if (mediaChunks != null ||
        audio != null ||
        video != null ||
        text != null ||
        audioStreamEnd != null ||
        activityStart != null ||
        activityEnd != null) {
      realtimeInput = LiveClientRealtimeInput(
        mediaChunks: mediaChunks,
        audio: audio,
        video: video,
        text: text,
        audioStreamEnd: audioStreamEnd,
        activityStart: activityStart == true ? ActivityStart() : null,
        activityEnd: activityEnd == true ? ActivityEnd() : null,
      );
    }

    if (realtimeInput != null) {
      final message = LiveClientMessage(realtimeInput: realtimeInput);
      sendMessage(message);
    }
  }

  /// Sends media chunks for realtime input
  void sendMediaChunks(List<Blob> mediaChunks) {
    final message = LiveClientMessage(
      realtimeInput: LiveClientRealtimeInput(mediaChunks: mediaChunks),
    );
    sendMessage(message);
  }

  /// Sends a signal indicating the end of audio stream
  void sendAudioStreamEnd() {
    final message = LiveClientMessage(
      realtimeInput: LiveClientRealtimeInput(audioStreamEnd: true),
    );
    sendMessage(message);
  }

  /// Sends realtime text input
  void sendRealtimeText(String text) {
    final message = LiveClientMessage(
      realtimeInput: LiveClientRealtimeInput(text: text),
    );
    sendMessage(message);
  }

  /// Marks the start of user activity (when automatic VAD is disabled)
  void sendActivityStart() {
    final message = LiveClientMessage(
      realtimeInput: LiveClientRealtimeInput(activityStart: ActivityStart()),
    );
    sendMessage(message);
  }

  /// Marks the end of user activity (when automatic VAD is disabled)
  void sendActivityEnd() {
    final message = LiveClientMessage(
      realtimeInput: LiveClientRealtimeInput(activityEnd: ActivityEnd()),
    );
    sendMessage(message);
  }

  /// Sends a tool response to the server
  void sendToolResponse({required List<FunctionResponse> functionResponses}) {
    final validatedResponses = LiveService.validateFunctionResponses(
      functionResponses,
    );
    final message = LiveClientMessage(
      toolResponse: LiveClientToolResponse(
        functionResponses: validatedResponses,
      ),
    );
    sendMessage(message);
  }

  /// Sends a single function response
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

  /// Closes the WebSocket connection
  Future<void> close() async {
    await _channel.sink.close();
  }

  /// Returns true if the connection is closed
  bool get isClosed => _channel.closeCode != null;
}
