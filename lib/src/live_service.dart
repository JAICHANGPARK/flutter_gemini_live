import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:web_socket_channel/web_socket_channel.dart';

import './platform/web_socket_service_stub.dart'
    if (dart.library.io) './platform/web_socket_service_io.dart'
    if (dart.library.html) './platform/web_socket_service_web.dart'
    as ws_connector;

import 'model/models.dart';

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
  });
}

// ============================================================================
// Live Service
// ============================================================================

/// Service for connecting to the Gemini Live API via WebSocket
class LiveService {
  final String apiKey;
  final String apiVersion;

  LiveService({required this.apiKey, this.apiVersion = 'v1beta'});

  /// Returns the current Dart version
  static String dartVersion() {
    final version = Platform.version;
    // Extract major.minor version
    final match = RegExp(r'(\d+)\.(\d+)').firstMatch(version);
    return match != null ? '${match.group(1)}.${match.group(2)}' : '3.0';
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
      print('📥 Received JSON: $jsonData');
      final message = LiveServerMessage.fromJson(json);
      callbacks.onMessage?.call(message);
    } catch (e, st) {
      callbacks.onError?.call(e, st);
    }
  }

  /// Establishes a WebSocket connection to the Live API
  Future<LiveSession> connect(LiveConnectParameters params) async {
    final websocketUri = Uri.parse(
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.$apiVersion.GenerativeService.BidiGenerateContent?key=$apiKey',
    );

    final userAgent = 'google-genai-sdk/1.39.0 dart/${dartVersion()}';

    print('🔌 Connecting to WebSocket at $websocketUri');

    try {
      final headers = {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
        'x-goog-api-client': userAgent,
        'user-agent': userAgent,
      };
      final channel = await ws_connector.connect(websocketUri, headers);
      final session = LiveSession._(channel);
      final setupCompleter = Completer<void>();

      StreamSubscription? streamSubscription;
      streamSubscription = channel.stream.listen(
        (data) {
          final jsonData = data is String
              ? data
              : utf8.decode(data as List<int>);
          print('📥 Received: $jsonData');

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

      final modelName = params.model.startsWith('models/')
          ? params.model
          : 'models/${params.model}';

      // Create setup message with all configuration options
      final setupMessage = LiveClientMessage(
        setup: LiveClientSetup(
          model: modelName,
          generationConfig: params.config,
          systemInstruction: params.systemInstruction,
          tools: params.tools,
          realtimeInputConfig: params.realtimeInputConfig,
          sessionResumption: params.sessionResumption,
          contextWindowCompression: params.contextWindowCompression,
          inputAudioTranscription: params.inputAudioTranscription,
          outputAudioTranscription: params.outputAudioTranscription,
          proactivity: params.proactivity,
          explicitVadSignal: params.explicitVadSignal,
        ),
      );
      session.sendMessage(setupMessage);

      await setupCompleter.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException("WebSocket setup timed out after 10 seconds.");
        },
      );

      return session;
    } catch (e) {
      print("Failed to connect or setup WebSocket: $e");
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

  LiveSession._(this._channel);

  /// Sends a message to the server
  void sendMessage(LiveClientMessage message) {
    if (_channel.closeCode != null) {
      print(
        '⚠️ Warning: Attempted to send a message on a closed WebSocket channel.',
      );
      return;
    }
    final jsonString = jsonEncode(message.toJson());
    print('📤 Sending: $jsonString');
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
    final message = LiveClientMessage(
      toolResponse: LiveClientToolResponse(
        functionResponses: functionResponses,
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
