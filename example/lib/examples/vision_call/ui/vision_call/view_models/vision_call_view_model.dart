import 'dart:async';

import 'package:camera/camera.dart';
import 'package:example/api_key_store.dart';
import 'package:example/app_translations.dart';
import 'package:example/live_api_defaults.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:record/record.dart';

import '../../../data/services/vision_call_audio_service.dart';
import '../../../data/services/vision_call_camera_service.dart';
import '../../../data/services/vision_call_live_service.dart';
import '../../../data/services/vision_call_mic_service.dart';
import '../../../domain/models/audio_activity.dart';
import '../../../domain/models/vision_chat_message.dart';
import '../vision_call_i18n.dart';
import 'vision_call_notice.dart';

/// State + logic for the Live Vision Call screen.
///
/// Coarse state (connection, camera, audio devices) notifies through
/// [ChangeNotifier]. High-frequency state (audio activity, subtitle, mute /
/// pause / flip flags, capture-in-flight) lives on dedicated [ValueNotifier]s.
///
/// The view model never touches a `BuildContext`; it asks the view for things
/// via [onNotice] and [requestApiKeySetup].
class VisionCallViewModel extends ChangeNotifier {
  VisionCallViewModel({
    this.customSystemPrompt,
    VisionCallAudioService? audioService,
    VisionCallMicService? micService,
    VisionCallCameraService? cameraService,
    VisionCallLiveService? liveService,
  }) : _audio = audioService ?? VisionCallAudioService(),
       _mic = micService ?? VisionCallMicService(),
       _cameraService = cameraService ?? VisionCallCameraService(),
       _live = liveService ?? VisionCallLiveService();

  static const _cameraFrameInterval = Duration(milliseconds: 1200);

  final String? customSystemPrompt;

  final VisionCallAudioService _audio;
  final VisionCallMicService _mic;
  final VisionCallCameraService _cameraService;
  final VisionCallLiveService _live;

  // --- View hooks (set by the screen) ---

  /// Show a transient message (snackbar).
  void Function(VisionCallNotice notice)? onNotice;

  /// Ask the user to configure an API key; resolves `true` if configured.
  Future<bool?> Function()? requestApiKeySetup;

  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  void _notice(VisionCallNotice notice) {
    if (_disposed) return;
    onNotice?.call(notice);
  }

  StreamSubscription<Uint8List>? _audioStreamSubscription;
  Timer? _cameraFrameTimer;
  Timer? _waveformTicker;

  CameraController? _cameraController;
  final List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;

  final List<InputDevice> _availableAudioDevices = [];
  InputDevice? _selectedAudioDevice;

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isCameraInitializing = false;
  String? _cameraErrorMessage;

  // Granular Reactive Notifiers (avoids screen-wide rebuilds)
  final ValueNotifier<AudioActivity> audioActivity = ValueNotifier(
    const AudioActivity(),
  );
  final ValueNotifier<String> liveSubtitleNotifier = ValueNotifier('');
  final ValueNotifier<bool> isMicMutedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isVideoPausedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> captureInFlightNotifier = ValueNotifier(false);
  final ValueNotifier<bool> isCameraFlippedNotifier = ValueNotifier(
    ApiKeyStore.isCameraFlipped,
  );

  bool get _isMicMuted => isMicMutedNotifier.value;
  bool get _isVideoPaused => isVideoPausedNotifier.value;
  bool get _captureInFlight => captureInFlightNotifier.value;
  bool get _isCameraFlipped => isCameraFlippedNotifier.value;

  // Local speech tracking state (no full-page rebuild needed)
  bool _serverVadSpeaking = false;
  double _userMicVolume = 0.0;
  DateTime _lastMicInputTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _lastAiAudioReceivedTime;
  final List<VisionChatMessage> _chatHistory = [];

  // Real-time token usage and cost tracker
  final GeminiTokenUsageTracker usageTracker = GeminiTokenUsageTracker(
    model: ApiKeyStore.liveModel,
  );

  // --- Read-only view state ---

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get isCameraInitializing => _isCameraInitializing;
  String? get cameraErrorMessage => _cameraErrorMessage;
  CameraController? get cameraController => _cameraController;
  List<CameraDescription> get availableCameras => _availableCameras;
  List<InputDevice> get availableAudioDevices => _availableAudioDevices;
  InputDevice? get selectedAudioDevice => _selectedAudioDevice;

  /// Live (mutable) list: appending does not notify listeners.
  List<VisionChatMessage> get chatHistory => _chatHistory;

  bool get _isAiSpeaking {
    final isPlaying = _audio.isPlaying;
    if (isPlaying) return true;
    if (_lastAiAudioReceivedTime != null) {
      final diff = DateTime.now()
          .difference(_lastAiAudioReceivedTime!)
          .inMilliseconds;
      if (diff < 1200) return true;
    }
    return false;
  }

  bool get cameraReady =>
      _cameraController != null && _cameraController!.value.isInitialized;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  void init() {
    _waveformTicker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final hasRecentMic =
          DateTime.now().difference(_lastMicInputTime).inMilliseconds < 450;
      if (!hasRecentMic) {
        _userMicVolume = _userMicVolume * 0.75;
        if (_userMicVolume < 0.005) _userMicVolume = 0.0;
      }
      final isSpeaking = hasRecentMic && _userMicVolume > 0.015;
      final isAi = _audio.isAnyPlaying;
      final isUser = !_isMicMuted && (_serverVadSpeaking || isSpeaking);

      // Updates only listening widgets via ValueNotifier without full-screen rebuild!
      audioActivity.value = AudioActivity(
        isAiResponding: isAi,
        isUserSpeaking: isUser,
        userMicVolume: _userMicVolume,
      );
    });

    _initAll();
  }

  Future<void> _initAll() async {
    await _audio.init();
    await loadAudioDevices();
    await _startMicStream();
    await loadCameras();
    await connectSession();
  }

  Future<void> loadAudioDevices() async {
    try {
      final devices = await _mic.listInputDevices();
      if (_disposed) return;
      _availableAudioDevices
        ..clear()
        ..addAll(devices);
      if (ApiKeyStore.audioDeviceId.isNotEmpty) {
        _selectedAudioDevice = devices
            .where((d) => d.id == ApiKeyStore.audioDeviceId)
            .firstOrNull;
      } else {
        _selectedAudioDevice = null;
      }
      if (!_disposed) notifyListeners();
    } catch (e) {
      debugPrint('Failed to load audio input devices: $e');
    }
  }

  Future<void> switchAudioDevice(InputDevice? device) async {
    if (_selectedAudioDevice?.id == device?.id) return;
    _selectedAudioDevice = device;
    notifyListeners();
    await ApiKeyStore.saveAudioDevice(device?.id ?? '', device?.label ?? '');

    if (_audioStreamSubscription != null) {
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;
      try {
        await _mic.stop();
      } catch (_) {}
      if (!_isMicMuted && !_disposed) {
        await _startMicStream();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _waveformTicker?.cancel();
    _cameraFrameTimer?.cancel();
    _audioStreamSubscription?.cancel();
    audioActivity.dispose();
    liveSubtitleNotifier.dispose();
    isMicMutedNotifier.dispose();
    isVideoPausedNotifier.dispose();
    captureInFlightNotifier.dispose();
    isCameraFlippedNotifier.dispose();
    _mic.dispose();
    unawaited(_cameraController?.dispose() ?? Future<void>.value());
    _live.close();
    _audio.dispose();
    usageTracker.dispose();
    super.dispose();
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On Desktop (macOS, Windows, Linux) and Web, switching focus to another window
    // (inactive) should NOT dispose or freeze the camera!
    final bool isDesktopOrWeb =
        kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (isDesktopOrWeb) return;

    // Mobile (Android / iOS) lifecycle handling
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _cameraFrameTimer?.cancel();
      final controller = _cameraController;
      if (controller != null) {
        _cameraController = null;
        notifyListeners();
        unawaited(controller.dispose());
      }
    } else if (state == AppLifecycleState.resumed &&
        _availableCameras.isNotEmpty) {
      if (_cameraController == null && !_isCameraInitializing) {
        unawaited(
          _initCameraController(_availableCameras[_selectedCameraIndex]),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Camera
  // ---------------------------------------------------------------------------

  Future<void> loadCameras() async {
    _cameraErrorMessage = null;
    _isCameraInitializing = true;
    notifyListeners();

    try {
      final cameras = await _cameraService.listCameras();
      if (_disposed) return;
      _availableCameras.clear();
      _availableCameras.addAll(cameras);
      notifyListeners();

      if (cameras.isNotEmpty) {
        await _initCameraController(cameras.first);
      } else {
        if (!_disposed) {
          final i18n = VisionCallI18n(
            AppLanguageController.instance.currentLanguage,
          );
          _isCameraInitializing = false;
          _cameraErrorMessage = i18n.noCameraFound;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Camera load error: $e');
      if (!_disposed) {
        final i18n = VisionCallI18n(
          AppLanguageController.instance.currentLanguage,
        );
        _isCameraInitializing = false;
        _cameraErrorMessage = kIsWeb
            ? i18n.cameraPermissionError(e)
            : i18n.cameraLoadError(e);
        notifyListeners();
      }
    }
  }

  Future<void> _initCameraController(CameraDescription description) async {
    final oldController = _cameraController;
    _cameraController = null;
    _isCameraInitializing = true;
    _cameraErrorMessage = null;
    notifyListeners();

    try {
      await oldController?.dispose();
      final controller = _cameraService.createController(description);

      await controller.initialize();
      if (_disposed) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;
      _isCameraInitializing = false;
      _cameraErrorMessage = null;
      notifyListeners();

      if (_isConnected && !_isVideoPaused) {
        _startCameraFrameLoop();
      }
    } catch (e) {
      if (!_disposed) {
        final i18n = VisionCallI18n(
          AppLanguageController.instance.currentLanguage,
        );
        _isCameraInitializing = false;
        _cameraErrorMessage = i18n.cameraInitError(e);
        notifyListeners();
      }
      debugPrint('Camera controller init error: $e');
    }
  }

  Future<void> toggleCameraDirection() async {
    if (_availableCameras.length < 2 || _isCameraInitializing) return;
    _cameraFrameTimer?.cancel();

    _selectedCameraIndex =
        (_selectedCameraIndex + 1) % _availableCameras.length;
    notifyListeners();

    await _initCameraController(_availableCameras[_selectedCameraIndex]);
  }

  void toggleVideoPause() {
    isVideoPausedNotifier.value = !isVideoPausedNotifier.value;
    if (_isVideoPaused) {
      _cameraFrameTimer?.cancel();
      _cameraFrameTimer = null;
    } else {
      _startCameraFrameLoop();
    }
  }

  Future<void> toggleCameraFlip() async {
    final next = !isCameraFlippedNotifier.value;
    isCameraFlippedNotifier.value = next;
    await ApiKeyStore.saveCameraFlipped(next);
    if (!_disposed) {
      final i18n = VisionCallI18n(
        AppLanguageController.instance.currentLanguage,
      );
      _notice(
        VisionCallNotice(
          next ? i18n.flipOn : i18n.flipOff,
          VisionCallNoticeKind.cameraFlip,
          flipped: next,
        ),
      );
    }
  }

  Future<void> toggleMicMute() async {
    if (_audioStreamSubscription == null) {
      await _startMicStream();
      return;
    }
    final nextMuted = !isMicMutedNotifier.value;
    isMicMutedNotifier.value = nextMuted;
    if (nextMuted) {
      _userMicVolume = 0.0;
      audioActivity.value = AudioActivity(
        isAiResponding: audioActivity.value.isAiResponding,
        isUserSpeaking: false,
        userMicVolume: 0.0,
      );
    }
    if (!nextMuted && kIsWeb) {
      try {
        await _mic.resume();
      } catch (_) {}
    }
  }

  /// Called by the screen after the settings dialog reported a change.
  Future<void> onSettingsChanged() async {
    await loadAudioDevices();
    notifyListeners();
    _cameraFrameTimer?.cancel();
    _audioStreamSubscription?.cancel();
    await _audio.stopAll();
    await _live.close();
    _live.detach();
    _isConnected = false;
    notifyListeners();
    await connectSession();
  }

  // --- Gemini Live Session & Streaming ---

  Future<void> connectSession() async {
    if (_isConnecting) return;
    final currentLang = AppLanguageController.instance.currentLanguage;
    final i18n = VisionCallI18n(currentLang);

    if (!ApiKeyStore.hasApiKey) {
      final configured = await requestApiKeySetup?.call();
      if (configured != true || !ApiKeyStore.hasApiKey) {
        if (!_disposed) {
          _notice(
            VisionCallNotice(i18n.apiKeyMissing, VisionCallNoticeKind.info),
          );
        }
        return;
      }
    }

    _isConnecting = true;
    notifyListeners();

    try {
      final currentModel = ApiKeyStore.liveModel;

      final basePrompt = customSystemPrompt ?? i18n.defaultSystemPrompt;
      final promptText = '$basePrompt${i18n.languageInstruction}';

      final session = await _live.connect(
        model: currentModel,
        promptText: promptText,
        onOpen: () {
          debugPrint('🌐 Live session onOpen received.');
          if (_disposed) return;
          _isConnected = true;
          _isConnecting = false;
          notifyListeners();
        },
        onMessage: (msg) {
          _handleServerMessage(msg);
        },
        onError: (error, stack) {
          debugPrint('❌ Live session error: $error');
          if (_disposed) return;
          liveSubtitleNotifier.value = i18n.connectionError(error);
          _isConnected = false;
          _isConnecting = false;
          notifyListeners();
        },
        onClose: (code, reason) {
          debugPrint('🔒 Live session closed ($code): $reason');
          if (_disposed) return;
          if (reason != null && reason.isNotEmpty) {
            liveSubtitleNotifier.value = i18n.connectionClosed(reason);
          }
          _isConnected = false;
          _isConnecting = false;
          notifyListeners();
        },
      );

      if (!_disposed) {
        _live.attach(session);
        _isConnected = true;
        _isConnecting = false;
        notifyListeners();
        _startLiveStreams();
      }
    } catch (e) {
      debugPrint('Failed to connect live session: $e');
      if (!_disposed) {
        liveSubtitleNotifier.value = i18n.connectionFailed(e);
        _isConnecting = false;
        notifyListeners();
      }
    }
  }

  void _handleServerMessage(LiveServerMessage message) {
    // Record real-time token usage and cost
    usageTracker.recordMessage(message);

    final serverContent = message.serverContent;

    // Interruption (User barged in)
    if (serverContent?.interrupted ?? false) {
      debugPrint(
        '⚡ Server reported interrupted (userVol: ${_userMicVolume.toStringAsFixed(3)}, isAiSpeaking: $_isAiSpeaking)',
      );
      _audio.clear();
      _lastAiAudioReceivedTime = null;
      audioActivity.value = AudioActivity(
        isAiResponding: false,
        isUserSpeaking: audioActivity.value.isUserSpeaking,
        userMicVolume: audioActivity.value.userMicVolume,
      );
    }

    // Audio stream data from Gemini
    if (message.data != null && message.data!.isNotEmpty) {
      _lastAiAudioReceivedTime = DateTime.now();
      _audio.appendBase64Chunk(message.data!);
      audioActivity.value = AudioActivity(
        isAiResponding: true,
        isUserSpeaking: audioActivity.value.isUserSpeaking,
        userMicVolume: audioActivity.value.userMicVolume,
      );
    }

    // Turn complete
    if ((serverContent?.turnComplete ?? false) ||
        (serverContent?.generationComplete ?? false)) {
      _audio.onTurnComplete();
    }

    // Transcription updates
    if (serverContent?.inputTranscription != null) {
      final text = serverContent!.inputTranscription!.text ?? '';
      if (text.isNotEmpty) {
        _addChatMessage(isUser: true, text: text);
        liveSubtitleNotifier.value = '🎤 $text';
      }
    }

    // Output transcription or fallback text updates
    final outputText = visibleModelText(message);
    if (outputText != null && outputText.isNotEmpty) {
      _addChatMessage(isUser: false, text: outputText);
      liveSubtitleNotifier.value = '🌿 $outputText';
    }

    // Voice Activity Detection (VAD)
    if (message.voiceActivity != null) {
      _serverVadSpeaking = message.voiceActivity!.speechActive == true;
    }
    if (message.voiceActivityDetectionSignal != null) {
      final sig = message.voiceActivityDetectionSignal!;
      if (sig.start == true) {
        _serverVadSpeaking = true;
      }
      if (sig.end == true) {
        _serverVadSpeaking = false;
      }
    }
  }

  void _addChatMessage({required bool isUser, required String text}) {
    if (_disposed) return;
    _chatHistory.add(
      VisionChatMessage(isUser: isUser, text: text, timestamp: DateTime.now()),
    );
  }

  Future<void> _startLiveStreams() async {
    if (_audioStreamSubscription == null) {
      await _startMicStream();
    }
    _startCameraFrameLoop();
  }

  Future<void> _startMicStream() async {
    try {
      if (!await _mic.hasPermission()) {
        debugPrint('Microphone permission denied.');
        if (!_disposed) {
          final i18n = VisionCallI18n(
            AppLanguageController.instance.currentLanguage,
          );
          liveSubtitleNotifier.value = i18n.micPermissionRequired;
        }
        return;
      }

      final bool enableVoiceProc = _mic.voiceProcessingEnabled;
      debugPrint(
        '🎙️ Starting mic stream (sampleRate: ${VisionCallMicService.sampleRate}, device: ${_selectedAudioDevice?.label ?? "default"}, voiceProc: $enableVoiceProc)...',
      );

      final stream = await _mic.startStream(
        device: _selectedAudioDevice,
        enableVoiceProc: enableVoiceProc,
      );

      await _audioStreamSubscription?.cancel();
      int chunkCount = 0;
      _audioStreamSubscription = stream.listen(
        (chunk) {
          if (_isMicMuted) return;

          // Real-time amplitude from raw PCM 16-bit audio
          if (chunk.length >= 2) {
            final byteData = ByteData.sublistView(chunk);
            var peak = 0;
            for (var i = 0; i < chunk.length - 1; i += 2) {
              final sample = byteData.getInt16(i, Endian.little).abs();
              if (sample > peak) peak = sample;
            }
            final norm = (peak / 32768.0).clamp(0.0, 1.0);
            _userMicVolume = (_userMicVolume * 0.25) + (norm * 0.75);
            if (_userMicVolume > 0.015) {
              _lastMicInputTime = DateTime.now();
            }
          }

          // 소프트웨어 에코 억제 및 끼어들기(Barge-in) 필터링:
          // AI가 응답을 생성하거나 스피커로 재생 중일 때, 스피커 소리가 마이크로 재유입되어
          // Gemini Live 서버가 "사용자가 끼어들었다"고 오판하여 자기 말을 끊는(interrupted) 현상 방지!
          if (_isAiSpeaking) {
            // 사용자가 스피커 소리를 뚫고 명시적으로 크게 말한 경우(진짜 끼어들기)에만 패킷 전송 허용
            const double intentionalBargeInThreshold = 0.12;
            if (_userMicVolume < intentionalBargeInThreshold) {
              // 스피커 에코이므로 서버로 보내지 않음!
              return;
            } else {
              debugPrint(
                '🗣️ Intentional user barge-in detected (vol=${_userMicVolume.toStringAsFixed(3)})',
              );
            }
          }

          chunkCount++;
          if (chunkCount % 40 == 1) {
            debugPrint(
              '🎙️ Mic chunk: len=${chunk.length}, vol=${_userMicVolume.toStringAsFixed(3)}, connected=$_isConnected',
            );
          }

          if (!_live.hasSession || !_isConnected) return;

          _live.sendAudioChunk(chunk);
        },
        onError: (e) {
          debugPrint('Microphone stream error: $e');
        },
        cancelOnError: false,
      );

      if (!_disposed) {
        isMicMutedNotifier.value = false;
      }
      debugPrint('🎙️ Mic stream successfully started and listening.');
    } catch (e) {
      debugPrint('Failed to start mic stream: $e');
      if (!_disposed) {
        liveSubtitleNotifier.value = '⚠️ 마이크 시작 실패: $e';
      }
    }
  }

  void _startCameraFrameLoop() {
    _cameraFrameTimer?.cancel();
    if (_isVideoPaused) return;

    unawaited(_captureAndSendFrame());
    _cameraFrameTimer = Timer.periodic(_cameraFrameInterval, (_) {
      unawaited(_captureAndSendFrame());
    });
  }

  Future<void> _captureAndSendFrame() async {
    final controller = _cameraController;
    if (_captureInFlight ||
        controller == null ||
        !controller.value.isInitialized ||
        !_live.hasSession ||
        !_isConnected ||
        _isVideoPaused) {
      return;
    }

    captureInFlightNotifier.value = true;
    try {
      final bytes = await _cameraService.takePictureBytes(controller);

      Uint8List sendBytes = bytes;
      if (_isCameraFlipped) {
        try {
          sendBytes = _cameraService.flipHorizontalJpeg(bytes);
        } catch (e) {
          debugPrint('Camera snapshot flip error: $e');
        }
      }

      _live.sendVideoFrame(sendBytes);
    } catch (e) {
      debugPrint('Camera snapshot send error: $e');
    } finally {
      captureInFlightNotifier.value = false;
    }
  }

  /// Stops streaming and closes the session. The screen pops the route.
  void endCall() {
    _cameraFrameTimer?.cancel();
    _audioStreamSubscription?.cancel();
    _audio.stopPrimary();
    _live.close();
  }
}
