import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:image/image.dart' as img;
import 'package:record/record.dart';

import 'api_key_store.dart';
import 'app_settings_dialog.dart';
import 'app_translations.dart';
import 'foldable_utils.dart';
import 'live_api_defaults.dart';
import 'live_audio_player.dart';
import 'soloud_live_audio_player.dart';

/// Fullscreen real-time multimodal Vision & Voice call page
/// for universal real-time multimodal interaction (Project Astra style).
class LiveVisionCallPage extends StatefulWidget {
  const LiveVisionCallPage({
    super.key,
    this.agentTitle,
    this.customSystemPrompt,
  });

  final String? agentTitle;
  final String? customSystemPrompt;

  @override
  State<LiveVisionCallPage> createState() => _LiveVisionCallPageState();
}

class _LiveVisionCallPageState extends State<LiveVisionCallPage>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const _cameraFrameInterval = Duration(milliseconds: 1200);
  static const _audioSampleRate = 16000;
  static const _audioMimeType = 'audio/pcm;rate=16000';

  final SoloudLiveAudioPlayer _audioPlayer = SoloudLiveAudioPlayer();
  final LiveAudioPlayer _fallbackAudioPlayer = LiveAudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _useFallbackAudio = kIsWeb;

  LiveSession? _session;
  CameraController? _cameraController;
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  Timer? _cameraFrameTimer;
  Timer? _waveformTicker;

  // Animation controller for bottom visualizer dots
  late final AnimationController _dotsAnimController;

  final List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;

  final List<InputDevice> _availableAudioDevices = [];
  InputDevice? _selectedAudioDevice;

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isCameraInitializing = false;
  String? _cameraErrorMessage;

  // Granular Reactive Notifiers (avoids screen-wide setState rebuilds)
  final ValueNotifier<_AudioActivity> _audioActivity = ValueNotifier(
    const _AudioActivity(),
  );
  final ValueNotifier<String> _liveSubtitleNotifier = ValueNotifier('');
  final ValueNotifier<bool> _isMicMutedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isVideoPausedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _captureInFlightNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isCameraFlippedNotifier = ValueNotifier(
    ApiKeyStore.isCameraFlipped,
  );

  bool get _isMicMuted => _isMicMutedNotifier.value;
  bool get _isVideoPaused => _isVideoPausedNotifier.value;
  bool get _captureInFlight => _captureInFlightNotifier.value;
  bool get _isCameraFlipped => _isCameraFlippedNotifier.value;

  // Local speech tracking state (no full-page rebuild needed)
  bool _serverVadSpeaking = false;
  double _userMicVolume = 0.0;
  DateTime _lastMicInputTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _lastAiAudioReceivedTime;
  final List<_ChatMessage> _chatHistory = [];

  // Real-time token usage and cost tracker
  final GeminiTokenUsageTracker _usageTracker = GeminiTokenUsageTracker(
    model: ApiKeyStore.liveModel,
  );

  bool get _isAiSpeaking {
    final isPlaying = _useFallbackAudio
        ? _fallbackAudioPlayer.isPlaying
        : _audioPlayer.isPlaying;
    if (isPlaying) return true;
    if (_lastAiAudioReceivedTime != null) {
      final diff = DateTime.now()
          .difference(_lastAiAudioReceivedTime!)
          .inMilliseconds;
      if (diff < 1200) return true;
    }
    return false;
  }

  bool get _cameraReady =>
      _cameraController != null && _cameraController!.value.isInitialized;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _dotsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _waveformTicker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      final hasRecentMic =
          DateTime.now().difference(_lastMicInputTime).inMilliseconds < 450;
      if (!hasRecentMic) {
        _userMicVolume = _userMicVolume * 0.75;
        if (_userMicVolume < 0.005) _userMicVolume = 0.0;
      }
      final isSpeaking = hasRecentMic && _userMicVolume > 0.015;
      final isAi = _audioPlayer.isPlaying || _fallbackAudioPlayer.isPlaying;
      final isUser = !_isMicMuted && (_serverVadSpeaking || isSpeaking);

      // Updates only listening widgets via ValueNotifier without full-screen rebuild!
      _audioActivity.value = _AudioActivity(
        isAiResponding: isAi,
        isUserSpeaking: isUser,
        userMicVolume: _userMicVolume,
      );
    });

    _initAll();
  }

  Future<void> _initAll() async {
    if (!kIsWeb) {
      try {
        await _audioPlayer.init();
      } catch (e) {
        debugPrint('SoLoud init error, fallback to audioplayers: $e');
        _useFallbackAudio = true;
      }
    } else {
      _useFallbackAudio = true;
    }
    await _loadAudioDevices();
    await _startMicStream();
    await _loadCameras();
    await _connectSession();
  }

  Future<void> _loadAudioDevices() async {
    try {
      final devices = await _audioRecorder.listInputDevices();
      if (!mounted) return;
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
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Failed to load audio input devices: $e');
    }
  }

  Future<void> _switchAudioDevice(InputDevice? device) async {
    if (_selectedAudioDevice?.id == device?.id) return;
    setState(() {
      _selectedAudioDevice = device;
    });
    await ApiKeyStore.saveAudioDevice(device?.id ?? '', device?.label ?? '');

    if (_audioStreamSubscription != null) {
      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = null;
      try {
        await _audioRecorder.stop();
      } catch (_) {}
      if (!_isMicMuted && mounted) {
        await _startMicStream();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _waveformTicker?.cancel();
    _cameraFrameTimer?.cancel();
    _audioStreamSubscription?.cancel();
    _dotsAnimController.dispose();
    _audioActivity.dispose();
    _liveSubtitleNotifier.dispose();
    _isMicMutedNotifier.dispose();
    _isVideoPausedNotifier.dispose();
    _captureInFlightNotifier.dispose();
    _isCameraFlippedNotifier.dispose();
    unawaited(_audioRecorder.stop());
    unawaited(_audioRecorder.dispose());
    unawaited(_cameraController?.dispose() ?? Future<void>.value());
    _session?.close();
    unawaited(_audioPlayer.dispose());
    unawaited(_fallbackAudioPlayer.dispose());
    _usageTracker.dispose();
    super.dispose();
  }

  @override
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
        setState(() {
          _cameraController = null;
        });
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

  Future<void> _loadCameras() async {
    setState(() {
      _cameraErrorMessage = null;
      _isCameraInitializing = true;
    });

    try {
      final cameras = await availableCameras();
      if (!mounted) return;
      setState(() {
        _availableCameras.clear();
        _availableCameras.addAll(cameras);
      });

      if (cameras.isNotEmpty) {
        await _initCameraController(cameras.first);
      } else {
        if (mounted) {
          final i18n = _VisionI18n(
            AppLanguageController.instance.currentLanguage,
          );
          setState(() {
            _isCameraInitializing = false;
            _cameraErrorMessage = i18n.noCameraFound;
          });
        }
      }
    } catch (e) {
      debugPrint('Camera load error: $e');
      if (mounted) {
        final i18n = _VisionI18n(
          AppLanguageController.instance.currentLanguage,
        );
        setState(() {
          _isCameraInitializing = false;
          _cameraErrorMessage = kIsWeb
              ? i18n.cameraPermissionError(e)
              : i18n.cameraLoadError(e);
        });
      }
    }
  }

  Future<void> _initCameraController(CameraDescription description) async {
    final oldController = _cameraController;
    setState(() {
      _cameraController = null;
      _isCameraInitializing = true;
      _cameraErrorMessage = null;
    });

    try {
      await oldController?.dispose();
      final controller = CameraController(
        description,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _cameraController = controller;
        _isCameraInitializing = false;
        _cameraErrorMessage = null;
      });

      if (_isConnected && !_isVideoPaused) {
        _startCameraFrameLoop();
      }
    } catch (e) {
      if (mounted) {
        final i18n = _VisionI18n(
          AppLanguageController.instance.currentLanguage,
        );
        setState(() {
          _isCameraInitializing = false;
          _cameraErrorMessage = i18n.cameraInitError(e);
        });
      }
      debugPrint('Camera controller init error: $e');
    }
  }

  Future<void> _toggleCameraDirection() async {
    if (_availableCameras.length < 2 || _isCameraInitializing) return;
    _cameraFrameTimer?.cancel();

    setState(() {
      _selectedCameraIndex =
          (_selectedCameraIndex + 1) % _availableCameras.length;
    });

    await _initCameraController(_availableCameras[_selectedCameraIndex]);
  }

  void _toggleVideoPause() {
    _isVideoPausedNotifier.value = !_isVideoPausedNotifier.value;
    if (_isVideoPaused) {
      _cameraFrameTimer?.cancel();
      _cameraFrameTimer = null;
    } else {
      _startCameraFrameLoop();
    }
  }

  Future<void> _toggleCameraFlip() async {
    final next = !_isCameraFlippedNotifier.value;
    _isCameraFlippedNotifier.value = next;
    await ApiKeyStore.saveCameraFlipped(next);
    if (mounted) {
      final i18n = _VisionI18n(AppLanguageController.instance.currentLanguage);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          content: Row(
            children: [
              Icon(
                next ? Icons.flip_rounded : Icons.swap_horiz_rounded,
                color: Colors.greenAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                next ? i18n.flipOn : i18n.flipOff,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _toggleMicMute() async {
    if (_audioStreamSubscription == null) {
      await _startMicStream();
      return;
    }
    final nextMuted = !_isMicMutedNotifier.value;
    _isMicMutedNotifier.value = nextMuted;
    if (nextMuted) {
      _userMicVolume = 0.0;
      _audioActivity.value = _AudioActivity(
        isAiResponding: _audioActivity.value.isAiResponding,
        isUserSpeaking: false,
        userMicVolume: 0.0,
      );
    }
    if (!nextMuted && kIsWeb) {
      try {
        await _audioRecorder.resume();
      } catch (_) {}
    }
  }

  Future<void> _openSettings() async {
    final updated = await AppSettingsDialog.show(context);
    if (updated == true && mounted) {
      await _loadAudioDevices();
      setState(() {});
      _cameraFrameTimer?.cancel();
      _audioStreamSubscription?.cancel();
      await _audioPlayer.stop();
      await _fallbackAudioPlayer.stop();
      await _session?.close();
      setState(() {
        _session = null;
        _isConnected = false;
      });
      await _connectSession();
    }
  }

  // --- Gemini Live Session & Streaming ---

  Future<void> _connectSession() async {
    if (_isConnecting) return;
    final currentLang = AppLanguageController.instance.currentLanguage;
    final i18n = _VisionI18n(currentLang);

    if (!ApiKeyStore.hasApiKey) {
      final configured = await AppSettingsDialog.show(context);
      if (configured != true || !ApiKeyStore.hasApiKey) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(i18n.apiKeyMissing)));
        }
        return;
      }
    }

    setState(() => _isConnecting = true);

    try {
      final genAI = GoogleGenAI(apiKey: ApiKeyStore.apiKey);
      final currentModel = ApiKeyStore.liveModel;

      final basePrompt = widget.customSystemPrompt ?? i18n.defaultSystemPrompt;
      final promptText = '$basePrompt${i18n.languageInstruction}';

      final systemInstruction = Content(parts: [Part(text: promptText)]);

      final session = await genAI.live.connect(
        LiveConnectParameters(
          model: currentModel,
          systemInstruction: systemInstruction,
          config: GenerationConfig(
            responseModalities: const [Modality.AUDIO],
            mediaResolution: MediaResolution.MEDIA_RESOLUTION_LOW,
            speechConfig: SpeechConfig(
              voiceConfig: VoiceConfig(
                prebuiltVoiceConfig: PrebuiltVoiceConfig(
                  voiceName: ApiKeyStore.voice,
                ),
              ),
            ),
            temperature: 0.7,
          ),
          realtimeInputConfig: RealtimeInputConfig(
            automaticActivityDetection: AutomaticActivityDetection(
              disabled: false,
              startOfSpeechSensitivity: StartSensitivity.START_SENSITIVITY_LOW,
              endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_LOW,
              prefixPaddingMs: 250,
              silenceDurationMs: 500,
            ),
          ),
          inputAudioTranscription: AudioTranscriptionConfig(),
          outputAudioTranscription: AudioTranscriptionConfig(),
          callbacks: LiveCallbacks(
            onOpen: () {
              debugPrint('🌐 Live session onOpen received.');
              if (!mounted) return;
              setState(() {
                _isConnected = true;
                _isConnecting = false;
              });
            },
            onMessage: (msg) {
              _handleServerMessage(msg);
            },
            onError: (error, stack) {
              debugPrint('❌ Live session error: $error');
              if (!mounted) return;
              _liveSubtitleNotifier.value = i18n.connectionError(error);
              setState(() {
                _isConnected = false;
                _isConnecting = false;
              });
            },
            onClose: (code, reason) {
              debugPrint('🔒 Live session closed ($code): $reason');
              if (!mounted) return;
              if (reason != null && reason.isNotEmpty) {
                _liveSubtitleNotifier.value = i18n.connectionClosed(reason);
              }
              setState(() {
                _isConnected = false;
                _isConnecting = false;
              });
            },
          ),
        ),
      );

      if (mounted) {
        setState(() {
          _session = session;
          _isConnected = true;
          _isConnecting = false;
        });
        _startLiveStreams();
      }
    } catch (e) {
      debugPrint('Failed to connect live session: $e');
      if (mounted) {
        _liveSubtitleNotifier.value = i18n.connectionFailed(e);
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  void _handleServerMessage(LiveServerMessage message) {
    // Record real-time token usage and cost
    _usageTracker.recordMessage(message);

    final serverContent = message.serverContent;

    // Interruption (User barged in)
    if (serverContent?.interrupted ?? false) {
      debugPrint(
        '⚡ Server reported interrupted (userVol: ${_userMicVolume.toStringAsFixed(3)}, isAiSpeaking: $_isAiSpeaking)',
      );
      if (_useFallbackAudio) {
        _fallbackAudioPlayer.clear();
      } else {
        _audioPlayer.clear();
      }
      _lastAiAudioReceivedTime = null;
      _audioActivity.value = _AudioActivity(
        isAiResponding: false,
        isUserSpeaking: _audioActivity.value.isUserSpeaking,
        userMicVolume: _audioActivity.value.userMicVolume,
      );
    }

    // Audio stream data from Gemini
    if (message.data != null && message.data!.isNotEmpty) {
      _lastAiAudioReceivedTime = DateTime.now();
      if (_useFallbackAudio) {
        _fallbackAudioPlayer.appendBase64Chunk(message.data!);
      } else {
        _audioPlayer.appendBase64Chunk(message.data!);
      }
      _audioActivity.value = _AudioActivity(
        isAiResponding: true,
        isUserSpeaking: _audioActivity.value.isUserSpeaking,
        userMicVolume: _audioActivity.value.userMicVolume,
      );
    }

    // Turn complete
    if ((serverContent?.turnComplete ?? false) ||
        (serverContent?.generationComplete ?? false)) {
      if (_useFallbackAudio) {
        if (_fallbackAudioPlayer.hasBufferedAudio) {
          unawaited(_fallbackAudioPlayer.playBufferedAudio());
        }
      } else {
        _audioPlayer.onTurnComplete();
      }
    }

    // Transcription updates
    if (serverContent?.inputTranscription != null) {
      final text = serverContent!.inputTranscription!.text ?? '';
      if (text.isNotEmpty) {
        _addChatMessage(isUser: true, text: text);
        _liveSubtitleNotifier.value = '🎤 $text';
      }
    }

    // Output transcription or fallback text updates
    final outputText = visibleModelText(message);
    if (outputText != null && outputText.isNotEmpty) {
      _addChatMessage(isUser: false, text: outputText);
      _liveSubtitleNotifier.value = '🌿 $outputText';
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
    if (!mounted) return;
    _chatHistory.add(
      _ChatMessage(isUser: isUser, text: text, timestamp: DateTime.now()),
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
      if (!await _audioRecorder.hasPermission()) {
        debugPrint('Microphone permission denied.');
        if (mounted) {
          final i18n = _VisionI18n(
            AppLanguageController.instance.currentLanguage,
          );
          _liveSubtitleNotifier.value = i18n.micPermissionRequired;
        }
        return;
      }

      final bool enableVoiceProc =
          !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      debugPrint(
        '🎙️ Starting mic stream (sampleRate: $_audioSampleRate, device: ${_selectedAudioDevice?.label ?? "default"}, voiceProc: $enableVoiceProc)...',
      );

      final stream = await _audioRecorder.startStream(
        RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _audioSampleRate,
          numChannels: 1,
          device: _selectedAudioDevice,
          autoGain: enableVoiceProc,
          echoCancel: enableVoiceProc,
          noiseSuppress: enableVoiceProc,
          streamBufferSize: 2048,
        ),
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

          if (_session == null || !_isConnected) return;

          final blob = Blob(
            mimeType: _audioMimeType,
            data: base64Encode(chunk),
          );
          _session!.sendRealtimeInput(audio: blob);
        },
        onError: (e) {
          debugPrint('Microphone stream error: $e');
        },
        cancelOnError: false,
      );

      if (mounted) {
        _isMicMutedNotifier.value = false;
      }
      debugPrint('🎙️ Mic stream successfully started and listening.');
    } catch (e) {
      debugPrint('Failed to start mic stream: $e');
      if (mounted) {
        _liveSubtitleNotifier.value = '⚠️ 마이크 시작 실패: $e';
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
        _session == null ||
        !_isConnected ||
        _isVideoPaused) {
      return;
    }

    _captureInFlightNotifier.value = true;
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();

      Uint8List sendBytes = bytes;
      if (_isCameraFlipped) {
        try {
          final decoded = img.decodeImage(bytes);
          if (decoded != null) {
            final flipped = img.flipHorizontal(decoded);
            sendBytes = Uint8List.fromList(img.encodeJpg(flipped, quality: 75));
          }
        } catch (e) {
          debugPrint('Camera snapshot flip error: $e');
        }
      }

      final blob = Blob(mimeType: 'image/jpeg', data: base64Encode(sendBytes));

      _session!.sendRealtimeInput(video: blob);
    } catch (e) {
      debugPrint('Camera snapshot send error: $e');
    } finally {
      _captureInFlightNotifier.value = false;
    }
  }

  void _endCall() {
    _cameraFrameTimer?.cancel();
    _audioStreamSubscription?.cancel();
    _audioPlayer.stop();
    _session?.close();
    Navigator.of(context).pop();
  }

  void _openChatSheet() {
    final i18n = _VisionI18n(AppLanguageController.instance.currentLanguage);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0C2417),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          i18n.liveTranscriptTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          i18n.messagesCount(_chatHistory.length),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 24),
                    Expanded(
                      child: _chatHistory.isEmpty
                          ? Center(
                              child: Text(
                                i18n.transcriptWaiting,
                                style: const TextStyle(color: Colors.white38),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _chatHistory.length,
                              reverse: true,
                              itemBuilder: (context, index) {
                                final item =
                                    _chatHistory[_chatHistory.length -
                                        1 -
                                        index];
                                return Align(
                                  alignment: item.isUser
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                          0.75,
                                    ),
                                    decoration: BoxDecoration(
                                      color: item.isUser
                                          ? const Color(0xFF1B4D36)
                                          : const Color(0xFF143323),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: item.isUser
                                            ? Colors.greenAccent.withAlpha(50)
                                            : Colors.white12,
                                      ),
                                    ),
                                    child: Text(
                                      item.text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- UI Build ---

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppLanguageController.instance,
      builder: (context, _) {
        final currentLang = AppLanguageController.instance.currentLanguage;
        final i18n = _VisionI18n(currentLang);

        // Deep forest green background theme matching the user's screenshot
        const themeBgColor = Color(0xFF091E14);
        final foldableInfo = FoldableLayoutInfo.of(context);

        // 1. Tabletop / Flex Mode (Foldable device half-opened on desk)
        if (foldableInfo.isTabletop) {
          return Scaffold(
            backgroundColor: themeBgColor,
            body: SafeArea(
              child: Column(
                children: [
                  _buildHeader(i18n),
                  // Top Upright Screen: Central Camera Viewfinder
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      child: _buildCameraViewfinder(i18n),
                    ),
                  ),

                  // Physical Crease Divider
                  Container(
                    height: 3,
                    color: Colors.greenAccent.withValues(alpha: 0.3),
                  ),

                  // Bottom Flat Screen: Live Subtitle, Transcript history, and Controls
                  Expanded(
                    flex: 4,
                    child: Column(
                      children: [
                        Expanded(
                          child: _chatHistory.isEmpty
                              ? Center(
                                  child: Text(
                                    i18n.tabletopWaiting,
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 13,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  reverse: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  itemCount: _chatHistory.length,
                                  itemBuilder: (context, index) {
                                    final item =
                                        _chatHistory[_chatHistory.length -
                                            1 -
                                            index];
                                    return Align(
                                      alignment: item.isUser
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 3,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: item.isUser
                                              ? const Color(0xFF1B4D36)
                                              : const Color(0xFF143323),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          item.text,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        _buildBottomControlBar(i18n),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 2. Dual-Screen Book Mode (Surface Duo or Galaxy Fold unfolded wide side-by-side)
        if (foldableInfo.hasHinge && foldableInfo.isBookMode) {
          return Scaffold(
            backgroundColor: themeBgColor,
            body: SafeArea(
              child: Row(
                children: [
                  // Left Screen: Header + Camera Viewfinder
                  Expanded(
                    child: Column(
                      children: [
                        _buildHeader(i18n),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: _buildCameraViewfinder(i18n),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Center Hinge Spacer
                  SizedBox(
                    width: (foldableInfo.hingeBounds?.width ?? 16).clamp(
                      8.0,
                      36.0,
                    ),
                    child: Center(
                      child: Container(
                        width: 2,
                        color: Colors.greenAccent.withValues(alpha: 0.2),
                      ),
                    ),
                  ),

                  // Right Screen: Transcript History & Controls
                  Expanded(
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.white70,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              i18n.liveTranscriptTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white12, height: 16),
                        Expanded(
                          child: _chatHistory.isEmpty
                              ? Center(
                                  child: Text(
                                    i18n.transcriptWaiting,
                                    style: const TextStyle(
                                      color: Colors.white38,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  reverse: true,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  itemCount: _chatHistory.length,
                                  itemBuilder: (context, index) {
                                    final item =
                                        _chatHistory[_chatHistory.length -
                                            1 -
                                            index];
                                    return Align(
                                      alignment: item.isUser
                                          ? Alignment.centerRight
                                          : Alignment.centerLeft,
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: item.isUser
                                              ? const Color(0xFF1B4D36)
                                              : const Color(0xFF143323),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          item.text,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        _buildBottomControlBar(i18n),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // 3. Standard Layout
        return Scaffold(
          backgroundColor: themeBgColor,
          body: SafeArea(
            child: Column(
              children: [
                // 1. Top Header (Logo + Title)
                _buildHeader(i18n),

                // 2. Central Camera Viewfinder with rounded corners
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 8,
                    ),
                    child: _buildCameraViewfinder(i18n),
                  ),
                ),

                // Live subtitle badge if any
                ValueListenableBuilder<String>(
                  valueListenable: _liveSubtitleNotifier,
                  builder: (context, subtitle, _) {
                    if (subtitle.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 6,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(160),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // 3. Bottom Control Bar (5 buttons)
                _buildBottomControlBar(i18n),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(_VisionI18n i18n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          // Circular green logo with eco/sprout icon
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Color(0xFF1B6A42),
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.agentTitle ?? i18n.defaultTitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              ValueListenableBuilder<_AudioActivity>(
                valueListenable: _audioActivity,
                builder: (context, act, _) {
                  final isAiSpeaking = act.isAiResponding;
                  final isUserSpeaking = act.isUserSpeaking;

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _isConnected
                              ? (isAiSpeaking
                                    ? Colors.greenAccent
                                    : (isUserSpeaking
                                          ? Colors.amberAccent
                                          : Colors.green))
                              : (_isConnecting
                                    ? Colors.orangeAccent
                                    : Colors.redAccent),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _isConnected
                            ? (isAiSpeaking
                                  ? i18n.aiSpeaking
                                  : (isUserSpeaking
                                        ? i18n.listening
                                        : i18n.liveStatus(
                                            ApiKeyStore.liveModel,
                                          )))
                            : (_isConnecting
                                  ? i18n.connecting
                                  : i18n.disconnected),
                        style: TextStyle(
                          color: Colors.white.withAlpha(180),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const Spacer(),
          // Real-time token usage and cost badge
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: GeminiLiveUsageBadge(
              tracker: _usageTracker,
              backgroundColor: Colors.white.withAlpha(25),
              foregroundColor: Colors.white,
            ),
          ),
          // Language switcher dropdown
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.0),
            child: LanguageSelectorButton(compact: true),
          ),
          // Audio Input Device selector
          PopupMenuButton<String>(
            tooltip: i18n.micSelectorTooltip(
              _selectedAudioDevice?.label.isNotEmpty == true
                  ? _selectedAudioDevice!.label
                  : i18n.defaultMic,
            ),
            icon: Icon(
              _selectedAudioDevice != null
                  ? Icons.mic_external_on_rounded
                  : Icons.mic_rounded,
              color: Colors.white70,
              size: 22,
            ),
            onOpened: _loadAudioDevices,
            onSelected: (deviceId) {
              if (deviceId == '__default__') {
                _switchAudioDevice(null);
              } else {
                final dev = _availableAudioDevices
                    .where((d) => d.id == deviceId)
                    .firstOrNull;
                _switchAudioDevice(dev);
              }
            },
            itemBuilder: (context) {
              return [
                PopupMenuItem<String>(
                  value: '__default__',
                  child: Row(
                    children: [
                      Icon(
                        _selectedAudioDevice == null
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 16,
                        color: _selectedAudioDevice == null
                            ? Colors.blueAccent
                            : Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(i18n.defaultMic),
                    ],
                  ),
                ),
                ..._availableAudioDevices.map((dev) {
                  final isSelected = _selectedAudioDevice?.id == dev.id;
                  return PopupMenuItem<String>(
                    value: dev.id,
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 16,
                          color: isSelected ? Colors.blueAccent : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            dev.label.isNotEmpty
                                ? dev.label
                                : '마이크 (${dev.id})',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ];
            },
          ),
          // Flip Camera Toggle button (좌우 반전 / 거울 모드)
          ValueListenableBuilder<bool>(
            valueListenable: _isCameraFlippedNotifier,
            builder: (context, isFlipped, _) {
              return IconButton(
                onPressed: _toggleCameraFlip,
                icon: Icon(
                  isFlipped ? Icons.flip_rounded : Icons.swap_horiz_rounded,
                  color: isFlipped ? Colors.greenAccent : Colors.white70,
                  size: 22,
                ),
                tooltip: isFlipped ? i18n.flipOn : i18n.flipOff,
              );
            },
          ),
          // Camera Switch button in header
          if (_availableCameras.length > 1)
            IconButton(
              onPressed: _toggleCameraDirection,
              icon: const Icon(
                Icons.flip_camera_ios_outlined,
                color: Colors.white70,
                size: 22,
              ),
              tooltip: i18n.switchCameraTooltip,
            ),
          // Settings button (API Key & Model)
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(
              Icons.tune_rounded,
              color: Colors.white70,
              size: 22,
            ),
            tooltip: i18n.settingsTooltip,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewWidget() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }

    final previewSize = controller.value.previewSize;

    // On mobile devices (Android/iOS portrait), width and height are swapped because sensors are naturally landscape.
    // On Web and Desktop, sensors match window orientation and should NOT be swapped.
    final bool swapDimensions =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    final double? previewWidth = previewSize != null
        ? (swapDimensions ? previewSize.height : previewSize.width)
        : null;
    final double? previewHeight = previewSize != null
        ? (swapDimensions ? previewSize.width : previewSize.height)
        : null;

    return ValueListenableBuilder<bool>(
      valueListenable: _isCameraFlippedNotifier,
      builder: (context, isFlipped, _) {
        final preview = CameraPreview(
          controller,
          key: ValueKey(controller.hashCode),
        );
        final flippedPreview = isFlipped
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(math.pi),
                child: preview,
              )
            : preview;

        if (previewWidth == null || previewHeight == null) {
          return flippedPreview;
        }

        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: previewWidth,
            height: previewHeight,
            child: flippedPreview,
          ),
        );
      },
    );
  }

  Widget _buildCameraViewfinder(_VisionI18n i18n) {
    const viewfinderRadius = 28.0;

    return ValueListenableBuilder<_AudioActivity>(
      valueListenable: _audioActivity,
      builder: (context, act, child) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF04100A),
            borderRadius: BorderRadius.circular(viewfinderRadius),
            border: Border.all(
              color: act.isAiResponding
                  ? Colors.greenAccent.withAlpha(120)
                  : Colors.white.withAlpha(18),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(100),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(viewfinderRadius - 1.5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera Preview or Loading/Error state
            ValueListenableBuilder<bool>(
              valueListenable: _isVideoPausedNotifier,
              builder: (context, isPaused, _) {
                if (_cameraReady && !isPaused) {
                  return _buildPreviewWidget();
                }

                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _cameraErrorMessage != null
                              ? Icons.videocam_off_outlined
                              : (isPaused
                                    ? Icons.pause_circle_outline
                                    : Icons.camera_alt_outlined),
                          color: _cameraErrorMessage != null
                              ? Colors.redAccent.withAlpha(200)
                              : Colors.white38,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _cameraErrorMessage ??
                              (isPaused
                                  ? i18n.cameraPaused
                                  : (_isCameraInitializing
                                        ? i18n.cameraConnecting
                                        : i18n.cameraPreparing)),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withAlpha(180),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_cameraErrorMessage != null) ...[
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: _loadCameras,
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: Text(i18n.retryCamera),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),

            // Top-left label pill
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.remove_red_eye_outlined,
                      color: Colors.white70,
                      size: 14,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Gemini Vision',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Top-right camera flip toggle pill
            Positioned(
              top: 14,
              right: 14,
              child: ValueListenableBuilder<bool>(
                valueListenable: _isCameraFlippedNotifier,
                builder: (context, isFlipped, _) {
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _toggleCameraFlip,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isFlipped
                              ? const Color(0xFF104626).withAlpha(220)
                              : Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFlipped
                                ? Colors.greenAccent.withAlpha(160)
                                : Colors.white24,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.swap_horiz_rounded,
                              color: isFlipped
                                  ? Colors.greenAccent
                                  : Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isFlipped
                                  ? i18n.flipToggleTextOn
                                  : i18n.flipToggleTextOff,
                              style: TextStyle(
                                color: isFlipped
                                    ? Colors.greenAccent
                                    : Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Subtle focus crosshair or corner guides
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withAlpha(40),
                        Colors.transparent,
                        Colors.black.withAlpha(60),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // Indicator pill (Sending frame)
            ValueListenableBuilder<bool>(
              valueListenable: _captureInFlightNotifier,
              builder: (context, inFlight, _) {
                if (!inFlight) return const SizedBox.shrink();
                return Positioned(
                  bottom: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 8,
                          height: 8,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.greenAccent,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControlBar(_VisionI18n i18n) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 12, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Chat button (Dark semi-transparent circle)
          _buildActionButton(
            backgroundColor: const Color(0xFF173827),
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: Colors.white,
            onTap: _openChatSheet,
            tooltip: i18n.liveTranscriptTitle,
          ),

          // 2. Camera Toggle button (White circle)
          ValueListenableBuilder<bool>(
            valueListenable: _isVideoPausedNotifier,
            builder: (context, isPaused, _) {
              return _buildActionButton(
                backgroundColor: Colors.white,
                icon: isPaused
                    ? Icons.videocam_off_rounded
                    : Icons.videocam_rounded,
                iconColor: isPaused ? Colors.black54 : const Color(0xFF0F2D1E),
                onTap: _toggleVideoPause,
                tooltip: i18n.cameraToggleTooltip,
              );
            },
          ),

          // 3. Central Dot Waveform Visualizer
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(child: _buildDotWaveform()),
            ),
          ),

          // 4. Microphone Toggle button (White circle)
          ValueListenableBuilder<bool>(
            valueListenable: _isMicMutedNotifier,
            builder: (context, isMuted, _) {
              return _buildActionButton(
                backgroundColor: Colors.white,
                icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                iconColor: isMuted ? Colors.redAccent : const Color(0xFF0F2D1E),
                onTap: _toggleMicMute,
                tooltip: i18n.micToggleTooltip,
              );
            },
          ),

          // 5. End Call button (Red circle)
          _buildActionButton(
            backgroundColor: const Color(0xFFD32F2F),
            icon: Icons.call_end_rounded,
            iconColor: Colors.white,
            onTap: _endCall,
            tooltip: i18n.endSessionTooltip,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        elevation: 4,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Icon(icon, color: iconColor, size: 26),
          ),
        ),
      ),
    );
  }

  /// Animated horizontal dots (••••••••••••••) responding to speech / AI response
  Widget _buildDotWaveform() {
    const dotCount = 14;

    return AnimatedBuilder(
      animation: Listenable.merge([_dotsAnimController, _audioActivity]),
      builder: (context, child) {
        final animValue = _dotsAnimController.value * 2 * math.pi;
        final act = _audioActivity.value;
        final isUserSpeaking = act.isUserSpeaking || act.userMicVolume > 0.015;
        final isAiActive = act.isAiResponding;
        final isActive = isAiActive || isUserSpeaking;

        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(dotCount, (i) {
            // Wave calculation
            final wave = math.sin(animValue + (i * 0.45));
            const baseHeight = 4.0;
            final dynamicHeight = isActive
                ? (isUserSpeaking
                      ? (baseHeight +
                            (wave.abs() * (8.0 + (act.userMicVolume * 28.0))))
                      : (baseHeight + (wave.abs() * 14.0)))
                : baseHeight;
            final alpha = isActive
                ? (160 + (wave.abs() * 95)).toInt().clamp(120, 255)
                : 100;

            final dotColor = isAiActive
                ? Colors.greenAccent
                : (isUserSpeaking ? const Color(0xFFFFD54F) : Colors.white);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.2),
              width: 4.0,
              height: dynamicHeight,
              decoration: BoxDecoration(
                color: dotColor.withAlpha(alpha),
                borderRadius: BorderRadius.circular(2.0),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ChatMessage {
  _ChatMessage({
    required this.isUser,
    required this.text,
    required this.timestamp,
  });

  final bool isUser;
  final String text;
  final DateTime timestamp;
}

/// Immutable state holder for real-time audio & voice activity.
/// Used with [ValueNotifier] to completely avoid full-page [setState] calls.
class _AudioActivity {
  const _AudioActivity({
    this.isAiResponding = false,
    this.isUserSpeaking = false,
    this.userMicVolume = 0.0,
  });

  final bool isAiResponding;
  final bool isUserSpeaking;
  final double userMicVolume;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _AudioActivity &&
          runtimeType == other.runtimeType &&
          isAiResponding == other.isAiResponding &&
          isUserSpeaking == other.isUserSpeaking &&
          (userMicVolume - other.userMicVolume).abs() < 0.005;

  @override
  int get hashCode => Object.hash(
    isAiResponding,
    isUserSpeaking,
    (userMicVolume * 100).round(),
  );
}

/// Multilingual translation helper for Live Vision Call Page (ko, en, ja, zh).
class _VisionI18n {
  final AppLanguage lang;
  const _VisionI18n(this.lang);

  String get defaultSystemPrompt => switch (lang) {
    AppLanguage.ja =>
      'あなたはリアルタイムカメラと音声でユーザーをサポートする汎用マルチモーダルAIアシスタントです。\n'
          '【言語ルール】\n'
          '1. 最優先ルール: ユーザーが発話した言語を自動認識し、常にユーザーと同じ言語で自然に回答してください。'
          '(ユーザーが日本語で話したら日本語で、韓国語なら韓国語で、英語なら英語で、中国語なら中国語で回答)\n'
          '2. ユーザーが言葉を発していない時や言語が不明確な場合の基本・優先言語は日本語（Japanese）です。\n'
          '3. ユーザーが会話の途中で言語を変更した場合は、柔軟に変更後の言語に合わせて回答してください。\n'
          '【応答スタイル】\n'
          'カメラ映像（物体、文字、コード、周囲の状況）をリアルタイムで観察し、親切かつ簡潔に（1〜2文程度）自然な口語体でリアルタイム音声で回答してください。',
    AppLanguage.ko =>
      '너는 실시간 카메라와 음성으로 사용자를 도와주는 범용 멀티모달 AI 비서야.\n'
          '【언어 규칙】\n'
          '1. 최우선 규칙: 사용자가 말하는 언어를 자동으로 감지하여, 항상 사용자가 말한 언어와 동일한 언어로 자연스럽게 답변해줘. '
          '(사용자가 한국어로 말하면 한국어로, 일본어로 말하면 일본어로, 영어로 말하면 영어로, 중국어로 말하면 중국어로 답변)\n'
          '2. 사용자의 발화가 아직 없거나 언어가 불분명한 경우 기본 설정 언어는 한국어(Korean)야.\n'
          '3. 사용자가 대화 도중 언어를 바꾸면 유연하게 바뀐 언어에 맞춰서 자연스럽게 답변해줘.\n'
          '【응답 스타일】\n'
          '카메라 화면(사물, 텍스트, 코드, 주변 환경 등)을 실시간으로 관찰하고, 친절하고 간결하게(1~2문장 내외) 자연스러운 구어체 음성으로 답변해줘.',
    AppLanguage.zh =>
      '你是一个通过实时摄像头和语音协助用户的全能多模态AI助手。\n'
          '【语言规则】\n'
          '1. 最高优先级规则: 自动识别用户说话所使用的语言，并始终以与用户相同的语言自然回答。'
          '(用户说中文就用中文回答，说日文就用日文回答，说韩文就用韩文回答，说英文就用英文回答)\n'
          '2. 用户未发声或语言不明确时的默认/首选语言为中文（Chinese）。\n'
          '3. 如果用户在对话中切换了语言，请迅速灵活地跟进切换后的语言。\n'
          '【交互风格】\n'
          '实时观察镜头画面（物体、文字、代码、环境），并以亲切、简短（1-2句左右）且自然的口语语音回答。',
    AppLanguage.en =>
      'You are a versatile multimodal AI assistant helping the user via live camera vision and voice.\n'
          '【Language Rules】\n'
          '1. TOP PRIORITY: Automatically detect the language the user is speaking in, and ALWAYS reply in the exact same language as the user. '
          '(If the user speaks Japanese, reply in Japanese; if Korean, reply in Korean; if English, reply in English; if Chinese, reply in Chinese, etc.)\n'
          '2. When the user has not spoken yet or the language is ambiguous, use English as the default preferred language.\n'
          '3. If the user switches languages mid-conversation, dynamically match their new language.\n'
          '【Response Style】\n'
          'Continuously observe objects, text, code, and surroundings in the camera stream, and answer concisely (1 to 2 sentences) in natural spoken conversational speech.',
  };

  String get languageInstruction => switch (lang) {
    AppLanguage.ja =>
      '\n\n[Multilingual Voice Interaction Rule]:\n'
          '- Primary Rule: Always respond in the EXACT SAME language that the user speaks. If the user speaks Japanese, reply in Japanese; if Korean, reply in Korean; if English, reply in English.\n'
          '- Default/Fallback Language: Japanese (日本語) when the user has not spoken yet or language is ambiguous.',
    AppLanguage.ko =>
      '\n\n[Multilingual Voice Interaction Rule]:\n'
          '- Primary Rule: Always respond in the EXACT SAME language that the user speaks. If the user speaks Korean, reply in Korean; if Japanese, reply in Japanese; if English, reply in English.\n'
          '- Default/Fallback Language: Korean (한국어) when the user has not spoken yet or language is ambiguous.',
    AppLanguage.zh =>
      '\n\n[Multilingual Voice Interaction Rule]:\n'
          '- Primary Rule: Always respond in the EXACT SAME language that the user speaks. If the user speaks Chinese, reply in Chinese; if Japanese, reply in Japanese; if English, reply in English.\n'
          '- Default/Fallback Language: Chinese (中文) when the user has not spoken or language is ambiguous.',
    AppLanguage.en =>
      '\n\n[Multilingual Voice Interaction Rule]:\n'
          '- Primary Rule: Always respond in the EXACT SAME language that the user speaks. If the user speaks English, reply in English; if Japanese, reply in Japanese; if Korean, reply in Korean.\n'
          '- Default/Fallback Language: English when the user has not spoken yet or language is ambiguous.',
  };

  String get defaultTitle => switch (lang) {
    AppLanguage.ja => 'Live Vision AI',
    AppLanguage.ko => 'Live Vision AI',
    AppLanguage.zh => 'Live Vision AI',
    AppLanguage.en => 'Live Vision AI',
  };

  String get aiSpeaking => switch (lang) {
    AppLanguage.ja => 'AI 発話中...',
    AppLanguage.ko => 'AI 답변 중...',
    AppLanguage.zh => 'AI 发言中...',
    AppLanguage.en => 'AI Speaking...',
  };

  String get listening => switch (lang) {
    AppLanguage.ja => '聞き取り中...',
    AppLanguage.ko => '듣는 중...',
    AppLanguage.zh => '正在倾听...',
    AppLanguage.en => 'Listening...',
  };

  String liveStatus(String model) => switch (lang) {
    AppLanguage.ja => 'ライブ · $model',
    AppLanguage.ko => '실시간 · $model',
    AppLanguage.zh => '实时 · $model',
    AppLanguage.en => 'Live · $model',
  };

  String get connecting => switch (lang) {
    AppLanguage.ja => '接続中...',
    AppLanguage.ko => '연결 중...',
    AppLanguage.zh => '正在连接...',
    AppLanguage.en => 'Connecting...',
  };

  String get disconnected => switch (lang) {
    AppLanguage.ja => '切断済み',
    AppLanguage.ko => '연결 끊김',
    AppLanguage.zh => '已断开',
    AppLanguage.en => 'Disconnected',
  };

  String get noCameraFound => switch (lang) {
    AppLanguage.ja => '利用可能なカメラが見つかりません。',
    AppLanguage.ko => '사용 가능한 카메라를 찾을 수 없습니다.',
    AppLanguage.zh => '未找到可用摄像头。',
    AppLanguage.en => 'No available cameras found.',
  };

  String cameraPermissionError(Object e) => switch (lang) {
    AppLanguage.ja => 'ブラウザのカメラ権限を許可してください: $e',
    AppLanguage.ko => '브라우저 카메라 권한을 허용해 주세요: $e',
    AppLanguage.zh => '请允许浏览器摄像头权限: $e',
    AppLanguage.en => 'Please grant browser camera permissions: $e',
  };

  String cameraLoadError(Object e) => switch (lang) {
    AppLanguage.ja => 'カメラを読み込めませんでした: $e',
    AppLanguage.ko => '카메라를 불러오지 못했습니다: $e',
    AppLanguage.zh => '无法加载摄像头: $e',
    AppLanguage.en => 'Failed to load camera: $e',
  };

  String cameraInitError(Object e) => switch (lang) {
    AppLanguage.ja => 'カメラの初期化に失敗しました: $e',
    AppLanguage.ko => '카메라 초기화 실패: $e',
    AppLanguage.zh => '摄像头初始化失败: $e',
    AppLanguage.en => 'Camera initialization failed: $e',
  };

  String get cameraPaused => switch (lang) {
    AppLanguage.ja => 'カメラが一時停止中です',
    AppLanguage.ko => '카메라가 일시정지되었습니다',
    AppLanguage.zh => '摄像头已暂停',
    AppLanguage.en => 'Camera is paused',
  };

  String get cameraConnecting => switch (lang) {
    AppLanguage.ja => 'カメラ接続中...',
    AppLanguage.ko => '카메라 연결 중...',
    AppLanguage.zh => '摄像头连接中...',
    AppLanguage.en => 'Connecting camera...',
  };

  String get cameraPreparing => switch (lang) {
    AppLanguage.ja => 'カメラ準備中...',
    AppLanguage.ko => '카메라 준비 중...',
    AppLanguage.zh => '摄像头准备中...',
    AppLanguage.en => 'Preparing camera...',
  };

  String get retryCamera => switch (lang) {
    AppLanguage.ja => 'カメラを再試行',
    AppLanguage.ko => '카메라 다시 시도',
    AppLanguage.zh => '重试摄像头',
    AppLanguage.en => 'Retry Camera',
  };

  String get flipOn => switch (lang) {
    AppLanguage.ja => 'カメラ左右反転ON (文字正常読取モード)',
    AppLanguage.ko => '카메라 좌우 반전 켜짐 (텍스트 정상 읽기 모드)',
    AppLanguage.zh => '摄像头水平翻转已开启 (正常识字模式)',
    AppLanguage.en => 'Camera flip ON (Natural reading mode)',
  };

  String get flipOff => switch (lang) {
    AppLanguage.ja => 'カメラ左右反転OFF (ミラーモード)',
    AppLanguage.ko => '카메라 좌우 반전 꺼짐 (거울 모드)',
    AppLanguage.zh => '摄像头水平翻转已关闭 (镜像模式)',
    AppLanguage.en => 'Camera flip OFF (Mirror mode)',
  };

  String get flipToggleTextOn => switch (lang) {
    AppLanguage.ja => '反転 (文字読取)',
    AppLanguage.ko => '좌우반전 (글자 읽기)',
    AppLanguage.zh => '翻转 (正常识字)',
    AppLanguage.en => 'Flipped (Reading)',
  };

  String get flipToggleTextOff => switch (lang) {
    AppLanguage.ja => 'ミラーモード',
    AppLanguage.ko => '거울 모드',
    AppLanguage.zh => '镜像模式',
    AppLanguage.en => 'Mirror Mode',
  };

  String get apiKeyMissing => switch (lang) {
    AppLanguage.ja => 'Gemini APIキーが設定されていません。',
    AppLanguage.ko => 'Gemini API 키가 설정되지 않았습니다.',
    AppLanguage.zh => '未设置 Gemini API 密钥。',
    AppLanguage.en => 'Gemini API key is not configured.',
  };

  String connectionError(Object error) => switch (lang) {
    AppLanguage.ja => '⚠️ 接続切断 / エラー: $error',
    AppLanguage.ko => '⚠️ 연결 끊김 / 오류: $error',
    AppLanguage.zh => '⚠️ 连接断开 / 错误: $error',
    AppLanguage.en => '⚠️ Disconnected / Error: $error',
  };

  String connectionClosed(String reason) => switch (lang) {
    AppLanguage.ja => '接続終了: $reason',
    AppLanguage.ko => '연결 종료: $reason',
    AppLanguage.zh => '连接已关闭: $reason',
    AppLanguage.en => 'Session closed: $reason',
  };

  String connectionFailed(Object error) => switch (lang) {
    AppLanguage.ja => '⚠️ 接続失敗: $error\n(右上の ⚙️ 設定をご確認ください)',
    AppLanguage.ko => '⚠️ 연결 실패: $error\n(상단 ⚙️ 설정을 확인하세요)',
    AppLanguage.zh => '⚠️ 连接失败: $error\n(请检查顶部 ⚙️ 设置)',
    AppLanguage.en => '⚠️ Connection failed: $error\n(Check ⚙️ settings above)',
  };

  String get micPermissionRequired => switch (lang) {
    AppLanguage.ja => '⚠️ マイク権限が必要です。システムのプライバシー設定でアプリを許可してください。',
    AppLanguage.ko =>
      '⚠️ 마이크 권한이 필요합니다. [시스템 설정 > 개인정보 보호 및 보안 > 마이크]에서 앱을 허용해 주세요.',
    AppLanguage.zh => '⚠️ 需要麦克风权限。请在系统设置中允许应用访问麦克风。',
    AppLanguage.en =>
      '⚠️ Microphone permission required. Please allow access in system settings.',
  };

  String get transcriptWaiting => switch (lang) {
    AppLanguage.ja => '対話が始まると、ここにリアルタイム字幕が表示されます。',
    AppLanguage.ko => '대화가 시작되면 실시간 자막이 여기에 표시됩니다.',
    AppLanguage.zh => '对话开始后，实时字幕将显示在此处。',
    AppLanguage.en =>
      'Live transcripts will appear here once conversation starts.',
  };

  String get tabletopWaiting => switch (lang) {
    AppLanguage.ja => 'リアルタイム対話と Vision AI の分析がここに表示されます。',
    AppLanguage.ko => '실시간 대화와 Vision AI 분석이 여기에 표시됩니다.',
    AppLanguage.zh => '实时对话与 Vision AI 分析将显示在此处。',
    AppLanguage.en =>
      'Live conversation and Vision AI analysis will appear here.',
  };

  String get liveTranscriptTitle => switch (lang) {
    AppLanguage.ja => 'リアルタイム文字起こし',
    AppLanguage.ko => '실시간 자막 & 대화 기록',
    AppLanguage.zh => '实时文字记录',
    AppLanguage.en => 'Live Transcript',
  };

  String messagesCount(int count) => switch (lang) {
    AppLanguage.ja => '$count 件のメッセージ',
    AppLanguage.ko => '$count개 메시지',
    AppLanguage.zh => '$count 条消息',
    AppLanguage.en => '$count messages',
  };

  String get defaultMic => switch (lang) {
    AppLanguage.ja => 'デフォルトマイク (System Default)',
    AppLanguage.ko => '기본 마이크 (System Default)',
    AppLanguage.zh => '系统默认麦克风 (System Default)',
    AppLanguage.en => 'System Default Microphone',
  };

  String micSelectorTooltip(String label) => switch (lang) {
    AppLanguage.ja => 'マイク入力デバイス選択 ($label)',
    AppLanguage.ko => '마이크 입력 장치 선택 ($label)',
    AppLanguage.zh => '选择麦克风输入设备 ($label)',
    AppLanguage.en => 'Select Microphone Device ($label)',
  };

  String get switchCameraTooltip => switch (lang) {
    AppLanguage.ja => 'カメラ切り替え',
    AppLanguage.ko => '카메라 전환',
    AppLanguage.zh => '切换摄像头',
    AppLanguage.en => 'Switch Camera',
  };

  String get settingsTooltip => switch (lang) {
    AppLanguage.ja => 'APIキー・モデル設定',
    AppLanguage.ko => 'API 키 및 모델 설정',
    AppLanguage.zh => 'API 密钥及模型设置',
    AppLanguage.en => 'API Key & Model Settings',
  };

  String get cameraToggleTooltip => switch (lang) {
    AppLanguage.ja => 'カメラ ON/OFF',
    AppLanguage.ko => '카메라 켜기/끄기',
    AppLanguage.zh => '摄像头 开/关',
    AppLanguage.en => 'Camera On/Off',
  };

  String get micToggleTooltip => switch (lang) {
    AppLanguage.ja => 'マイクミュート切替',
    AppLanguage.ko => '마이크 음소거 전환',
    AppLanguage.zh => '麦克风静音切换',
    AppLanguage.en => 'Microphone Mute',
  };

  String get endSessionTooltip => switch (lang) {
    AppLanguage.ja => '通話を終了',
    AppLanguage.ko => '통화 종료',
    AppLanguage.zh => '结束通话',
    AppLanguage.en => 'End Session',
  };
}
