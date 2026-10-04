// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import './platform/runtime_info_stub.dart'
    if (dart.library.io) './platform/runtime_info_io.dart'
    if (dart.library.html) './platform/runtime_info_web.dart'
    as runtime_info;
import './platform/web_socket_service_stub.dart'
    if (dart.library.io) './platform/web_socket_service_io.dart'
    if (dart.library.html) './platform/web_socket_service_web.dart'
    as ws_connector;
import 'live_service.dart';
import 'model/models.dart';

// ============================================================================
// Live Music Callbacks
// ============================================================================

/// Callbacks for Realtime Music (Lyria Live) events.
class LiveMusicCallbacks {
  /// Called when the WebSocket connection is established.
  final void Function()? onOpen;

  /// Called when a message is received from the server.
  final void Function(LiveMusicServerMessage message)? onMessage;

  /// Called when a connection or decoding error occurs.
  final void Function(Object error, StackTrace stackTrace)? onError;

  /// Called when the WebSocket connection closes.
  final void Function(int? closeCode, String? closeReason)? onClose;

  /// Creates a container of callbacks for Realtime Music events.
  LiveMusicCallbacks({
    this.onOpen,
    this.onMessage,
    this.onError,
    this.onClose,
  });
}

// ============================================================================
// Live Music Connect Parameters
// ============================================================================

/// Parameters for establishing a Realtime Music generation session.
class LiveMusicConnectParameters {
  /// The model resource name. Defaults to [LiveMusicModels.lyriaRealtimeExp].
  final String model;

  /// Event callbacks.
  final LiveMusicCallbacks callbacks;

  /// Creates parameters for connecting to the Realtime Music service.
  LiveMusicConnectParameters({
    this.model = LiveMusicModels.lyriaRealtimeExp,
    required this.callbacks,
  });
}

// ============================================================================
// Live Music Session
// ============================================================================

/// Represents an active Realtime Music generation session via WebSocket.
class LiveMusicSession {
  final WebSocketChannel _channel;
  final void Function(String message)? _logger;

  StreamSubscription? _subscription;

  /// The setup confirmation message received from the server, if any.
  LiveMusicServerSetupComplete? setupComplete;

  LiveMusicSession._(
    this._channel, {
    void Function(String message)? logger,
  }) : _logger = logger;

  /// Sets or updates the weighted text prompts to steer music generation.
  ///
  /// At least one prompt is required. The server automatically normalizes
  /// weights across prompts.
  void setWeightedPrompts(List<WeightedPrompt> weightedPrompts) {
    if (weightedPrompts.isEmpty) {
      throw ArgumentError(
        'Weighted prompts must be set and contain at least one entry.',
      );
    }
    _send(
      LiveMusicClientMessage(
        clientContent: LiveMusicClientContent(weightedPrompts: weightedPrompts),
      ),
    );
  }

  /// Sets or updates the music generation configuration (BPM, scale, variance, etc.).
  ///
  /// Passing an empty config or `null` resets the configuration to server defaults.
  void setMusicGenerationConfig([LiveMusicGenerationConfig? config]) {
    _send(
      LiveMusicClientMessage(
        musicGenerationConfig: config ?? LiveMusicGenerationConfig(),
      ),
    );
  }

  /// Sends a playback control signal to the model.
  void sendPlaybackControl(LiveMusicPlaybackControl control) {
    _send(
      LiveMusicClientMessage(
        playbackControl: control,
      ),
    );
  }

  /// Starts or resumes the music stream from the current position.
  void play() => sendPlaybackControl(LiveMusicPlaybackControl.PLAY);

  /// Temporarily halts the music stream. Use [play] to resume.
  void pause() => sendPlaybackControl(LiveMusicPlaybackControl.PAUSE);

  /// Stops the music stream and resets generation state, retaining current prompts and config.
  void stop() => sendPlaybackControl(LiveMusicPlaybackControl.STOP);

  /// Resets the context of the music generation without stopping playback.
  void resetContext() =>
      sendPlaybackControl(LiveMusicPlaybackControl.RESET_CONTEXT);

  void _send(LiveMusicClientMessage message) {
    final jsonStr = jsonEncode(message.toJson());
    _logger?.call('LiveMusic -> $jsonStr');
    _channel.sink.add(jsonStr);
  }

  /// Terminates the music generation WebSocket session.
  Future<void> close() async {
    await _subscription?.cancel();
    await _channel.sink.close();
  }
}

// ============================================================================
// Live Music Service
// ============================================================================

/// Service for connecting to Gemini Realtime Music generation (Lyria Live).
class LiveMusicService {
  static const _sdkVersion = '2.27.0';

  /// The Gemini API key used for authentication.
  final String apiKey;

  /// The Gemini API version string (e.g. 'v1alpha').
  final String apiVersion;

  /// Optional logging sink for debugging WebSocket messages.
  final void Function(String message)? logger;
  final WebSocketConnector _connector;
  final Duration _setupTimeout;
  final String Function() _dartVersionProvider;

  /// Creates a Realtime Music service client.
  LiveMusicService({
    required this.apiKey,
    this.apiVersion = 'v1alpha',
    this.logger,
    WebSocketConnector? connector,
    Duration setupTimeout = const Duration(seconds: 10),
    String Function()? dartVersionProvider,
  })  : _connector = connector ?? ws_connector.connect,
        _setupTimeout = setupTimeout,
        _dartVersionProvider = dartVersionProvider ?? runtime_info.dartVersion;

  void _handleWebSocketData(
    dynamic data,
    LiveMusicCallbacks callbacks, {
    void Function(LiveMusicServerMessage message)? onMessage,
  }) {
    String jsonData;
    if (data is String) {
      jsonData = data;
    } else if (data is List<int>) {
      jsonData = utf8.decode(data);
    } else {
      callbacks.onError?.call(
        Exception('Received unexpected data type: ${data.runtimeType}'),
        StackTrace.current,
      );
      return;
    }

    try {
      final json = jsonDecode(jsonData) as Map<String, dynamic>;
      logger?.call('LiveMusic <- $jsonData');
      final message = LiveMusicServerMessage.fromJson(json);
      final dispatch = onMessage ?? callbacks.onMessage;
      dispatch?.call(message);
    } catch (e, st) {
      logger?.call('LiveMusic parse error: $e');
      callbacks.onError?.call(e, st);
    }
  }

  /// Establishes a WebSocket connection to the Realtime Music service.
  Future<LiveMusicSession> connect(LiveMusicConnectParameters params) async {
    final websocketUri = Uri(
      scheme: 'wss',
      host: 'generativelanguage.googleapis.com',
      path:
          '/ws/google.ai.generativelanguage.$apiVersion.GenerativeService.BidiGenerateMusic',
      queryParameters: {'key': apiKey},
    );

    final userAgent =
        'google-genai-sdk/$_sdkVersion dart/${_dartVersionProvider()}';
    logger?.call('🔌 Connecting to LiveMusic WebSocket at $websocketUri');

    try {
      final headers = {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
        'x-goog-api-client': userAgent,
        'user-agent': userAgent,
      };

      final channel = await _connector(websocketUri, headers);
      final session = LiveMusicSession._(channel, logger: logger);
      final setupCompleter = Completer<void>();

      var sessionResolved = false;
      final messageQueue = <LiveMusicServerMessage>[];

      session._subscription = channel.stream.listen(
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
        onError: (Object error, StackTrace stackTrace) {
          logger?.call('LiveMusic WebSocket Error: $error');
          if (!setupCompleter.isCompleted) {
            setupCompleter.completeError(error, stackTrace);
          }
          params.callbacks.onError?.call(error, stackTrace);
        },
        onDone: () {
          logger?.call(
            'LiveMusic WebSocket closed: code=${channel.closeCode} reason=${channel.closeReason}',
          );
          if (!setupCompleter.isCompleted) {
            setupCompleter.completeError(
              StateError('WebSocket closed before setup completed.'),
            );
          }
          params.callbacks.onClose?.call(
            channel.closeCode,
            channel.closeReason,
          );
        },
        cancelOnError: false,
      );

      params.callbacks.onOpen?.call();

      final modelName = params.model.startsWith('models/')
          ? params.model
          : 'models/${params.model}';

      final setupMessage = LiveMusicClientMessage(
        setup: LiveMusicClientSetup(model: modelName),
      );
      session._send(setupMessage);

      try {
        await setupCompleter.future.timeout(_setupTimeout);
      } on TimeoutException {
        unawaited(session.close());
        throw TimeoutException(
          'Timeout waiting for setupComplete message from Live Music server.',
        );
      }

      sessionResolved = true;
      for (final msg in messageQueue) {
        params.callbacks.onMessage?.call(msg);
      }
      messageQueue.clear();

      return session;
    } catch (e, st) {
      params.callbacks.onError?.call(e, st);
      rethrow;
    }
  }
}
