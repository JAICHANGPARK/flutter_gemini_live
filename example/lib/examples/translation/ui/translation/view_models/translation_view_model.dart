import 'dart:async';

import 'package:example/api_key_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:record/record.dart';

import '../../../data/services/translation_audio_service.dart';
import '../../../data/services/translation_live_service.dart';
import '../../../data/services/translation_mic_service.dart';
import '../../../domain/models/live_translation_message.dart';
import '../../../domain/models/translation_languages.dart';

/// State + logic for the Live Translation (동시통역) screen.
///
/// Coarse state notifies through [ChangeNotifier]; the per-chunk mic level
/// lives on [micVolumeNotifier]. The view model never touches a
/// `BuildContext`; it asks the view for things via [onNotice] and
/// [requestApiKeySetup].
class TranslationViewModel extends ChangeNotifier {
  TranslationViewModel({
    TranslationAudioService? audioService,
    TranslationMicService? micService,
    TranslationLiveService? liveService,
  }) : _audio = audioService ?? TranslationAudioService(),
       _mic = micService ?? TranslationMicService(),
       _live = liveService ?? TranslationLiveService();

  final TranslationAudioService _audio;
  final TranslationMicService _mic;
  final TranslationLiveService _live;

  // --- View hooks (set by the screen) ---

  /// Show a transient message (snackbar).
  void Function(String message)? onNotice;

  /// Ask the user to configure an API key; resolves `true` if configured.
  Future<bool?> Function()? requestApiKeySetup;

  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  void _notice(String message) {
    if (_disposed) return;
    onNotice?.call(message);
  }

  bool _isAudioOutputEnabled = true; // 음성 출력 (스피커) ON/OFF

  StreamSubscription<Uint8List>? _audioStreamSubscription;

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isMicActive = false;
  String _myLanguageCode = 'ko'; // 내 언어 (기본 한국어)
  String _targetLanguageCode = 'en'; // 상대방 언어 (기본 영어)
  final bool _echoTargetLanguage = false; // 원문 반복 에코 비활성화 (피드백 루프 원인 제거)
  bool _preventEchoLoop = false; // 스피커 소리의 마이크 재유입 방지 (소프트웨어 에코 억제)
  bool _isAiSpeaking = false;
  DateTime? _lastAiAudioReceivedTime;
  Timer? _statusTicker;
  bool _isDualFlipMode = true; // 양방향 분할 플립 모드 기본 활성화

  /// Smoothed mic level (0..1); updated for every mic chunk.
  final ValueNotifier<double> micVolumeNotifier = ValueNotifier(0.0);
  final List<LiveTranslationMessage> _history = [];

  /// Auto-scroll controllers; owned here because incoming transcripts trigger
  /// the scrolling, the view just attaches them.
  final ScrollController scrollController = ScrollController();
  final ScrollController partnerScrollController = ScrollController();

  InputDevice? _selectedAudioDevice;

  // Real-time token and cost tracker
  final GeminiTokenUsageTracker usageTracker = GeminiTokenUsageTracker(
    model: 'gemini-3.5-live-translate-preview',
  );

  Timer? _aiSpeakingResetTimer;
  Timer? _webAudioFlushTimer;

  /// 현재 열려 있는 말풍선의 화자 (null이면 다음 조각은 새 말풍선).
  bool? _openTranscriptIsUser;

  bool get isAudioOutputEnabled => _isAudioOutputEnabled;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get isMicActive => _isMicActive;
  String get myLanguageCode => _myLanguageCode;
  String get targetLanguageCode => _targetLanguageCode;
  bool get preventEchoLoop => _preventEchoLoop;
  bool get isDualFlipMode => _isDualFlipMode;
  List<LiveTranslationMessage> get history => _history;
  double get micVolume => micVolumeNotifier.value;

  Map<String, String> get myLanguage =>
      findTranslationLanguage(_myLanguageCode);
  Map<String, String> get targetLanguage =>
      findTranslationLanguage(_targetLanguageCode);

  /// AI가 현재 번역 음성을 스피커로 재생 중인지 여부
  bool get isAiCurrentlySpeaking => _isAudioOutputEnabled && _isAiSpeaking;

  void init() {
    _loadAudioDevice();
    _initAudioPlayer();

    // 100ms마다 AI 발화 상태를 점검하여, 마지막 오디오 청크 수신 후 1.2초가 지나면 마이크를 자동으로 정상 개방합니다.
    _statusTicker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!_isAudioOutputEnabled || _lastAiAudioReceivedTime == null) {
        if (_isAiSpeaking && !_disposed) {
          _isAiSpeaking = false;
          notifyListeners();
        }
        return;
      }
      final diff = DateTime.now()
          .difference(_lastAiAudioReceivedTime!)
          .inMilliseconds;
      final isSpeaking = diff < 1200;
      if (_isAiSpeaking != isSpeaking && !_disposed) {
        _isAiSpeaking = isSpeaking;
        notifyListeners();
      }
    });
  }

  Future<void> _initAudioPlayer() => _audio.init();

  Future<void> _loadAudioDevice() async {
    try {
      final devices = await _mic.listInputDevices();
      final savedId = ApiKeyStore.audioDeviceId;
      if (savedId.isNotEmpty) {
        _selectedAudioDevice = devices
            .where((d) => d.id == savedId)
            .firstOrNull;
      }
    } catch (_) {}
  }

  /// Called after the settings dialog changed something.
  Future<void> reloadAfterSettings() async {
    await _loadAudioDevice();
    notifyListeners();
  }

  void toggleAudioOutput() {
    _isAudioOutputEnabled = !_isAudioOutputEnabled;
    if (!_isAudioOutputEnabled) {
      _aiSpeakingResetTimer?.cancel();
      _lastAiAudioReceivedTime = null;
      _isAiSpeaking = false;
      _audio.clear();
    }
    notifyListeners();
  }

  void togglePreventEchoLoop() {
    _preventEchoLoop = !_preventEchoLoop;
    notifyListeners();
  }

  void toggleDualFlipMode() {
    _isDualFlipMode = !_isDualFlipMode;
    notifyListeners();
  }

  void setMyLanguage(String code) {
    _myLanguageCode = code;
    notifyListeners();
  }

  void setTargetLanguage(String code) {
    _targetLanguageCode = code;
    notifyListeners();
  }

  void swapLanguages() {
    final temp = _myLanguageCode;
    _myLanguageCode = _targetLanguageCode;
    _targetLanguageCode = temp;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _statusTicker?.cancel();
    _aiSpeakingResetTimer?.cancel();
    _webAudioFlushTimer?.cancel();
    _audioStreamSubscription?.cancel();
    _mic.dispose();
    _audio.dispose();
    _live.close();
    scrollController.dispose();
    partnerScrollController.dispose();
    usageTracker.dispose();
    micVolumeNotifier.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
      if (partnerScrollController.hasClients) {
        partnerScrollController.animateTo(
          partnerScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> connect() async {
    if (_isConnecting) return;
    if (!ApiKeyStore.hasApiKey) {
      final configured = await requestApiKeySetup?.call();
      if (configured != true || !ApiKeyStore.hasApiKey) {
        _notice('Gemini API 키가 설정되지 않았습니다.');
        return;
      }
    }

    _isConnecting = true;
    notifyListeners();

    try {
      final session = await _live.connect(
        targetLanguageCode: _targetLanguageCode,
        echoTargetLanguage: _echoTargetLanguage,
        onOpen: () {
          if (_disposed) return;
          _isConnected = true;
          _isConnecting = false;
          notifyListeners();
          _startMicStreaming();
        },
        onMessage: (message) {
          if (_disposed) return;
          _handleServerMessage(message);
        },
        onError: (error, stack) {
          if (_disposed) return;
          _isConnected = false;
          _isConnecting = false;
          _isMicActive = false;
          notifyListeners();
          _notice('세션 오류: $error');
        },
        onClose: (code, reason) {
          if (_disposed) return;
          _isConnected = false;
          _isConnecting = false;
          _isMicActive = false;
          notifyListeners();
        },
      );

      // 화면이 이미 닫혔다면(setState가 던지던 기존 동작) 세션을 보관하지 않습니다.
      if (_disposed) throw StateError('disposed');
      _live.attach(session);
      notifyListeners();
    } catch (e) {
      if (!_disposed) {
        _isConnecting = false;
        _isConnected = false;
        notifyListeners();
        _notice('연결 실패: $e');
      }
    }
  }

  Future<void> disconnect() async {
    await _stopMicStreaming();
    await _audio.stop();
    await _live.close();
    _live.detach();
    _isConnected = false;
    _isConnecting = false;
    _isMicActive = false;
    notifyListeners();
  }

  /// Mic pause / resume button.
  void toggleMicStreaming() {
    if (_isMicActive) {
      _stopMicStreaming();
      _lastAiAudioReceivedTime = null;
      _isAiSpeaking = false;
      _audio.clear();
    } else {
      _startMicStreaming();
    }
  }

  Future<void> _startMicStreaming() async {
    if (!await _mic.hasPermission()) {
      _notice('마이크 권한이 필요합니다.');
      return;
    }

    try {
      final stream = await _mic.startStream(device: _selectedAudioDevice);

      _isMicActive = true;
      notifyListeners();

      _audioStreamSubscription = stream.listen((chunk) {
        if (!_isMicActive || !_live.hasSession || !_isConnected) return;

        // Amplitude calculation for waveform indicator
        var norm = 0.0;
        if (chunk.length >= 2) {
          final byteData = ByteData.sublistView(chunk);
          var peak = 0;
          for (var i = 0; i < chunk.length - 1; i += 2) {
            final sample = byteData.getInt16(i, Endian.little).abs();
            if (sample > peak) peak = sample;
          }
          norm = (peak / 32768.0).clamp(0.0, 1.0);
          if (!_disposed) {
            micVolumeNotifier.value =
                (micVolumeNotifier.value * 0.3) + (norm * 0.7);
          }
        }

        // 🛡️ 소프트웨어 에코 차단 (Acoustic Echo Cancellation Gate):
        // AI가 번역된 음성을 스피커로 출력하는 동안에는 스피커 소리가 마이크로 재유입되는 것을 차단합니다.
        // 사용자가 스피커 소리를 뚫고 자연스럽게 말할 때(norm >= 0.05)는 즉시 끼어들기로 전송 허용.
        if (_preventEchoLoop && isAiCurrentlySpeaking) {
          const double intentionalBargeInThreshold = 0.12;
          if (norm < intentionalBargeInThreshold) {
            // 청크를 버리면 스트림이 끊겨 서버 VAD/턴 처리가 멈추므로 무음으로 대체해 전송합니다.
            _live.sendSilence(chunk.length);
            return;
          }
        }

        _live.sendAudio(chunk);
      });
    } catch (e) {
      debugPrint('Mic streaming start error: $e');
    }
  }

  Future<void> _stopMicStreaming() async {
    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;
    try {
      await _mic.stop();
    } catch (_) {}
    if (!_disposed) {
      _isMicActive = false;
      micVolumeNotifier.value = 0.0;
      notifyListeners();
    }
  }

  void _feedAudioChunk(String base64Data) {
    if (!_isAudioOutputEnabled || base64Data.isEmpty) return;
    _lastAiAudioReceivedTime = DateTime.now();
    if (!_isAiSpeaking && !_disposed) {
      _isAiSpeaking = true;
      notifyListeners();
    }

    if (!_audio.useFallbackAudio) {
      _audio.appendBase64Chunk(base64Data);
    } else {
      _audio.appendBase64Chunk(base64Data);
      _webAudioFlushTimer?.cancel();
      _webAudioFlushTimer = Timer(const Duration(milliseconds: 350), () {
        if (_isAudioOutputEnabled &&
            _audio.fallbackHasBufferedAudio &&
            !_audio.fallbackIsPlaying) {
          unawaited(_audio.playFallbackBufferedAudio());
        }
      });
    }
  }

  void _handleServerMessage(LiveServerMessage message) {
    // Record real-time token usage and cost
    usageTracker.recordMessage(message);

    // Interruption Handling: immediately flush local audio buffers when interrupted
    if (message.serverContent?.interrupted == true) {
      _aiSpeakingResetTimer?.cancel();
      _lastAiAudioReceivedTime = null;
      _isAiSpeaking = false;
      _openTranscriptIsUser = null;
      if (!_audio.useFallbackAudio) {
        _audio.clear();
      } else {
        _webAudioFlushTimer?.cancel();
        _audio.clear();
      }
      if (!_disposed) notifyListeners();
      return;
    }

    // 1. Translated Audio output
    if (_isAudioOutputEnabled) {
      if (message.data != null && message.data!.isNotEmpty) {
        _feedAudioChunk(message.data!);
      }

      final turnComplete = message.serverContent?.turnComplete ?? false;
      if (turnComplete) {
        if (!_audio.useFallbackAudio) {
          _audio.onTurnComplete();
        } else {
          _webAudioFlushTimer?.cancel();
          unawaited(_audio.playFallbackBufferedAudio());
        }
      }
    }

    // 2. Transcriptions: 서버는 누적 텍스트가 아닌 증분(delta) 조각을 보냅니다.
    // 같은 턴 안에서는 마지막 말풍선에 이어 붙이고, 턴이 끝나면 닫습니다.
    final inputChunk = message.serverContent?.inputTranscription?.text;
    if (inputChunk != null && inputChunk.isNotEmpty) {
      _appendTranscript(
        isUser: true,
        chunk: inputChunk,
        languageCode:
            message.serverContent?.inputTranscription?.languageCode ??
            _myLanguageCode,
      );
    }

    final outputChunk = message.serverContent?.outputTranscription?.text;
    if (outputChunk != null && outputChunk.isNotEmpty) {
      _appendTranscript(
        isUser: false,
        chunk: outputChunk,
        languageCode:
            message.serverContent?.outputTranscription?.languageCode ??
            _targetLanguageCode,
      );
    }

    if (message.serverContent?.turnComplete == true) {
      _openTranscriptIsUser = null;
    }
  }

  void _appendTranscript({
    required bool isUser,
    required String chunk,
    required String languageCode,
  }) {
    if (_openTranscriptIsUser == isUser && _history.isNotEmpty) {
      final last = _history.last;
      _history[_history.length - 1] = LiveTranslationMessage(
        isUser: isUser,
        text: last.text + chunk,
        languageCode: languageCode,
        timestamp: last.timestamp,
      );
    } else if (chunk.trim().isNotEmpty) {
      _history.add(
        LiveTranslationMessage(
          isUser: isUser,
          text: chunk.trimLeft(),
          languageCode: languageCode,
        ),
      );
      _openTranscriptIsUser = isUser;
    }
    notifyListeners();
    _scrollToBottom();
  }
}
