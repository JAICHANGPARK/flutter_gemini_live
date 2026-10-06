import 'dart:async';
import 'dart:ui' show AppLifecycleState;

import 'package:camera/camera.dart';
import 'package:example/api_key_store.dart';
import 'package:example/live_api_defaults.dart';
import 'package:flutter/foundation.dart';
import 'package:gemini_live/gemini_live.dart';

import '../../../data/repositories/media_log_repository.dart';
import '../../../data/services/realtime_media_audio_service.dart';
import '../../../data/services/realtime_media_camera_service.dart';
import '../../../data/services/realtime_media_image_service.dart';
import '../../../data/services/realtime_media_live_service.dart';
import '../../../data/services/realtime_media_mic_service.dart';
import '../../../domain/camera_text.dart';
import '../../../domain/models/media_log.dart';

/// State + logic for the Realtime Media demo screen.
///
/// All state notifies through [ChangeNotifier]; the screen wraps its tree in a
/// single `ListenableBuilder`. The view model never touches a `BuildContext`.
class RealtimeMediaViewModel extends ChangeNotifier {
  RealtimeMediaViewModel({
    RealtimeMediaLiveService? liveService,
    RealtimeMediaAudioService? audioService,
    RealtimeMediaMicService? micService,
    RealtimeMediaCameraService? cameraService,
    RealtimeMediaImageService? imageService,
    MediaLogRepository? logRepository,
  }) : _live = liveService ?? RealtimeMediaLiveService(),
       _audio = audioService ?? RealtimeMediaAudioService(),
       _mic = micService ?? RealtimeMediaMicService(),
       _cameraService = cameraService ?? RealtimeMediaCameraService(),
       _imageService = imageService ?? RealtimeMediaImageService(),
       _logRepo = logRepository ?? MediaLogRepository();

  static const _cameraFrameInterval = Duration(milliseconds: 1200);

  final RealtimeMediaLiveService _live;
  final RealtimeMediaAudioService _audio;
  final RealtimeMediaMicService _mic;
  final RealtimeMediaCameraService _cameraService;
  final RealtimeMediaImageService _imageService;
  final MediaLogRepository _logRepo;

  CameraController? _cameraController;
  StreamSubscription<Uint8List>? _audioStreamSubscription;
  Timer? _cameraFrameTimer;

  bool _disposed = false;

  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isSendingVideo = false;
  bool _isCameraInitializing = false;
  bool _isStreamingAudio = false;
  bool _isStreamingCamera = false;
  bool _captureInFlight = false;

  final List<CameraDescription> _availableCameras = [];

  // Activity detection mode
  bool _manualActivityMode = false;
  bool _isActivityActive = false;
  bool _isAutomaticSpeechActive = false;

  int _selectedCameraIndex = 0;
  int _audioChunksSent = 0;
  int _videoFramesSent = 0;

  // --- Read-only state for the view ---

  bool get isConnected => _isConnected;
  bool get isConnecting => _isConnecting;
  bool get isSendingVideo => _isSendingVideo;
  bool get isCameraInitializing => _isCameraInitializing;
  bool get isStreamingAudio => _isStreamingAudio;
  bool get isStreamingCamera => _isStreamingCamera;
  bool get isActivityActive => _isActivityActive;
  bool get manualActivityMode => _manualActivityMode;
  int get selectedCameraIndex => _selectedCameraIndex;
  int get audioChunksSent => _audioChunksSent;
  int get videoFramesSent => _videoFramesSent;
  List<MediaLog> get logs => _logRepo.logs;
  List<CameraDescription> get availableCameras => _availableCameras;
  CameraController? get cameraController => _cameraController;

  bool get cameraReady => _cameraController?.value.isInitialized ?? false;
  bool get cameraInputActive =>
      _manualActivityMode ? _isActivityActive : _isAutomaticSpeechActive;

  set manualActivityMode(bool value) {
    _manualActivityMode = value;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  /// Equivalent of the page's `initState` body after the observer and client
  /// are set up.
  void init() {
    unawaited(_loadAvailableCameras());
  }

  @override
  void dispose() {
    _cameraFrameTimer?.cancel();
    _audioStreamSubscription?.cancel();
    unawaited(_mic.stop());
    unawaited(_mic.dispose());
    unawaited(_cameraController?.dispose() ?? Future<void>.value());
    unawaited(_live.close());
    unawaited(_audio.dispose());
    _disposed = true;
    super.dispose();
  }

  void handleAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _cameraFrameTimer?.cancel();
      unawaited(controller.dispose());
      if (!_disposed) {
        _cameraController = null;
        _isStreamingCamera = false;
        notifyListeners();
      }
    } else if (state == AppLifecycleState.resumed &&
        _availableCameras.isNotEmpty) {
      unawaited(
        _initializeCameraController(
          _availableCameras[_selectedCameraIndex],
          logStatus: false,
        ),
      );
    }
  }

  void _addLog(String type, String message) {
    if (_disposed) return;
    _logRepo.add(type, message);
    notifyListeners();
  }

  Future<void> _loadAvailableCameras() async {
    try {
      final cameras = await _cameraService.listCameras();
      if (_disposed) return;

      _availableCameras
        ..clear()
        ..addAll(cameras);
      if (_selectedCameraIndex >= _availableCameras.length) {
        _selectedCameraIndex = 0;
      }
      notifyListeners();

      if (cameras.isEmpty) {
        _addLog('VIDEO', '⚠️ No camera devices were found on this platform.');
        return;
      }

      await _initializeCameraController(
        _availableCameras[_selectedCameraIndex],
        logStatus: false,
      );
    } on CameraException catch (error) {
      _addLog(
        'ERROR',
        '❌ Camera is unavailable: ${describeCameraError(error)}',
      );
    } catch (error) {
      _addLog('ERROR', '❌ Camera is unavailable: $error');
    }
  }

  Future<void> _initializeCameraController(
    CameraDescription description, {
    bool logStatus = true,
  }) async {
    if (_isCameraInitializing) return;

    _isCameraInitializing = true;
    notifyListeners();

    final previousController = _cameraController;

    try {
      await previousController?.dispose();

      final controller = await _cameraService.createAndInitialize(description);

      if (_disposed) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;
      _isCameraInitializing = false;
      notifyListeners();

      if (logStatus) {
        _addLog('VIDEO', '✅ Camera ready: ${cameraLabel(description)}');
      }
    } on CameraException catch (error) {
      if (_disposed) return;
      _cameraController = null;
      _isCameraInitializing = false;
      notifyListeners();
      _addLog('ERROR', '❌ Camera init failed: ${describeCameraError(error)}');
    } catch (error) {
      if (_disposed) return;
      _cameraController = null;
      _isCameraInitializing = false;
      notifyListeners();
      _addLog('ERROR', '❌ Camera init failed: $error');
    }
  }

  Future<bool> ensureCameraReady() async {
    if (cameraReady) return true;

    if (_availableCameras.isEmpty) {
      await _loadAvailableCameras();
    }

    if (_availableCameras.isEmpty) {
      _addLog(
        'ERROR',
        '❌ Camera preview is unavailable. Check camera access and whether a camera device is attached.',
      );
      return false;
    }

    await _initializeCameraController(_availableCameras[_selectedCameraIndex]);
    return cameraReady;
  }

  Future<void> switchCamera() async {
    if (_availableCameras.length < 2 || _isCameraInitializing) return;

    final shouldResumeFrames = _isStreamingCamera;
    _cameraFrameTimer?.cancel();

    _selectedCameraIndex =
        (_selectedCameraIndex + 1) % _availableCameras.length;
    _isStreamingCamera = false;
    notifyListeners();

    await _initializeCameraController(_availableCameras[_selectedCameraIndex]);

    if (shouldResumeFrames && cameraReady) {
      _startCameraFrameLoop();
    }
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
      'Connecting to Live API with Gemini 3.8 Live ($kLatestRealtimeLiveModel)...',
    );
    await _audio.stop();

    try {
      final session = await _live.connect(
        manualActivityMode: _manualActivityMode,
        onOpen: () {
          _addLog('CONNECTION', '✅ Connected');
          if (_disposed) return;
          _isConnected = true;
          _isConnecting = false;
          notifyListeners();
        },
        onMessage: _handleMessage,
        onError: (error, stack) {
          unawaited(stopLiveMultimodalStream(sendAudioStreamEnd: false));
          unawaited(_audio.stop());
          _addLog('ERROR', '❌ $error');
          if (_disposed) return;
          _isConnected = false;
          _isConnecting = false;
          notifyListeners();
        },
        onClose: (code, reason) {
          unawaited(stopLiveMultimodalStream(sendAudioStreamEnd: false));
          unawaited(_audio.stop());
          _addLog('CONNECTION', '🔒 Disconnected');
          if (_disposed) return;
          _isConnected = false;
          _isConnecting = false;
          notifyListeners();
        },
      );

      if (_disposed) return;
      _live.session = session;
      notifyListeners();
    } catch (error) {
      _addLog('ERROR', '❌ Connection failed: $error');
      if (_disposed) return;
      _isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    await stopLiveMultimodalStream();
    await _audio.stop();
    await _live.close();
    if (_disposed) return;
    _live.session = null;
    _isConnected = false;
    _isConnecting = false;
    notifyListeners();
  }

  void _handleMessage(LiveServerMessage message) {
    final serverContent = message.serverContent;
    final turnFinished =
        (serverContent?.turnComplete ?? false) ||
        (serverContent?.generationComplete ?? false);

    if (serverContent?.interrupted ?? false) {
      _audio.clear();
    }

    final textChunk = visibleModelText(message);
    if (textChunk != null) {
      _addLog('TEXT', '🤖 $textChunk');
    }

    if (message.data != null) {
      _audio.appendBase64Chunk(message.data!);
      _addLog('AUDIO', '🔊 Received audio: ${message.data!.length} chars');
    }

    if (message.serverContent?.inputTranscription != null) {
      final transcription = message.serverContent!.inputTranscription!;
      _addLog('TRANSCRIPTION', '🎤 Input: ${transcription.text}');
    }
    if (message.serverContent?.outputTranscription != null) {
      final transcription = message.serverContent!.outputTranscription!;
      _addLog('TRANSCRIPTION', '🔈 Output: ${transcription.text}');
    }

    if (message.voiceActivity != null) {
      if (!_manualActivityMode && !_disposed) {
        _isAutomaticSpeechActive = message.voiceActivity!.speechActive == true;
        notifyListeners();
      }
      _addLog(
        'VAD',
        '🎤 ${message.voiceActivity!.speechActive == true ? "Speaking" : "Silent"}',
      );
    }
    if (message.voiceActivityDetectionSignal != null) {
      final signal = message.voiceActivityDetectionSignal!;
      if (signal.start == true) {
        _addLog('VAD', '🎙️ Speech started');
        if (!_manualActivityMode) {
          if (!_disposed) {
            _isAutomaticSpeechActive = true;
            notifyListeners();
          } else {
            _isAutomaticSpeechActive = true;
          }
          if (_isStreamingAudio && !_isStreamingCamera) {
            _startCameraFrameLoop(logStart: true);
          }
        }
      }
      if (signal.end == true) {
        _addLog('VAD', '🎙️ Speech ended');
        if (!_manualActivityMode) {
          if (!_disposed) {
            _isAutomaticSpeechActive = false;
            notifyListeners();
          } else {
            _isAutomaticSpeechActive = false;
          }
          _stopCameraFrameLoop(logStop: true);
        }
      }
    }

    if (turnFinished && _audio.hasBufferedAudio) {
      _addLog('AUDIO', '▶️ Playing received audio');
      unawaited(_audio.playBufferedAudio());
    }
  }

  void sendRealtimeText(String text) {
    if (_live.session == null || !_isConnected) return;
    _addLog('USER', '💬 Realtime text: $text');
    _live.sendRealtimeText(text);
  }

  void toggleActivity() {
    if (_live.session == null || !_isConnected) return;

    _isActivityActive = !_isActivityActive;
    notifyListeners();

    if (_isActivityActive) {
      _addLog('ACTIVITY', '🎙️ Activity START');
      _live.sendActivityStart();
      if (_isStreamingAudio) {
        _startCameraFrameLoop(logStart: true);
      }
    } else {
      _addLog('ACTIVITY', '🎙️ Activity END');
      _live.sendActivityEnd();
      _stopCameraFrameLoop(logStop: true);
    }
  }

  void sendAudioStreamEnd() {
    if (_live.session == null || !_isConnected) return;
    _addLog('AUDIO', '🔇 Audio stream end signal');
    _live.sendAudioStreamEnd();
  }

  Future<void> pickAndSendImage() async {
    if (_live.session == null || !_isConnected) return;

    final image = await _imageService.pickFromGallery();

    if (image == null) return;

    _isSendingVideo = true;
    notifyListeners();
    _addLog('VIDEO', '📷 Sending image...');

    try {
      final bytes = await image.readAsBytes();
      _live.sendVideo(bytes);
      _addLog('VIDEO', '✅ Image sent: ${bytes.length} bytes');
    } catch (error) {
      _addLog('ERROR', '❌ Failed to send image: $error');
    }

    if (!_disposed) {
      _isSendingVideo = false;
      notifyListeners();
    }
  }

  Future<void> sendMediaChunks() async {
    if (_live.session == null || !_isConnected) return;

    _addLog('MEDIA', '📦 Sending media chunks...');

    final count = _live.sendDemoMediaChunks();
    _addLog('MEDIA', '✅ Sent $count chunks');
  }

  Future<void> sendCombinedRealtimeInput() async {
    if (_live.session == null || !_isConnected) return;

    final ready = await ensureCameraReady();
    if (!ready) return;

    await _captureAndSendCameraFrame(logUpload: true);
    _live.sendRealtimeText(
      'Describe what you see in the current camera frame.',
    );
    _addLog('USER', '🔄 Sent current camera frame with a prompt');
  }

  Future<void> startLiveMultimodalStream() async {
    if (_live.session == null || !_isConnected) {
      _addLog('ERROR', '❌ Connect to the Live session first.');
      return;
    }
    if (_isStreamingAudio || _isStreamingCamera) return;

    final hasMicPermission = await _mic.hasPermission();
    if (!hasMicPermission) {
      _addLog('ERROR', '❌ Microphone permission is required.');
      return;
    }

    final ready = await ensureCameraReady();
    if (!ready) return;

    try {
      final stream = await _mic.startStream();

      await _audioStreamSubscription?.cancel();
      _audioChunksSent = 0;
      _videoFramesSent = 0;

      _audioStreamSubscription = stream.listen(
        (chunk) {
          if (_live.session == null || !_isConnected) return;

          _live.sendAudioChunk(chunk);

          if (!_disposed && _audioChunksSent % 12 == 0) {
            notifyListeners();
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          _addLog('ERROR', '❌ Audio stream failed: $error');
          unawaited(stopLiveMultimodalStream(sendAudioStreamEnd: false));
        },
        cancelOnError: true,
      );

      if (_manualActivityMode && !_isActivityActive) {
        _live.sendActivityStart();
        _addLog('ACTIVITY', '🎙️ Activity START (live camera + voice)');
        _isActivityActive = true;
      }

      if (_disposed) return;
      _isStreamingAudio = true;
      _isStreamingCamera = _manualActivityMode;
      notifyListeners();

      _addLog('AUDIO', '🎤 Microphone streaming started (16 kHz PCM)');
      if (_manualActivityMode) {
        _addLog(
          'VIDEO',
          '📹 Camera frame streaming started (${_cameraFrameInterval.inMilliseconds} ms snapshots)',
        );
        _startCameraFrameLoop();
      } else {
        _addLog(
          'VIDEO',
          '📹 Auto mode is armed. Camera frames upload only while speech is detected.',
        );
      }
    } catch (error) {
      _addLog('ERROR', '❌ Failed to start live camera + voice stream: $error');
    }
  }

  void _startCameraFrameLoop({bool logStart = false}) {
    if (_cameraFrameTimer != null) return;
    if (!_disposed) {
      _isStreamingCamera = true;
      notifyListeners();
    } else {
      _isStreamingCamera = true;
    }

    if (logStart) {
      _addLog(
        'VIDEO',
        '📹 Camera frame streaming started (${_cameraFrameInterval.inMilliseconds} ms snapshots)',
      );
    }

    unawaited(_captureAndSendCameraFrame(logUpload: true));
    _cameraFrameTimer = Timer.periodic(
      _cameraFrameInterval,
      (_) => unawaited(_captureAndSendCameraFrame()),
    );
  }

  void _stopCameraFrameLoop({bool logStop = false}) {
    final wasStreaming = _cameraFrameTimer != null || _isStreamingCamera;
    _cameraFrameTimer?.cancel();
    _cameraFrameTimer = null;

    if (!_disposed) {
      _isStreamingCamera = false;
      notifyListeners();
    } else {
      _isStreamingCamera = false;
    }

    if (logStop && wasStreaming) {
      _addLog('VIDEO', '⏹️ Camera frame streaming stopped');
    }
  }

  Future<void> _captureAndSendCameraFrame({bool logUpload = false}) async {
    final controller = _cameraController;
    if (_captureInFlight ||
        controller == null ||
        !controller.value.isInitialized ||
        _live.session == null ||
        !_isConnected) {
      return;
    }

    _captureInFlight = true;

    try {
      final bytes = await _cameraService.capture(controller);

      _live.sendVideoFrame(bytes);

      _videoFramesSent += 1;

      if (logUpload || _videoFramesSent % 5 == 0) {
        _addLog(
          'VIDEO',
          '📸 Sent live camera frame #$_videoFramesSent (${bytes.length} bytes)',
        );
      } else if (!_disposed) {
        notifyListeners();
      }
    } catch (error) {
      _addLog('ERROR', '❌ Camera frame upload failed: $error');
    } finally {
      _captureInFlight = false;
    }
  }

  Future<void> stopLiveMultimodalStream({
    bool sendAudioStreamEnd = true,
  }) async {
    final wasStreamingAudio = _isStreamingAudio;
    final wasStreamingCamera = _isStreamingCamera;

    _stopCameraFrameLoop();

    await _audioStreamSubscription?.cancel();
    _audioStreamSubscription = null;

    if (wasStreamingAudio) {
      if (sendAudioStreamEnd && _live.session != null && _isConnected) {
        _live.sendAudioStreamEnd();
      }

      try {
        await _mic.stop();
      } catch (_) {
        // Ignore recorder shutdown errors during teardown.
      }
    }

    if (_manualActivityMode &&
        _isActivityActive &&
        _live.session != null &&
        _isConnected) {
      _live.sendActivityEnd();
      _addLog('ACTIVITY', '🎙️ Activity END (live camera + voice)');
      _isActivityActive = false;
    }

    _isAutomaticSpeechActive = false;

    if (_disposed) return;
    _isStreamingAudio = false;
    _captureInFlight = false;
    notifyListeners();

    if (wasStreamingAudio) {
      _addLog('AUDIO', '⏹️ Microphone streaming stopped');
    }
    if (wasStreamingCamera) {
      _addLog('VIDEO', '⏹️ Camera frame streaming stopped');
    }
  }
}
