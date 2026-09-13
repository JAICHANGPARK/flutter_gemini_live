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
import 'live_api_defaults.dart';
import 'live_audio_player.dart';
import 'soloud_live_audio_player.dart';

/// Fullscreen real-time multimodal Vision & Voice call page
/// for universal real-time multimodal interaction (Project Astra style).
class LiveVisionCallPage extends StatefulWidget {
  const LiveVisionCallPage({
    super.key,
    this.agentTitle = 'Live Vision AI',
    this.customSystemPrompt,
  });

  final String agentTitle;
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
  final ValueNotifier<_AudioActivity> _audioActivity =
      ValueNotifier(const _AudioActivity());
  final ValueNotifier<String> _liveSubtitleNotifier = ValueNotifier('');
  final ValueNotifier<bool> _isMicMutedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isVideoPausedNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _captureInFlightNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isCameraFlippedNotifier =
      ValueNotifier(ApiKeyStore.isCameraFlipped);

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

  bool get _isAiSpeaking {
    final isPlaying = _useFallbackAudio
        ? _fallbackAudioPlayer.isPlaying
        : _audioPlayer.isPlaying;
    if (isPlaying) return true;
    if (_lastAiAudioReceivedTime != null) {
      final diff =
          DateTime.now().difference(_lastAiAudioReceivedTime!).inMilliseconds;
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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On Desktop (macOS, Windows, Linux) and Web, switching focus to another window
    // (inactive) should NOT dispose or freeze the camera!
    final bool isDesktopOrWeb = kIsWeb ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux;

    if (isDesktopOrWeb) return;

    // Mobile (Android / iOS) lifecycle handling
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraFrameTimer?.cancel();
      final controller = _cameraController;
      if (controller != null) {
        setState(() {
          _cameraController = null;
        });
        unawaited(controller.dispose());
      }
    } else if (state == AppLifecycleState.resumed && _availableCameras.isNotEmpty) {
      if (_cameraController == null && !_isCameraInitializing) {
        unawaited(_initCameraController(_availableCameras[_selectedCameraIndex]));
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
          setState(() {
            _isCameraInitializing = false;
            _cameraErrorMessage = '사용 가능한 카메라를 찾을 수 없습니다.';
          });
        }
      }
    } catch (e) {
      debugPrint('Camera load error: $e');
      if (mounted) {
        setState(() {
          _isCameraInitializing = false;
          _cameraErrorMessage = kIsWeb
              ? '브라우저 카메라 권한을 허용해 주세요: $e'
              : '카메라를 불러오지 못했습니다: $e';
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
        setState(() {
          _isCameraInitializing = false;
          _cameraErrorMessage = '카메라 초기화 실패: $e';
        });
      }
      debugPrint('Camera controller init error: $e');
    }
  }

  Future<void> _toggleCameraDirection() async {
    if (_availableCameras.length < 2 || _isCameraInitializing) return;
    _cameraFrameTimer?.cancel();

    setState(() {
      _selectedCameraIndex = (_selectedCameraIndex + 1) % _availableCameras.length;
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
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              Icon(
                next ? Icons.flip_rounded : Icons.swap_horiz_rounded,
                color: Colors.greenAccent,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                next
                    ? '카메라 좌우 반전 켜짐 (텍스트 정상 읽기 모드)'
                    : '카메라 좌우 반전 꺼짐 (거울 모드)',
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
    if (!ApiKeyStore.hasApiKey) {
      final configured = await AppSettingsDialog.show(context);
      if (configured != true || !ApiKeyStore.hasApiKey) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gemini API 키가 설정되지 않았습니다.')),
          );
        }
        return;
      }
    }

    setState(() => _isConnecting = true);

    try {
      final genAI = GoogleGenAI(apiKey: ApiKeyStore.apiKey);
      final currentModel = ApiKeyStore.liveModel;

      final promptText = widget.customSystemPrompt ??
          '너는 실시간 카메라와 음성으로 사용자를 도와주는 범용 멀티모달 AI 비서야. '
          '카메라 화면에 비치는 사물, 텍스트, 코드, 주변 환경, 상황 등을 실시간으로 관찰하고, '
          '사용자의 질문이나 대화에 맞춰 친절하고 자연스러운 한국어 구어체로 간결하게(1~2문장 내외) 실시간 음성으로 답변해줘. '
          '듣는 사람이 편안하게 이해할 수 있도록 대화하듯이 말해줘.';

      final systemInstruction = Content(
        parts: [
          Part(text: promptText),
        ],
      );

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
              _liveSubtitleNotifier.value = '⚠️ 연결 끊김 / 오류: $error';
              setState(() {
                _isConnected = false;
                _isConnecting = false;
              });
            },
            onClose: (code, reason) {
              debugPrint('🔒 Live session closed ($code): $reason');
              if (!mounted) return;
              if (reason != null && reason.isNotEmpty) {
                _liveSubtitleNotifier.value = '연결 종료: $reason';
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
        _liveSubtitleNotifier.value = '⚠️ 연결 실패: $e\n(상단 ⚙️ 설정을 확인하세요)';
        setState(() {
          _isConnecting = false;
        });
      }
    }
  }

  void _handleServerMessage(LiveServerMessage message) {
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
    _chatHistory.add(_ChatMessage(
      isUser: isUser,
      text: text,
      timestamp: DateTime.now(),
    ));
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
          _liveSubtitleNotifier.value =
              '⚠️ 마이크 권한이 필요합니다. macOS [시스템 설정 > 개인정보 보호 및 보안 > 마이크]에서 앱을 허용해 주세요.';
        }
        return;
      }

      final bool enableVoiceProc = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
      debugPrint('🎙️ Starting mic stream (sampleRate: $_audioSampleRate, device: ${_selectedAudioDevice?.label ?? "default"}, voiceProc: $enableVoiceProc)...');

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
              debugPrint('🗣️ Intentional user barge-in detected (vol=${_userMicVolume.toStringAsFixed(3)})');
            }
          }

          chunkCount++;
          if (chunkCount % 40 == 1) {
            debugPrint('🎙️ Mic chunk: len=${chunk.length}, vol=${_userMicVolume.toStringAsFixed(3)}, connected=$_isConnected');
          }

          if (_session == null || !_isConnected) return;

          final blob = Blob(mimeType: _audioMimeType, data: base64Encode(chunk));
          _session!.sendRealtimeInput(
            audio: blob,
          );
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

      _session!.sendRealtimeInput(
        video: blob,
      );
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                        const Icon(Icons.chat_bubble_outline, color: Colors.white70, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Live Transcript',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_chatHistory.length} messages',
                          style: const TextStyle(color: Colors.white38, fontSize: 13),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white12, height: 24),
                    Expanded(
                      child: _chatHistory.isEmpty
                          ? const Center(
                              child: Text(
                                '대화가 시작되면 실시간 자막이 여기에 표시됩니다.',
                                style: TextStyle(color: Colors.white38),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _chatHistory.length,
                              reverse: true,
                              itemBuilder: (context, index) {
                                final item = _chatHistory[_chatHistory.length - 1 - index];
                                return Align(
                                  alignment: item.isUser
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 10,
                                    ),
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.75,
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
    // Deep forest green background theme matching the user's screenshot
    const themeBgColor = Color(0xFF091E14);

    return Scaffold(
      backgroundColor: themeBgColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Top Header (Logo + Title)
            _buildHeader(),

            // 2. Central Camera Viewfinder with rounded corners
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                child: _buildCameraViewfinder(),
              ),
            ),

            // Live subtitle badge if any
            ValueListenableBuilder<String>(
              valueListenable: _liveSubtitleNotifier,
              builder: (context, subtitle, _) {
                if (subtitle.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            _buildBottomControlBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                widget.agentTitle,
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
                                ? 'AI Speaking...'
                                : (isUserSpeaking
                                    ? 'Listening...'
                                    : 'Live · ${ApiKeyStore.liveModel}'))
                            : (_isConnecting
                                ? 'Connecting...'
                                : 'Disconnected'),
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
          // Audio Input Device selector
          PopupMenuButton<String>(
            tooltip:
                '마이크 입력 장치 선택 (${_selectedAudioDevice?.label.isNotEmpty == true ? _selectedAudioDevice!.label : "기본 마이크"})',
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
                      const Text('기본 마이크 (System Default)'),
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
                            dev.label.isNotEmpty ? dev.label : '마이크 (${dev.id})',
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
                tooltip: isFlipped
                    ? '좌우 반전 켜짐 (텍스트 정상 읽기 모드)'
                    : '좌우 반전 꺼짐 (거울 모드)',
              );
            },
          ),
          // Camera Switch button in header
          if (_availableCameras.length > 1)
            IconButton(
              onPressed: _toggleCameraDirection,
              icon: const Icon(Icons.flip_camera_ios_outlined, color: Colors.white70, size: 22),
              tooltip: 'Switch Camera',
            ),
          // Settings button (API Key & Model)
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.tune_rounded, color: Colors.white70, size: 22),
            tooltip: 'API Key & Model Settings',
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
    final bool swapDimensions = !kIsWeb &&
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
        final preview = CameraPreview(controller, key: ValueKey(controller.hashCode));
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

  Widget _buildCameraViewfinder() {
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
                                  ? '카메라가 일시정지되었습니다'
                                  : (_isCameraInitializing
                                      ? '카메라 연결 중...'
                                      : '카메라 준비 중...')),
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
                            label: const Text('카메라 다시 시도'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white24),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.remove_red_eye_outlined, color: Colors.white70, size: 14),
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
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
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
                              color: isFlipped ? Colors.greenAccent : Colors.white70,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isFlipped ? '좌우반전 (글자 읽기)' : '거울 모드',
                              style: TextStyle(
                                color: isFlipped ? Colors.greenAccent : Colors.white70,
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
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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

  Widget _buildBottomControlBar() {
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
            tooltip: 'Live Transcript',
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
                iconColor:
                    isPaused ? Colors.black54 : const Color(0xFF0F2D1E),
                onTap: _toggleVideoPause,
                tooltip: 'Camera On/Off',
              );
            },
          ),

          // 3. Central Dot Waveform Visualizer
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(
                child: _buildDotWaveform(),
              ),
            ),
          ),

          // 4. Microphone Toggle button (White circle)
          ValueListenableBuilder<bool>(
            valueListenable: _isMicMutedNotifier,
            builder: (context, isMuted, _) {
              return _buildActionButton(
                backgroundColor: Colors.white,
                icon: isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                iconColor:
                    isMuted ? Colors.redAccent : const Color(0xFF0F2D1E),
                onTap: _toggleMicMute,
                tooltip: 'Microphone Mute',
              );
            },
          ),

          // 5. End Call button (Red circle)
          _buildActionButton(
            backgroundColor: const Color(0xFFD32F2F),
            icon: Icons.call_end_rounded,
            iconColor: Colors.white,
            onTap: _endCall,
            tooltip: 'End Session',
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
  int get hashCode =>
      Object.hash(isAiResponding, isUserSpeaking, (userMicVolume * 100).round());
}
