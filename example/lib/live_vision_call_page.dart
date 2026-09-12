import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gemini_live/gemini_live.dart';
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

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isMicMuted = false;
  bool _isVideoPaused = false;
  bool _isCameraInitializing = false;
  String? _cameraErrorMessage;
  bool _captureInFlight = false;

  // Speech & VAD states
  bool _isUserSpeaking = false;
  double _userMicVolume = 0.0;
  DateTime _lastMicInputTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isAiResponding = false;
  String _liveSubtitle = '';
  final List<_ChatMessage> _chatHistory = [];

  bool get _cameraReady =>
      _cameraController != null && _cameraController!.value.isInitialized;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _dotsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();

    _waveformTicker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) {
        final hasRecentMic =
            DateTime.now().difference(_lastMicInputTime).inMilliseconds < 350;
        if (!hasRecentMic) {
          _userMicVolume = _userMicVolume * 0.75;
          if (_userMicVolume < 0.01) _userMicVolume = 0.0;
        }
        final isSpeaking = hasRecentMic && _userMicVolume > 0.03;
        setState(() {
          _isAiResponding = _audioPlayer.isPlaying;
          if (!_isMicMuted) {
            _isUserSpeaking = isSpeaking;
          }
        });
      }
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
    await _loadCameras();
    await _connectSession();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _waveformTicker?.cancel();
    _cameraFrameTimer?.cancel();
    _audioStreamSubscription?.cancel();
    _dotsAnimController.dispose();
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
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _cameraFrameTimer?.cancel();
      unawaited(controller.dispose());
      if (mounted) {
        setState(() {
          _cameraController = null;
        });
      }
    } else if (state == AppLifecycleState.resumed && _availableCameras.isNotEmpty) {
      unawaited(_initCameraController(_availableCameras[_selectedCameraIndex]));
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
    setState(() {
      _isCameraInitializing = true;
      _cameraErrorMessage = null;
    });

    try {
      await _cameraController?.dispose();
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
    setState(() => _isVideoPaused = !_isVideoPaused);
    if (_isVideoPaused) {
      _cameraFrameTimer?.cancel();
      _cameraFrameTimer = null;
    } else {
      _startCameraFrameLoop();
    }
  }

  Future<void> _toggleMicMute() async {
    if (_audioStreamSubscription == null) {
      await _startMicStream();
      return;
    }
    setState(() {
      _isMicMuted = !_isMicMuted;
      if (_isMicMuted) {
        _userMicVolume = 0.0;
        _isUserSpeaking = false;
      }
    });
    if (!_isMicMuted && kIsWeb) {
      try {
        await _audioRecorder.resume();
      } catch (_) {}
    }
  }

  Future<void> _openSettings() async {
    final updated = await AppSettingsDialog.show(context);
    if (updated == true && mounted) {
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
                  voiceName: 'Puck',
                ),
              ),
            ),
            temperature: 0.7,
          ),
          realtimeInputConfig: RealtimeInputConfig(
            automaticActivityDetection: AutomaticActivityDetection(
              disabled: false,
              startOfSpeechSensitivity: StartSensitivity.START_SENSITIVITY_HIGH,
              endOfSpeechSensitivity: EndSensitivity.END_SENSITIVITY_LOW,
              prefixPaddingMs: 250,
              silenceDurationMs: 400,
            ),
          ),
          inputAudioTranscription: AudioTranscriptionConfig(),
          outputAudioTranscription: AudioTranscriptionConfig(),
          callbacks: LiveCallbacks(
            onOpen: () {
              if (!mounted) return;
              setState(() {
                _isConnected = true;
                _isConnecting = false;
              });
              _startLiveStreams();
            },
            onMessage: _handleServerMessage,
            onError: (error, stack) {
              debugPrint('Live session error: $error');
              if (!mounted) return;
              setState(() {
                _isConnected = false;
                _isConnecting = false;
                _liveSubtitle = '⚠️ 연결 끊김 / 오류: $error';
              });
            },
            onClose: (code, reason) {
              if (!mounted) return;
              setState(() {
                _isConnected = false;
                _isConnecting = false;
                if (reason != null && reason.isNotEmpty) {
                  _liveSubtitle = '연결 종료: $reason';
                }
              });
            },
          ),
        ),
      );

      if (mounted) {
        setState(() => _session = session);
      }
    } catch (e) {
      debugPrint('Failed to connect live session: $e');
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _liveSubtitle = '⚠️ 연결 실패: $e\n(상단 ⚙️ 설정을 확인하세요)';
        });
      }
    }
  }

  void _handleServerMessage(LiveServerMessage message) {
    final serverContent = message.serverContent;

    // Interruption (User barged in)
    if (serverContent?.interrupted ?? false) {
      if (_useFallbackAudio) {
        _fallbackAudioPlayer.clear();
      } else {
        _audioPlayer.clear();
      }
      if (mounted) {
        setState(() {
          _isAiResponding = false;
        });
      }
    }

    // Audio stream data from Gemini
    if (message.data != null && message.data!.isNotEmpty) {
      if (_useFallbackAudio) {
        _fallbackAudioPlayer.appendBase64Chunk(message.data!);
      } else {
        _audioPlayer.appendBase64Chunk(message.data!);
      }
      if (mounted) {
        setState(() => _isAiResponding = true);
      }
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
        if (mounted) {
          setState(() {
            _liveSubtitle = '🎤 $text';
          });
        }
      }
    }

    // Output transcription or fallback text updates
    final outputText = visibleModelText(message);
    if (outputText != null && outputText.isNotEmpty) {
      _addChatMessage(isUser: false, text: outputText);
      if (mounted) {
        setState(() {
          _liveSubtitle = '🌿 $outputText';
        });
      }
    }

    // Voice Activity Detection (VAD)
    if (message.voiceActivity != null) {
      if (mounted) {
        setState(() {
          _isUserSpeaking = message.voiceActivity!.speechActive == true;
        });
      }
    }
    if (message.voiceActivityDetectionSignal != null) {
      final sig = message.voiceActivityDetectionSignal!;
      if (sig.start == true && mounted) {
        setState(() => _isUserSpeaking = true);
      }
      if (sig.end == true && mounted) {
        setState(() => _isUserSpeaking = false);
      }
    }
  }

  void _addChatMessage({required bool isUser, required String text}) {
    if (!mounted) return;
    setState(() {
      _chatHistory.add(_ChatMessage(
        isUser: isUser,
        text: text,
        timestamp: DateTime.now(),
      ));
    });
  }

  Future<void> _startLiveStreams() async {
    await _startMicStream();
    _startCameraFrameLoop();
  }

  Future<void> _startMicStream() async {
    try {
      final hasMicPermission = await _audioRecorder.hasPermission();
      if (!hasMicPermission) {
        if (mounted) {
          setState(() {
            _liveSubtitle = '⚠️ 마이크 권한이 필요합니다. 아래 마이크 버튼을 눌러 허용해 주세요.';
          });
        }
        return;
      }

      final stream = await _audioRecorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: _audioSampleRate,
          numChannels: 1,
          autoGain: true,
          echoCancel: true,
          noiseSuppress: true,
          streamBufferSize: 2048,
        ),
      );

      await _audioStreamSubscription?.cancel();
      _audioStreamSubscription = stream.listen(
        (chunk) {
          if (_session == null || !_isConnected || _isMicMuted) return;

          // Real-time amplitude from raw PCM 16-bit audio
          if (chunk.length >= 2) {
            final byteData = ByteData.sublistView(chunk);
            var peak = 0;
            for (var i = 0; i < chunk.length - 1; i += 2) {
              final sample = byteData.getInt16(i, Endian.little).abs();
              if (sample > peak) peak = sample;
            }
            final norm = (peak / 32768.0).clamp(0.0, 1.0);
            _userMicVolume = (_userMicVolume * 0.3) + (norm * 0.7);
            if (_userMicVolume > 0.035) {
              _lastMicInputTime = DateTime.now();
            }
          }

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
        setState(() {
          _isMicMuted = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to start mic stream: $e');
      if (mounted) {
        setState(() {
          _liveSubtitle = '⚠️ 마이크 시작 실패: $e';
        });
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

    _captureInFlight = true;
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      final blob = Blob(mimeType: 'image/jpeg', data: base64Encode(bytes));

      _session!.sendRealtimeInput(
        video: blob,
      );
    } catch (e) {
      debugPrint('Camera snapshot send error: $e');
    } finally {
      _captureInFlight = false;
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
            if (_liveSubtitle.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(160),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    _liveSubtitle,
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
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _isConnected
                          ? (_isAiResponding
                              ? Colors.greenAccent
                              : (_isUserSpeaking ? Colors.amberAccent : Colors.green))
                          : (_isConnecting ? Colors.orangeAccent : Colors.redAccent),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isConnected
                        ? (_isAiResponding
                            ? 'AI Speaking...'
                            : (_isUserSpeaking ? 'Listening...' : 'Live · ${ApiKeyStore.liveModel}'))
                        : (_isConnecting ? 'Connecting...' : 'Disconnected'),
                    style: TextStyle(
                      color: Colors.white.withAlpha(180),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
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
    if (previewSize == null) {
      return CameraPreview(controller);
    }

    // On mobile devices (Android/iOS portrait), width and height are swapped because sensors are naturally landscape.
    // On Web and Desktop, sensors match window orientation and should NOT be swapped.
    final bool swapDimensions = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
         defaultTargetPlatform == TargetPlatform.iOS);

    final double previewWidth = swapDimensions ? previewSize.height : previewSize.width;
    final double previewHeight = swapDimensions ? previewSize.width : previewSize.height;

    return FittedBox(
      fit: BoxFit.cover,
      child: SizedBox(
        width: previewWidth,
        height: previewHeight,
        child: CameraPreview(controller),
      ),
    );
  }

  Widget _buildCameraViewfinder() {
    const viewfinderRadius = 28.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF04100A),
        borderRadius: BorderRadius.circular(viewfinderRadius),
        border: Border.all(
          color: _isAiResponding
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(viewfinderRadius - 1.5),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Camera Preview or Loading/Error state
            if (_cameraReady && !_isVideoPaused)
              _buildPreviewWidget()
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _cameraErrorMessage != null
                            ? Icons.videocam_off_outlined
                            : (_isVideoPaused
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
                            (_isVideoPaused
                                ? '카메라 전송이 일시 중지됨'
                                : (_isCameraInitializing
                                    ? '카메라 초기화 중...'
                                    : '카메라 준비 중...')),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _cameraErrorMessage != null
                              ? Colors.redAccent.shade100
                              : Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      if (_cameraErrorMessage != null) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadCameras,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('카메라 다시 시도 / 권한 허용'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white12,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
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
            if (_captureInFlight)
              Positioned(
                top: 14,
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
          _buildActionButton(
            backgroundColor: Colors.white,
            icon: _isVideoPaused
                ? Icons.videocam_off_rounded
                : Icons.videocam_rounded,
            iconColor: _isVideoPaused ? Colors.black54 : const Color(0xFF0F2D1E),
            onTap: _toggleVideoPause,
            tooltip: 'Camera On/Off',
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
          _buildActionButton(
            backgroundColor: Colors.white,
            icon: _isMicMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
            iconColor: _isMicMuted ? Colors.redAccent : const Color(0xFF0F2D1E),
            onTap: _toggleMicMute,
            tooltip: 'Microphone Mute',
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
      animation: _dotsAnimController,
      builder: (context, child) {
        final animValue = _dotsAnimController.value * 2 * math.pi;
        final isUserActive = _isUserSpeaking && !_isMicMuted;
        final isActive = _isAiResponding || isUserActive;

        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(dotCount, (i) {
            // Wave calculation
            final wave = math.sin(animValue + (i * 0.45));
            const baseHeight = 4.0;
            final dynamicHeight = isActive
                ? (isUserActive
                    ? (baseHeight +
                        (wave.abs() * (6.0 + (_userMicVolume * 22.0))))
                    : (baseHeight + (wave.abs() * 14.0)))
                : baseHeight;
            final alpha = isActive
                ? (160 + (wave.abs() * 95)).toInt().clamp(120, 255)
                : 100;

            final dotColor = _isAiResponding
                ? Colors.greenAccent
                : (isUserActive ? const Color(0xFFFFD54F) : Colors.white);

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
