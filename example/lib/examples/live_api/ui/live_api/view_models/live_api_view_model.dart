import 'dart:async';

import 'package:example/api_key_store.dart';
import 'package:example/live_api_defaults.dart';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';

import '../../../data/services/live_api_audio_service.dart';
import '../../../data/services/live_api_live_service.dart';
import '../../../domain/models/log_entry.dart';

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
    _live.close();
    unawaited(_audio.dispose());
    _disposed = true;
    super.dispose();
  }

  void _addLog(String type, String message, {Map<String, dynamic>? data}) {
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
      _addLog('ERROR', '❌ API key is not configured. Open Settings first.');
      return;
    }

    _isConnecting = true;
    notifyListeners();
    _addLog(
      'SYSTEM',
      'Connecting to Gemini Live API with Gemini 2.5 Flash Live compatibility...',
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
          _addLog('CONNECTION', '✅ Connected successfully');
          _isConnected = true;
          _isConnecting = false;
          _interactionStatus = null;
          notifyListeners();
        },
        onMessage: _handleMessage,
        onError: (error, stack) {
          unawaited(_audio.stop());
          _addLog('ERROR', '❌ Error: $error');
          _isConnecting = false;
          _interactionStatus = null;
          notifyListeners();
        },
        onClose: (code, reason) {
          unawaited(_audio.stop());
          _addLog(
            'CONNECTION',
            '🔒 Connection closed: code=$code, reason=$reason',
          );
          _isConnected = false;
          _isConnecting = false;
          _interactionStatus = null;
          notifyListeners();
        },
      );

      _live.attach(session);
      notifyListeners();
    } catch (e) {
      _addLog('ERROR', '❌ Connection failed: $e');
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
      _addLog('STATUS', '⚡ Interaction status: ${status.name}');
    }

    // Handle text
    final textChunk = visibleModelText(message);
    if (textChunk != null) {
      _addLog('TEXT', '🤖 $textChunk');
    }

    // Handle audio data
    if (message.data != null) {
      _audio.appendBase64Chunk(message.data!);
      _addLog('AUDIO', '🔊 Received audio: ${message.data!.length} chars');
    }

    // Handle transcriptions
    if (message.serverContent?.inputTranscription != null) {
      final t = message.serverContent!.inputTranscription!;
      _addLog(
        'TRANSCRIPTION',
        '🎤 Input: ${t.text} ${t.finished == true ? "(complete)" : ""}',
      );
    }

    if (message.serverContent?.outputTranscription != null) {
      final t = message.serverContent!.outputTranscription!;
      _addLog(
        'TRANSCRIPTION',
        '🔈 Output: ${t.text} ${t.finished == true ? "(complete)" : ""}',
      );
    }

    // Handle voice activity
    if (message.voiceActivity != null) {
      _addLog(
        'VAD',
        '🎤 Voice activity: ${message.voiceActivity!.speechActive == true ? "speaking" : "silent"}',
      );
    }

    if (message.voiceActivityDetectionSignal != null) {
      final signal = message.voiceActivityDetectionSignal!;
      if (signal.start == true) _addLog('VAD', '🎙️ Speech started');
      if (signal.end == true) _addLog('VAD', '🎙️ Speech ended');
    }

    // Handle session resumption
    if (message.sessionResumptionUpdate != null) {
      final update = message.sessionResumptionUpdate!;
      _addLog('SESSION', '🔄 Resumption update: handle=${update.newHandle}');
      if (update.newHandle != null) {
        _sessionHandle = update.newHandle;
        notifyListeners();
      }
    }

    // Handle go away
    if (message.goAway != null) {
      _addLog(
        'WARNING',
        '⏰ Server will disconnect in ${message.goAway!.timeRemaining}s: ${message.goAway!.reason}',
      );
    }

    // Handle usage
    if (message.usageMetadata != null) {
      final u = message.usageMetadata!;
      _addLog(
        'USAGE',
        '📊 Tokens: ${u.totalTokenCount} (prompt: ${u.promptTokenCount}, response: ${u.responseTokenCount})',
      );
    }

    if (turnFinished && _audio.hasBufferedAudio) {
      _addLog('AUDIO', '▶️ Playing received audio');
      unawaited(_audio.playBufferedAudio());
    }
  }

  void sendText(String text) {
    if (!_live.hasSession || !_isConnected) {
      _addLog('ERROR', '❌ Not connected');
      return;
    }

    _addLog('USER', '💬 $text');
    _live.sendText(text);
  }

  void sendClientContent() {
    if (!_live.hasSession || !_isConnected) {
      _addLog('ERROR', '❌ Not connected');
      return;
    }

    _addLog('USER', '💬 [Multi-turn content]');
    _live.sendClientContent();
  }

  void sendRealtimeInput() {
    if (!_live.hasSession || !_isConnected) {
      _addLog('ERROR', '❌ Not connected');
      return;
    }

    _addLog('USER', '🎙️ [Realtime input with media]');
    _live.sendRealtimeInput();
  }

  void toggleActivity(bool isStart) {
    if (!_live.hasSession || !_isConnected) {
      _addLog('ERROR', '❌ Not connected');
      return;
    }

    if (isStart) {
      _addLog('USER', '🎙️ [Activity Start]');
      _live.sendActivityStart();
    } else {
      _addLog('USER', '🎙️ [Activity End]');
      _live.sendActivityEnd();
    }
  }

  void closeConnection() {
    _live.close();
    _addLog('SYSTEM', '👋 Closing connection...');
  }
}
