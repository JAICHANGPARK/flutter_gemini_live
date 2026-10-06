import 'dart:async';

import 'package:camera/camera.dart';
import 'package:example/api_key_store.dart';
import 'package:example/app_translations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gemini_live/gemini_live.dart';
import 'package:record/record.dart';

import '../../../data/repositories/solution_history_repository.dart';
import '../../../data/repositories/system_instruction_repository.dart';
import '../../../data/repositories/transcript_repository.dart';
import '../../../data/services/math_tutor_audio_service.dart';
import '../../../data/services/math_tutor_camera_service.dart';
import '../../../data/services/math_tutor_image_service.dart';
import '../../../data/services/math_tutor_live_service.dart';
import '../../../data/services/math_tutor_mic_service.dart';
import '../../../domain/models/default_system_instruction.dart';
import '../../../domain/models/live_transcript_entry.dart';
import '../../../domain/models/math_curriculum_level.dart';
import '../../../domain/models/math_solution_record.dart';
import '../../../domain/solution_parser.dart';
import '../math_tutor_i18n.dart';
import 'math_tutor_notice.dart';

/// State + logic for the Live Exam Tutor screen.
///
/// Coarse state (connection, camera, history, tabs, ...) notifies through
/// [ChangeNotifier]. High-frequency streaming state (subtitles, live solution
/// / thoughts text, mic level, transcript ticks, thinking status) lives on
/// dedicated [ValueNotifier]s so only the small subtrees that listen rebuild.
///
/// The view model never touches a `BuildContext`; it asks the view for things
/// via [onNotice] and [requestApiKeySetup].
class MathTutorViewModel extends ChangeNotifier {
  MathTutorViewModel({
    MathTutorAudioService? audioService,
    MathTutorMicService? micService,
    MathTutorCameraService? cameraService,
    MathTutorImageService? imageService,
    MathTutorLiveService? liveService,
    SolutionHistoryRepository? historyRepository,
    SystemInstructionRepository? systemInstructionRepository,
    TranscriptRepository? transcriptRepository,
  }) : _audio = audioService ?? MathTutorAudioService(),
       _mic = micService ?? MathTutorMicService(),
       _cameraService = cameraService ?? MathTutorCameraService(),
       _imageService = imageService ?? MathTutorImageService(),
       _live = liveService ?? MathTutorLiveService(),
       _historyRepo = historyRepository ?? SolutionHistoryRepository(),
       _siRepo = systemInstructionRepository ?? SystemInstructionRepository(),
       _transcriptRepo = transcriptRepository ?? TranscriptRepository();

  static const _cameraFrameInterval = Duration(milliseconds: 1600);

  final MathTutorAudioService _audio;
  final MathTutorMicService _mic;
  final MathTutorCameraService _cameraService;
  final MathTutorImageService _imageService;
  final MathTutorLiveService _live;
  final SolutionHistoryRepository _historyRepo;
  final SystemInstructionRepository _siRepo;
  final TranscriptRepository _transcriptRepo;

  // --- View hooks (set by the screen) ---

  /// Show a transient message (snackbar).
  void Function(MathTutorNotice notice)? onNotice;

  /// Ask the user to configure an API key; resolves `true` if configured.
  Future<bool?> Function()? requestApiKeySetup;

  bool _disposed = false;
  bool get isDisposed => _disposed;

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  void _notice(String message, MathTutorNoticeKind kind) {
    if (_disposed) return;
    onNotice?.call(MathTutorNotice(message, kind));
  }

  // --- Connection / session state ---

  bool _isConnected = false;
  bool _isConnecting = false;
  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;

  StreamSubscription<Uint8List>? _audioStreamSubscription;
  Timer? _cameraFrameTimer;

  // --- Camera state ---

  CameraController? _cameraController;
  final List<CameraDescription> _availableCameras = [];
  int _selectedCameraIndex = 0;
  bool _isCameraInitializing = false;
  bool _isFlashOn = false;
  bool _captureInFlight = false;
  Uint8List? _lastProblemImage;

  CameraController? get cameraController => _cameraController;
  bool get isCameraInitializing => _isCameraInitializing;
  bool get isFlashOn => _isFlashOn;

  // --- UI state ---

  bool _isAutoScanEnabled = true;
  bool _isCameraExpanded = false;
  bool _isBottomSheetVisible = true;
  bool _isMicMuted = false;
  int _activeTabIndex = 0; // 0: 풀이 노트, 1: 실시간 대화 로그, 2: AI 심층 생각 과정
  MathCurriculumLevel _curriculumLevel = MathCurriculumLevel.auto;

  bool get isAutoScanEnabled => _isAutoScanEnabled;
  bool get isCameraExpanded => _isCameraExpanded;
  bool get isBottomSheetVisible => _isBottomSheetVisible;
  bool get isMicMuted => _isMicMuted;
  int get activeTabIndex => _activeTabIndex;
  MathCurriculumLevel get curriculumLevel => _curriculumLevel;

  set activeTabIndex(int index) {
    _activeTabIndex = index;
    notifyListeners();
  }

  set isBottomSheetVisible(bool visible) {
    _isBottomSheetVisible = visible;
    notifyListeners();
  }

  void toggleBottomSheet() => isBottomSheetVisible = !_isBottomSheetVisible;

  void toggleCameraExpanded() {
    _isCameraExpanded = !_isCameraExpanded;
    notifyListeners();
  }

  void toggleMic() {
    _isMicMuted = !_isMicMuted;
    notifyListeners();
  }

  void toggleAutoScan() {
    _isAutoScanEnabled = !_isAutoScanEnabled;
    notifyListeners();
    if (_isAutoScanEnabled) {
      _startCameraFrameLoop();
    } else {
      _cameraFrameTimer?.cancel();
    }
  }

  // --- Streaming state (ValueNotifiers, zero full-tree rebuilds) ---

  final ValueNotifier<int> transcriptUpdateNotifier = ValueNotifier(0);
  final ValueNotifier<double> liveMicVolumeNotifier = ValueNotifier(0.0);
  final ValueNotifier<String> liveSubtitleNotifier = ValueNotifier('');
  final ValueNotifier<String> liveSolutionNotifier = ValueNotifier('');
  final ValueNotifier<String> liveThoughtsNotifier = ValueNotifier('');
  final ValueNotifier<InteractionStatus> interactionStatusNotifier =
      ValueNotifier(InteractionStatus.IDLE);
  final ValueNotifier<int> thoughtsTokenNotifier = ValueNotifier(0);

  final StringBuffer _currentTurnSolutionBuffer = StringBuffer();
  final StringBuffer _currentTurnThoughtsBuffer = StringBuffer();
  Timer? _solutionStreamThrottleTimer;
  Timer? _thoughtsStreamThrottleTimer;
  bool _turnHasModelTextParts = false;

  /// Mic level (0..1) and number of consecutive chunks (~64 ms each) required
  /// to treat speech during AI playback as a deliberate interruption.
  static const double _bargeInVolumeThreshold = 0.3;
  static const int _bargeInSustainedChunks = 5;
  int _bargeInLoudChunks = 0;
  Timer? _interruptionNoticeTimer;

  /// Auto-scroll controllers for the three tab bodies. Owned here because the
  /// streaming handlers trigger the scrolling; the view just attaches them.
  final ScrollController transcriptScrollController = ScrollController();
  final ScrollController solutionScrollController = ScrollController();
  final ScrollController thoughtsScrollController = ScrollController();

  // --- Audio input devices & VAD ---

  final List<InputDevice> _availableAudioDevices = [];
  InputDevice? _selectedAudioDevice;
  double _userMicVolume = 0.0;
  DateTime _lastMicInputTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _serverVadSpeaking = false;
  int _micChunkCount = 0;

  List<InputDevice> get availableAudioDevices => _availableAudioDevices;
  InputDevice? get selectedAudioDevice => _selectedAudioDevice;
  bool get isAiSpeaking => _audio.isAiSpeaking;

  /// Server VAD says speech is active, or the mic heard input in the last 450ms.
  bool get isUserSpeaking =>
      _serverVadSpeaking ||
      DateTime.now().difference(_lastMicInputTime).inMilliseconds < 450;

  // --- Data ---

  final List<MathSolutionRecord> _solutionHistory = [];
  List<MathSolutionRecord> get solutionHistory => _solutionHistory;
  List<LiveTranscriptEntry> get transcriptEntries => _transcriptRepo.entries;
  String _customSystemInstruction = defaultMathTutorSystemInstruction;
  String get customSystemInstruction => _customSystemInstruction;

  final GeminiTokenUsageTracker _usageTracker = GeminiTokenUsageTracker(
    model: LiveModels.gemini38LiveExtendedThinking,
  );

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  Future<void> init() async {
    await _audio.init();
    await _loadPersistedData();
    await loadAudioDevices();
    await _loadCameras();
    await _startMicStream();
    await connectSession();
  }

  @override
  void dispose() {
    _disposed = true;
    _cameraFrameTimer?.cancel();
    _solutionStreamThrottleTimer?.cancel();
    _thoughtsStreamThrottleTimer?.cancel();
    _interruptionNoticeTimer?.cancel();
    _audioStreamSubscription?.cancel();
    liveSubtitleNotifier.dispose();
    liveSolutionNotifier.dispose();
    liveThoughtsNotifier.dispose();
    interactionStatusNotifier.dispose();
    thoughtsTokenNotifier.dispose();
    transcriptUpdateNotifier.dispose();
    liveMicVolumeNotifier.dispose();
    solutionScrollController.dispose();
    thoughtsScrollController.dispose();
    transcriptScrollController.dispose();
    _mic.dispose();
    unawaited(_cameraController?.dispose() ?? Future<void>.value());
    _live.close();
    _audio.dispose();
    _usageTracker.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> _loadPersistedData() async {
    _customSystemInstruction = await _siRepo.load();
    final loaded = await _historyRepo.load();
    if (loaded != null && !_disposed) {
      _solutionHistory
        ..clear()
        ..addAll(loaded);
      notifyListeners();
    }
  }

  /// Wipes the saved history (the view has already confirmed with the user).
  Future<void> clearHistory() async {
    _solutionHistory.clear();
    notifyListeners();
    await _historyRepo.clear();
    if (_disposed) return;
    _notice(
      MathTutorI18n(
        AppLanguageController.instance.currentLanguage,
      ).clearHistorySuccess,
      MathTutorNoticeKind.success,
    );
  }

  void clearTranscript() {
    _transcriptRepo.clear();
    notifyListeners();
    transcriptUpdateNotifier.value++;
  }

  /// Saves and applies a new system instruction, reconnecting if connected.
  Future<void> applySystemInstruction(String newText) async {
    if (newText.isEmpty) return;
    _customSystemInstruction = newText;
    notifyListeners();
    await _siRepo.save(newText);

    if (_disposed) return;
    if (_isConnected) {
      _notice(
        '새 System Instruction을 적용하여 세션을 재연결합니다...',
        MathTutorNoticeKind.sync,
      );
      _live.close();
      await connectSession();
    } else {
      _notice('System Instruction이 저장되었습니다.', MathTutorNoticeKind.success);
    }
  }

  // ---------------------------------------------------------------------------
  // Audio input devices
  // ---------------------------------------------------------------------------

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
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load audio input devices: $e');
    }
  }

  /// Selects the input device by id (`null` = system default).
  Future<void> selectAudioDeviceById(String? deviceId) {
    final dev = deviceId == null
        ? null
        : _availableAudioDevices.where((d) => d.id == deviceId).firstOrNull;
    return _switchAudioDevice(dev);
  }

  Future<void> _switchAudioDevice(InputDevice? device) async {
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

  // ---------------------------------------------------------------------------
  // Camera
  // ---------------------------------------------------------------------------

  Future<void> _loadCameras() async {
    _isCameraInitializing = true;
    notifyListeners();
    try {
      final cameras = await _cameraService.listCameras();
      if (_disposed) return;
      _availableCameras
        ..clear()
        ..addAll(cameras);

      if (_availableCameras.isNotEmpty) {
        // Prefer back camera for scanning documents
        _selectedCameraIndex = _cameraService.preferredCameraIndex(
          _availableCameras,
        );
        await _initCameraController(_availableCameras[_selectedCameraIndex]);
      }
    } catch (e) {
      debugPrint('Failed to load cameras: $e');
    } finally {
      if (!_disposed) {
        _isCameraInitializing = false;
        notifyListeners();
      }
    }
  }

  Future<void> _initCameraController(CameraDescription desc) async {
    final prev = _cameraController;
    if (prev != null) {
      await prev.dispose();
    }

    try {
      final controller = await _cameraService.createAndInitialize(desc);
      if (_disposed) return;
      _cameraController = controller;
      _isFlashOn = false;
      notifyListeners();
      if (_isAutoScanEnabled && _isConnected) {
        _startCameraFrameLoop();
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> toggleCamera() async {
    if (_availableCameras.length < 2) return;
    _cameraFrameTimer?.cancel();
    _selectedCameraIndex =
        (_selectedCameraIndex + 1) % _availableCameras.length;
    await _initCameraController(_availableCameras[_selectedCameraIndex]);
  }

  Future<void> toggleFlash() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;
    try {
      final next = !_isFlashOn;
      await _cameraService.setTorch(controller, next);
      if (!_disposed) {
        _isFlashOn = next;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Flash toggle error: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Gemini Live session with Extended Thinking
  // ---------------------------------------------------------------------------

  Future<void> connectSession({String? specificModel}) async {
    if (_isConnecting) return;
    if (!ApiKeyStore.hasApiKey) {
      final configured = await requestApiKeySetup?.call();
      if (configured != true || !ApiKeyStore.hasApiKey) {
        _notice('Gemini API 키가 설정되지 않았습니다.', MathTutorNoticeKind.keyOff);
        return;
      }
    }

    _isConnecting = true;
    notifyListeners();

    // Prefer specificModel, or user-selected ApiKeyStore.liveModel, or default to extended thinking
    final targetModel =
        specificModel ??
        (ApiKeyStore.liveModel.isNotEmpty
            ? ApiKeyStore.liveModel
            : LiveModels.gemini38LiveExtendedThinking);

    try {
      final systemInstruction = MathTutorLiveService.buildSystemInstruction(
        customInstruction: _customSystemInstruction,
        language: AppLanguageController.instance.currentLanguage,
        curriculum: _curriculumLevel,
      );

      await _live.connect(
        model: targetModel,
        systemInstruction: systemInstruction,
        onOpen: () {
          if (_disposed) return;
          _isConnected = true;
          _isConnecting = false;
          notifyListeners();
          debugPrint(
            '✅ Math Tutor Gemini Live Session Connected ($targetModel)!',
          );
          _transcriptRepo.addSystem(
            '✅ Gemini 3.8 Live 세션 연결 완료 ($targetModel)',
          );
          transcriptUpdateNotifier.value++;
          if (_isAutoScanEnabled) {
            _startCameraFrameLoop();
          }
        },
        onMessage: _handleServerMessage,
        onError: (err, st) {
          debugPrint('🔴 Live Session Error ($targetModel): $err\n$st');
          if (_disposed) return;
          _isConnected = false;
          _isConnecting = false;
          notifyListeners();
          _transcriptRepo.addSystem('🔴 Live 세션 오류 발생: $err');
          transcriptUpdateNotifier.value++;
          _notice('수학 과외 세션 오류: $err', MathTutorNoticeKind.error);
        },
        onClose: (code, reason) {
          debugPrint('⚪ Live Session Closed ($targetModel): $code / $reason');
          if (_disposed) return;
          _isConnected = false;
          _isConnecting = false;
          notifyListeners();
          _transcriptRepo.addSystem('⚪ Live 세션 연결 종료 ($code: $reason)');
          transcriptUpdateNotifier.value++;
        },
      );
    } catch (e) {
      debugPrint('Live session connect failed ($targetModel): $e');
      if (_disposed) return;
      _isConnecting = false;
      notifyListeners();

      // Auto-fallback: If extended thinking failed, try standard live model
      if (targetModel != LiveModels.gemini38Live) {
        debugPrint(
          '⚠️ Falling back to stable model ${LiveModels.gemini38Live}...',
        );
        _notice(
          '안정적인 실시간 모델(${LiveModels.gemini38Live})로 자동 재연결 중...',
          MathTutorNoticeKind.sync,
        );
        await connectSession(specificModel: LiveModels.gemini38Live);
        return;
      }

      _notice('연결 실패: $e', MathTutorNoticeKind.cloudOff);
    }
  }

  void _handleServerMessage(LiveServerMessage message) {
    if (_disposed) return;

    // Track usage and thinking tokens
    final usage = message.usageMetadata;
    if (usage != null) {
      _usageTracker.recordUsage(usage);
      if (usage.thoughtsTokenCount != null) {
        thoughtsTokenNotifier.value = usage.thoughtsTokenCount!;
      }
    }

    final serverContent = message.serverContent;

    // 0. Live user speech transcription feedback (User STT)
    final userInput =
        serverContent?.inputTranscription?.text ??
        serverContent?.interimInputTranscription?.text;
    if (userInput != null && userInput.trim().isNotEmpty) {
      final text = userInput.trim();
      liveSubtitleNotifier.value = '🎤 나: $text';

      // Record user utterance into live transcript history
      _transcriptRepo.recordUserUtterance(text);
      transcriptUpdateNotifier.value++;
      _scrollToBottom(transcriptScrollController);
    }

    // 1. Interaction status tracking (IN_PROGRESS vs IDLE)
    if (serverContent?.interactionStatus != null) {
      final newStatus = serverContent!.interactionStatus!;
      if (newStatus != interactionStatusNotifier.value) {
        interactionStatusNotifier.value = newStatus;
      }
    }

    // 2. Interruption / Barge-in handling
    if (serverContent?.interrupted == true) {
      _audio.clear();
      final lang = AppLanguageController.instance.currentLanguage;
      liveSubtitleNotifier.value = MathTutorI18n(lang).interruptedNotice;

      // Add system interruption log entry
      _transcriptRepo.addSystem(
        '⚡ 사용자 발화 감지로 AI 해설이 일시 중단되었습니다 (Interrupted)',
        isInterrupted: true,
      );
      transcriptUpdateNotifier.value++;
      _scrollToBottom(transcriptScrollController);

      // Auto-clear notice after 2.5s so false alarms or quick stops don't stay frozen
      _interruptionNoticeTimer?.cancel();
      _interruptionNoticeTimer = Timer(const Duration(milliseconds: 2500), () {
        if (!_disposed &&
            liveSubtitleNotifier.value ==
                MathTutorI18n(lang).interruptedNotice) {
          liveSubtitleNotifier.value = '';
        }
      });
      return;
    }

    // 3. Audio stream playback
    if (message.data != null && message.data!.isNotEmpty) {
      _audio.appendBase64Chunk(message.data!);
    }

    // Voice Activity Detection (VAD) from server
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

    // 3b. Audio-only responses carry no text parts; the spoken explanation
    // arrives as output transcription, so build the notes and transcript
    // from it unless the server also sent text parts for this turn.
    final modelSpeech = serverContent?.outputTranscription?.text;
    if (modelSpeech != null &&
        modelSpeech.isNotEmpty &&
        !_turnHasModelTextParts) {
      _currentTurnSolutionBuffer.write(modelSpeech);
      final spoken = _currentTurnSolutionBuffer.toString().trim();
      liveSubtitleNotifier.value = spoken.length > 140
          ? '…${spoken.substring(spoken.length - 140)}'
          : spoken;
      _notifySolutionStream();
      _scrollToBottom(solutionScrollController);

      _transcriptRepo.appendModelText(modelSpeech);
      transcriptUpdateNotifier.value++;
      _scrollToBottom(transcriptScrollController);
    }

    // 4. Extract thoughts vs spoken answer from modelTurn parts
    final parts = serverContent?.modelTurn?.parts;
    if (parts != null && parts.isNotEmpty) {
      for (final part in parts) {
        final text = part.text;
        if (text == null || text.isEmpty) continue;

        if (part.thought == true) {
          // Internal Extended Thinking scratchpad
          _currentTurnThoughtsBuffer.write(text);
          _notifyThoughtsStream();
          _scrollToBottom(thoughtsScrollController);
        } else {
          // Visible Solution explanation text
          _turnHasModelTextParts = true;
          _currentTurnSolutionBuffer.write(text);
          liveSubtitleNotifier.value = text.trim();
          _notifySolutionStream();
          _scrollToBottom(solutionScrollController);

          // Append model speech to live transcript history
          _transcriptRepo.appendModelText(text);
          transcriptUpdateNotifier.value++;
          _scrollToBottom(transcriptScrollController);
        }
      }
    }

    // 5. Turn Complete: commit the solution card to history
    final isTurnComplete =
        (serverContent?.turnComplete ?? false) ||
        (serverContent?.generationComplete ?? false);

    if (isTurnComplete) {
      _audio.onTurnComplete();

      // Flush any throttled buffers immediately
      _solutionStreamThrottleTimer?.cancel();
      _thoughtsStreamThrottleTimer?.cancel();
      liveSolutionNotifier.value = _currentTurnSolutionBuffer.toString().trim();
      liveThoughtsNotifier.value = _currentTurnThoughtsBuffer.toString();

      _commitCurrentTurnToRecord();
    }
  }

  void _notifySolutionStream() {
    if (_solutionStreamThrottleTimer?.isActive ?? false) return;
    _solutionStreamThrottleTimer = Timer(const Duration(milliseconds: 80), () {
      if (!_disposed) {
        liveSolutionNotifier.value = _currentTurnSolutionBuffer
            .toString()
            .trim();
      }
    });
  }

  void _notifyThoughtsStream() {
    if (_thoughtsStreamThrottleTimer?.isActive ?? false) return;
    _thoughtsStreamThrottleTimer = Timer(const Duration(milliseconds: 80), () {
      if (!_disposed) {
        liveThoughtsNotifier.value = _currentTurnThoughtsBuffer.toString();
      }
    });
  }

  void _scrollToBottom(ScrollController controller) {
    if (!controller.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (controller.hasClients) {
        controller.animateTo(
          controller.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _commitCurrentTurnToRecord() {
    final solution = _currentTurnSolutionBuffer.toString().trim();
    final thoughts = _currentTurnThoughtsBuffer.toString().trim();

    if (solution.isEmpty && thoughts.isEmpty) return;

    final parsed = SolutionParser.parse(solution);

    final record = MathSolutionRecord(
      id: 'exam_${DateTime.now().millisecondsSinceEpoch}',
      timestamp: DateTime.now(),
      level: _curriculumLevel,
      problemSummary: parsed.summary,
      problemLevel: parsed.problemLevel,
      examinerIntent: parsed.examinerIntent,
      solutionMarkdown: solution,
      finalAnswer: parsed.finalAnswer,
      thinkingLog: thoughts,
      capturedImage: _lastProblemImage,
    );

    _solutionHistory.insert(0, record);
    _currentTurnSolutionBuffer.clear();
    _currentTurnThoughtsBuffer.clear();
    _lastProblemImage = null;
    _turnHasModelTextParts = false;
    notifyListeners();
    liveSolutionNotifier.value = '';
    liveThoughtsNotifier.value = '';
    liveSubtitleNotifier.value = '';

    unawaited(_historyRepo.save(_solutionHistory));
  }

  // ---------------------------------------------------------------------------
  // Video streaming, gallery picker & Snap & Solve
  // ---------------------------------------------------------------------------

  void _startCameraFrameLoop() {
    _cameraFrameTimer?.cancel();
    if (!_isAutoScanEnabled) return;

    unawaited(captureAndSendFrame());
    _cameraFrameTimer = Timer.periodic(_cameraFrameInterval, (_) {
      unawaited(captureAndSendFrame());
    });
  }

  Future<void> captureAndSendFrame({bool isManualSnap = false}) async {
    final controller = _cameraController;
    if (_captureInFlight ||
        controller == null ||
        !controller.value.isInitialized ||
        !_live.hasSession ||
        !_isConnected) {
      return;
    }

    _captureInFlight = true;
    try {
      final bytes = await _cameraService.capture(controller);

      // Compress and resize for real-time Live streaming
      final sendBytes = _imageService.compressForStreaming(
        bytes,
        errorLabel: 'Image',
      );

      if (isManualSnap) {
        _lastProblemImage = sendBytes;
      }

      _live.sendVideoFrame(sendBytes);

      if (isManualSnap) {
        final i18n = MathTutorI18n(
          AppLanguageController.instance.currentLanguage,
        );

        // Send problem image directly inside client content turn alongside prompt
        // to guarantee that the model receives and analyzes the exact problem image atomically.
        _live.sendProblemImage(sendBytes, i18n.snapSolvePrompt);

        if (!_disposed) {
          _isBottomSheetVisible = true;
          notifyListeners();
          HapticFeedback.mediumImpact();
          _notice(i18n.snapScanningSnackBar, MathTutorNoticeKind.camera);
        }
      }
    } catch (e) {
      debugPrint('Send camera frame error: $e');
    } finally {
      _captureInFlight = false;
    }
  }

  Future<void> pickAndSendImage() async {
    if (!_live.hasSession || !_isConnected) {
      _notice('세션이 연결되지 않았습니다. 잠시 후 다시 시도해 주세요.', MathTutorNoticeKind.info);
      return;
    }

    try {
      final bytes = await _imageService.pickFromGallery();
      if (bytes == null) return;

      final sendBytes = _imageService.compressForStreaming(
        bytes,
        errorLabel: 'Gallery image',
      );

      _lastProblemImage = sendBytes;

      _live.sendVideoFrame(sendBytes);

      // Prompt model to immediately inspect and solve the attached image
      final i18n = MathTutorI18n(
        AppLanguageController.instance.currentLanguage,
      );
      _live.sendProblemImage(sendBytes, i18n.snapSolvePrompt);

      if (!_disposed) {
        _isBottomSheetVisible = true;
        notifyListeners();
        HapticFeedback.mediumImpact();
        _notice(i18n.gallerySendingSnackBar, MathTutorNoticeKind.gallery);
      }
    } catch (e) {
      debugPrint('Pick image error: $e');
    }
  }

  /// Tells the view to confirm that a solution was copied.
  void notifyCopied() {
    _notice(
      MathTutorI18n(
        AppLanguageController.instance.currentLanguage,
      ).copiedSnackBar,
      MathTutorNoticeKind.copy,
    );
  }

  // ---------------------------------------------------------------------------
  // Microphone stream
  // ---------------------------------------------------------------------------

  Future<void> _startMicStream() async {
    try {
      final stream = await _mic.start(device: _selectedAudioDevice);
      if (stream == null) return;

      await _audioStreamSubscription?.cancel();
      _micChunkCount = 0;
      _audioStreamSubscription = stream.listen(
        _onMicChunk,
        onError: (e) {
          debugPrint('Microphone stream error: $e');
        },
        cancelOnError: false,
      );
      debugPrint('🎙️ Tutor mic stream listening.');
    } catch (e) {
      debugPrint('Mic stream start error: $e');
    }
  }

  void _onMicChunk(Uint8List chunk) {
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

    // Visual level meter notifier (scaled for responsive bar UI)
    liveMicVolumeNotifier.value = (_userMicVolume * 2.5).clamp(0.0, 1.0);

    // Acoustic echo & barge-in filtering:
    // AI가 발화 중일 때 스피커 소리가 마이크로 재유입되어 말을 끊지 않도록 방지
    if (isAiSpeaking) {
      // 스피커 소리가 마이크로 재유입되면 서버가 사용자 발화로 오인합니다.
      // 일시적인 큰 소리(에코)는 무시하고, 충분히 크고 지속적인 발화만
      // 의도적인 끼어들기(barge-in)로 인정합니다.
      if (_userMicVolume >= _bargeInVolumeThreshold) {
        _bargeInLoudChunks++;
      } else {
        _bargeInLoudChunks = 0;
      }
      if (_bargeInLoudChunks < _bargeInSustainedChunks) {
        // 청크를 버리면 스트림이 끊겨 서버 VAD/턴 처리가 멈추므로
        // 무음으로 대체해 전송합니다.
        if (_live.hasSession && _isConnected) {
          _live.sendAudioChunk(Uint8List(chunk.length));
        }
        return;
      }
      debugPrint(
        '🗣️ Intentional student barge-in detected (vol=${_userMicVolume.toStringAsFixed(3)})',
      );
    } else {
      _bargeInLoudChunks = 0;
    }

    _micChunkCount++;
    if (_micChunkCount % 40 == 1) {
      debugPrint(
        '🎙️ [Tutor Mic] Chunk #$_micChunkCount, len=${chunk.length}, vol=${_userMicVolume.toStringAsFixed(3)}, connected=$_isConnected',
      );
    }

    if (!_live.hasSession || !_isConnected) return;

    _live.sendAudioChunk(chunk);
  }

  // ---------------------------------------------------------------------------
  // Curriculum
  // ---------------------------------------------------------------------------

  Future<void> switchCurriculum(MathCurriculumLevel level) async {
    if (_curriculumLevel == level) return;
    _curriculumLevel = level;
    notifyListeners();

    // Prompt context update via sendClientContent
    if (_live.hasSession && _isConnected) {
      try {
        _live.sendUserText(
          '[Student Notice]: Curriculum focus preference updated to "${level.labelKo}". '
          '${level.promptHint}',
        );
      } catch (e) {
        debugPrint('Failed to update curriculum level: $e');
      }
    }
  }
}
