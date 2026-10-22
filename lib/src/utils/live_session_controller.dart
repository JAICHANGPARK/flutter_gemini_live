import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../live_service.dart';
import '../model/models.dart';
import 'pcm_audio_buffer.dart';
import 'reconnect_policy.dart';
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

  /// Optional image attachment bytes for multimodal user turns.
  final Uint8List? imageBytes;

  /// Optional MIME type for attached image (e.g. `'image/jpeg'`).
  final String? imageMimeType;

  /// Timestamp when this segment was created.
  final DateTime timestamp;

  /// Whether this turn is still receiving streaming text updates.
  final bool isStreaming;

  /// Creates a live transcript history item.
  const LiveTranscriptItem({
    required this.role,
    required this.text,
    this.speaker,
    this.style,
    this.imageBytes,
    this.imageMimeType,
    required this.timestamp,
    this.isStreaming = false,
  });

  /// Creates a copy of this transcript item with specified attributes replaced.
  LiveTranscriptItem copyWith({
    String? role,
    String? text,
    String? speaker,
    String? style,
    Uint8List? imageBytes,
    String? imageMimeType,
    DateTime? timestamp,
    bool? isStreaming,
  }) {
    return LiveTranscriptItem(
      role: role ?? this.role,
      text: text ?? this.text,
      speaker: speaker ?? this.speaker,
      style: style ?? this.style,
      imageBytes: imageBytes ?? this.imageBytes,
      imageMimeType: imageMimeType ?? this.imageMimeType,
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
/// transcript accumulation, audio streams for visualizers, tool execution state,
/// session resumption handles, and optional automatic reconnection via
/// [GeminiLiveReconnectPolicy].
class GeminiLiveSessionController extends ChangeNotifier {
  /// The underlying Live API service for establishing sessions.
  final LiveService liveService;

  /// The token accounting tracker monitoring consumption and estimated cost.
  final GeminiTokenUsageTracker tokenTracker;

  /// Optional automatic reconnection policy when `GoAway` or abnormal close occurs.
  final GeminiLiveReconnectPolicy? reconnectPolicy;

  LiveSessionState _state = LiveSessionState.disconnected;
  LiveSession? _session;
  LiveConnectParameters? _lastConnectParams;
  Object? _lastError;
  StackTrace? _lastStackTrace;

  bool _isModelSpeaking = false;
  bool _isUserSpeaking = false;
  bool _isInterrupted = false;
  bool _isThinking = false;
  bool _manualDisconnectRequested = false;
  bool _isReconnecting = false;
  int _reconnectAttempt = 0;
  Timer? _reconnectTimer;

  String? _sessionId;
  String? _latestSessionHandle;
  bool _isSessionResumable = false;
  LiveServerGoAway? _lastGoAway;

  Content? _activeSystemInstruction;
  List<Tool> _activeTools = const [];

  final List<String> _thoughts = [];
  String? _latestThought;
  bool _currentTurnThoughtActive = false;

  final List<FunctionCall> _activeToolCalls = [];
  final GeminiLiveAudioBuffer _currentTurnAudioBuffer = GeminiLiveAudioBuffer(
    sampleRate: 24000,
    numChannels: 1,
    bitsPerSample: 16,
  );
  Uint8List? _lastCompletedTurnWav;

  final List<LiveTranscriptItem> _transcripts = [];
  String? _latestTranscript;
  String? _latestTranscriptRole;

  final StreamController<Uint8List> _incomingAudioController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _outgoingAudioController =
      StreamController<Uint8List>.broadcast();

  /// Creates a reactive controller managing Gemini Live session state.
  GeminiLiveSessionController({
    required this.liveService,
    GeminiTokenUsageTracker? tokenTracker,
    this.reconnectPolicy,
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

  /// Whether the model is currently streaming internal Extended Thinking (`thought: true`) parts.
  bool get isThinking => _isThinking;

  /// Latest reasoning/thought text emitted by the model during Extended Thinking.
  String? get latestThought => _latestThought;

  /// History of model reasoning/thought texts recorded across turns.
  List<String> get thoughts => List.unmodifiable(_thoughts);

  /// Currently active system instruction (initialized on [connect] and updated via [sendContextUpdate]).
  Content? get activeSystemInstruction => _activeSystemInstruction;

  /// Currently active tools registered in the session (initialized on [connect] and updated via [sendContextUpdate]).
  List<Tool> get activeTools => List.unmodifiable(_activeTools);

  /// Whether the controller is currently attempting an automatic reconnection.
  bool get isReconnecting => _isReconnecting;

  /// Current reconnection attempt count (`0` when connected normally).
  int get reconnectAttempt => _reconnectAttempt;

  /// Server session identifier assigned upon setup completion.
  String? get sessionId => _sessionId;

  /// Latest session resumption handle emitted by the server (`sessionResumptionUpdate.newHandle`).
  String? get latestSessionHandle => _latestSessionHandle;

  /// Whether the current session state is marked as resumable by the server.
  bool get isSessionResumable => _isSessionResumable;

  /// Latest `GoAway` notice emitted by the server, if any.
  LiveServerGoAway? get lastGoAway => _lastGoAway;

  /// Currently active (in-flight) function calls requested by the model.
  List<FunctionCall> get activeToolCalls => List.unmodifiable(_activeToolCalls);

  /// Whether one or more tool/function calls are currently awaiting responses.
  bool get isExecutingTool => _activeToolCalls.isNotEmpty;

  /// Audio buffer accumulating 24kHz 16-bit mono PCM chunks for the current model turn.
  GeminiLiveAudioBuffer get currentTurnAudioBuffer => _currentTurnAudioBuffer;

  /// Exports the most recently completed (or current in-progress) model speech turn
  /// as a complete 24kHz 16-bit mono WAV byte array, or `null` if no audio was received.
  Uint8List? exportLastTurnWav() {
    if (_currentTurnAudioBuffer.isNotEmpty) {
      return _currentTurnAudioBuffer.toWavBytes();
    }
    return _lastCompletedTurnWav;
  }

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

    _manualDisconnectRequested = false;
    _reconnectTimer?.cancel();
    _lastConnectParams = params;
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

    final effectiveSessionResumption = (_latestSessionHandle != null &&
            (params.sessionResumption != null || reconnectPolicy != null))
        ? SessionResumptionConfig(
            handle: _latestSessionHandle,
            transparent: params.sessionResumption?.transparent,
          )
        : params.sessionResumption;

    _activeSystemInstruction = params.systemInstruction;
    _activeTools = params.tools != null ? List<Tool>.from(params.tools!) : const [];

    final wrappedParams = LiveConnectParameters(
      model: params.model,
      callbacks: wrappedCallbacks,
      config: params.config,
      systemInstruction: params.systemInstruction,
      tools: params.tools,
      realtimeInputConfig: params.realtimeInputConfig,
      sessionResumption: effectiveSessionResumption,
      contextWindowCompression: params.contextWindowCompression,
      inputAudioTranscription: params.inputAudioTranscription,
      outputAudioTranscription: params.outputAudioTranscription,
      proactivity: params.proactivity,
      explicitVadSignal: params.explicitVadSignal,
      avatarConfig: params.avatarConfig,
      safetySettings: params.safetySettings,
      historyConfig: params.historyConfig,
      labels: params.labels,
      translationConfig: params.translationConfig,
      responseModalities: params.responseModalities,
      temperature: params.temperature,
      topP: params.topP,
      topK: params.topK,
      maxOutputTokens: params.maxOutputTokens,
      mediaResolution: params.mediaResolution,
      seed: params.seed,
      speechConfig: params.speechConfig,
      thinkingConfig: params.thinkingConfig,
      enableAffectiveDialog: params.enableAffectiveDialog,
    );

    try {
      _session = await liveService.connect(wrappedParams);
      _reconnectAttempt = 0;
      _isReconnecting = false;
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

    // 1b. Session resumption handle update
    if (message.sessionResumptionUpdate != null) {
      final update = message.sessionResumptionUpdate!;
      if (update.newHandle != null && update.newHandle!.isNotEmpty) {
        _latestSessionHandle = update.newHandle;
      }
      if (update.resumable != null) {
        _isSessionResumable = update.resumable!;
      }
      notifyListeners();
    }

    // 1c. GoAway server notice
    if (message.goAway != null) {
      _lastGoAway = message.goAway;
      notifyListeners();
      if (reconnectPolicy != null &&
          reconnectPolicy!.reconnectOnGoAway &&
          !_manualDisconnectRequested) {
        _scheduleReconnect();
      }
    }

    // 1d. Tool calls & cancellations
    if (message.toolCall?.functionCalls != null &&
        message.toolCall!.functionCalls!.isNotEmpty) {
      _activeToolCalls.addAll(message.toolCall!.functionCalls!);
      notifyListeners();
    }
    if (message.toolCallCancellation?.ids != null &&
        message.toolCallCancellation!.ids!.isNotEmpty) {
      final cancelledIds = message.toolCallCancellation!.ids!.toSet();
      _activeToolCalls.removeWhere(
        (call) => call.id != null && cancelledIds.contains(call.id),
      );
      notifyListeners();
    }

    // 2. Server content / Model turn
    final serverContent = message.serverContent;
    if (serverContent != null) {
      // Barge-in interruption
      if (serverContent.interrupted == true) {
        _isInterrupted = true;
        _isModelSpeaking = false;
        _isThinking = false;
        _currentTurnThoughtActive = false;
        _currentTurnAudioBuffer.clear();
        _finalizeStreamingTranscripts();
        notifyListeners();
      }

      final modelTurn = serverContent.modelTurn;
      if (modelTurn?.parts != null) {
        for (final part in modelTurn!.parts!) {
          // Extended Thinking thought part
          if (part.thought == true && part.text != null && part.text!.isNotEmpty) {
            _isThinking = true;
            if (_currentTurnThoughtActive && _thoughts.isNotEmpty) {
              _thoughts[_thoughts.length - 1] = _thoughts.last + part.text!;
            } else {
              _currentTurnThoughtActive = true;
              _thoughts.add(part.text!);
            }
            _latestThought = _thoughts.last;
          }

          // Audio chunk
          if (part.inlineData != null &&
              part.inlineData!.mimeType.startsWith('audio/')) {
            _isThinking = false;
            _isModelSpeaking = true;
            _isInterrupted = false;
            try {
              final bytes = Uint8List.fromList(base64Decode(part.inlineData!.data));
              _currentTurnAudioBuffer.add(bytes);
              _incomingAudioController.add(bytes);
            } catch (_) {}
          }

          // Text part (skip internal thought parts)
          if (part.text != null &&
              part.text!.isNotEmpty &&
              part.thought != true) {
            _isThinking = false;
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
        final transcription = serverContent.inputTranscription!;
        final text = transcription.text!;
        if (text.isNotEmpty) {
          _appendOrUpdateTranscript(
            role: 'user',
            text: text,
            speaker: transcription.speakerLabel,
            isStreaming: !(serverContent.turnComplete ?? false) &&
                !(transcription.finished ?? false),
          );
        }
      }

      // Interim input transcription (streaming user STT)
      if (serverContent.interimInputTranscription?.text != null) {
        final transcription = serverContent.interimInputTranscription!;
        final text = transcription.text!;
        if (text.isNotEmpty) {
          _appendOrUpdateTranscript(
            role: 'user',
            text: text,
            speaker: transcription.speakerLabel,
            isStreaming: true,
            replaceLastStreaming: true,
          );
        }
      }

      // Output audio transcription (model STT)
      if (serverContent.outputTranscription?.text != null) {
        final transcription = serverContent.outputTranscription!;
        final text = transcription.text!;
        if (text.isNotEmpty) {
          _appendOrUpdateTranscript(
            role: 'model',
            text: text,
            speaker: transcription.speakerLabel,
            isStreaming: !(serverContent.turnComplete ?? false) &&
                !(transcription.finished ?? false),
          );
        }
      }

      // Turn complete
      if (serverContent.turnComplete == true ||
          serverContent.isInteractionComplete) {
        _isModelSpeaking = false;
        _isThinking = false;
        _currentTurnThoughtActive = false;
        if (_currentTurnAudioBuffer.isNotEmpty) {
          _lastCompletedTurnWav = _currentTurnAudioBuffer.toWavBytes();
          _currentTurnAudioBuffer.clear();
        }
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
    Uint8List? imageBytes,
    String? imageMimeType,
    required bool isStreaming,
    bool replaceLastStreaming = false,
  }) {
    _latestTranscript = text;
    _latestTranscriptRole = role;

    if (_transcripts.isNotEmpty &&
        _transcripts.last.isStreaming &&
        _transcripts.last.role == role) {
      final last = _transcripts.last;
      _transcripts[_transcripts.length - 1] = last.copyWith(
        text: replaceLastStreaming ? text : (last.text + text),
        speaker: speaker ?? last.speaker,
        style: style ?? last.style,
        imageBytes: imageBytes ?? last.imageBytes,
        imageMimeType: imageMimeType ?? last.imageMimeType,
        isStreaming: isStreaming,
      );
    } else {
      _transcripts.add(
        LiveTranscriptItem(
          role: role,
          text: text,
          speaker: speaker,
          style: style,
          imageBytes: imageBytes,
          imageMimeType: imageMimeType,
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

    if (reconnectPolicy != null &&
        reconnectPolicy!.reconnectOnAbnormalClose &&
        !_manualDisconnectRequested &&
        closeCode != 1000) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    final policy = reconnectPolicy;
    final params = _lastConnectParams;
    if (policy == null || params == null || _manualDisconnectRequested) return;
    if (_reconnectAttempt >= policy.maxAttempts) {
      _isReconnecting = false;
      notifyListeners();
      return;
    }

    _reconnectTimer?.cancel();
    _isReconnecting = true;
    final delay = policy.delayForAttempt(_reconnectAttempt);
    _reconnectAttempt++;
    notifyListeners();

    _reconnectTimer = Timer(delay, () async {
      if (_manualDisconnectRequested || _lastConnectParams == null) return;
      if (_session != null) {
        try {
          await _session!.close();
        } catch (_) {}
        _session = null;
      }
      _state = LiveSessionState.disconnected;
      try {
        await connect(_lastConnectParams!);
      } catch (_) {
        if (!_manualDisconnectRequested &&
            _reconnectAttempt < policy.maxAttempts) {
          _scheduleReconnect();
        } else {
          _isReconnecting = false;
          notifyListeners();
        }
      }
    });
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
      audio: Blob(
        mimeType: mimeType,
        data: base64Encode(pcmBytes),
      ),
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

  /// Immediately interrupts and stops model AI audio speaking and generation.
  void stopModelSpeaking() {
    if (_isModelSpeaking) {
      _isModelSpeaking = false;
      _isInterrupted = true;
      _currentTurnAudioBuffer.clear();
      _finalizeStreamingTranscripts();
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

  /// Sends a complete multimodal user turn combining optional [imageBytes] and [text].
  ///
  /// This transmits both the image (camera snapshot or gallery file) and user text
  /// within a single [Content] turn.
  void sendRealtimeTurn({
    String? text,
    Uint8List? imageBytes,
    String imageMimeType = 'image/jpeg',
    List<Part>? additionalParts,
    bool turnComplete = true,
  }) {
    if (_session == null || !isConnected) return;

    final parts = <Part>[];

    if (imageBytes != null && imageBytes.isNotEmpty) {
      parts.add(
        Part(
          inlineData: Blob(
            mimeType: imageMimeType,
            data: base64Encode(imageBytes),
          ),
        ),
      );
    }

    if (text != null && text.isNotEmpty) {
      parts.add(Part(text: text));
    }

    if (additionalParts != null) {
      parts.addAll(additionalParts);
    }

    if (parts.isEmpty) return;

    _appendOrUpdateTranscript(
      role: 'user',
      text: text ?? '',
      imageBytes: imageBytes,
      imageMimeType: imageMimeType,
      isStreaming: !turnComplete,
    );

    _session!.sendClientContent(
      turns: [
        Content(
          role: 'user',
          parts: parts,
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
      video: Blob(
        mimeType: mimeType,
        data: base64Encode(imageBytes),
      ),
    );
  }

  /// Sends tool / function call responses back to Gemini.
  void sendToolResponses(List<FunctionResponse> responses) {
    final respondedIds = responses
        .map((r) => r.id)
        .whereType<String>()
        .toSet();
    final respondedNames = responses
        .map((r) => r.name)
        .whereType<String>()
        .toSet();
    if (_activeToolCalls.isNotEmpty) {
      _activeToolCalls.removeWhere(
        (call) =>
            (call.id != null && respondedIds.contains(call.id)) ||
            (call.id == null &&
                call.name != null &&
                respondedNames.contains(call.name)),
      );
      notifyListeners();
    }
    if (_session == null || !isConnected) return;
    _session!.sendToolResponse(functionResponses: responses);
  }

  /// Sends an in-session context update (`systemInstruction` and/or `tools`)
  /// to the active Live session.
  ///
  /// Pass `tools: const <Tool>[]` to clear all previously configured tools.
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
    if (resolved.systemInstruction != null) {
      _activeSystemInstruction = resolved.systemInstruction;
    }
    if (resolved.tools != null) {
      _activeTools = List<Tool>.from(resolved.tools!.tools ?? const <Tool>[]);
    }
    notifyListeners();

    if (_session == null || !isConnected) return;
    _session!.sendContextUpdate(update: resolved);
  }

  /// Disconnects the active session cleanly.
  Future<void> disconnect({int? closeCode, String? closeReason}) async {
    _manualDisconnectRequested = true;
    _reconnectTimer?.cancel();
    _isReconnecting = false;
    _reconnectAttempt = 0;

    if (_session == null) {
      _setState(LiveSessionState.disconnected);
      return;
    }

    _setState(LiveSessionState.disconnecting);
    await _session!.close();
    _session = null;
    _isModelSpeaking = false;
    _isUserSpeaking = false;
    _isThinking = false;
    _currentTurnThoughtActive = false;
    _activeToolCalls.clear();
    _currentTurnAudioBuffer.clear();
    _setState(LiveSessionState.disconnected);
  }

  /// Clears the recorded transcripts and resets the token tracker.
  void clearHistory() {
    _transcripts.clear();
    _thoughts.clear();
    _latestThought = null;
    _isThinking = false;
    _currentTurnThoughtActive = false;
    _latestTranscript = null;
    _latestTranscriptRole = null;
    _lastCompletedTurnWav = null;
    _currentTurnAudioBuffer.clear();
    tokenTracker.reset();
    notifyListeners();
  }

  /// Injects a server message for unit and widget testing purposes.
  void handleServerMessageForTesting(LiveServerMessage message) {
    _handleServerMessage(message);
  }

  void _setState(LiveSessionState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _manualDisconnectRequested = true;
    _reconnectTimer?.cancel();
    _session?.close();
    _incomingAudioController.close();
    _outgoingAudioController.close();
    super.dispose();
  }
}
