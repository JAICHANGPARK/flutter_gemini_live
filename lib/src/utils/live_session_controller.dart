import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../live_service.dart';
import '../model/models.dart';
import 'token_usage_tracker.dart';

/// Connection state of a [GeminiLiveSessionController].
enum LiveSessionState {
  /// Session is not connected.
  disconnected,

  /// Session is currently establishing WebSocket connection and handshake.
  connecting,

  /// Session is fully connected and ready for bi-directional streaming.
  connected,

  /// Session is disconnecting.
  disconnecting,

  /// Session encountered a fatal error.
  error,
}

/// A single transcribed turn or speech segment in the conversation history.
class LiveTranscriptItem {
  /// Speaker role, typically `'user'` or `'model'`.
  final String role;

  /// Transcribed text content.
  final String text;

  /// Optional speaker identifier or voice name.
  final String? speaker;

  /// Optional vocal style instruction.
  final String? style;

  /// Timestamp when this segment was created.
  final DateTime timestamp;

  /// Whether this turn is still receiving streaming text updates.
  final bool isStreaming;

  const LiveTranscriptItem({
    required this.role,
    required this.text,
    this.speaker,
    this.style,
    required this.timestamp,
    this.isStreaming = false,
  });

  LiveTranscriptItem copyWith({
    String? role,
    String? text,
    String? speaker,
    String? style,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return LiveTranscriptItem(
      role: role ?? this.role,
      text: text ?? this.text,
      speaker: speaker ?? this.speaker,
      style: style ?? this.style,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
    );
  }
}

/// High-level reactive state controller for managing Gemini Live sessions.
///
/// Implements [ChangeNotifier] to seamlessly integrate with Flutter's
/// `ListenableBuilder`, `AnimatedBuilder`, or state management solutions.
/// Handles connection lifecycle, token accounting via [GeminiTokenUsageTracker],
/// transcript accumulation, audio streams for visualizers, and error states.
class GeminiLiveSessionController extends ChangeNotifier {
  final LiveService liveService;
  final GeminiTokenUsageTracker tokenTracker;

  LiveSessionState _state = LiveSessionState.disconnected;
  LiveSession? _session;
  Object? _lastError;
  StackTrace? _lastStackTrace;

  bool _isModelSpeaking = false;
  bool _isUserSpeaking = false;
  bool _isInterrupted = false;
  String? _sessionId;

  final List<LiveTranscriptItem> _transcripts = [];
  String? _latestTranscript;
  String? _latestTranscriptRole;

  final StreamController<Uint8List> _incomingAudioController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _outgoingAudioController =
      StreamController<Uint8List>.broadcast();

  GeminiLiveSessionController({
    required this.liveService,
    GeminiTokenUsageTracker? tokenTracker,
  }) : tokenTracker = tokenTracker ?? GeminiTokenUsageTracker();

  /// Current session connection state.
  LiveSessionState get state => _state;

  /// Whether the session is active and ready for communication.
  bool get isConnected => _state == LiveSessionState.connected;

  /// Whether the model is currently speaking or streaming audio response.
  bool get isModelSpeaking => _isModelSpeaking;

  /// Whether the user is currently speaking or transmitting audio.
  bool get isUserSpeaking => _isUserSpeaking;

  /// Whether the model was interrupted by user speech during the current turn.
  bool get isInterrupted => _isInterrupted;

  /// Server session identifier assigned upon setup completion.
  String? get sessionId => _sessionId;

  /// Last error encountered by the session, if any.
  Object? get lastError => _lastError;

  /// Last error stack trace, if any.
  StackTrace? get lastStackTrace => _lastStackTrace;

  /// Full conversation transcript history.
  List<LiveTranscriptItem> get transcripts => List.unmodifiable(_transcripts);

  /// Latest transcribed text snippet.
  String? get latestTranscript => _latestTranscript;

  /// Role associated with the latest transcribed text (`'user'` or `'model'`).
  String? get latestTranscriptRole => _latestTranscriptRole;

  /// Broadcast stream of raw 16-bit linear PCM audio chunks received from Gemini.
  /// Ideal for piping into audio players or [GeminiLiveWaveform].
  Stream<Uint8List> get incomingAudioStream => _incomingAudioController.stream;

  /// Broadcast stream of raw 16-bit linear PCM audio chunks transmitted by the user.
  Stream<Uint8List> get outgoingAudioStream => _outgoingAudioController.stream;

  /// Active underlying [LiveSession], or `null` if not connected.
  LiveSession? get session => _session;

  /// Connects to the Gemini Live API.
  Future<void> connect(LiveConnectParameters params) async {
    if (_state == LiveSessionState.connecting || _state == LiveSessionState.connected) {
      return;
    }

    _setState(LiveSessionState.connecting);
    _lastError = null;
    _lastStackTrace = null;

    final wrappedCallbacks = LiveCallbacks(
      onOpen: () {
        params.callbacks.onOpen?.call();
      },
      onMessage: (message) {
        _handleServerMessage(message);
        params.callbacks.onMessage?.call(message);
      },
      onError: (error, stackTrace) {
        _lastError = error;
        _lastStackTrace = stackTrace;
        _setState(LiveSessionState.error);
        params.callbacks.onError?.call(error, stackTrace);
      },
      onClose: (closeCode, [closeReason]) {
        _handleClose(closeCode, closeReason);
        params.callbacks.onClose?.call(closeCode, closeReason);
      },
    );

    final wrappedParams = LiveConnectParameters(
      model: params.model,
      callbacks: wrappedCallbacks,
      config: params.config,
      systemInstruction: params.systemInstruction,
      tools: params.tools,
      realtimeInputConfig: params.realtimeInputConfig,
      sessionResumption: params.sessionResumption,
      contextWindowCompression: params.contextWindowCompression,
      inputAudioTranscription: params.inputAudioTranscription,
      outputAudioTranscription: params.outputAudioTranscription,
      proactivity: params.proactivity,
      explicitVadSignal: params.explicitVadSignal,
      avatarConfig: params.avatarConfig,
      safetySettings: params.safetySettings,
      historyConfig: params.historyConfig,
      labels: params.labels,
    );

    try {
      _session = await liveService.connect(wrappedParams);
      _setState(LiveSessionState.connected);
    } catch (e, st) {
      _lastError = e;
      _lastStackTrace = st;
      _setState(LiveSessionState.error);
      rethrow;
    }
  }

  void _handleServerMessage(LiveServerMessage message) {
    // 1. Setup complete
    if (message.setupComplete != null) {
      _sessionId = message.setupComplete!.sessionId;
      notifyListeners();
    }

    // 2. Server content / Model turn
    final serverContent = message.serverContent;
    if (serverContent != null) {
      // Barge-in interruption
      if (serverContent.interrupted == true) {
        _isInterrupted = true;
        _isModelSpeaking = false;
        notifyListeners();
      }

      final modelTurn = serverContent.modelTurn;
      if (modelTurn?.parts != null) {
        for (final part in modelTurn!.parts!) {
          // Audio chunk
          if (part.inlineData != null &&
              part.inlineData!.mimeType.startsWith('audio/')) {
            _isModelSpeaking = true;
            _isInterrupted = false;
            try {
              final bytes = Uint8List.fromList(base64Decode(part.inlineData!.data));
              _incomingAudioController.add(bytes);
            } catch (_) {}
          }

          // Text part
          if (part.text != null && part.text!.isNotEmpty) {
            _appendOrUpdateTranscript(
              role: 'model',
              text: part.text!,
              speaker: part.speechMetadata?.speaker,
              style: part.speechMetadata?.style,
              isStreaming: !(serverContent.turnComplete ?? false),
            );
          }
        }
      }

      // Input audio transcription (user STT)
      if (serverContent.inputTranscription?.text != null) {
        final text = serverContent.inputTranscription!.text!;
        if (text.isNotEmpty) {
          _appendOrUpdateTranscript(
            role: 'user',
            text: text,
            isStreaming: !(serverContent.turnComplete ?? false),
          );
        }
      }

      // Interim input transcription (streaming user STT)
      if (serverContent.interimInputTranscription?.text != null) {
        final text = serverContent.interimInputTranscription!.text!;
        if (text.isNotEmpty) {
          _appendOrUpdateTranscript(
            role: 'user',
            text: text,
            isStreaming: true,
          );
        }
      }

      // Output audio transcription (model STT)
      if (serverContent.outputTranscription?.text != null) {
        final text = serverContent.outputTranscription!.text!;
        if (text.isNotEmpty) {
          _appendOrUpdateTranscript(
            role: 'model',
            text: text,
            isStreaming: !(serverContent.turnComplete ?? false),
          );
        }
      }

      // Turn complete
      if (serverContent.turnComplete == true) {
        _isModelSpeaking = false;
        _finalizeStreamingTranscripts();
        notifyListeners();
      }
    }

    // 3. Track token consumption
    tokenTracker.recordMessage(message);
    notifyListeners();
  }

  void _appendOrUpdateTranscript({
    required String role,
    required String text,
    String? speaker,
    String? style,
    required bool isStreaming,
  }) {
    _latestTranscript = text;
    _latestTranscriptRole = role;

    if (_transcripts.isNotEmpty &&
        _transcripts.last.isStreaming &&
        _transcripts.last.role == role) {
      final last = _transcripts.last;
      _transcripts[_transcripts.length - 1] = last.copyWith(
        text: last.text + text,
        speaker: speaker ?? last.speaker,
        style: style ?? last.style,
        isStreaming: isStreaming,
      );
    } else {
      _transcripts.add(
        LiveTranscriptItem(
          role: role,
          text: text,
          speaker: speaker,
          style: style,
          timestamp: DateTime.now(),
          isStreaming: isStreaming,
        ),
      );
    }
    notifyListeners();
  }

  void _finalizeStreamingTranscripts() {
    for (int i = 0; i < _transcripts.length; i++) {
      if (_transcripts[i].isStreaming) {
        _transcripts[i] = _transcripts[i].copyWith(isStreaming: false);
      }
    }
  }

  void _handleClose(int? closeCode, [String? closeReason]) {
    _isModelSpeaking = false;
    _isUserSpeaking = false;
    _session = null;
    _setState(LiveSessionState.disconnected);
  }

  /// Sends a raw 16-bit linear PCM audio chunk to the model.
  void sendRealtimeAudio(
    Uint8List pcmBytes, {
    String mimeType = 'audio/pcm;rate=16000',
  }) {
    if (_session == null || !isConnected) return;

    _isUserSpeaking = true;
    _outgoingAudioController.add(pcmBytes);

    _session!.sendRealtimeInput(
      mediaChunks: [
        Blob(
          mimeType: mimeType,
          data: base64Encode(pcmBytes),
        ),
      ],
    );
    notifyListeners();
  }

  /// Informs the controller that the user has stopped speaking into the microphone.
  void stopUserSpeaking() {
    if (_isUserSpeaking) {
      _isUserSpeaking = false;
      notifyListeners();
    }
  }

  /// Sends a real-time text message to the model turn.
  void sendRealtimeText(String text, {bool turnComplete = true}) {
    if (_session == null || !isConnected) return;

    _appendOrUpdateTranscript(
      role: 'user',
      text: text,
      isStreaming: !turnComplete,
    );

    _session!.sendClientContent(
      turns: [
        Content(
          role: 'user',
          parts: [Part(text: text)],
        ),
      ],
      turnComplete: turnComplete,
    );
  }

  /// Sends a video frame or image buffer to the Gemini Live session.
  void sendRealtimeImage(
    Uint8List imageBytes, {
    String mimeType = 'image/jpeg',
  }) {
    if (_session == null || !isConnected) return;

    _session!.sendRealtimeInput(
      mediaChunks: [
        Blob(
          mimeType: mimeType,
          data: base64Encode(imageBytes),
        ),
      ],
    );
  }

  /// Sends tool / function call responses back to Gemini.
  void sendToolResponses(List<FunctionResponse> responses) {
    if (_session == null || !isConnected) return;
    _session!.sendToolResponse(functionResponses: responses);
  }

  /// Disconnects the active session cleanly.
  Future<void> disconnect({int? closeCode, String? closeReason}) async {
    if (_session == null) {
      _setState(LiveSessionState.disconnected);
      return;
    }

    _setState(LiveSessionState.disconnecting);
    await _session!.close();
    _session = null;
    _isModelSpeaking = false;
    _isUserSpeaking = false;
    _setState(LiveSessionState.disconnected);
  }

  /// Clears the recorded transcripts and resets the token tracker.
  void clearHistory() {
    _transcripts.clear();
    _latestTranscript = null;
    _latestTranscriptRole = null;
    tokenTracker.reset();
    notifyListeners();
  }

  void _setState(LiveSessionState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _session?.close();
    _incomingAudioController.close();
    _outgoingAudioController.close();
    super.dispose();
  }
}
