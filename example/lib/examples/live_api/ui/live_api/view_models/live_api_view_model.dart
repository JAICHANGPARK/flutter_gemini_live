import 'dart:async';

import 'package:example/api_key_store.dart';
import 'package:example/live_api_defaults.dart';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';

import '../../../data/services/live_api_audio_service.dart';
import '../../../data/services/live_api_live_service.dart';
import '../../../domain/models/log_entry.dart';
import '../live_api_i18n.dart';

/// State + logic for the Live API features demo screen.
class LiveApiViewModel extends ChangeNotifier {
  LiveApiViewModel({
    LiveApiLiveService? liveService,
    LiveApiAudioService? audioService,
  }) : _live = liveService ?? LiveApiLiveService(),
       _audio = audioService ?? LiveApiAudioService();

  final LiveApiLiveService _live;
  final LiveApiAudioService _audio;

  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  // Connection state
  bool _isConnected = false;
  bool _isConnecting = false;
  InteractionStatus? _interactionStatus;

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  InteractionStatus? get interactionStatus => _interactionStatus;

  // Message logs
  final List<LogEntry> _logs = [];
  List<LogEntry> get logs => _logs;

  // Feature toggles
  bool _enableRealtimeConfig = true;
  bool _enableTranscription = true;
  bool _useSmartTranscription = false;
  bool _enableSessionResumption = false;
  bool _enableContextCompression = true;

  bool get enableRealtimeConfig => _enableRealtimeConfig;
  bool get enableTranscription => _enableTranscription;
  bool get useSmartTranscription => _useSmartTranscription;
  bool get enableSessionResumption => _enableSessionResumption;
  bool get enableContextCompression => _enableContextCompression;

  set enableRealtimeConfig(bool v) {
    _enableRealtimeConfig = v;
    notifyListeners();
  }

  set enableTranscription(bool v) {
    _enableTranscription = v;
    notifyListeners();
  }

  set useSmartTranscription(bool v) {
    _useSmartTranscription = v;
    notifyListeners();
  }

  set enableSessionResumption(bool v) {
    _enableSessionResumption = v;
    notifyListeners();
  }

  set enableContextCompression(bool v) {
    _enableContextCompression = v;
    notifyListeners();
  }

  // Session handle for resumption
  String? _sessionHandle;

  @override
  void dispose() {
    _disposed = true;
    _live.close();
    unawaited(_audio.dispose());
    super.dispose();
  }

  void _addLog(String type, String message, {Map<String, dynamic>? data}) {
    if (_disposed) return;
    _logs.insert(
      0,
      LogEntry(
        timestamp: DateTime.now(),
        type: type,
        message: message,
        data: data,
      ),
    );
    notifyListeners();
  }

  Future<void> connect() async {
    if (_isConnecting) return;
    if (!ApiKeyStore.hasApiKey) {
      _addLog('ERROR', LiveApiI18n.current.logApiKeyNotConfigured);
      return;
    }

    _isConnecting = true;
    notifyListeners();
    _addLog(
      'SYSTEM',
      LiveApiI18n.current.logConnecting,
    );
    await _audio.stop();

    try {
      final session = await _live.connect(
        enableRealtimeConfig: _enableRealtimeConfig,
        enableTranscription: _enableTranscription,
        useSmartTranscription: _useSmartTranscription,
        enableSessionResumption: _enableSessionResumption,
        enableContextCompression: _enableContextCompression,
        sessionHandle: _sessionHandle,
        onOpen: () {
          _addLog('CONNECTION', LiveApiI18n.current.logConnectedSuccess);
          _isConnected = true;
          _isConnecting = false;
          _interactionStatus = null;
          notifyListeners();
        },
        onMessage: _handleMessage,
        onError: (error, stack) {
          unawaited(_audio.stop());
          _addLog('ERROR', LiveApiI18n.current.logError(error));
          _isConnecting = false;
          _interactionStatus = null;
          notifyListeners();
        },
        onClose: (code, reason) {
          unawaited(_audio.stop());
          _addLog(
            'CONNECTION',
            LiveApiI18n.current.logConnectionClosed(code, reason),
          );
          _isConnected = false;
          _isConnecting = false;
          _interactionStatus = null;
          notifyListeners();
        },
      );

      _live.attach(session);
      if (session.sessionId != null) {
        _addLog('SESSION', LiveApiI18n.current.logSessionId(session.sessionId!));
      }
      notifyListeners();
    } catch (e) {
      _addLog('ERROR', LiveApiI18n.current.logConnectionFailed(e));
      _isConnecting = false;
      notifyListeners();
    }
  }

  void _handleMessage(LiveServerMessage message) {
    final serverContent = message.serverContent;
    final turnFinished =
        (serverContent?.turnComplete ?? false) ||
        (serverContent?.generationComplete ?? false);

    if (serverContent?.interrupted ?? false) {
      _audio.clear();
    }

    // Handle interaction status
    if (serverContent?.interactionStatus != null) {
      final status = serverContent!.interactionStatus!;
      _interactionStatus = status;
      notifyListeners();
      _addLog('STATUS', LiveApiI18n.current.logInteractionStatus(status.name));
    }

    // Handle text
    final textChunk = visibleModelText(message);
    if (textChunk != null) {
      _addLog('TEXT', '🤖 $textChunk');
    }

    // Handle audio data
    if (message.data != null) {
      _audio.appendBase64Chunk(message.data!);
      _addLog(
        'AUDIO',
        LiveApiI18n.current.logReceivedAudio(message.data!.length),
      );
    }

    // Handle transcriptions
    if (message.serverContent?.inputTranscription != null) {
      final t = message.serverContent!.inputTranscription!;
      _addLog(
        'TRANSCRIPTION',
        LiveApiI18n.current.logInputTranscription(t.text, t.finished == true),
      );
    }

    if (message.serverContent?.outputTranscription != null) {
      final t = message.serverContent!.outputTranscription!;
      _addLog(
        'TRANSCRIPTION',
        LiveApiI18n.current.logOutputTranscription(t.text, t.finished == true),
      );
    }

    // Handle voice activity
    if (message.voiceActivity != null) {
      _addLog(
        'VAD',
        LiveApiI18n.current.logVoiceActivity(
          message.voiceActivity!.speechActive == true,
        ),
      );
    }

    if (message.voiceActivityDetectionSignal != null) {
      final signal = message.voiceActivityDetectionSignal!;
      if (signal.start == true) {
        _addLog('VAD', LiveApiI18n.current.logSpeechStarted);
      }
      if (signal.end == true) {
        _addLog('VAD', LiveApiI18n.current.logSpeechEnded);
      }
    }

    // Handle session resumption
    if (message.sessionResumptionUpdate != null) {
      final update = message.sessionResumptionUpdate!;
      _addLog(
        'SESSION',
        LiveApiI18n.current.logResumptionUpdate(update.newHandle),
      );
      if (update.newHandle != null) {
        _sessionHandle = update.newHandle;
        notifyListeners();
      }
    }

    // Handle go away
    if (message.goAway != null) {
      _addLog(
        'WARNING',
        LiveApiI18n.current.logGoAway(
          message.goAway!.timeRemaining,
          message.goAway!.reason,
        ),
      );
    }

    // Handle usage
    if (message.usageMetadata != null) {
      final u = message.usageMetadata!;
      final extras = <String>[
        if (u.initialPromptTokenCount != null)
          'init: ${u.initialPromptTokenCount}',
        if (u.toolUsePromptTokenCount != null)
          'tool: ${u.toolUsePromptTokenCount}',
      ];
      final extraSuffix = extras.isEmpty ? '' : ', ${extras.join(", ")}';
      _addLog(
        'USAGE',
        '📊 Tokens: ${u.totalTokenCount} (prompt: ${u.promptTokenCount}, response: ${u.responseTokenCount}$extraSuffix)',
      );
    }

    if (turnFinished && _audio.hasBufferedAudio) {
      _addLog('AUDIO', LiveApiI18n.current.logPlayingAudio);
      unawaited(_audio.playBufferedAudio());
    }
  }

  void sendText(String text) {
    if (!_live.hasSession || !_isConnected) {
      _addLog('ERROR', LiveApiI18n.current.logNotConnected);
      return;
    }

    _addLog('USER', '💬 $text');
    _live.sendText(text);
  }

  void sendClientContent() {
    if (!_live.hasSession || !_isConnected) {
      _addLog('ERROR', LiveApiI18n.current.logNotConnected);
      return;
    }

    _addLog('USER', LiveApiI18n.current.logMultiTurnContent);
    _live.sendClientContent();
  }

  void sendRealtimeInput() {
    if (!_live.hasSession || !_isConnected) {
      _addLog('ERROR', LiveApiI18n.current.logNotConnected);
      return;
    }

    _addLog('USER', LiveApiI18n.current.logRealtimeInputMedia);
    _live.sendRealtimeInput();
  }

  void sendContextUpdate() {
    if (!_live.hasSession || !_isConnected) {
      _addLog('ERROR', LiveApiI18n.current.logNotConnected);
      return;
    }

    const updatedInstruction =
        'You are now a concise technical expert. Keep every answer to 1-2 short sentences.';
    _addLog('USER', LiveApiI18n.current.logContextUpdate);
    _live.sendContextUpdate(systemInstruction: updatedInstruction);
  }

  void toggleActivity(bool isStart) {
    if (!_live.hasSession || !_isConnected) {
      _addLog('ERROR', LiveApiI18n.current.logNotConnected);
      return;
    }

    if (isStart) {
      _addLog('USER', LiveApiI18n.current.logActivityStart);
      _live.sendActivityStart();
    } else {
      _addLog('USER', LiveApiI18n.current.logActivityEnd);
      _live.sendActivityEnd();
    }
  }

  void closeConnection() {
    _live.close();
    _addLog('SYSTEM', LiveApiI18n.current.logClosingConnection);
  }
}
